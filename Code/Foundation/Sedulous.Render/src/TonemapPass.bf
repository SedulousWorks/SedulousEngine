using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Maps a high dynamic range image down to what a display can show, compositing the bloom and
/// the occlusion on the way.
///
/// Declared once per view, after that view's forward pass.
class TonemapPass
{
	private const TextureFormat cHdrFormat = .RGBA16Float;
	private const int cMaxFramesInFlight = 8;
	private const int cMaxViews = 8;
	private const int cMaxSlots = cMaxViews * cMaxFramesInFlight;

	/// One frame can hold views with DIFFERENT target formats, an offscreen thumbnail beside
	/// the window say, so the pipelines are cached per format. Destroying one on a format
	/// mismatch would destroy a pipeline an earlier view of the same frame still refers to.
	private const int cMaxPipelineFormats = 4;

	/// The push constants: exposure, bloom, the coordinate transform, occlusion, the two
	/// mode flags, the auto exposure window and the grading.
	private const int cPushFloats = 16;

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight = 2;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private PipelineEntry[cMaxPipelineFormats] mPipelines = .();

	/// Linear and clamped, for the bloom composite.
	private ISampler mSampler = null;

	private IBindGroup[cMaxSlots] mBindGroups = .();
	private ITextureView[cMaxSlots] mBindGroupHdr = .();
	private ITextureView[cMaxSlots] mBindGroupBloom = .();
	private ITextureView[cMaxSlots] mBindGroupAo = .();
	/// The transient generation the cached group was built for.
	private uint64[cMaxSlots] mBindGroupGeneration = .();

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = Max(framesInFlight, (uint32)1);
	}

	public ~this()
	{
		Shutdown();
	}

	public TextureFormat HdrFormat => cHdrFormat;

	public Result<void> Initialize()
	{
		// The scene, the bloom, the occlusion, the adapted luminance and the grading table,
		// all sampled through one linear sampler.
		var entries = BindGroupLayoutEntry[6](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.SampledTexture(3, .Fragment),
			BindGroupLayoutEntry.SampledTexture(4, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 6);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = sizeof(float) * cPushFloats;

		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		pipelineLayoutDesc.PushConstantRanges = .(&pushRange, 1);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "tonemap.bloomSampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		return .Ok;
	}

	/// Declares the pass: read the scene, the bloom and the occlusion, and write the display
	/// image into this view's sub rectangle.
	///
	/// The bind group is built at EXECUTE time, because the inputs are transients the graph
	/// only resolves then.
	public void DeclareTonemap(RenderGraph graph, RGHandle hdr, RGHandle bloom, RGHandle ao,
		RGHandle ldr, bool clearColor, ClearColor clear, TextureFormat ldrFormat, int32 viewportX,
		int32 viewportY, uint32 viewportWidth, uint32 viewportHeight, uint32 frameIndex,
		uint32 viewIndex, float exposure = 1.0f, float bloomIntensity = 0.0f,
		Float2 uvScale = .(1, 1), Float2 uvOffset = .(0, 0), float aoStrength = 0.0f,
		bool debugShowAo = false, bool agx = true, bool sceneYFlipped = false,
		TonemapAutoExposure autoExposure = .(), TonemapGrading grading = .())
	{
		let pipeline = EnsurePipeline(ldrFormat);
		if (pipeline == null)
			return;

		let slot = (int)(viewIndex % cMaxViews) * (int)mFramesInFlight
			+ (int)(frameIndex % mFramesInFlight);

		// The scene input is mirrored on a backend that flips clip space, unless the temporal
		// resolve already unmirrored it; the shader compensates here when it did not.
		let flipSceneY = sceneYFlipped && mDevice.NeedsClipSpaceYFlip;

		// Both are optional, and an unbound slot falls back to the scene view: any valid
		// texture will do, because the shader gates on the flags rather than on the binding.
		let autoOn = (autoExposure.View != null) && autoExposure.Enabled;
		let gradeOn = (grading.View != null) && (grading.LutSize >= 2.0f);

		float[cPushFloats] push = .(
			exposure, bloomIntensity, uvScale.X, uvScale.Y,
			uvOffset.X, uvOffset.Y, aoStrength, debugShowAo ? 1.0f : 0.0f,
			agx ? 1.0f : 0.0f, flipSceneY ? 1.0f : 0.0f,
			autoOn ? 1.0f : 0.0f, autoExposure.Key, autoExposure.MinExposure,
			autoExposure.MaxExposure,
			gradeOn ? grading.Intensity : 0.0f, gradeOn ? grading.LutSize : 0.0f);

		let load = clearColor ? LoadOp.Clear : LoadOp.Load;
		let autoView = autoOn ? autoExposure.View : null;
		let autoGeneration = autoOn ? autoExposure.Generation : 0;
		let autoHandle = autoExposure.Handle;
		let lutView = gradeOn ? grading.View : null;
		let lutUid = gradeOn ? grading.Uid : 0;

		graph.AddRenderPass("tonemap", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, ldr, load, .Store, clear);
				builder.ReadTexture(hdr);
				builder.ReadTexture(bloom);
				builder.ReadTexture(ao);
				if ((autoView != null) && autoHandle.IsValid)
					builder.ReadTexture(autoHandle);

				builder.SetViewport(viewportX, viewportY, viewportWidth, viewportHeight);
				builder.NeverCull();

				builder.SetExecute(new [=] (encoder) =>
					{
						let hdrView = graph.GetTextureView(hdr);
						// The generation MIXES every input's, so a change in any of them
						// rebuilds the group: an address that came back around would
						// otherwise leave it pointing at a destroyed texture.
						let generation = graph.GetTextureGeneration(hdr)
							^ (graph.GetTextureGeneration(bloom) &* 1099511628211UL)
							^ (graph.GetTextureGeneration(ao) &* 14695981039346656037UL)
							^ (autoGeneration &* 31UL) ^ (lutUid &* 131071UL);

						let bindGroup = EnsureBindGroup(slot, hdrView,
							graph.GetTextureView(bloom), graph.GetTextureView(ao),
							(autoView != null) ? autoView : hdrView,
							(lutView != null) ? lutView : hdrView, generation);
						if (bindGroup == null)
							return;

						encoder.SetPipeline(pipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = push;
						encoder.SetPushConstants(.Fragment, 0, sizeof(float) * cPushFloats,
							&constants[0]);
						encoder.Draw(3, 1, 0, 0);
					});
			});
	}

	/// The pipeline for a target format, built once and rebuilt only when the shader reloads.
	///
	/// NEVER destroyed on a format mismatch: a frame can hold views with different formats,
	/// and an earlier view's commands still refer to their pipeline.
	private IRenderPipeline EnsurePipeline(TextureFormat format)
	{
		let shaderVersion = mShaders.Version("tonemap");

		var index = -1;
		for (int i < cMaxPipelineFormats)
		{
			if ((mPipelines[i].Pipeline != null) && (mPipelines[i].Format == format))
			{
				index = i;
				break;
			}
		}

		if ((index >= 0) && (mPipelines[index].ShaderVersion == shaderVersion))
			return mPipelines[index].Pipeline;

		let vertex = mShaders.GetVariant("tonemap", .Vertex, .None);
		let fragment = mShaders.GetVariant("tonemap", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		if (index < 0)
		{
			for (int i < cMaxPipelineFormats)
			{
				if (mPipelines[i].Pipeline == null)
				{
					index = i;
					break;
				}
			}
		}
		// More distinct formats in one run than slots is not a real case, so the first is
		// evicted rather than the cache growing.
		if (index < 0)
			index = 0;

		if (mPipelines[index].Pipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipelines[index].Pipeline);

		var color = ColorTargetState();
		color.Format = format;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "tonemap";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		mPipelines[index].Pipeline = pipeline;
		mPipelines[index].Format = format;
		mPipelines[index].ShaderVersion = shaderVersion;
		return pipeline;
	}

	/// One group per (view, frame) slot over its own inputs, rebuilt when the GENERATION
	/// changes.
	///
	/// Comparing the views alone is not enough: a freed view's address is reused by the next
	/// allocation, which would leave a cached group pointing at a destroyed texture.
	private IBindGroup EnsureBindGroup(int slot, ITextureView hdrView, ITextureView bloomView,
		ITextureView aoView, ITextureView autoView, ITextureView lutView, uint64 generation)
	{
		if ((slot < 0) || (slot >= cMaxSlots))
			return null;
		if ((hdrView == null) || (bloomView == null) || (aoView == null) || (autoView == null)
			|| (lutView == null))
			return null;

		if ((mBindGroups[slot] != null) && (mBindGroupHdr[slot] == hdrView)
			&& (mBindGroupBloom[slot] == bloomView) && (mBindGroupAo[slot] == aoView)
			&& (mBindGroupGeneration[slot] == generation))
			return mBindGroups[slot];

		if (mBindGroups[slot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[slot]);

		var entries = BindGroupEntry[6](
			BindGroupEntry.TextureEntry(hdrView),
			BindGroupEntry.TextureEntry(bloomView),
			BindGroupEntry.TextureEntry(aoView),
			BindGroupEntry.TextureEntry(autoView),
			BindGroupEntry.TextureEntry(lutView),
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 6);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[slot] = bindGroup;
		mBindGroupHdr[slot] = hdrView;
		mBindGroupBloom[slot] = bloomView;
		mBindGroupAo[slot] = aoView;
		mBindGroupGeneration[slot] = generation;
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int slot < cMaxSlots)
		{
			if (mBindGroups[slot] != null)
				mDevice.DestroyBindGroup(ref mBindGroups[slot]);
		}

		for (int i < cMaxPipelineFormats)
		{
			if (mPipelines[i].Pipeline != null)
				mDevice.DestroyRenderPipeline(ref mPipelines[i].Pipeline);
		}

		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
