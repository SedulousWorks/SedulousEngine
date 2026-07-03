namespace RenderGraphSandbox;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using GraphicsFramework;

/// Minimal render graph sample: draws a colored triangle using the render graph
/// for barrier management and pass execution. Double-buffered with per-frame
/// command pools and fence synchronization.
class RenderGraphSandboxApp : SampleApp
{
	const String cShaderSource = """
		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float3 Color    : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float3 Color    : TEXCOORD0;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.Color = input.Color;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return float4(input.Color, 1.0);
		}
		""";

	static float[18] sVertexData = .(
		 0.0f,  0.5f, 0.0f,    1.0f, 0.0f, 0.0f,
		 0.5f, -0.5f, 0.0f,    0.0f, 1.0f, 0.0f,
		-0.5f, -0.5f, 0.0f,    0.0f, 0.0f, 1.0f
	);

	private const int32 FramesInFlight = 2;

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBindGroupLayout mBindGroupLayout;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;

	// Double-buffered resources
	private ICommandPool[FramesInFlight] mCommandPools;
	private IFence mFrameFence;
	private uint64[FramesInFlight] mFenceValues;
	private uint64 mNextFenceValue = 1;
	private int32 mFrameIndex = 0;

	// Render graph
	private RenderGraph mGraph;

	protected override StringView Title => "RenderGraph Sandbox — Triangle";

	public this() : base(.DX12)
	{

	}

	protected override Result<void> OnInit()
	{
		// Shader compiler
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("VS: {}", errors); return .Err; }
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("PS: {}", errors); return .Err; }

		// Shader modules
		mVertexShader = Try!(mDevice.CreateShaderModule(.() { Code = .(vsBytecode.Ptr, vsBytecode.Count), Label = "VS" }));
		mPixelShader = Try!(mDevice.CreateShaderModule(.() { Code = .(psBytecode.Ptr, psBytecode.Count), Label = "PS" }));

		// Vertex buffer
		mVertexBuffer = Try!(mDevice.CreateBuffer(.() { Size = 72, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "TriangleVB" }));
		let batch = Try!(mGraphicsQueue.CreateTransferBatch());
		var transfer = batch;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&sVertexData[0], 72));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Pipeline
		mBindGroupLayout = Try!(mDevice.CreateBindGroupLayout(.() { Label = "EmptyBGL" }));
		let bglSpan = scope IBindGroupLayout[](mBindGroupLayout);
		mPipelineLayout = Try!(mDevice.CreatePipelineLayout(.() { BindGroupLayouts = bglSpan, Label = "PL" }));

		let attribs = scope VertexAttribute[](
			.() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 },
			.() { ShaderLocation = 1, Format = .Float32x3, Offset = 12 }
		);
		let vbLayouts = scope VertexBufferLayout[](.() { Stride = 24, StepMode = .Vertex, Attributes = attribs });
		let colorTargets = scope ColorTargetState[](.() { Format = mSwapChain.Format, WriteMask = .All });

		mPipeline = Try!(mDevice.CreateRenderPipeline(.()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vbLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList },
			Label = "TrianglePipeline"
		}));

		// Per-frame command pools
		for (int i = 0; i < FramesInFlight; i++)
			mCommandPools[i] = Try!(mDevice.CreateCommandPool(.Graphics));

		// Fence
		mFrameFence = Try!(mDevice.CreateFence(0));

		// Render graph
		mGraph = new RenderGraph(mDevice, .() { FrameBufferCount = FramesInFlight });

		Console.WriteLine("RenderGraph Sandbox initialized (double-buffered)");
		return .Ok;
	}

	protected override void OnRender()
	{
		let fi = mFrameIndex;

		// Wait for this frame slot's previous work
		if (mFenceValues[fi] > 0)
			mFrameFence.Wait(mFenceValues[fi]);

		// Acquire swapchain image
		if (mSwapChain.AcquireNextImage() case .Err) return;

		// Reset command pool and create encoder
		mCommandPools[fi].Reset();
		var encoder = mCommandPools[fi].CreateEncoder().Value;

		// Transition swapchain from Present to RenderTarget
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Present, .RenderTarget);

		// --- Render Graph ---
		mGraph.SetOutputSize((uint32)mWidth, (uint32)mHeight);
		mGraph.BeginFrame(fi);

		// Import swapchain as render target
		let outputHandle = mGraph.ImportTarget("Output",
			mSwapChain.CurrentTexture, mSwapChain.CurrentTextureView,
			currentState: .RenderTarget);

		// Add triangle pass
		let capturedPipeline = mPipeline;
		let capturedVB = mVertexBuffer;
		let capturedWidth = mWidth;
		let capturedHeight = mHeight;

		mGraph.AddRenderPass("Triangle", scope (builder) => {
			builder
				.SetColorTarget(0, outputHandle, .Clear, .Store, ClearColor(0.1f, 0.1f, 0.15f, 1.0f))
				.NeverCull()
				.SetExecute(new (rp) => {
					rp.SetPipeline(capturedPipeline);
					rp.SetViewport(0, 0, (float)capturedWidth, (float)capturedHeight, 0, 1);
					rp.SetScissor(0, 0, (uint32)capturedWidth, (uint32)capturedHeight);
					rp.SetVertexBuffer(0, capturedVB, 0);
					rp.Draw(3);
				});
		});

		// Execute graph
		mGraph.Execute(encoder);
		mGraph.EndFrame();

		// Transition swapchain to Present
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		// Submit
		var cmdBuf = encoder.Finish();
		mCommandPools[fi].DestroyEncoder(ref encoder);
		mFenceValues[fi] = mNextFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFenceValues[fi]);

		// Present
		mSwapChain.Present(mGraphicsQueue);

		// Advance frame index
		mFrameIndex = (fi + 1) % FramesInFlight;
	}

	protected override void OnShutdown()
	{
		mDevice.WaitIdle();

		delete mGraph;

		for (int i = 0; i < FramesInFlight; i++)
		{
			if (mCommandPools[i] != null)
				mDevice.DestroyCommandPool(ref mCommandPools[i]);
		}

		if (mFrameFence != null) mDevice.DestroyFence(ref mFrameFence);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		if (mVertexShader != null) mDevice.DestroyShaderModule(ref mVertexShader);
		if (mPixelShader != null) mDevice.DestroyShaderModule(ref mPixelShader);
		delete mShaderCompiler;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope RenderGraphSandboxApp();
		return app.Run();
	}
}
