namespace Sample015_Queries;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates GPU timestamp queries.
/// Measures render pass duration using timestamps before and after, prints to console.
class QuerySample : SampleApp
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
	private IQuerySet mTimestampQuerySet;
	private IBuffer mQueryResultBuffer;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;
	private int mFrameCount;
	private float mLastReportTime;

	public this()  { }

	protected override StringView Title => "Sample015 — GPU Queries";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "QueryVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "QueryPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Simple triangle
		float[21] verts = .(
			 0.0f,  0.5f, 0.0f,   1.0f, 0.3f, 0.3f, 1.0f,
			 0.5f, -0.5f, 0.0f,   0.3f, 1.0f, 0.3f, 1.0f,
			-0.5f, -0.5f, 0.0f,   0.3f, 0.3f, 1.0f, 1.0f
		);
		uint16[3] indices = .(0, 1, 2);

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = 84, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "QueryVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = 6, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "QueryIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], 84));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], 6));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "QueryPL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

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
			Label = "QueryPipeline"
		});
		if (pipR case .Err) return .Err;
		mPipeline = pipR.Value;

		// Timestamp query set: 2 queries (before + after render pass)
		let qsR = mDevice.CreateQuerySet(QuerySetDesc() { Type = .Timestamp, Count = 2, Label = "TimestampQS" });
		if (qsR case .Err) return .Err;
		mTimestampQuerySet = qsR.Value;

		// Buffer to receive resolved query results (2 * uint64 = 16 bytes)
		let qbR = mDevice.CreateBuffer(BufferDesc() { Size = 16, Usage = .CopyDst, Memory = .GpuToCpu, Label = "QueryResultBuf" });
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

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);

		// Read back previous frame's query results (after fence wait ensures GPU is done)
		if (mFrameCount > 1)
		{
			let mapped = mQueryResultBuffer.Map();
			if (mapped != null)
			{
				uint64* timestamps = (uint64*)mapped;
				uint64 begin = timestamps[0];
				uint64 end = timestamps[1];
				uint64 delta = end - begin;
				float period = mGraphicsQueue.TimestampPeriod;
				float gpuTimeUs = (float)delta * period / 1000.0f;

				// Report every ~2 seconds
				if (mTotalTime - mLastReportTime >= 2.0f)
				{
					Console.WriteLine("GPU render pass time: {0:F2} us ({1} ticks, period={2:F2} ns)", gpuTimeUs, delta, period);
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

		// Reset queries for this frame
		encoder.ResetQuerySet(mTimestampQuerySet, 0, 2);

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		// Timestamp before render pass
		encoder.WriteTimestamp(mTimestampQuerySet, 0);

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.08f, 0.08f, 0.12f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca)
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(3);
		rp.End();

		// Timestamp after render pass
		encoder.WriteTimestamp(mTimestampQuerySet, 1);

		// Resolve timestamps to buffer
		encoder.ResolveQuerySet(mTimestampQuerySet, 0, 2, mQueryResultBuffer, 0);

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
		if (mTimestampQuerySet != null) mDevice?.DestroyQuerySet(ref mTimestampQuerySet);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
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
		let app = scope QuerySample();
		return app.Run();
	}
}
