using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Screen space global illumination: the reflections' DIFFUSE twin.
///
/// A few cosine weighted hemisphere rays per pixel are marched against the depth buffer, and
/// the lit scene is gathered at each hit as one bounce of radiance. The result is accumulated
/// against a reprojected history and composited into the scene. The forward already lit every
/// surface with the sky's ambient as if nothing stood in the way; a ray that hits geometry
/// finds what really is in that direction, so the composite swaps the sky light for the bounce
/// there: out = hdr + albedo * (bounce - hitShare * skyRadiance) * intensity, skyRadiance being
/// the pixel's own ambient (the scene's SH sky over its normal, plus the flat fill). The bounce
/// is tinted by the G-buffer's diffuse albedo, and occluded corners darken instead of lifting.
/// (A unit albedo, purely additive composite washed colours out and erased contact shadows,
/// counting the sky twice.)
///
/// FOUR PASSES. The gather source is prefiltered to a quarter of the resolution first, which
/// is the structural fix for fireflies: every tap the trace takes is already a mean of some
/// sixteen pixels, so the variance dies at its source rather than being chased afterwards.
/// The trace then fills a bounce buffer, a depth aware blur has neighbours share their hits,
/// and the resolve accumulates and composites. At one to four rays the raw estimate cannot
/// converge on its own, so both the spatial and the temporal step are load bearing.
class SsgiPass
{
	/// Matches the scene's own.
	private const TextureFormat cHdrFormat = .RGBA16Float;
	private const int cMaxViews = 8;
	private const uint32 cRetireFrames = 4;
	/// The scene's SH9 irradiance: nine float4s.
	private const uint64 cShBytes = sizeof(Float4) * 9;

	private struct ViewHistory
	{
		public ITexture[2] Textures;
		public ITextureView[2] Views;
		public ResourceState[2] States;
		public uint32 Width;
		public uint32 Height;
		public uint32 Current;
		public bool Valid;
	}

	private struct Entry
	{
		public IBindGroup BindGroup;
		public ITextureView Depth;
		public ITextureView Normal;
		public uint64 Generation;
	}

	private struct DownEntry
	{
		public IBindGroup BindGroup;
		public uint64 Generation;
	}

	private struct BlurEntry
	{
		public IBindGroup BindGroup;
		public ITextureView Depth;
		public uint64 Generation;
	}

	private struct Retired
	{
		public IBindGroup BindGroup;
		public uint32 FramesLeft;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;

	private IBindGroupLayout mDownLayout = null;
	private IPipelineLayout mDownPipelineLayout = null;
	private IRenderPipeline mDownPipeline = null;

	private IBindGroupLayout mBlurLayout = null;
	private IPipelineLayout mBlurPipelineLayout = null;
	private IRenderPipeline mBlurPipeline = null;

	private IBindGroupLayout mResolveLayout = null;
	private IPipelineLayout mResolvePipelineLayout = null;
	private IRenderPipeline mResolvePipeline = null;
	private uint64 mPipelineShaderVersion = 0;

	/// Point, for the depth and the reconstruction; linear, for the radiance gather.
	private ISampler mSampler = null;
	private ISampler mLinearSampler = null;

	private ViewHistory[cMaxViews] mViews = .();
	private Dictionary<int, Entry> mBindGroups = new .() ~ delete _;
	private Dictionary<int, DownEntry> mDownBindGroups = new .() ~ delete _;
	private Dictionary<int, BlurEntry> mBlurBindGroups = new .() ~ delete _;
	/// The resolve's groups, one per history view being read, rebuilt when ANY of its inputs
	/// (the filtered bounce, velocity, HDR, albedo, normal, and the SH sky with its context's
	/// generation) is a different one.
	private BindGroupCache<5> mResolveBindGroups = new .() ~ delete _;
	/// Bound in the SH slot when a scene has no SH sky: the composite then never reads it (its
	/// dimmer is nought), so its contents do not matter.
	private IBuffer mDummyShBuffer = null;
	private List<Retired> mRetired = new .() ~ delete _;
	private uint32 mLastFrame = 0xFFFFFFFF;

	public this(IDevice device, ShaderSystem shaders)
	{
		mDevice = device;
		mShaders = shaders;
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		var traceEntries = BindGroupLayoutEntry[5](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment),
			BindGroupLayoutEntry.Sampler(1, .Fragment));

