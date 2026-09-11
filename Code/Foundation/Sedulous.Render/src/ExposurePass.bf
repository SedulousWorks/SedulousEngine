using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Automatic exposure: the eye adapting to the scene.
///
/// One single pixel pass per view measures the frame's geometric mean luminance over a fixed
/// sixteen by sixteen grid of samples across the view's sub rectangle, and eases the PREVIOUS
/// adapted value towards it. The adapted pixel is a persistent per view ping pong, imported
/// into the graph so the tonemap reads it along a real edge, and the tonemap is what turns it
/// into a multiplier clamped to the authored exposure window.
class ExposurePass
{
	public const int cMaxViews = 8;
	public const int cMaxFramesInFlight = 8;
	public const int cMaxSlots = cMaxViews * cMaxFramesInFlight;
	public const TextureFormat cFormat = .R16Float;

	private struct ViewState
	{
		public ITexture[2] Textures;
		public ITextureView[2] Views;
		public ResourceState[2] States;
		public uint32 Current;
		public bool Valid;
		public uint64 Generation;
	}

	private struct Entry
	{
		public IBindGroup BindGroup;
		public ITextureView Hdr;
		public ITextureView Previous;
		public uint64 Generation;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private uint64 mPipelineShaderVersion = 0;
	private ISampler mSampler = null;

	private ViewState[cMaxViews] mViews = .();
	private Entry[cMaxSlots] mBindGroups = .();

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		var entries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 3);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = sizeof(float) * 8;

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
		samplerDesc.Label = "exposure.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		return .Ok;
	}

	/// Measures and adapts for one view. Answers the ADAPTED single pixel, left in ShaderRead
	/// for the tonemap to read, or an empty result when the pass cannot run.
	public ExposureResult DeclareExposure(RenderGraph graph, RGHandle hdr, uint32 viewIndex,
		uint32 frameIndex, Float2 uvScale, Float2 uvOffset, float deltaSeconds, float adaptSpeed)
	{
		var result = ExposureResult();

		let pipeline = EnsurePipeline();
		if (pipeline == null)
			return result;

		let view = viewIndex % cMaxViews;
		if (!EnsureState(ref mViews[view]))
			return result;

		let currentSlot = mViews[view].Current;
		let previousSlot = currentSlot ^ 1;

		let previousHandle = graph.ImportTarget("exposure.prev",
			mViews[view].Textures[previousSlot], mViews[view].Views[previousSlot],
			ResourceState.ShaderRead, mViews[view].States[previousSlot]);
		mViews[view].States[previousSlot] = .ShaderRead;

		let currentHandle = graph.ImportTarget("exposure.cur",
			mViews[view].Textures[currentSlot], mViews[view].Views[currentSlot],
			ResourceState.ShaderRead, mViews[view].States[currentSlot]);
		mViews[view].States[currentSlot] = .ShaderRead;

		let push = float[8](
			uvScale.X, uvScale.Y,
			uvOffset.X, uvOffset.Y,
			Max(deltaSeconds, 0.0f) * Max(adaptSpeed, 0.0f),
			mViews[view].Valid ? 1.0f : 0.0f,
			0.0f, 0.0f);

		let previousView = mViews[view].Views[previousSlot];

		// A slot PER VIEW AND FRAME. The previous view ping pongs every frame, so a slot keyed
		// on the view alone mismatches every frame, and rebuilding it then frees a set the
		// previous frame's command buffer is still reading. Folding the frame in means a slot
		// is only rewritten once that many frames have passed, its buffer long since done.
		let slot = (int)view * mFramesInFlight + (frameIndex % mFramesInFlight);

		graph.AddRenderPass("exposure.measure", scope (builder) =>
			{
				builder.SetColorTarget(0, currentHandle, .Clear, .Store, .Black);
				builder.ReadTexture(hdr);
				builder.ReadTexture(previousHandle);
				builder.SetViewport(0, 0, 1, 1);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureBindGroup(slot, graph.GetTextureView(hdr),
							previousView, graph.GetTextureGeneration(hdr));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(pipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = push;
						encoder.SetPushConstants(.Fragment, 0, sizeof(float) * 8, &constants[0]);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		mViews[view].Valid = true;
		// Next frame writes the other slot.
		mViews[view].Current = previousSlot;

		result.Handle = currentHandle;
		result.View = mViews[view].Views[currentSlot];
		result.Generation = mViews[view].Generation + currentSlot;
		return result;
	}

	private bool EnsureState(ref ViewState state)
	{
		if (state.Textures[0] != null)
			return true;

		for (int i < 2)
		{
			var textureDesc = TextureDesc();
			textureDesc.Format = cFormat;
			textureDesc.Width = 1;
			textureDesc.Height = 1;
			textureDesc.Usage = .RenderTarget | .Sampled;
			textureDesc.Label = "exposure.adapted";

			if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			{
				DestroyState(ref state);
				return false;
			}
			state.Textures[i] = texture;

			var viewDesc = TextureViewDesc();
			viewDesc.Format = cFormat;
			viewDesc.Dimension = .Texture2D;

			if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
			{
				DestroyState(ref state);
				return false;
			}
			state.Views[i] = view;
			state.States[i] = .Undefined;
		}

		state.Current = 0;
		state.Valid = false;
		state.Generation += 2;
		return true;
	}

	private void DestroyState(ref ViewState state)
	{
		for (int i < 2)
		{
			if (state.Views[i] != null)
				mDevice.DestroyTextureView(ref state.Views[i]);
			if (state.Textures[i] != null)
				mDevice.DestroyTexture(ref state.Textures[i]);
		}

		state.Valid = false;
	}

	private IRenderPipeline EnsurePipeline()
	{
		let shaderVersion = mShaders.Version("exposure_measure");
		if ((mPipeline != null) && (mPipelineShaderVersion == shaderVersion))
			return mPipeline;

		let vertex = mShaders.GetVariant("exposure_measure", .Vertex, .None);
		let fragment = mShaders.GetVariant("exposure_measure", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);

		var color = ColorTargetState();
		color.Format = cFormat;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "exposure.measure";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		mPipeline = pipeline;
		mPipelineShaderVersion = shaderVersion;
		return mPipeline;
	}

	private IBindGroup EnsureBindGroup(int slot, ITextureView hdr, ITextureView previous,
		uint64 generation)
	{
		if ((slot < 0) || (slot >= cMaxSlots) || (hdr == null) || (previous == null))
			return null;

		if ((mBindGroups[slot].BindGroup != null) && (mBindGroups[slot].Hdr == hdr)
			&& (mBindGroups[slot].Previous == previous)
			&& (mBindGroups[slot].Generation == generation))
			return mBindGroups[slot].BindGroup;

		if (mBindGroups[slot].BindGroup != null)
			mDevice.DestroyBindGroup(ref mBindGroups[slot].BindGroup);

		var entries = BindGroupEntry[3](
			BindGroupEntry.TextureEntry(hdr),
			BindGroupEntry.TextureEntry(previous),
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 3);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[slot].BindGroup = bindGroup;
		mBindGroups[slot].Hdr = hdr;
		mBindGroups[slot].Previous = previous;
		mBindGroups[slot].Generation = generation;
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int i < cMaxSlots)
		{
			if (mBindGroups[i].BindGroup != null)
				mDevice.DestroyBindGroup(ref mBindGroups[i].BindGroup);
		}

		for (int i < cMaxViews)
			DestroyState(ref mViews[i]);

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
