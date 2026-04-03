namespace Sample025_MultiDrawIndirect;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates multi-draw indirect and line topology.
/// Renders 4 shapes using a single DrawIndexedIndirect call with drawCount=4,
/// then overlays line wireframes using LineList topology.
class MultiDrawIndirectSample : SampleApp
{
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

	[CRepr]
	struct DrawIndexedIndirectArgs
	{
		public uint32 IndexCountPerInstance;
		public uint32 InstanceCount;
		public uint32 StartIndexLocation;
		public int32 BaseVertexLocation;
		public uint32 StartInstanceLocation;
	}

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mIndirectBuffer;
	private IBuffer mLineVertexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mFillPipeline;
	private IRenderPipeline mLinePipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample025 — Multi-Draw Indirect & Lines";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "MDIVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "MDIPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		if (CreateGeometry() case .Err) return .Err;
		if (CreateIndirectBuffer() case .Err) return .Err;
		if (CreateLineGeometry() case .Err) return .Err;

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "MDIPL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };
		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 28, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		// Fill pipeline (TriangleList)
		{
			let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mPipelineLayout,
				Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Multisample = .(),
				Label = "FillPipeline"
			});
			if (pipR case .Err) return .Err;
			mFillPipeline = pipR.Value;
		}

		// Line pipeline (LineList)
		{
			let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mPipelineLayout,
				Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .LineList },
				Multisample = .(),
				Label = "LinePipeline"
			});
			if (pipR case .Err) return .Err;
			mLinePipeline = pipR.Value;
		}

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateGeometry()
	{
		// 4 quads at different positions
		float[?] verts = .(
			// Quad 0: top-left (red)
			-0.9f,  0.1f, 0.5f,   0.8f, 0.2f, 0.2f, 1.0f,
			-0.1f,  0.1f, 0.5f,   0.8f, 0.2f, 0.2f, 1.0f,
			-0.1f,  0.9f, 0.5f,   1.0f, 0.4f, 0.4f, 1.0f,
			-0.9f,  0.9f, 0.5f,   1.0f, 0.4f, 0.4f, 1.0f,

			// Quad 1: top-right (green)
			 0.1f,  0.1f, 0.5f,   0.2f, 0.8f, 0.2f, 1.0f,
			 0.9f,  0.1f, 0.5f,   0.2f, 0.8f, 0.2f, 1.0f,
			 0.9f,  0.9f, 0.5f,   0.4f, 1.0f, 0.4f, 1.0f,
			 0.1f,  0.9f, 0.5f,   0.4f, 1.0f, 0.4f, 1.0f,

			// Quad 2: bottom-left (blue)
			-0.9f, -0.9f, 0.5f,   0.2f, 0.2f, 0.8f, 1.0f,
			-0.1f, -0.9f, 0.5f,   0.2f, 0.2f, 0.8f, 1.0f,
			-0.1f, -0.1f, 0.5f,   0.4f, 0.4f, 1.0f, 1.0f,
			-0.9f, -0.1f, 0.5f,   0.4f, 0.4f, 1.0f, 1.0f,

			// Quad 3: bottom-right (yellow)
			 0.1f, -0.9f, 0.5f,   0.8f, 0.8f, 0.2f, 1.0f,
			 0.9f, -0.9f, 0.5f,   0.8f, 0.8f, 0.2f, 1.0f,
			 0.9f, -0.1f, 0.5f,   1.0f, 1.0f, 0.4f, 1.0f,
			 0.1f, -0.1f, 0.5f,   1.0f, 1.0f, 0.4f, 1.0f
		);

		uint16[24] indices = .(
			0, 1, 2, 0, 2, 3,       // Quad 0
			4, 5, 6, 4, 6, 7,       // Quad 1
			8, 9, 10, 8, 10, 11,    // Quad 2
			12, 13, 14, 12, 14, 15  // Quad 3
		);

		uint32 vbSize = sizeof(decltype(verts));
		uint32 ibSize = sizeof(decltype(indices));

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "MDIVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "MDIIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		return .Ok;
	}

	private Result<void> CreateIndirectBuffer()
	{
		// 4 indirect draw commands — one per quad
		DrawIndexedIndirectArgs[4] args = .(
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 0,  BaseVertexLocation = 0,  StartInstanceLocation = 0 },
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 6,  BaseVertexLocation = 0,  StartInstanceLocation = 0 },
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 12, BaseVertexLocation = 0,  StartInstanceLocation = 0 },
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 18, BaseVertexLocation = 0,  StartInstanceLocation = 0 }
		);

		uint32 bufSize = sizeof(decltype(args));
		let bufR = mDevice.CreateBuffer(BufferDesc() { Size = bufSize, Usage = .Indirect | .CopyDst, Memory = .GpuOnly, Label = "IndirectBuf" });
		if (bufR case .Err) return .Err;
		mIndirectBuffer = bufR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var xfer = batchR.Value;
		xfer.WriteBuffer(mIndirectBuffer, 0, Span<uint8>((uint8*)&args[0], bufSize));
		xfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref xfer);

		return .Ok;
	}

	private Result<void> CreateLineGeometry()
	{
		// Line wireframes for each quad: 4 lines per quad = 8 verts per quad
		float[?] lineVerts = .(
			// Quad 0 edges (white lines)
			-0.9f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.9f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.9f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.9f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,

			// Quad 1 edges
			 0.1f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.1f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.1f,  0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.1f,  0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,

			// Quad 2 edges
			-0.9f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.1f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.9f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.9f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			-0.9f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,

			// Quad 3 edges
			 0.1f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.9f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.1f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.1f, -0.1f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f,
			 0.1f, -0.9f, 0.4f,   1.0f, 1.0f, 1.0f, 1.0f
		);

		uint32 vbSize = sizeof(decltype(lineVerts));
		let r = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "LineVB" });
		if (r case .Err) return .Err;
		mLineVertexBuffer = r.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var xfer = batchR.Value;
		xfer.WriteBuffer(mLineVertexBuffer, 0, Span<uint8>((uint8*)&lineVerts[0], vbSize));
		xfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref xfer);

		return .Ok;
	}

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
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.06f, 0.06f, 0.1f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca)
		});

		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);

		// Pass 1: Draw all 4 quads with a single multi-draw indirect call
		rp.SetPipeline(mFillPipeline);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexedIndirect(mIndirectBuffer, 0, 4, (uint32)sizeof(DrawIndexedIndirectArgs));

		// Pass 2: Draw line wireframes
		rp.SetPipeline(mLinePipeline);
		rp.SetVertexBuffer(0, mLineVertexBuffer, 0);
		rp.Draw(32); // 4 quads * 4 edges * 2 verts = 32 line verts

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
		if (mLinePipeline != null) mDevice?.DestroyRenderPipeline(ref mLinePipeline);
		if (mFillPipeline != null) mDevice?.DestroyRenderPipeline(ref mFillPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mLineVertexBuffer != null) mDevice?.DestroyBuffer(ref mLineVertexBuffer);
		if (mIndirectBuffer != null) mDevice?.DestroyBuffer(ref mIndirectBuffer);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MultiDrawIndirectSample();
		return app.Run();
	}
}