		// The depth is read as DATA through the point sampler, so it is declared unfilterable
		// and that sampler non filtering.
		traceEntries[1].TextureSampleType = .UnfilterableFloat;
		traceEntries[3].SamplerNonFiltering = true;

		var traceLayoutDesc = BindGroupLayoutDesc();
		traceLayoutDesc.Entries = .(&traceEntries[0], 5);
		if (!(mDevice.CreateBindGroupLayout(traceLayoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		mPipelineLayout = MakePipelineLayout(mLayout, sizeof(SsgiPush));
		if (mPipelineLayout == null)
			return .Err;

		var pointDesc = SamplerDesc();
		pointDesc.MinFilter = .Nearest;
		pointDesc.MagFilter = .Nearest;
		pointDesc.MipmapFilter = .Nearest;
		pointDesc.AddressU = .ClampToEdge;
		pointDesc.AddressV = .ClampToEdge;
		pointDesc.AddressW = .ClampToEdge;
		pointDesc.Label = "ssgi.sampler";
		if (!(mDevice.CreateSampler(pointDesc) case .Ok(let point)))
			return .Err;
		mSampler = point;

		var linearDesc = SamplerDesc();
		linearDesc.MinFilter = .Linear;
		linearDesc.MagFilter = .Linear;
		linearDesc.AddressU = .ClampToEdge;
		linearDesc.AddressV = .ClampToEdge;
		linearDesc.AddressW = .ClampToEdge;
		linearDesc.Label = "ssgi.linear";
		if (!(mDevice.CreateSampler(linearDesc) case .Ok(let linear)))
			return .Err;
		mLinearSampler = linear;

		if (!CreateTracePipeline())
			return .Err;

		// The radiance prefilter: the full resolution scene through a linear sampler.
		var downEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var downLayoutDesc = BindGroupLayoutDesc();
		downLayoutDesc.Entries = .(&downEntries[0], 2);
		if (!(mDevice.CreateBindGroupLayout(downLayoutDesc) case .Ok(let downLayout)))
			return .Err;
		mDownLayout = downLayout;

		mDownPipelineLayout = MakePipelineLayout(mDownLayout, sizeof(SsgiDownPush));
		if (mDownPipelineLayout == null)
			return .Err;

		if (!CreateDownPipeline())
			return .Err;

		// The spatial denoise: the raw bounce and the depth, both read as data.
		var blurEntries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		blurEntries[1].TextureSampleType = .UnfilterableFloat;
		blurEntries[2].SamplerNonFiltering = true;

		var blurLayoutDesc = BindGroupLayoutDesc();
		blurLayoutDesc.Entries = .(&blurEntries[0], 3);
		if (!(mDevice.CreateBindGroupLayout(blurLayoutDesc) case .Ok(let blurLayout)))
			return .Err;
		mBlurLayout = blurLayout;

		mBlurPipelineLayout = MakePipelineLayout(mBlurLayout, sizeof(SsgiBlurPush));
		if (mBlurPipelineLayout == null)
			return .Err;

		if (!CreateBlurPipeline())
			return .Err;

		// The resolve: the bounce, its history, the velocity, the scene, the albedo, the normal
		// and the scene's SH sky.
		var resolveEntries = BindGroupLayoutEntry[9](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.SampledTexture(3, .Fragment),
			BindGroupLayoutEntry.SampledTexture(4, .Fragment),
			BindGroupLayoutEntry.SampledTexture(5, .Fragment),
			BindGroupLayoutEntry.StorageBuffer(6, .Fragment, true, sizeof(Float4)),
			BindGroupLayoutEntry.Sampler(0, .Fragment),
			BindGroupLayoutEntry.Sampler(1, .Fragment));

		var resolveLayoutDesc = BindGroupLayoutDesc();
		resolveLayoutDesc.Entries = .(&resolveEntries[0], 9);
		if (!(mDevice.CreateBindGroupLayout(resolveLayoutDesc) case .Ok(let resolveLayout)))
			return .Err;
		mResolveLayout = resolveLayout;

		mResolvePipelineLayout = MakePipelineLayout(mResolveLayout, sizeof(SsgiResolvePush));
		if (mResolvePipelineLayout == null)
			return .Err;

		if (!CreateResolvePipeline())
			return .Err;

		var shDesc = BufferDesc();
		shDesc.Size = cShBytes;
		shDesc.Usage = .Storage;
		shDesc.Memory = .GpuOnly;
		shDesc.Label = "ssgi.dummySH";
		if (!(mDevice.CreateBuffer(shDesc) case .Ok(let shBuffer)))
			return .Err;
		mDummyShBuffer = shBuffer;

		mPipelineShaderVersion = ShaderVersion();
		return .Ok;
	}

	/// Forgets history slot `slot`'s accumulated state, the frame having handed the slot to
	/// another view (RenderFrame.HistorySlotFor): its next frame starts fresh rather than
	/// blending in what the slot's previous view saw.
	public void InvalidateHistory(uint32 slot)
	{
		if (slot < cMaxViews)
			mViews[slot].Valid = false;
	}

	/// Bounces the scene into a fresh transient, and answers it. The scene comes back
	/// unchanged when it cannot run.
	public RGHandle DeclareSsgi(RenderGraph graph, RGHandle hdr, RGHandle depth, RGHandle normal,
		RGHandle velocity, RGHandle albedo, SsgiSky sky, uint32 width, uint32 height, int32 viewportX, int32 viewportY,
		uint32 viewportWidth, uint32 viewportHeight, Float4x4 invProj, Float4x4 proj,
		SsgiParams parameters, uint32 viewIndex, uint32 frameIndex)
	{
		if ((width == 0) || (height == 0) || (viewIndex >= cMaxViews))
			return hdr;

		let shaderVersion = ShaderVersion();
		if (shaderVersion != mPipelineShaderVersion)
		{
			if (mPipeline != null)
				mDevice.DestroyRenderPipeline(ref mPipeline);
			if (mDownPipeline != null)
				mDevice.DestroyRenderPipeline(ref mDownPipeline);
			if (mBlurPipeline != null)
				mDevice.DestroyRenderPipeline(ref mBlurPipeline);
			if (mResolvePipeline != null)
				mDevice.DestroyRenderPipeline(ref mResolvePipeline);

			CreateTracePipeline();
			CreateDownPipeline();
			CreateBlurPipeline();
			CreateResolvePipeline();
			mPipelineShaderVersion = shaderVersion;

			if ((mPipeline == null) || (mDownPipeline == null) || (mBlurPipeline == null)
				|| (mResolvePipeline == null))
			{
				// A reloaded shader that no longer matches this binary, its push block having
				// grown say, fails to build and the pass silently stops. Say so once per
				// version rather than leaving only the validation noise.
				Console.Error.WriteLine("Render: the bounce pipelines failed to rebuild after a shader reload, so the pass is off");
			}
		}

		if ((mPipeline == null) || (mDownPipeline == null) || (mBlurPipeline == null)
			|| (mResolvePipeline == null))
			return hdr;

		Tick(frameIndex);

		let fullWidth = (float)width;
		let fullHeight = (float)height;
		let vpMin = Float2((float)viewportX / fullWidth, (float)viewportY / fullHeight);
		let vpSize = Float2((float)viewportWidth / fullWidth, (float)viewportHeight / fullHeight);
		let texelSize = Float2(1.0f / fullWidth, 1.0f / fullHeight);

		// The prefilter: a quarter resolution box average of the lit scene, which is what the
		// trace gathers from. Every tap is then already a mean of some sixteen pixels, so the
		// fireflies never arise rather than being denoised away afterwards.
		let quarterWidth = (width / 4 > 0) ? width / 4 : 1;
		let quarterHeight = (height / 4 > 0) ? height / 4 : 1;
		let sceneQuarter = graph.CreateTransient("ssgi.scene.quarter",
			.(cHdrFormat, quarterWidth, quarterHeight));

		var downPush = SsgiDownPush();
		downPush.SrcTexelSize = texelSize;

		graph.AddRenderPass("ssgi.down", scope (builder) =>
			{
				builder.SetColorTarget(0, sceneQuarter, .Clear, .Store, .Black);
				builder.ReadTexture(hdr);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureDownBindGroup(graph.GetTextureView(hdr),
							graph.GetTextureGeneration(hdr));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mDownPipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = downPush;
						encoder.SetPushConstants(.Fragment, 0, sizeof(SsgiDownPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		// The trace: one bounce of radiance, with the hit fraction in the fourth channel.
		let bounce = graph.CreateTransient("ssgi.raw", .(cHdrFormat, width, height));

		var tracePush = SsgiPush();
		tracePush.InvProj = invProj;
		tracePush.VpMin = vpMin;
		tracePush.VpSize = vpSize;
		tracePush.Jitter = .(proj[2, 0], proj[2, 1]);
		tracePush.ProjXX = proj[0, 0];
		tracePush.ProjYY = proj[1, 1];
		tracePush.Thickness = (parameters.Thickness > 1e-3f) ? parameters.Thickness : 1e-3f;
		tracePush.Radius = (parameters.Radius > 1e-2f) ? parameters.Radius : 1e-2f;
		tracePush.MaxSteps = (parameters.MaxSteps > 1) ? parameters.MaxSteps : 1;
		tracePush.RayCount = Clamp(parameters.RayCount, 1, 4);
		tracePush.YSign = mDevice.NeedsClipSpaceYFlip ? 1.0f : -1.0f;
		tracePush.FrameIndex = frameIndex;
		tracePush.MaxRadiance = (parameters.MaxRadiance > 0.1f) ? parameters.MaxRadiance : 0.1f;

		graph.AddRenderPass("ssgi.trace", scope (builder) =>
			{
				builder.SetColorTarget(0, bounce, .Clear, .Store, .Black);
				builder.ReadTexture(sceneQuarter);
				builder.ReadTexture(depth);
				builder.ReadTexture(normal);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureBindGroup(graph.GetTextureView(sceneQuarter),
							graph.GetTextureView(depth), graph.GetTextureView(normal),
							Combine(graph, sceneQuarter, depth, normal));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mPipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = tracePush;
						encoder.SetPushConstants(.Fragment, 0, sizeof(SsgiPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		// The spatial denoise: neighbours share their hits, depth aware, before the frames are
		// accumulated. At one to four rays the raw estimate alone cannot converge.
		let filtered = graph.CreateTransient("ssgi.filtered", .(cHdrFormat, width, height));

		var blurPush = SsgiBlurPush();
		blurPush.TexelSize = texelSize;
		blurPush.DepthSigma = (parameters.DepthSigma > 1e-3f) ? parameters.DepthSigma : 1e-3f;
		blurPush.InvProj = invProj;
		blurPush.VpMin = vpMin;
		blurPush.VpSize = vpSize;
		blurPush.YSign = mDevice.NeedsClipSpaceYFlip ? 1.0f : -1.0f;

		graph.AddRenderPass("ssgi.blur", scope (builder) =>
			{
				builder.SetColorTarget(0, filtered, .Clear, .Store, .Black);
				builder.ReadTexture(bounce);
				builder.ReadTexture(depth);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureBlurBindGroup(graph.GetTextureView(bounce),
							graph.GetTextureView(depth),
							graph.GetTextureGeneration(bounce)
							^ (graph.GetTextureGeneration(depth) &* 1099511628211UL));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mBlurPipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = blurPush;
						encoder.SetPushConstants(.Fragment, 0, sizeof(SsgiBlurPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		// The resolve: reproject, clip against the neighbourhood, accumulate, then composite.
		if (!EnsureHistory(ref mViews[viewIndex], width, height))
			return hdr;

		let currentSlot = mViews[viewIndex].Current;
		let previousSlot = currentSlot ^ 1;

		let composited = graph.CreateTransient("ssgi.scene", .(cHdrFormat, width, height));

		let historyPrevious = graph.ImportTarget("ssgi.histPrev",
			mViews[viewIndex].Textures[previousSlot], mViews[viewIndex].Views[previousSlot],
			ResourceState.ShaderRead, mViews[viewIndex].States[previousSlot]);
		mViews[viewIndex].States[previousSlot] = .ShaderRead;

		let historyCurrent = graph.ImportTarget("ssgi.histCur",
			mViews[viewIndex].Textures[currentSlot], mViews[viewIndex].Views[currentSlot],
			ResourceState.RenderTarget, mViews[viewIndex].States[currentSlot]);
		mViews[viewIndex].States[currentSlot] = .RenderTarget;

		var resolvePush = SsgiResolvePush();
		resolvePush.VpMin = vpMin;
		resolvePush.VpSize = vpSize;
		resolvePush.TexelSize = texelSize;
		resolvePush.BlendFactor = parameters.HistoryBlend;
		resolvePush.HistoryValid = mViews[viewIndex].Valid ? 1.0f : 0.0f;
		resolvePush.VarianceGamma = parameters.VarianceGamma;
		resolvePush.MotionScale = parameters.MotionScale;
		resolvePush.TemporalOn = parameters.Temporal ? 1 : 0;
		resolvePush.Debug = parameters.Debug;
		resolvePush.GhostReject = parameters.GhostReject;
		resolvePush.Intensity = (parameters.Intensity >= 0.0f) ? parameters.Intensity : 0.0f;
		// The ambient a hit replaces: the camera's world rotation turns the G-buffer's view space
		// normal to world space, where the SH sky is. No SH sky is the flat fill alone, as in
		// the forward.
		for (int row < 3)
		{
			resolvePush.ViewToWorld[row] = .(sky.ViewToWorld[row, 0], sky.ViewToWorld[row, 1],
				sky.ViewToWorld[row, 2], 0.0f);
		}
		let shSky = sky.ShBuffer != null;
		resolvePush.SkyAmbient = .(sky.Ambient.X, sky.Ambient.Y, sky.Ambient.Z, shSky ? sky.IblDiffuse : 0.0f);
		let shBuffer = shSky ? sky.ShBuffer : mDummyShBuffer;
		let shGeneration = shSky ? sky.Generation : 0;
		let shHandle = shSky ? sky.ShHandle : RGHandle.Invalid;

		let previousView = mViews[viewIndex].Views[previousSlot];

		graph.AddRenderPass("ssgi.resolve", scope (builder) =>
			{
				builder.SetColorTarget(0, composited, .Clear, .Store, .Black);
				builder.SetColorTarget(1, historyCurrent, .Clear, .Store, .Black);
				builder.ReadTexture(filtered);
				builder.ReadTexture(historyPrevious);
				builder.ReadTexture(velocity);
				builder.ReadTexture(hdr);
				builder.ReadTexture(albedo);
				builder.ReadTexture(normal);
				if (shHandle.IsValid)
					builder.ReadBuffer(shHandle);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						var inputs = BindGroupInputs<5>();
						inputs.Set(0, graph.GetTextureView(filtered), graph.GetTextureGeneration(filtered));
						inputs.Set(1, graph.GetTextureView(velocity), graph.GetTextureGeneration(velocity));
						inputs.Set(2, graph.GetTextureView(hdr), graph.GetTextureGeneration(hdr));
						inputs.Set(3, graph.GetTextureView(albedo), graph.GetTextureGeneration(albedo));
						inputs.Set(4, graph.GetTextureView(normal), graph.GetTextureGeneration(normal));
						inputs.SetBuffer(shBuffer, shGeneration);
						let bindGroup = EnsureResolveBindGroup(previousView, inputs);
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mResolvePipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = resolvePush;
						encoder.SetPushConstants(.Fragment, 0, sizeof(SsgiResolvePush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		mViews[viewIndex].Current = previousSlot;
		mViews[viewIndex].Valid = true;
		return composited;
	}

	private uint64 ShaderVersion()
	{
		return mShaders.Version("ssgi") + mShaders.Version("ssgi_down")
			+ mShaders.Version("ssgi_blur") + mShaders.Version("ssgi_resolve");
	}

	private IPipelineLayout MakePipelineLayout(IBindGroupLayout bindGroupLayout, int pushSize)
	{
		var layouts = IBindGroupLayout[1](bindGroupLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = (uint32)pushSize;

		var desc = PipelineLayoutDesc();
		desc.BindGroupLayouts = .(&layouts[0], 1);
		desc.PushConstantRanges = .(&pushRange, 1);

		if (!(mDevice.CreatePipelineLayout(desc) case .Ok(let layout)))
			return null;
		return layout;
	}

	/// The single target passes all build the same way, differing only in their shader and
	/// their layout.
	private bool CreateSingleTargetPipeline(StringView name, IPipelineLayout pipelineLayout,
		ref IRenderPipeline pipeline)
	{
		let vertex = mShaders.GetVariant(name, .Vertex, .None);
		let fragment = mShaders.GetVariant(name, .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return false;

		var color = ColorTargetState();
		color.Format = cHdrFormat;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = pipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = name;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let created)))
			return false;

		pipeline = created;
		return true;
	}

	private bool CreateTracePipeline() =>
		CreateSingleTargetPipeline("ssgi", mPipelineLayout, ref mPipeline);

	private bool CreateDownPipeline() =>
		CreateSingleTargetPipeline("ssgi_down", mDownPipelineLayout, ref mDownPipeline);

	private bool CreateBlurPipeline() =>
		CreateSingleTargetPipeline("ssgi_blur", mBlurPipelineLayout, ref mBlurPipeline);

	private bool CreateResolvePipeline()
	{
		let vertex = mShaders.GetVariant("ssgi_resolve", .Vertex, .None);
		let fragment = mShaders.GetVariant("ssgi_resolve", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return false;

		// The composited scene, and the bounce history it becomes.
		var targets = ColorTargetState[2](.(), .());
		targets[0].Format = cHdrFormat;
		targets[1].Format = cHdrFormat;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&targets[0], 2);

		var desc = RenderPipelineDesc();
		desc.Layout = mResolvePipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "ssgi_resolve";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return false;

		mResolvePipeline = pipeline;
		return true;
	}

	private bool EnsureHistory(ref ViewHistory history, uint32 width, uint32 height)
	{
		if ((history.Textures[0] != null) && (history.Width == width) && (history.Height == height))
			return true;

		DestroyHistory(ref history);

		for (int i < 2)
		{
			var textureDesc = TextureDesc();
			textureDesc.Format = cHdrFormat;
			textureDesc.Width = width;
			textureDesc.Height = height;
			textureDesc.Usage = .RenderTarget | .Sampled;
			textureDesc.Label = "ssgi.history";

			if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			{
				DestroyHistory(ref history);
				return false;
			}
			history.Textures[i] = texture;

			var viewDesc = TextureViewDesc();
			viewDesc.Format = cHdrFormat;
			viewDesc.Dimension = .Texture2D;

			if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
			{
				DestroyHistory(ref history);
				return false;
			}
			history.Views[i] = view;
			history.States[i] = .Undefined;
		}

		history.Width = width;
		history.Height = height;
		history.Current = 0;
		history.Valid = false;
		return true;
	}

	private void DestroyHistory(ref ViewHistory history)
	{
		for (int i < 2)
		{
			if (history.Views[i] != null)
				mDevice.DestroyTextureView(ref history.Views[i]);
			if (history.Textures[i] != null)
				mDevice.DestroyTexture(ref history.Textures[i]);
		}

		history.Width = 0;
		history.Height = 0;
		history.Valid = false;
	}

	/// Folds three transient generations into one cache key.
	private static uint64 Combine(RenderGraph graph, RGHandle first, RGHandle second,
		RGHandle third)
	{
		var key = graph.GetTextureGeneration(first);
		key = (key ^ graph.GetTextureGeneration(second)) &* 1099511628211UL;
		key = (key ^ graph.GetTextureGeneration(third)) &* 1099511628211UL;
		return key;
	}

	private void Tick(uint32 frameIndex)
	{
		if (frameIndex == mLastFrame)
			return;

		mLastFrame = frameIndex;
		for (int i = mRetired.Count - 1; i >= 0; i--)
		{
			var retired = mRetired[i];
			if (retired.FramesLeft <= 1)
			{
				mDevice.DestroyBindGroup(ref retired.BindGroup);
				mRetired.RemoveAt(i);
				continue;
			}

			retired.FramesLeft--;
			mRetired[i] = retired;
		}
	}

	private IBindGroup EnsureDownBindGroup(ITextureView hdr, uint64 generation)
	{
		if (hdr == null)
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(hdr);
		if (mDownBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mRetired.Add(.() { BindGroup = existing.BindGroup, FramesLeft = cRetireFrames });
		}

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(hdr),
			BindGroupEntry.SamplerEntry(mLinearSampler));

		var desc = BindGroupDesc();
		desc.Layout = mDownLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mDownBindGroups[key] = .() { BindGroup = bindGroup, Generation = generation };
		return bindGroup;
	}

	private IBindGroup EnsureBindGroup(ITextureView scene, ITextureView depth, ITextureView normal,
		uint64 generation)
	{
		if ((scene == null) || (depth == null) || (normal == null))
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(scene);
		if (mBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.Depth == depth)
				&& (existing.Normal == normal) && (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mRetired.Add(.() { BindGroup = existing.BindGroup, FramesLeft = cRetireFrames });
		}

		var entries = BindGroupEntry[5](
			BindGroupEntry.TextureEntry(scene),
			BindGroupEntry.TextureEntry(depth),
			BindGroupEntry.TextureEntry(normal),
			BindGroupEntry.SamplerEntry(mSampler),
			BindGroupEntry.SamplerEntry(mLinearSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 5);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[key] = .()
			{
				BindGroup = bindGroup, Depth = depth, Normal = normal, Generation = generation
			};
		return bindGroup;
	}

	private IBindGroup EnsureBlurBindGroup(ITextureView bounce, ITextureView depth,
		uint64 generation)
	{
		if ((bounce == null) || (depth == null))
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(bounce);
		if (mBlurBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.Depth == depth)
				&& (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mRetired.Add(.() { BindGroup = existing.BindGroup, FramesLeft = cRetireFrames });
		}

		var entries = BindGroupEntry[3](
			BindGroupEntry.TextureEntry(bounce),
			BindGroupEntry.TextureEntry(depth),
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = mBlurLayout;
		desc.Entries = .(&entries[0], 3);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBlurBindGroups[key] = .()
			{
				BindGroup = bindGroup, Depth = depth, Generation = generation
			};
		return bindGroup;
	}

	private IBindGroup EnsureResolveBindGroup(ITextureView historyPrevious, BindGroupInputs<5> inputs)
	{
		if ((historyPrevious == null) || !inputs.Complete)
			return null;

		if (let cached = mResolveBindGroups.Find(historyPrevious, inputs, var stale))
			return cached;
		// A frame in flight may still bind the stale group, so it is retired, not destroyed.
		if (stale != null)
			mRetired.Add(.() { BindGroup = stale, FramesLeft = cRetireFrames });

		var entries = BindGroupEntry[9](
			BindGroupEntry.TextureEntry(inputs.Views[0]),
			BindGroupEntry.TextureEntry(historyPrevious),
			BindGroupEntry.TextureEntry(inputs.Views[1]),
			BindGroupEntry.TextureEntry(inputs.Views[2]),
			BindGroupEntry.TextureEntry(inputs.Views[3]),
			BindGroupEntry.TextureEntry(inputs.Views[4]),
			BindGroupEntry.BufferEntry(inputs.Buffer, 0, cShBytes),
			BindGroupEntry.SamplerEntry(mSampler),
			BindGroupEntry.SamplerEntry(mLinearSampler));

		var desc = BindGroupDesc();
		desc.Layout = mResolveLayout;
		desc.Entries = .(&entries[0], 9);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mResolveBindGroups.Store(historyPrevious, inputs, bindGroup);
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (var entry in ref mBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mBindGroups.Clear();

		for (var entry in ref mDownBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mDownBindGroups.Clear();

		for (var entry in ref mBlurBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mBlurBindGroups.Clear();

		mResolveBindGroups.Release(scope (bindGroup) => { var group = bindGroup; mDevice.DestroyBindGroup(ref group); });

		for (var retired in ref mRetired)
		{
			if (retired.BindGroup != null)
				mDevice.DestroyBindGroup(ref retired.BindGroup);
		}
		mRetired.Clear();

		if (mDummyShBuffer != null)
			mDevice.DestroyBuffer(ref mDummyShBuffer);

		for (int i < cMaxViews)
			DestroyHistory(ref mViews[i]);

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mDownPipeline != null)
			mDevice.DestroyRenderPipeline(ref mDownPipeline);
		if (mBlurPipeline != null)
			mDevice.DestroyRenderPipeline(ref mBlurPipeline);
		if (mResolvePipeline != null)
			mDevice.DestroyRenderPipeline(ref mResolvePipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mDownPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mDownPipelineLayout);
		if (mBlurPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mBlurPipelineLayout);
		if (mResolvePipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mResolvePipelineLayout);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mLinearSampler != null)
			mDevice.DestroySampler(ref mLinearSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
		if (mDownLayout != null)
			mDevice.DestroyBindGroupLayout(ref mDownLayout);
		if (mBlurLayout != null)
			mDevice.DestroyBindGroupLayout(ref mBlurLayout);
		if (mResolveLayout != null)
			mDevice.DestroyBindGroupLayout(ref mResolveLayout);
	}
}
