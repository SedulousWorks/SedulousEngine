namespace Sample001_Triangle;

using System;
using System.Collections;
using System.IO;
using Sedulous.RHI;
using SampleFramework;

class TriangleSample : SampleApp
{
	// Triangle HLSL source - compiled at runtime via DXC.
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

	// Triangle vertex data: position (xyz) + color (rgb)
	static float[30] sVertexData = .(
		// Top vertex - red
		 0.0f,  0.5f, 0.0f,    1.0f, 0.0f, 0.0f,
		// Bottom-right - green
		 0.5f, -0.5f, 0.0f,    0.0f, 1.0f, 0.0f,
		// Bottom-left - blue
		-0.5f, -0.5f, 0.0f,    0.0f, 0.0f, 1.0f,
		// (2 unused floats for alignment - 30 total, 18 used)
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	);

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBindGroupLayout mBindGroupLayout;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this()
	{
	}

	protected override StringView Title => "Sample001 - Triangle";

	protected override Result<void> OnInit()
	{
		// Init shader compiler
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err)
		{
			Console.WriteLine("ERROR: ShaderCompiler.Init failed");
			return .Err;
		}

		// Determine shader format based on backend
		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;

		// Compile shaders
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{
			Console.WriteLine("VS compile failed: {}", errors);
			return .Err;
		}

		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{
			Console.WriteLine("PS compile failed: {}", errors);
			return .Err;
		}

		// Create shader modules
		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "TriangleVS" });
		if (vsResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (VS) failed"); return .Err; }
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "TrianglePS" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mPixelShader = psResult.Value;

		// Create vertex buffer (3 vertices * 6 floats * 4 bytes = 72 bytes)
		let bufResult = mDevice.CreateBuffer(BufferDesc()
		{
			Size = 72,
			Usage = .Vertex | .CopyDst,
			Memory = .GpuOnly,
			Label = "TriangleVB"
		});
		if (bufResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (VB) failed"); return .Err; }
		mVertexBuffer = bufResult.Value;

		// Upload vertex data
		let batch = mGraphicsQueue.CreateTransferBatch();
		if (batch case .Err) { Console.WriteLine("ERROR: CreateTransferBatch failed"); return .Err; }
		var transfer = batch.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&sVertexData[0], 72));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Create empty bind group layout (no bindings needed for this sample)
		let bglResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = default,
			Label = "EmptyBGL"
		});
		if (bglResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout failed"); return .Err; }
		mBindGroupLayout = bglResult.Value;

		// Create pipeline layout
		let bglSpan = scope IBindGroupLayout[1];
		bglSpan[0] = mBindGroupLayout;
		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(bglSpan),
			Label = "TrianglePL"
		});
		if (plResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout failed"); return .Err; }
		mPipelineLayout = plResult.Value;

		// Create render pipeline
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x3, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = 24, // 6 floats
			StepMode = .Vertex,
			Attributes = Span<VertexAttribute>(vertexAttribs)
		};

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format,
			WriteMask = .All
		};

		let rpDesc = RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "TrianglePipeline"
		};

		let pipResult = mDevice.CreateRenderPipeline(rpDesc);
		if (pipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline failed"); return .Err; }
		mPipeline = pipResult.Value;

		// Create command pool
		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) { Console.WriteLine("ERROR: CreateCommandPool failed"); return .Err; }
		mCommandPool = poolResult.Value;

		// Create frame fence for GPU synchronization
		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) { Console.WriteLine("ERROR: CreateFence failed"); return .Err; }
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		return .Ok;
	}

	protected override void OnRender()
	{
		// Wait for previous frame's GPU work to complete before reusing the command pool
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		// Acquire next swap chain image
		if (mSwapChain.AcquireNextImage() case .Err) return;

		// Reset and create encoder
		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// Transition swap chain image to render target
		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .RenderTarget
		};
		encoder.Barrier(BarrierGroup()
		{
			TextureBarriers = Span<TextureBarrier>(texBarriers)
		});

		// Begin render pass
		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.1f, 0.1f, 0.15f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments)
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.Draw(3);
		rp.End();

		// Transition to present
		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup()
		{
			TextureBarriers = Span<TextureBarrier>(texBarriers)
		});

		// Finish and submit with fence signal
		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);

		// Present
		mSwapChain.Present(mGraphicsQueue);

		// Destroy the encoder wrapper (validated or not)
		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null)
			mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)
			mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null)
			mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null)
			mDevice?.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mPixelShader != null)
			mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null)
			mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mVertexBuffer != null)
			mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null)
		{
			mShaderCompiler.Destroy();
			delete mShaderCompiler;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope TriangleSample();
		return app.Run();
	}
}
