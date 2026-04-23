namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Shaders;
using Sedulous.Profiler;

/// Sky texture mode.
enum SkyMode
{
	/// Equirectangular 2D HDR map (default).
	Equirectangular,
	/// Cubemap (6-face TextureCube).
	Cubemap,
}

/// Sky pass - renders environment sky behind all geometry.
/// Supports equirectangular HDR map, cubemap, or procedural gradient fallback.
/// Uses depth test LessEqual at z=1.0 to only render where nothing was drawn.
///
/// Pipeline and bind group changes are double-buffered to avoid destroying
/// GPU resources that may still be referenced by in-flight command buffers.
class SkyPass : PipelinePass
{
	/// Full set of GPU resources for one pipeline configuration.
	private class PipelineState
	{
		public Sedulous.RHI.IRenderPipeline Pipeline;
		public IPipelineLayout PipelineLayout;
		public IBindGroupLayout BindGroupLayout;
		public ISampler Sampler;
		public IBuffer ParamsBuffer;
		public IBindGroup[Sedulous.Renderer.Pipeline.MaxFramesInFlight] BindGroups;
		public SkyMode Mode;

		public void Destroy(IDevice device)
		{
			if (device == null) return;
			for (int i = 0; i < Sedulous.Renderer.Pipeline.MaxFramesInFlight; i++)
				if (BindGroups[i] != null)
					device.DestroyBindGroup(ref BindGroups[i]);
			if (Pipeline != null) device.DestroyRenderPipeline(ref Pipeline);
			if (PipelineLayout != null) device.DestroyPipelineLayout(ref PipelineLayout);
			if (BindGroupLayout != null) device.DestroyBindGroupLayout(ref BindGroupLayout);
			if (Sampler != null) device.DestroySampler(ref Sampler);
			if (ParamsBuffer != null) device.DestroyBuffer(ref ParamsBuffer);
		}

		public void InvalidateBindGroups(IDevice device)
		{
			for (int i = 0; i < Sedulous.Renderer.Pipeline.MaxFramesInFlight; i++)
				if (BindGroups[i] != null)
					device?.DestroyBindGroup(ref BindGroups[i]);
		}
	}

	// Active state used for rendering
	private PipelineState mActive ~ { _?.Destroy(mDevice); delete _; };

	// Retired state waiting for in-flight frames to finish before destruction.
	// Destroyed after RetireFrames frames have passed.
	private PipelineState mRetired ~ { _?.Destroy(mDevice); delete _; };
	private int mRetireCountdown = 0;

	// Sky texture (set externally, not owned)
	private ITextureView mSkyTextureView;
	private IDevice mDevice;
	private SkyMode mMode = .Equirectangular;
	private bool mNeedsRebuild = false;
	private bool mBindGroupsDirty = false;
	private RenderContext mRenderContext;
	private TextureFormat mOutputFormat;

	/// Sky texture mode. Changing this rebuilds the pipeline and bind groups.
	public SkyMode Mode
	{
		get => mMode;
		set
		{
			if (mMode != value)
			{
				mMode = value;
				mNeedsRebuild = true;
			}
		}
	}

	/// Set the sky texture. Pass null for procedural fallback.
	/// Must match the current Mode (Texture2D for Equirectangular, TextureCube for Cubemap).
	public ITextureView SkyTexture
	{
		get => mSkyTextureView;
		set
		{
			mSkyTextureView = value;
			mBindGroupsDirty = true;
		}
	}

	/// Sky brightness multiplier.
	public float Intensity = 1.0f;

	public override StringView Name => "Sky";

