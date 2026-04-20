namespace Sample024_OcclusionQuery;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates occlusion queries and debug labels.
/// Renders an occluder quad, then two test quads behind it with occlusion queries.
/// Prints pixel counts to console. Uses debug labels to mark render sections.
class OcclusionQuerySample : SampleApp
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

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private IQuerySet mOcclusionQuerySet;
	private IBuffer mQueryResultBuffer;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;
	private int mFrameCount;
	private float mLastReportTime;

	public this() { }

	protected override StringView Title => "Sample024 - Occlusion Queries & Debug Labels";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "OccVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "OccPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Geometry: 3 quads
		// Quad 0: Occluder (opaque gray, z=0.3, center)
		// Quad 1: Test A (red, z=0.7, partially behind occluder)
		// Quad 2: Test B (blue, z=0.7, fully behind occluder)
		float[?] verts = .(
			// Quad 0: Occluder - center, near
			-0.3f, -0.4f, 0.3f,   0.4f, 0.4f, 0.4f, 1.0f,
			 0.3f, -0.4f, 0.3f,   0.4f, 0.4f, 0.4f, 1.0f,
			 0.3f,  0.4f, 0.3f,   0.5f, 0.5f, 0.5f, 1.0f,
			-0.3f,  0.4f, 0.3f,   0.5f, 0.5f, 0.5f, 1.0f,

			// Quad 1: Test A - partially occluded (left side visible)
			-0.7f, -0.3f, 0.7f,   1.0f, 0.3f, 0.3f, 1.0f,
			 0.0f, -0.3f, 0.7f,   1.0f, 0.3f, 0.3f, 1.0f,
			 0.0f,  0.3f, 0.7f,   1.0f, 0.5f, 0.5f, 1.0f,
			-0.7f,  0.3f, 0.7f,   1.0f, 0.5f, 0.5f, 1.0f,

			// Quad 2: Test B - fully occluded (behind occluder)
			-0.15f, -0.2f, 0.7f,  0.3f, 0.3f, 1.0f, 1.0f,
			 0.15f, -0.2f, 0.7f,  0.3f, 0.3f, 1.0f, 1.0f,
			 0.15f,  0.2f, 0.7f,  0.5f, 0.5f, 1.0f, 1.0f,
			-0.15f,  0.2f, 0.7f,  0.5f, 0.5f, 1.0f, 1.0f
		);

		uint16[18] indices = .(
			0, 1, 2, 0, 2, 3,
			4, 5, 6, 4, 6, 7,
			8, 9, 10, 8, 10, 11
		);

		uint32 vbSize = sizeof(decltype(verts));
		uint32 ibSize = sizeof(decltype(indices));

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "OccVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "OccIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "OccPL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		if (CreateDepthBuffer() case .Err) return .Err;

		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };
		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 28, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			DepthStencil = DepthStencilState() { Format = .Depth24PlusStencil8, DepthWriteEnabled = true, DepthCompare = .Less },
			Multisample = .(),
			Label = "OccPipeline"
		});
		if (pipR case .Err) return .Err;
		mPipeline = pipR.Value;

		// Occlusion query set: 2 queries (one per test quad)
		let qsR = mDevice.CreateQuerySet(QuerySetDesc() { Type = .Occlusion, Count = 2, Label = "OcclusionQS" });
		if (qsR case .Err) return .Err;
		mOcclusionQuerySet = qsR.Value;

		// Buffer for query results (2 * uint64 = 16 bytes)
		let qbR = mDevice.CreateBuffer(BufferDesc() { Size = 16, Usage = .CopyDst, Memory = .GpuToCpu, Label = "OccResultBuf" });
		if (qbR case .Err) return .Err;
		mQueryResultBuffer = qbR.Value;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateDepthBuffer()
	{
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);

		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .Depth24PlusStencil8,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1, Usage = .DepthStencil, Label = "OccDepthTex"
		});
		if (texR case .Err) return .Err;
		mDepthTexture = texR.Value;

		let viewR = mDevice.CreateTextureView(mDepthTexture, TextureViewDesc() { Format = .Depth24PlusStencil8, Dimension = .Texture2D });
		if (viewR case .Err) return .Err;
		mDepthView = viewR.Value;
		return .Ok;
	}

	protected override void OnResize(uint32 w, uint32 h) { CreateDepthBuffer(); }

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);

		// Read back previous frame's occlusion results
		if (mFrameCount > 1)
		{
			let mapped = mQueryResultBuffer.Map();
			if (mapped != null)
			{
				uint64* results = (uint64*)mapped;
				uint64 pixelsA = results[0];
				uint64 pixelsB = results[1];

				if (mTotalTime - mLastReportTime >= 2.0f)
				{
					Console.WriteLine("Occlusion: QuadA={} pixels, QuadB={} pixels (B should be ~0)", pixelsA, pixelsB);
					mLastReportTime = mTotalTime;
				}
				mQueryResultBuffer.Unmap();
			}
		}

		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		// Debug label: frame start
		encoder.InsertDebugLabel("Frame Start", 0, 1, 0);

		encoder.ResetQuerySet(mOcclusionQuerySet, 0, 2);

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.08f, 0.08f, 0.12f, 1.0f) };

		let dsAttach = DepthStencilAttachment()
		{
			View = mDepthView,
			DepthLoadOp = .Clear, DepthStoreOp = .Store, DepthClearValue = 1.0f
		};

		// Debug label: render pass
		encoder.BeginDebugLabel("Main Render Pass", 0.2f, 0.5f, 1.0f);

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca),
			DepthStencilAttachment = dsAttach
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// Draw occluder first (writes depth)
		rp.DrawIndexed(6, 1, 0, 0, 0);

		// Draw test quad A with occlusion query 0
		rp.BeginOcclusionQuery(mOcclusionQuerySet, 0);
		rp.DrawIndexed(6, 1, 6, 0, 0);
		rp.EndOcclusionQuery(mOcclusionQuerySet, 0);

		// Draw test quad B with occlusion query 1
		rp.BeginOcclusionQuery(mOcclusionQuerySet, 1);
		rp.DrawIndexed(6, 1, 12, 0, 0);
		rp.EndOcclusionQuery(mOcclusionQuerySet, 1);

		rp.End();

		encoder.EndDebugLabel();

		// Resolve occlusion queries to buffer
		encoder.ResolveQuerySet(mOcclusionQuerySet, 0, 2, mQueryResultBuffer, 0);

		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);

		mFrameCount++;
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mQueryResultBuffer != null) mDevice?.DestroyBuffer(ref mQueryResultBuffer);
		if (mOcclusionQuerySet != null) mDevice?.DestroyQuerySet(ref mOcclusionQuerySet);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mDepthView != null) mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice?.DestroyTexture(ref mDepthTexture);
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
		let app = scope OcclusionQuerySample();
		return app.Run();
	}
}
