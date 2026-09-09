using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Ambient occlusion: how much of the sky each pixel can actually see.
///
/// Owns both estimators and the blur and composite they share. The result is applied to the
/// scene BEFORE the temporal resolve, so the resolve stabilises the occlusion; applying it
/// afterwards leaves it wobbling under the jitter.
class AoPass
{
	public const TextureFormat AoFormat = .R8Unorm;
	/// Matches the scene's own.
	private const TextureFormat cHdrFormat = .RGBA16Float;
	/// Frames of headroom before a replaced group is certainly idle.
	private const uint32 cRetireFrames = 4;

	private struct Entry
	{
		public IBindGroup BindGroup;
		public ITextureView Second;
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
	private IPipelineLayout mGtaoLayout = null;
	private IPipelineLayout mSsaoLayout = null;
	private IPipelineLayout mBlurLayout = null;
	private IPipelineLayout mApplyLayout = null;

	private IRenderPipeline mGtaoPipeline = null;
	private IRenderPipeline mSsaoPipeline = null;
	private IRenderPipeline mBlurPipeline = null;
	private IRenderPipeline mApplyPipeline = null;
	private uint64 mPipelineShaderVersion = 0;

	private ISampler mSampler = null;

	/// Keyed by the first texture's address, with the second and the combined generation
	/// beside it. The graph ALIASES its transients, so a cache on the addresses alone
	/// thrashes mid frame; a replaced group is retired rather than freed, because the frame
	/// that used it may still be in flight.
	private Dictionary<int, Entry> mBindGroups = new .() ~ delete _;
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
		// Two sampled textures and a sampler, shared by every one of these passes.
		var entries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		// Every one of these samples through the POINT sampler, and the slots take depth as
		// well as colour across the passes, so both are declared unfilterable and the sampler
		// non filtering: one backend requires that pairing, and the others ignore it.
		entries[0].TextureSampleType = .UnfilterableFloat;
		entries[1].TextureSampleType = .UnfilterableFloat;
		entries[2].SamplerNonFiltering = true;

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 3);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		mGtaoLayout = MakePipelineLayout(sizeof(GtaoPush));
		mSsaoLayout = MakePipelineLayout(sizeof(SsaoPush));
		mBlurLayout = MakePipelineLayout(sizeof(AoBlurPush));
		mApplyLayout = MakePipelineLayout(sizeof(AoApplyPush));
		if ((mGtaoLayout == null) || (mSsaoLayout == null) || (mBlurLayout == null)
			|| (mApplyLayout == null))
			return .Err;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Nearest;
		samplerDesc.MagFilter = .Nearest;
		// Nearest THROUGHOUT, the mip filter included: a linear mip filter counts as
		// filtering, which an unfilterable binding refuses.
		samplerDesc.MipmapFilter = .Nearest;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "ao.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		if (!RebuildPipelines())
			return .Err;

