using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Screen space reflections: rays marched through the depth buffer to find what each surface
/// reflects, from what the frame has already drawn.
///
/// TWO PASSES. The trace fills a reflection buffer with radiance and a confidence; the resolve
/// then accumulates it against a reprojected history and composites it into the scene. The
/// accumulation is what makes a sparse trace usable: a single frame of it is far too noisy.
class SsrPass
{
	/// Matches the scene's own.
	private const TextureFormat cHdrFormat = .RGBA16Float;
	private const int cMaxViews = 8;
	private const uint32 cRetireFrames = 4;

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
		public ITextureView Material;
		public uint64 Generation;
	}

	private struct ResolveEntry
	{
		public IBindGroup BindGroup;
		public ITextureView Reflection;
		public ITextureView Velocity;
		public ITextureView Hdr;
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

	private IBindGroupLayout mResolveLayout = null;
	private IPipelineLayout mResolvePipelineLayout = null;
	private IRenderPipeline mResolvePipeline = null;
	private uint64 mPipelineShaderVersion = 0;

	/// Point, for the depth and the reconstruction; linear, for the glossy colour gather.
	private ISampler mSampler = null;
	private ISampler mLinearSampler = null;

	private ViewHistory[cMaxViews] mViews = .();
	private Dictionary<int, Entry> mBindGroups = new .() ~ delete _;
	private Dictionary<int, ResolveEntry> mResolveBindGroups = new .() ~ delete _;
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
		var traceEntries = BindGroupLayoutEntry[6](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.SampledTexture(3, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment),
			BindGroupLayoutEntry.Sampler(1, .Fragment));

		// The depth is read as DATA through the point sampler, so it is declared unfilterable
		// and that sampler non filtering.
		traceEntries[1].TextureSampleType = .UnfilterableFloat;
		traceEntries[4].SamplerNonFiltering = true;

		var traceLayoutDesc = BindGroupLayoutDesc();
		traceLayoutDesc.Entries = .(&traceEntries[0], 6);
		if (!(mDevice.CreateBindGroupLayout(traceLayoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		mPipelineLayout = MakePipelineLayout(mLayout, sizeof(SsrPush));
		if (mPipelineLayout == null)
			return .Err;

		var pointDesc = SamplerDesc();
		pointDesc.MinFilter = .Nearest;
		pointDesc.MagFilter = .Nearest;
		pointDesc.MipmapFilter = .Nearest;
		pointDesc.AddressU = .ClampToEdge;
		pointDesc.AddressV = .ClampToEdge;
		pointDesc.AddressW = .ClampToEdge;
		pointDesc.Label = "ssr.sampler";
		if (!(mDevice.CreateSampler(pointDesc) case .Ok(let point)))
			return .Err;
		mSampler = point;

		var linearDesc = SamplerDesc();
		linearDesc.MinFilter = .Linear;
		linearDesc.MagFilter = .Linear;
		linearDesc.AddressU = .ClampToEdge;
		linearDesc.AddressV = .ClampToEdge;
		linearDesc.AddressW = .ClampToEdge;
		linearDesc.Label = "ssr.linear";
		if (!(mDevice.CreateSampler(linearDesc) case .Ok(let linear)))
			return .Err;
		mLinearSampler = linear;

		if (!CreateTracePipeline())
			return .Err;

		var resolveEntries = BindGroupLayoutEntry[6](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.SampledTexture(3, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment),
			BindGroupLayoutEntry.Sampler(1, .Fragment));

		var resolveLayoutDesc = BindGroupLayoutDesc();
		resolveLayoutDesc.Entries = .(&resolveEntries[0], 6);
		if (!(mDevice.CreateBindGroupLayout(resolveLayoutDesc) case .Ok(let resolveLayout)))
			return .Err;
		mResolveLayout = resolveLayout;

		mResolvePipelineLayout = MakePipelineLayout(mResolveLayout, sizeof(SsrResolvePush));
		if (mResolvePipelineLayout == null)
			return .Err;

		if (!CreateResolvePipeline())
			return .Err;

		mPipelineShaderVersion = ShaderVersion();
		return .Ok;
	}

	/// Reflects the scene into a fresh transient, and answers it. The scene comes back
	/// unchanged when it cannot run.
	public RGHandle DeclareSsr(RenderGraph graph, RGHandle hdr, RGHandle depth, RGHandle normal,
		RGHandle material, RGHandle velocity, uint32 width, uint32 height, int32 viewportX,
		int32 viewportY, uint32 viewportWidth, uint32 viewportHeight, Float4x4 invProj,
		Float4x4 proj, SsrParams parameters, uint32 viewIndex, uint32 frameIndex)
	{
		if ((width == 0) || (height == 0) || (viewIndex >= cMaxViews))
			return hdr;

		let shaderVersion = ShaderVersion();
		if (shaderVersion != mPipelineShaderVersion)
		{
			if (mPipeline != null)
				mDevice.DestroyRenderPipeline(ref mPipeline);
			if (mResolvePipeline != null)
				mDevice.DestroyRenderPipeline(ref mResolvePipeline);

			CreateTracePipeline();
			CreateResolvePipeline();
			mPipelineShaderVersion = shaderVersion;

			if ((mPipeline == null) || (mResolvePipeline == null))
			{
				// A reloaded shader that no longer matches this binary, its push block having
				// grown say, fails to build and the pass silently stops. Say so once per
				// version rather than leaving only the validation noise.
				Console.Error.WriteLine("Render: the reflection pipelines failed to rebuild after a shader reload, so the pass is off");
			}
		}

		if ((mPipeline == null) || (mResolvePipeline == null))
			return hdr;

		Tick(frameIndex);

		let fullWidth = (float)width;
		let fullHeight = (float)height;
		let vpMin = Float2((float)viewportX / fullWidth, (float)viewportY / fullHeight);
		let vpSize = Float2((float)viewportWidth / fullWidth, (float)viewportHeight / fullHeight);

		// The trace: reflected radiance, with a confidence in the fourth channel.
		let reflection = graph.CreateTransient("ssr.refl", .(cHdrFormat, width, height));

		var tracePush = SsrPush();
		tracePush.InvProj = invProj;
		tracePush.VpMin = vpMin;
		tracePush.VpSize = vpSize;
		tracePush.Jitter = .(proj[2, 0], proj[2, 1]);
		tracePush.ProjXX = proj[0, 0];
		tracePush.ProjYY = proj[1, 1];
		tracePush.Thickness = parameters.Thickness;
		tracePush.Intensity = parameters.Intensity;
		tracePush.EdgeFade = (parameters.EdgeFade > 1e-4f) ? parameters.EdgeFade : 1e-4f;
		tracePush.RoughCutoff = parameters.RoughnessCutoff;
		tracePush.MaxSteps = (parameters.MaxSteps > 1) ? parameters.MaxSteps : 1;
		tracePush.YSign = mDevice.NeedsClipSpaceYFlip ? 1.0f : -1.0f;
		tracePush.Debug = parameters.Debug;
		tracePush.Glossy = (parameters.Glossy >= 0.0f) ? parameters.Glossy : 0.0f;

		graph.AddRenderPass("ssr.trace", scope (builder) =>
			{
				builder.SetColorTarget(0, reflection, .Clear, .Store, .Black);
				builder.ReadTexture(hdr);
				builder.ReadTexture(depth);
				builder.ReadTexture(normal);
				builder.ReadTexture(material);
				builder.SetViewport(0, 0, width, height);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureBindGroup(graph.GetTextureView(hdr),
							graph.GetTextureView(depth), graph.GetTextureView(normal),
							graph.GetTextureView(material),
							Combine(graph, hdr, depth, normal, material));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mPipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = tracePush;
						encoder.SetPushConstants(.Fragment, 0, sizeof(SsrPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		if (!EnsureHistory(ref mViews[viewIndex], width, height))
			return hdr;

		let currentSlot = mViews[viewIndex].Current;
		let previousSlot = currentSlot ^ 1;

		let composited = graph.CreateTransient("ssr.scene", .(cHdrFormat, width, height));

		let historyPrevious = graph.ImportTarget("ssr.histPrev",
			mViews[viewIndex].Textures[previousSlot], mViews[viewIndex].Views[previousSlot],
			ResourceState.ShaderRead, mViews[viewIndex].States[previousSlot]);
		mViews[viewIndex].States[previousSlot] = .ShaderRead;

		let historyCurrent = graph.ImportTarget("ssr.histCur",
			mViews[viewIndex].Textures[currentSlot], mViews[viewIndex].Views[currentSlot],
			ResourceState.RenderTarget, mViews[viewIndex].States[currentSlot]);
		mViews[viewIndex].States[currentSlot] = .RenderTarget;

		var resolvePush = SsrResolvePush();
		resolvePush.VpMin = vpMin;
		resolvePush.VpSize = vpSize;
		resolvePush.TexelSize = .(1.0f / fullWidth, 1.0f / fullHeight);
		resolvePush.BlendFactor = parameters.HistoryBlend;
		resolvePush.HistoryValid = mViews[viewIndex].Valid ? 1.0f : 0.0f;
		resolvePush.VarianceGamma = parameters.VarianceGamma;
		resolvePush.MotionScale = parameters.MotionScale;
		resolvePush.TemporalOn = parameters.Temporal ? 1 : 0;
		resolvePush.Debug = parameters.Debug;
		resolvePush.GhostReject = parameters.GhostReject;

		let previousView = mViews[viewIndex].Views[previousSlot];

		graph.AddRenderPass("ssr.resolve", scope (builder) =>
			{
				builder.SetColorTarget(0, composited, .Clear, .Store, .Black);
				builder.SetColorTarget(1, historyCurrent, .Clear, .Store, .Black);
				builder.ReadTexture(reflection);
				builder.ReadTexture(historyPrevious);
				builder.ReadTexture(velocity);
				builder.ReadTexture(hdr);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureResolveBindGroup(graph.GetTextureView(reflection),
							previousView, graph.GetTextureView(velocity), graph.GetTextureView(hdr),
							graph.GetTextureGeneration(reflection)
							^ (graph.GetTextureGeneration(hdr) &* 1099511628211UL));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mResolvePipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = resolvePush;
						encoder.SetPushConstants(.Fragment, 0, sizeof(SsrResolvePush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		mViews[viewIndex].Current = previousSlot;
		mViews[viewIndex].Valid = true;
		return composited;
	}

	private uint64 ShaderVersion() => mShaders.Version("ssr") + mShaders.Version("ssr_resolve");

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

	private bool CreateTracePipeline()
	{
		let vertex = mShaders.GetVariant("ssr", .Vertex, .None);
		let fragment = mShaders.GetVariant("ssr", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return false;

		var color = ColorTargetState();
		color.Format = cHdrFormat;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "ssr";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return false;

		mPipeline = pipeline;
		return true;
	}

	private bool CreateResolvePipeline()
	{
		let vertex = mShaders.GetVariant("ssr_resolve", .Vertex, .None);
		let fragment = mShaders.GetVariant("ssr_resolve", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return false;

		// The composited scene, and the reflection history it becomes.
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
		desc.Label = "ssr_resolve";

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
			textureDesc.Label = "ssr.history";

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

	/// Folds four transient generations into one cache key.
	private static uint64 Combine(RenderGraph graph, RGHandle first, RGHandle second,
		RGHandle third, RGHandle fourth)
	{
		var key = graph.GetTextureGeneration(first);
		key = (key ^ graph.GetTextureGeneration(second)) &* 1099511628211UL;
		key = (key ^ graph.GetTextureGeneration(third)) &* 1099511628211UL;
		key = (key ^ graph.GetTextureGeneration(fourth)) &* 1099511628211UL;
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

	private IBindGroup EnsureBindGroup(ITextureView scene, ITextureView depth, ITextureView normal,
		ITextureView material, uint64 generation)
	{
		if ((scene == null) || (depth == null) || (normal == null) || (material == null))
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(scene);
		if (mBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.Depth == depth)
				&& (existing.Normal == normal) && (existing.Material == material)
				&& (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mRetired.Add(.() { BindGroup = existing.BindGroup, FramesLeft = cRetireFrames });
		}

		var entries = BindGroupEntry[6](
			BindGroupEntry.TextureEntry(scene),
			BindGroupEntry.TextureEntry(depth),
			BindGroupEntry.TextureEntry(normal),
			BindGroupEntry.TextureEntry(material),
			BindGroupEntry.SamplerEntry(mSampler),
			BindGroupEntry.SamplerEntry(mLinearSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 6);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[key] = .()
			{
				BindGroup = bindGroup, Depth = depth, Normal = normal, Material = material,
				Generation = generation
			};
		return bindGroup;
	}

	private IBindGroup EnsureResolveBindGroup(ITextureView reflection, ITextureView historyPrevious,
		ITextureView velocity, ITextureView hdr, uint64 generation)
	{
		if ((reflection == null) || (historyPrevious == null) || (velocity == null) || (hdr == null))
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(historyPrevious);
		if (mResolveBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.Reflection == reflection)
				&& (existing.Velocity == velocity) && (existing.Hdr == hdr)
				&& (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mRetired.Add(.() { BindGroup = existing.BindGroup, FramesLeft = cRetireFrames });
		}

		var entries = BindGroupEntry[6](
			BindGroupEntry.TextureEntry(reflection),
			BindGroupEntry.TextureEntry(historyPrevious),
			BindGroupEntry.TextureEntry(velocity),
			BindGroupEntry.TextureEntry(hdr),
			BindGroupEntry.SamplerEntry(mSampler),
			BindGroupEntry.SamplerEntry(mLinearSampler));

		var desc = BindGroupDesc();
		desc.Layout = mResolveLayout;
		desc.Entries = .(&entries[0], 6);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mResolveBindGroups[key] = .()
			{
				BindGroup = bindGroup, Reflection = reflection, Velocity = velocity, Hdr = hdr,
				Generation = generation
			};
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

		for (var entry in ref mResolveBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mResolveBindGroups.Clear();

		for (var retired in ref mRetired)
		{
			if (retired.BindGroup != null)
				mDevice.DestroyBindGroup(ref retired.BindGroup);
		}
		mRetired.Clear();

		for (int i < cMaxViews)
			DestroyHistory(ref mViews[i]);

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mResolvePipeline != null)
			mDevice.DestroyRenderPipeline(ref mResolvePipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mResolvePipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mResolvePipelineLayout);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mLinearSampler != null)
			mDevice.DestroySampler(ref mLinearSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
		if (mResolveLayout != null)
			mDevice.DestroyBindGroupLayout(ref mResolveLayout);
	}
}
