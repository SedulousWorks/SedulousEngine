namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Shaders;
using Sedulous.Profiler;

/// Sky pass — renders environment sky behind all geometry.
/// Supports equirectangular HDR map or procedural gradient fallback.
/// Uses depth test LessEqual at z=1.0 to only render where nothing was drawn.
class SkyPass : PipelinePass
{
	private IRenderPipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mSkyBindGroupLayout;
	private ISampler mSkySampler;
	private IBuffer mSkyParamsBuffer;

	// Per-frame bind groups (sky texture can change)
	private const int MaxFrames = 2;
	private IBindGroup[MaxFrames] mSkyBindGroups;

	// Sky texture (set externally, not owned)
	private ITextureView mSkyTextureView;
	private IDevice mDevice;

	/// Set the equirectangular sky texture. Pass null for procedural fallback.
	public ITextureView SkyTexture
	{
		get => mSkyTextureView;
		set
		{
			mSkyTextureView = value;
			// Invalidate bind groups so they get rebuilt
			for (int i = 0; i < MaxFrames; i++)
				if (mSkyBindGroups[i] != null)
					mDevice?.DestroyBindGroup(ref mSkyBindGroups[i]);
		}
	}

	/// Sky brightness multiplier.
	public float Intensity = 1.0f;

	public override StringView Name => "Sky";

	public override Result<void> OnInitialize(Pipeline pipeline)
	{
		let renderer = pipeline.Renderer;
		mDevice = renderer.Device;
		let shaderSystem = renderer.ShaderSystem;
		if (shaderSystem == null)
			return .Ok;

		return CreatePipeline(renderer, shaderSystem, pipeline.OutputFormat);
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

		if (mPipeline == null)
			return;

		let renderer = pipeline.Renderer;
		let frame = pipeline.GetFrameResources(view.FrameIndex);
		let frameSlot = view.FrameIndex % MaxFrames;

		// Upload sky params
		SkyParams @params = .()
		{
			SkyIntensity = Intensity,
			HasEnvironmentMap = (mSkyTextureView != null) ? 1.0f : 0.0f
		};
		TransferHelper.WriteMappedBuffer(mSkyParamsBuffer, 0,
			Span<uint8>((uint8*)&@params, SkyParams.Size));

		// Build sky bind group if needed
		if (mSkyBindGroups[frameSlot] == null)
		{
			// Use a fallback texture view if no sky texture set
			let texView = (mSkyTextureView != null) ? mSkyTextureView : renderer.MaterialSystem.WhiteTexture;

			BindGroupEntry[3] bgEntries = .(
				BindGroupEntry.Buffer(mSkyParamsBuffer, 0, SkyParams.Size),
				BindGroupEntry.Texture(texView),
				BindGroupEntry.Sampler(mSkySampler)
			);

			BindGroupDesc bgDesc = .() { Label = "Sky BindGroup", Layout = mSkyBindGroupLayout, Entries = bgEntries };
			if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
				mSkyBindGroups[frameSlot] = bg;
		}

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);
		encoder.SetPipeline(mPipeline);

		if (frame.FrameBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Frame, frame.FrameBindGroup, default);

		if (mSkyBindGroups[frameSlot] != null)
			encoder.SetBindGroup(BindGroupFrequency.RenderPass, mSkyBindGroups[frameSlot], default);

		encoder.Draw(3, 1, 0, 0);

		} // Sky scope
	}

	private Result<void> CreatePipeline(Renderer renderer, ShaderSystem shaderSystem, TextureFormat outputFormat)
	{
		let shaderResult = shaderSystem.GetShaderPair("sky");
		if (shaderResult case .Err)
			return .Err;

		let (vertModule, fragModule) = shaderResult.Value;
		let device = renderer.Device;

		// Sky bind group layout (set 1): b0=SkyParams, t0=EnvironmentMap, s0=SkySampler
		BindGroupLayoutEntry[3] skyEntries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment),
			.Sampler(0, .Fragment)
		);

		BindGroupLayoutDesc skyLayoutDesc = .() { Label = "Sky BindGroup Layout", Entries = skyEntries };
		if (device.CreateBindGroupLayout(skyLayoutDesc) case .Ok(let layout))
			mSkyBindGroupLayout = layout;
		else
			return .Err;

		// Pipeline layout: set 0 = frame, set 1 = sky
		let frameLayout = renderer.FrameBindGroupLayout;
		IBindGroupLayout[2] layouts = .(frameLayout, mSkyBindGroupLayout);

		if (device.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		// Sampler
		SamplerDesc samplerDesc = .()
		{
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Linear,
			AddressU = .Repeat,
			AddressV = .ClampToEdge,
			AddressW = .Repeat
		};
		if (device.CreateSampler(samplerDesc) case .Ok(let sampler))
			mSkySampler = sampler;
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
			mSkyParamsBuffer = buf;
		else
			return .Err;

		// Depth test LessEqual, no write — only render where depth == 1.0
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
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(vertModule.Module, "main"), Buffers = default },
			Fragment = .() { Shader = .(fragModule.Module, "main"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList, FrontFace = .CCW, CullMode = .None },
			DepthStencil = depthState,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (device.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			mPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	public override void OnShutdown()
	{
		if (mDevice == null) return;

		for (int i = 0; i < MaxFrames; i++)
			if (mSkyBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mSkyBindGroups[i]);

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mSkyBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mSkyBindGroupLayout);
		if (mSkySampler != null) mDevice.DestroySampler(ref mSkySampler);
		if (mSkyParamsBuffer != null) mDevice.DestroyBuffer(ref mSkyParamsBuffer);
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