		mPipelineShaderVersion = ShaderVersion();
		return .Ok;
	}

	public TextureFormat Format => AoFormat;

	/// Declares the occlusion for one view, and answers the blurred result. An invalid handle
	/// means the mode is off.
	public RGHandle DeclareAo(RenderGraph graph, RGHandle depth, RGHandle normal, uint32 width,
		uint32 height, Float4x4 invProj, Float4x4 proj, float radius, float intensity,
		uint32 frameIndex, AoMode mode, int32 debugMode = 0)
	{
		if ((mode == .Off) || (width == 0) || (height == 0))
			return .Invalid;

		// A hot reload rebuilds all four: they share their common shader code, so any change
		// bumps every version at once.
		let shaderVersion = ShaderVersion();
		if (shaderVersion != mPipelineShaderVersion)
		{
			DestroyPipelines();
			RebuildPipelines();
			mPipelineShaderVersion = shaderVersion;
		}

		if ((mGtaoPipeline == null) || (mSsaoPipeline == null) || (mBlurPipeline == null)
			|| (mApplyPipeline == null))
			return .Invalid;

		Tick(frameIndex);

		let texel = Float2(1.0f / (float)width, 1.0f / (float)height);
		let raw = graph.CreateTransient("ao.raw", .(AoFormat, width, height));
		let temporary = graph.CreateTransient("ao.tmp", .(AoFormat, width, height));
		let blurred = graph.CreateTransient("ao.ao", .(AoFormat, width, height));

		if (mode == .GTAO)
		{
			var push = GtaoPush();
			push.InvProj = invProj;
			push.TexelSize = texel;
			push.Radius = radius;
			push.Intensity = intensity;
			push.ProjScaleY = proj[1, 1];
			push.FrameMod = (int32)(frameIndex & 63);
			push.DebugMode = debugMode;

			DeclareGenerate(graph, depth, normal, raw, width, height, mGtaoPipeline, &push,
				sizeof(GtaoPush));
		}
		else
		{
			var push = SsaoPush();
			push.InvProj = invProj;
			push.TexelSize = texel;
			push.ProjXX = proj[0, 0];
			push.ProjYY = proj[1, 1];
			// The projection's own jitter, taken from its third row.
			push.Jitter = .(proj[2, 0], proj[2, 1]);
			push.Radius = radius;
			push.Intensity = intensity;
			push.Bias = 0.05f;
			push.SampleCount = 16;
			push.DebugMode = debugMode;

			DeclareGenerate(graph, depth, normal, raw, width, height, mSsaoPipeline, &push,
				sizeof(SsaoPush));
		}

		// A debug channel is a raw per pixel value, so the blur that would smear it is
		// skipped.
		if (debugMode >= 2)
			return raw;

		// Separable: across, then down.
		DeclareBlur(graph, raw, depth, temporary, width, height, texel, .(1.0f, 0.0f));
		DeclareBlur(graph, temporary, depth, blurred, width, height, texel, .(0.0f, 1.0f));
		return blurred;
	}

	/// Multiplies the occlusion into the scene, into a fresh transient.
	public RGHandle DeclareApply(RenderGraph graph, RGHandle hdr, RGHandle ao, uint32 width,
		uint32 height, float strength)
	{
		if ((width == 0) || (height == 0))
			return hdr;

		let applied = graph.CreateTransient("ao.applied", .(cHdrFormat, width, height));

		var push = AoApplyPush();
		push.Strength = strength;
		// The generate passes store the occlusion mirrored against the scene on a backend
		// that flips clip space, so the sample is flipped back here.
		push.FlipAoY = mDevice.NeedsClipSpaceYFlip ? 1.0f : 0.0f;

		graph.AddRenderPass("ao.apply", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, applied, .Clear, .Store, .Black);
				builder.ReadTexture(hdr);
				builder.ReadTexture(ao);
				builder.SetViewport(0, 0, width, height);
				builder.NeverCull();

				builder.SetExecute(new [=] (encoder) =>
					{
						let bindGroup = EnsureBindGroup(graph.GetTextureView(hdr),
							graph.GetTextureView(ao), graph.GetTextureGeneration(hdr)
							^ (graph.GetTextureGeneration(ao) &* 1099511628211UL));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mApplyPipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = push;
						encoder.SetPushConstants(.Fragment, 0, sizeof(AoApplyPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		return applied;
	}

	private void DeclareGenerate(RenderGraph graph, RGHandle depth, RGHandle normal, RGHandle raw,
		uint32 width, uint32 height, IRenderPipeline pipeline, void* push, int pushSize)
	{
		// Copied by value, so the pass body owns what it pushes rather than pointing at a
		// caller's stack that is long gone by execute time.
		uint8[128] pushData = default;
		Internal.MemCpy(&pushData[0], push, pushSize);
		let pushBytes = pushSize;

		graph.AddRenderPass("ao.gen", scope [&] (builder) =>
			{
				// Cleared to WHITE, which is no occlusion: an unwritten pixel must not
				// darken the scene.
				builder.SetColorTarget(0, raw, .Clear, .Store, .White);
				builder.ReadTexture(depth);
				builder.ReadTexture(normal);
				builder.SetViewport(0, 0, width, height);
				builder.NeverCull();

				builder.SetExecute(new [=] (encoder) =>
					{
						let bindGroup = EnsureBindGroup(graph.GetTextureView(depth),
							graph.GetTextureView(normal), graph.GetTextureGeneration(depth)
							^ (graph.GetTextureGeneration(normal) &* 1099511628211UL));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(pipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = pushData;
						encoder.SetPushConstants(.Fragment, 0, (uint32)pushBytes, &constants[0]);
						encoder.Draw(3, 1, 0, 0);
					});
			});
	}

	/// One direction of the bilateral blur, which stops at depth discontinuities so the
	/// occlusion does not bleed across an edge.
	private void DeclareBlur(RenderGraph graph, RGHandle ao, RGHandle depth, RGHandle result,
		uint32 width, uint32 height, Float2 texel, Float2 direction)
	{
		var push = AoBlurPush();
		push.Direction = direction;
		push.TexelSize = texel;

		graph.AddRenderPass("ao.blur", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, result, .Clear, .Store, .White);
				builder.ReadTexture(ao);
				builder.ReadTexture(depth);
				builder.SetViewport(0, 0, width, height);
				builder.NeverCull();

				builder.SetExecute(new [=] (encoder) =>
					{
						let bindGroup = EnsureBindGroup(graph.GetTextureView(ao),
							graph.GetTextureView(depth), graph.GetTextureGeneration(ao)
							^ (graph.GetTextureGeneration(depth) &* 14695981039346656037UL));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mBlurPipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = push;
						encoder.SetPushConstants(.Fragment, 0, sizeof(AoBlurPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});
	}

	private uint64 ShaderVersion() =>
		mShaders.Version("ao_gtao") + mShaders.Version("ao_ssao") + mShaders.Version("ao_blur")
		+ mShaders.Version("ao_apply");

	private bool RebuildPipelines()
	{
		mGtaoPipeline = MakePipeline("ao_gtao", mGtaoLayout);
		mSsaoPipeline = MakePipeline("ao_ssao", mSsaoLayout);
		mBlurPipeline = MakePipeline("ao_blur", mBlurLayout);
		mApplyPipeline = MakePipeline("ao_apply", mApplyLayout, cHdrFormat);

		return (mGtaoPipeline != null) && (mSsaoPipeline != null) && (mBlurPipeline != null)
			&& (mApplyPipeline != null);
	}

	private void DestroyPipelines()
	{
		if (mGtaoPipeline != null)
			mDevice.DestroyRenderPipeline(ref mGtaoPipeline);
		if (mSsaoPipeline != null)
			mDevice.DestroyRenderPipeline(ref mSsaoPipeline);
		if (mBlurPipeline != null)
			mDevice.DestroyRenderPipeline(ref mBlurPipeline);
		if (mApplyPipeline != null)
			mDevice.DestroyRenderPipeline(ref mApplyPipeline);
	}

	private IPipelineLayout MakePipelineLayout(int pushSize)
	{
		var layouts = IBindGroupLayout[1](mLayout);
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

	private IRenderPipeline MakePipeline(StringView name, IPipelineLayout layout,
		TextureFormat format = AoFormat)
	{
		let vertex = mShaders.GetVariant(name, .Vertex, .None);
		let fragment = mShaders.GetVariant(name, .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		var color = ColorTargetState();
		color.Format = format;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = layout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = name;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		return pipeline;
	}

	/// Frees the groups that have waited out their frames. Once per frame.
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

	private IBindGroup EnsureBindGroup(ITextureView first, ITextureView second, uint64 generation)
	{
		if ((first == null) || (second == null))
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(first);
		if (mBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.Second == second)
				&& (existing.BindGroup != null))
				return existing.BindGroup;

			// Deferred rather than freed: the frame that bound it may still be in flight.
			if (existing.BindGroup != null)
				mRetired.Add(.() { BindGroup = existing.BindGroup, FramesLeft = cRetireFrames });
		}

		var entries = BindGroupEntry[3](
			BindGroupEntry.TextureEntry(first),
			BindGroupEntry.TextureEntry(second),
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 3);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[key] = .() { BindGroup = bindGroup, Second = second, Generation = generation };
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

		for (var retired in ref mRetired)
		{
			if (retired.BindGroup != null)
				mDevice.DestroyBindGroup(ref retired.BindGroup);
		}
		mRetired.Clear();

		DestroyPipelines();

		if (mGtaoLayout != null)
			mDevice.DestroyPipelineLayout(ref mGtaoLayout);
		if (mSsaoLayout != null)
			mDevice.DestroyPipelineLayout(ref mSsaoLayout);
		if (mBlurLayout != null)
			mDevice.DestroyPipelineLayout(ref mBlurLayout);
		if (mApplyLayout != null)
			mDevice.DestroyPipelineLayout(ref mApplyLayout);

		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