	public override Result<void> OnInitialize(Pipeline pipeline)
	{
		let renderer = pipeline.RenderContext;
		mDevice = renderer.Device;
		mRenderContext = renderer;
		mOutputFormat = pipeline.OutputFormat;
		let shaderSystem = renderer.ShaderSystem;
		if (shaderSystem == null)
			return .Ok;

		mActive = new PipelineState();
		return CreatePipeline(mActive, renderer, shaderSystem, mOutputFormat);
	}

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let depthHandle = graph.GetResource("SceneDepth");
		if (!depthHandle.IsValid)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		graph.AddRenderPass("Sky", scope (builder) => {
			builder
				.SetColorTarget(0, outputHandle, .Load, .Store)
				.SetDepthTarget(depthHandle, .Load, .Store, 1.0f)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteSky(encoder, view, pipeline);
				});
		});
	}

	private void ExecuteSky(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		using (Profiler.Begin("Sky"))
		{

		// Tick down retired state and destroy when safe
		if (mRetired != null)
		{
			mRetireCountdown--;
			if (mRetireCountdown <= 0)
			{
				mRetired.Destroy(mDevice);
				delete mRetired;
				mRetired = null;
			}
		}

		// Rebuild pipeline if mode changed
		if (mNeedsRebuild)
		{
			mNeedsRebuild = false;
			mBindGroupsDirty = false;

			// Retire the active state (keep alive for MaxFrames)
			RetireActive();

			// Create new active state
			mActive = new PipelineState();
			let shaderSystem = mRenderContext.ShaderSystem;
			if (shaderSystem != null)
				CreatePipeline(mActive, mRenderContext, shaderSystem, mOutputFormat);
		}
		// Rebuild bind groups if texture changed (but not mode)
		else if (mBindGroupsDirty)
		{
			mBindGroupsDirty = false;
			if (mActive != null)
				mActive.InvalidateBindGroups(mDevice);
		}

		if (mActive == null || mActive.Pipeline == null)
			return;

		let renderer = pipeline.RenderContext;
		let frame = pipeline.GetFrameResources(view.FrameIndex);
		let frameSlot = view.FrameIndex % Pipeline.MaxFramesInFlight;

		// Upload sky params
		SkyParams @params = .()
		{
			SkyIntensity = Intensity,
			HasEnvironmentMap = (mSkyTextureView != null) ? 1.0f : 0.0f
		};
		TransferHelper.WriteMappedBuffer(mActive.ParamsBuffer, 0,
			Span<uint8>((uint8*)&@params, SkyParams.Size));

		// Build sky bind group if needed
		if (mActive.BindGroups[frameSlot] == null)
		{
			let texView = (mSkyTextureView != null) ? mSkyTextureView : renderer.MaterialSystem.WhiteTexture;

			BindGroupEntry[3] bgEntries = .(
				BindGroupEntry.Buffer(mActive.ParamsBuffer, 0, SkyParams.Size),
				BindGroupEntry.Texture(texView),
				BindGroupEntry.Sampler(mActive.Sampler)
			);

			BindGroupDesc bgDesc = .() { Label = "Sky BindGroup", Layout = mActive.BindGroupLayout, Entries = bgEntries };
			if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
				mActive.BindGroups[frameSlot] = bg;
		}

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);
		encoder.SetPipeline(mActive.Pipeline);

		pipeline.BindFrameGroup(encoder, frame);

		if (mActive.BindGroups[frameSlot] != null)
			encoder.SetBindGroup(BindGroupFrequency.RenderPass, mActive.BindGroups[frameSlot], default);

		encoder.Draw(3, 1, 0, 0);

		} // Sky scope
	}

	/// Retires the active state so it stays alive until in-flight frames complete.
	private void RetireActive()
	{
		if (mActive == null) return;

		// If there's already a retired state, destroy it now (it's old enough)
		if (mRetired != null)
		{
			mRetired.Destroy(mDevice);
			delete mRetired;
		}

		mRetired = mActive;
		mActive = null;
		mRetireCountdown = Pipeline.MaxFramesInFlight;
	}

	private Result<void> CreatePipeline(PipelineState state, RenderContext renderContext, ShaderSystem shaderSystem, TextureFormat outputFormat)
	{
		state.Mode = mMode;

		let shaderName = (mMode == .Cubemap) ? "sky_cubemap" : "sky";
		let shaderResult = shaderSystem.GetShaderPair(shaderName);
		if (shaderResult case .Err)
			return .Err;

		let (vertModule, fragModule) = shaderResult.Value;
		let device = renderContext.Device;

		// Sky bind group layout (set 1): b0=SkyParams, t0=EnvironmentMap, s0=SkySampler
		let texDimension = (mMode == .Cubemap) ? TextureViewDimension.TextureCube : TextureViewDimension.Texture2D;
		BindGroupLayoutEntry[3] skyEntries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment, texDimension),
			.Sampler(0, .Fragment)
		);

		BindGroupLayoutDesc skyLayoutDesc = .() { Label = "Sky BindGroup Layout", Entries = skyEntries };
		if (device.CreateBindGroupLayout(skyLayoutDesc) case .Ok(let layout))
			state.BindGroupLayout = layout;
		else
			return .Err;

		// Pipeline layout: set 0 = frame, set 1 = sky
		let frameLayout = renderContext.FrameBindGroupLayout;
		IBindGroupLayout[2] layouts = .(frameLayout, state.BindGroupLayout);

		if (device.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			state.PipelineLayout = plLayout;
		else
			return .Err;

		// Sampler - cubemap uses clamp on all axes, equirectangular uses repeat U
		SamplerDesc samplerDesc = .()
		{
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Linear,
			AddressU = (mMode == .Cubemap) ? .ClampToEdge : .Repeat,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};
		if (device.CreateSampler(samplerDesc) case .Ok(let sampler))
			state.Sampler = sampler;
		else
			return .Err;

		// Sky params buffer
		BufferDesc bufDesc = .()
		{
			Label = "Sky Params",
			Size = SkyParams.Size,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};
		if (device.CreateBuffer(bufDesc) case .Ok(let buf))
			state.ParamsBuffer = buf;
		else
			return .Err;

		// Depth test LessEqual, no write - only render where depth == 1.0
		DepthStencilState depthState = .()
		{
			Format = .Depth24PlusStencil8,
			DepthTestEnabled = true,
			DepthWriteEnabled = false,
			DepthCompare = .LessEqual
		};

		ColorTargetState[1] colorTargets = .(.() { Format = outputFormat });

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "Sky Pipeline",
			Layout = state.PipelineLayout,
			Vertex = .() { Shader = .(vertModule.Module, "main"), Buffers = default },
			Fragment = .() { Shader = .(fragModule.Module, "main"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList, FrontFace = .CCW, CullMode = .None },
			DepthStencil = depthState,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (device.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			state.Pipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	public override void OnShutdown()
	{
		// Field destructors handle mActive and mRetired
	}

	[CRepr]
	private struct SkyParams
	{
		public float SkyIntensity;
		public float HasEnvironmentMap;
		public float _Pad0;
		public float _Pad1;
		public const uint64 Size = 16;
	}
}
