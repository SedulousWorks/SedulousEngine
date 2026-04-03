namespace Sample006_Blending;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

class BlendingSample : SampleApp
{
	// Simple shader: per-vertex position + color (with alpha).
	const String cShaderSource = """
		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float4 Color    : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float4 Color    : COLOR0;
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
		    return input.Color;
		}
		""";

	const int QuadCount = 4;

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mBlendPipeline;
	private IRenderPipeline mOpaquePipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this()  { }

	protected override StringView Title => "Sample006 — Alpha Blending";

	protected override Result<void> OnInit()
	{
		// Shader compiler
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) { Console.WriteLine("ERROR: ShaderCompiler.Init failed"); return .Err; }

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("VS compile failed: {}", errors); return .Err; }

		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("PS compile failed: {}", errors); return .Err; }

		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "BlendVS" });
		if (vsResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (VS) failed"); return .Err; }
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "BlendPS" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mPixelShader = psResult.Value;

		// Build quad geometry: 4 overlapping quads with different colors and alpha
		if (CreateQuadGeometry() case .Err) return .Err;

		// Pipeline layout (no bind groups, no push constants)
		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "BlendPL" });
		if (plResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout failed"); return .Err; }
		mPipelineLayout = plResult.Value;

		// Shared vertex layout
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = 28, // 3 floats pos + 4 floats color = 28 bytes
			StepMode = .Vertex,
			Attributes = Span<VertexAttribute>(vertexAttribs)
		};

		// Alpha blend pipeline: src*srcAlpha + dst*(1-srcAlpha)
		{
			let colorTargets = scope ColorTargetState[1];
			colorTargets[0] = ColorTargetState()
			{
				Format = mSwapChain.Format,
				WriteMask = .All,
				Blend = BlendState()
				{
					Color = BlendComponent()
					{
						SrcFactor = .SrcAlpha,
						DstFactor = .OneMinusSrcAlpha,
						Operation = .Add
					},
					Alpha = BlendComponent()
					{
						SrcFactor = .One,
						DstFactor = .OneMinusSrcAlpha,
						Operation = .Add
					}
				}
			};

			let pipResult = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mPipelineLayout,
				Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Label = "BlendPipeline"
			});
			if (pipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline (blend) failed"); return .Err; }
			mBlendPipeline = pipResult.Value;
		}

		// Opaque pipeline (no blending) for the background quad
		{
			let colorTargets = scope ColorTargetState[1];
			colorTargets[0] = ColorTargetState()
			{
				Format = mSwapChain.Format,
				WriteMask = .All
			};

			let pipResult = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mPipelineLayout,
				Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Label = "OpaquePipeline"
			});
			if (pipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline (opaque) failed"); return .Err; }
			mOpaquePipeline = pipResult.Value;
		}

		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) { Console.WriteLine("ERROR: CreateCommandPool failed"); return .Err; }
		mCommandPool = poolResult.Value;

		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) { Console.WriteLine("ERROR: CreateFence failed"); return .Err; }
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		return .Ok;
	}

	private Result<void> CreateQuadGeometry()
	{
		// Each quad: 4 verts * 7 floats (pos xyz + color rgba) = 28 bytes/vert
		// Quad 0: dark background (opaque)
		// Quads 1-3: overlapping colored translucent quads
		float[?] vertexData = .(
			// Quad 0: Background (gray, opaque, full screen)
			-0.9f, -0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,
			 0.9f, -0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,
			 0.9f,  0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,
			-0.9f,  0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,

			// Quad 1: Red (semi-transparent, left-center)
			-0.6f, -0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,
			 0.1f, -0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,
			 0.1f,  0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,
			-0.6f,  0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,

			// Quad 2: Green (semi-transparent, center)
			-0.3f, -0.5f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,
			 0.4f, -0.5f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,
			 0.4f,  0.3f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,
			-0.3f,  0.3f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,

			// Quad 3: Blue (semi-transparent, right-center)
			-0.1f, -0.3f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f,
			 0.6f, -0.3f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f,
			 0.6f,  0.5f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f,
			-0.1f,  0.5f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f
		);

		// Indices: 4 quads * 6 indices each
		uint16[?] indexData = .(
			 0,  1,  2,  0,  2,  3,
			 4,  5,  6,  4,  6,  7,
			 8,  9, 10,  8, 10, 11,
			12, 13, 14, 12, 14, 15
		);

		uint32 vbSize = sizeof(decltype(vertexData));
		uint32 ibSize = sizeof(decltype(indexData));

		let vbResult = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "BlendVB" });
		if (vbResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (VB) failed"); return .Err; }
		mVertexBuffer = vbResult.Value;

		let ibResult = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "BlendIB" });
		if (ibResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (IB) failed"); return .Err; }
		mIndexBuffer = ibResult.Value;

		let batchResult = mGraphicsQueue.CreateTransferBatch();
		if (batchResult case .Err) { Console.WriteLine("ERROR: CreateTransferBatch failed"); return .Err; }
		var transfer = batchResult.Value;

		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&vertexData[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indexData[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .RenderTarget
		};
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.05f, 0.05f, 0.08f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments)
		});

		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);

		// Draw background quad (opaque) — SetPipeline before SetVertexBuffer for correct stride
		rp.SetPipeline(mOpaquePipeline);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(6, 1, 0, 0, 0);

		// Draw transparent quads (back-to-front: 1, 2, 3)
		rp.SetPipeline(mBlendPipeline);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(6, 1, 6, 0, 0);   // Red
		rp.DrawIndexed(6, 1, 12, 0, 0);  // Green
		rp.DrawIndexed(6, 1, 18, 0, 0);  // Blue

		rp.End();

		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);

		mSwapChain.Present(mGraphicsQueue);

		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mOpaquePipeline != null) mDevice?.DestroyRenderPipeline(ref mOpaquePipeline);
		if (mBlendPipeline != null) mDevice?.DestroyRenderPipeline(ref mBlendPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
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
		let app = scope BlendingSample();
		return app.Run();
	}
}
