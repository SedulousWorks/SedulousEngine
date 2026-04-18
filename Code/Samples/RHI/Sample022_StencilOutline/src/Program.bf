namespace Sample022_StencilOutline;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates stencil buffer operations for object outlining.
/// Pass 1: Draw solid hexagon, write stencil = 1.
/// Pass 2: Draw scaled-up hexagon, only where stencil != 1 (outline effect).
class StencilOutlineSample : SampleApp
{
	const String cShaderSource = """
		struct PushConstants
		{
		    float Scale;
		    float AspectRatio;
		    float Time;
		    float _pad;
		};

		[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space0);

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
		    float2 pos = input.Position.xy * pc.Scale;
		    pos.x /= pc.AspectRatio;
		    // Gentle rotation
		    float c = cos(pc.Time * 0.5);
		    float s = sin(pc.Time * 0.5);
		    float2 rotated = float2(pos.x * c - pos.y * s, pos.x * s + pos.y * c);
		    output.Position = float4(rotated, input.Position.z, 1.0);
		    output.Color = input.Color;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return input.Color;
		}
		""";

	[CRepr]
	struct PushData
	{
		public float Scale;
		public float AspectRatio;
		public float Time;
		public float _pad;
	}

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mStencilWritePipeline;
	private IRenderPipeline mStencilTestPipeline;
	private ITexture mDepthStencilTexture;
	private ITextureView mDepthStencilView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample022 — Stencil Outline";

