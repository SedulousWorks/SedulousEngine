namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;
using Sedulous.Profiler;

/// ACES filmic tone mapping + gamma correction.
/// Reads HDR scene color (and optional bloom), writes LDR output.
class TonemapEffect : PostProcessEffect
{
	private Sedulous.RHI.IRenderPipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;
	private ISampler mSampler;
	private IBuffer mParamsBuffer;
	private IDevice mDevice;

	// Per-frame bind groups (double-buffered to avoid use-after-free)
	private const int MaxFrames = 2;
	private IBindGroup[MaxFrames] mBindGroups;

	/// Exposure multiplier (1.0 = no change).
	public float Exposure = 1.0f;

	/// White point for tone curve.
	public float WhitePoint = 11.2f;

	/// Gamma correction value.
	public float Gamma = 2.2f;

	public override StringView Name => "Tonemap";

	public override Result<void> OnInitialize(RenderContext renderContext)
	{
		mRenderContext = renderContext;
		mDevice = renderContext.Device;
		let shaderSystem = renderContext.ShaderSystem;
		if (shaderSystem == null)
			return .Err;

		// Fullscreen triangle vertex shader (shared across post-process passes).
		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err)
			return .Err;
		let vertModule = vertResult.Value;

		// Tonemap-specific fragment shader.
		let fragResult = shaderSystem.GetShader("tonemap", .Fragment);
		if (fragResult case .Err)
			return .Err;
		let fragModule = fragResult.Value;

		// Bind group layout: b0 = params, t0 = HDR texture, t1 = bloom texture, s0 = sampler
		BindGroupLayoutEntry[4] entries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment),
			.SampledTexture(1, .Fragment),
			.Sampler(0, .Fragment)
		);

		BindGroupLayoutDesc layoutDesc = .() { Label = "Tonemap BindGroup Layout", Entries = entries };
		if (mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		// Pipeline layout
		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		if (mDevice.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		// Sampler
		SamplerDesc samplerDesc = .()
		{
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Nearest,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};
		if (mDevice.CreateSampler(samplerDesc) case .Ok(let sampler))
			mSampler = sampler;
		else
			return .Err;

		// Params constant buffer
		BufferDesc bufDesc = .()
		{
			Label = "Tonemap Params",
			Size = TonemapParams.Size,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
			mParamsBuffer = buf;
		else
			return .Err;

		// Render pipeline (no vertex buffers — fullscreen triangle via SV_VertexID)
		// Output format matches pipeline output (RGBA16Float) — blit handles final format conversion
		ColorTargetState[1] colorTargets = .(.() { Format = .RGBA16Float });

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "Tonemap Pipeline",
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(vertModule.Module, "main"), Buffers = default },
			Fragment = .() { Shader = .(fragModule.Module, "main"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList, FrontFace = .CCW, CullMode = .None },
			DepthStencil = null,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			mPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	public override void AddPasses(RenderGraph graph, RenderView view, RenderContext renderContext, PostProcessContext ctx)
	{
		using (Profiler.Begin("Tonemap"))
		{

		// Upload params
		TonemapParams @params = .() { Exposure = Exposure, WhitePoint = WhitePoint, Gamma = Gamma };
		TransferHelper.WriteMappedBuffer(mParamsBuffer, 0, Span<uint8>((uint8*)&@params, TonemapParams.Size));

		let input = ctx.Input;
		let output = ctx.Output;
		let bloomHandle = ctx.GetAux("BloomTexture");

		graph.AddRenderPass("Tonemap", scope (builder) => {
			builder
				.ReadTexture(input);

			// Declare the bloom texture as a read dependency so the render graph
			// emits the COLOR_ATTACHMENT → SHADER_READ barrier after the bloom
			// upsample chain writes to it.
			if (bloomHandle.IsValid)
				builder.ReadTexture(bloomHandle);

			builder
				.SetColorTarget(0, output, .DontCare, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteTonemap(encoder, view, graph, input, bloomHandle);
				});
		});

		} // Tonemap profiler scope
	}

	private RenderContext mRenderContext;

	private void ExecuteTonemap(IRenderPassEncoder encoder, RenderView view, RenderGraph graph,
		RGHandle inputHandle, RGHandle bloomHandle)
	{
		let inputView = graph.GetTextureView(inputHandle);
		if (inputView == null)
			return;

		// Get bloom view. When bloom is not active, fall back to a 1×1 black
		// texture so the shader's `hdr += bloom` adds zero (no brightness change).
		ITextureView bloomView = null;
		if (bloomHandle.IsValid)
			bloomView = graph.GetTextureView(bloomHandle);
		if (bloomView == null)
			bloomView = mRenderContext?.MaterialSystem?.BlackTexture;

		let frameSlot = view.FrameIndex % MaxFrames;

		// Destroy previous bind group for this frame slot
		if (mBindGroups[frameSlot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[frameSlot]);

		// Build bind group entries
		if (bloomView != null)
		{
			BindGroupEntry[4] bgEntries = .(
				BindGroupEntry.Buffer(mParamsBuffer, 0, TonemapParams.Size),
				BindGroupEntry.Texture(inputView),
				BindGroupEntry.Texture(bloomView),
				BindGroupEntry.Sampler(mSampler)
			);

			BindGroupDesc bgDesc = .() { Label = "Tonemap BindGroup", Layout = mBindGroupLayout, Entries = bgEntries };
			if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
				mBindGroups[frameSlot] = bg;
		}

		if (mBindGroups[frameSlot] == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0, 1);
		encoder.SetScissor(0, 0, view.Width, view.Height);
		encoder.SetPipeline(mPipeline);
		encoder.SetBindGroup(0, mBindGroups[frameSlot], default);
		encoder.Draw(3, 1, 0, 0);
	}

	public override void OnShutdown()
	{
		if (mDevice == null) return;

		for (int i = 0; i < MaxFrames; i++)
			if (mBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mBindGroups[i]);

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
		if (mParamsBuffer != null) mDevice.DestroyBuffer(ref mParamsBuffer);
	}

	[CRepr]
	private struct TonemapParams
	{
		public float Exposure;
		public float WhitePoint;
		public float Gamma;
		public float _Pad;
		public const uint64 Size = 16;
	}
}