	protected override Result<void> OnInit()
	{
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("VS: {}", errors); return .Err; }
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("PS: {}", errors); return .Err; }

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "StencilVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "StencilPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Hexagon: center + 6 outer vertices
		float[?] verts = .(
			// Center
			0.0f, 0.0f, 0.5f,   0.9f, 0.9f, 0.9f, 1.0f,
			// Outer vertices (radius 0.6)
			 0.6f,   0.0f,   0.5f,   0.3f, 0.6f, 1.0f, 1.0f,
			 0.3f,   0.52f,  0.5f,   0.3f, 1.0f, 0.6f, 1.0f,
			-0.3f,   0.52f,  0.5f,   1.0f, 1.0f, 0.3f, 1.0f,
			-0.6f,   0.0f,   0.5f,   1.0f, 0.6f, 0.3f, 1.0f,
			-0.3f,  -0.52f,  0.5f,   1.0f, 0.3f, 0.6f, 1.0f,
			 0.3f,  -0.52f,  0.5f,   0.6f, 0.3f, 1.0f, 1.0f
		);

		uint16[18] indices = .(
			0, 1, 2,
			0, 2, 3,
			0, 3, 4,
			0, 4, 5,
			0, 5, 6,
			0, 6, 1
		);

		uint32 vbSize = sizeof(decltype(verts));
		uint32 ibSize = sizeof(decltype(indices));

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "StencilVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "StencilIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Pipeline layout with push constants (0 bind groups -> push constants at space0)
		let pushRanges = scope PushConstantRange[1];
		pushRanges[0] = PushConstantRange() { Stages = .Vertex, Offset = 0, Size = sizeof(PushData) };

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			PushConstantRanges = Span<PushConstantRange>(pushRanges),
			Label = "StencilPL"
		});
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		if (CreateDepthStencil() case .Err) return .Err;

		// Shared vertex layout
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };
		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 28, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		// Pipeline 1: Stencil write — draw solid, always pass depth, write stencil = ref (1)
		{
			let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mPipelineLayout,
				Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				DepthStencil = DepthStencilState()
				{
					Format = .Depth24PlusStencil8,
					DepthWriteEnabled = true,
					DepthCompare = .Always,
					StencilEnabled = true,
					StencilReadMask = 0xFF,
					StencilWriteMask = 0xFF,
					StencilFront = StencilFaceState() { Compare = .Always, PassOp = .Replace, FailOp = .Keep, DepthFailOp = .Keep },
					StencilBack = StencilFaceState() { Compare = .Always, PassOp = .Replace, FailOp = .Keep, DepthFailOp = .Keep }
				},
				Multisample = .(),
				Label = "StencilWritePipeline"
			});
			if (pipR case .Err) return .Err;
			mStencilWritePipeline = pipR.Value;
		}

		// Pipeline 2: Stencil test — draw outline, only where stencil != 1
		{
			let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mPipelineLayout,
				Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				DepthStencil = DepthStencilState()
				{
					Format = .Depth24PlusStencil8,
					DepthWriteEnabled = false,
					DepthCompare = .Always,
					StencilEnabled = true,
					StencilReadMask = 0xFF,
					StencilWriteMask = 0x00,
					StencilFront = StencilFaceState() { Compare = .NotEqual, PassOp = .Keep, FailOp = .Keep, DepthFailOp = .Keep },
					StencilBack = StencilFaceState() { Compare = .NotEqual, PassOp = .Keep, FailOp = .Keep, DepthFailOp = .Keep }
				},
				Multisample = .(),
				Label = "StencilTestPipeline"
			});
			if (pipR case .Err) return .Err;
			mStencilTestPipeline = pipR.Value;
		}

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateDepthStencil()
	{
		if (mDepthStencilView != null) mDevice.DestroyTextureView(ref mDepthStencilView);
		if (mDepthStencilTexture != null) mDevice.DestroyTexture(ref mDepthStencilTexture);

		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .Depth24PlusStencil8,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1, Usage = .DepthStencil, Label = "StencilDSTex"
		});
		if (texR case .Err) return .Err;
		mDepthStencilTexture = texR.Value;

		let viewR = mDevice.CreateTextureView(mDepthStencilTexture, TextureViewDesc() { Format = .Depth24PlusStencil8, Dimension = .Texture2D });
		if (viewR case .Err) return .Err;
		mDepthStencilView = viewR.Value;
		return .Ok;
	}

	protected override void OnResize(uint32 w, uint32 h) { CreateDepthStencil(); }

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.08f, 0.08f, 0.12f, 1.0f) };

		let dsAttach = DepthStencilAttachment()
		{
			View = mDepthStencilView,
			DepthLoadOp = .Clear, DepthStoreOp = .Store, DepthClearValue = 1.0f,
			StencilLoadOp = .Clear, StencilStoreOp = .Store, StencilClearValue = 0
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca),
			DepthStencilAttachment = dsAttach
		});

		float aspect = (float)mWidth / (float)mHeight;

		// Pass 1: Draw solid hexagon, write stencil = 1
		rp.SetPipeline(mStencilWritePipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.SetStencilReference(1);
		var pc1 = PushData() { Scale = 1.0f, AspectRatio = aspect, Time = mTotalTime };
		rp.SetPushConstants(.Vertex, 0, sizeof(PushData), &pc1);
		rp.DrawIndexed(18);

		// Pass 2: Draw scaled-up hexagon, only where stencil != 1 (outline ring)
		rp.SetPipeline(mStencilTestPipeline);
		rp.SetStencilReference(1);
		var pc2 = PushData() { Scale = 1.15f, AspectRatio = aspect, Time = mTotalTime };
		rp.SetPushConstants(.Vertex, 0, sizeof(PushData), &pc2);
		rp.DrawIndexed(18);

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
		if (mStencilTestPipeline != null) mDevice?.DestroyRenderPipeline(ref mStencilTestPipeline);
		if (mStencilWritePipeline != null) mDevice?.DestroyRenderPipeline(ref mStencilWritePipeline);
		if (mDepthStencilView != null) mDevice?.DestroyTextureView(ref mDepthStencilView);
		if (mDepthStencilTexture != null) mDevice?.DestroyTexture(ref mDepthStencilTexture);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope StencilOutlineSample();
		return app.Run();
	}
}
