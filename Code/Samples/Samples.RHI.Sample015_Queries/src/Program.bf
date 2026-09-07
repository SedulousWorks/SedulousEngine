using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample015_Queries;

/// GPU timestamps around a render pass, resolved and read back.
///
/// The result is read a frame LATE, after the fence for that frame has been waited on: a
/// timestamp is only meaningful once the work it brackets has finished, and reading it in
/// the same frame would either stall or return nothing.
class QuerySample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position,1); o.Color = i.Color; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return i.Color; }
		""";

	private static float[21] sVertices = .(
		 0.0f,  0.5f, 0.0f,   1.0f, 0.3f, 0.3f, 1.0f,
		 0.5f, -0.5f, 0.0f,   0.3f, 1.0f, 0.3f, 1.0f,
		-0.5f, -0.5f, 0.0f,   0.3f, 0.3f, 1.0f, 1.0f);
	private static uint16[3] sIndices = .(0, 1, 2);

	/// One before the pass and one after.
	private const uint32 cQueryCount = 2;
	/// Two 64 bit timestamps.
	private const uint64 cQueryResultSize = 16;
	/// How often the measurement is printed, so the log stays readable.
	private const float cReportInterval = 2.0f;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private IQuerySet mTimestampQueries = null;
	private IBuffer mQueryResults = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private int mFrameCount = 0;
	private float mLastReportTime = 0.0f;

	protected override StringView Title => "Sample015 - GPU Queries";

	/// Timestamps are an optional feature, so a device without them refuses here rather
	/// than returning zeros that look like an impossibly fast pass.
	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.TimestampQueries = true;
			return features;
		}
	}

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Vertex,
			"VSMain", "VS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "PS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateBuffers() case .Err)
			return .Err;
		if (CreatePipeline() case .Err)
			return .Err;
		if (CreateQueries() case .Err)
			return .Err;

		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return .Err;
		mPool = pool;
		if (!(mDevice.CreateFence(0) case .Ok(let fence)))
			return .Err;
		mFence = fence;
		return .Ok;
	}

	private Result<void> CreateBuffers()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sVertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = sizeof(uint16) * sIndices.Count;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertices[0], sizeof(float) * sVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sIndices[0], sizeof(uint16) * sIndices.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x4, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 28;
		vertexLayout.Attributes = attributes;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;

		var buffers = VertexBufferLayout[1](vertexLayout);
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;
		var fragment = FragmentState();
		fragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;
		return .Ok;
	}

	private Result<void> CreateQueries()
	{
		var querySetDesc = QuerySetDesc();
		querySetDesc.Type = .Timestamp;
		querySetDesc.Count = cQueryCount;
		if (!(mDevice.CreateQuerySet(querySetDesc) case .Ok(let querySet)))
			return .Err;
		mTimestampQueries = querySet;

		// GpuToCpu, because reading a timestamp is the whole point and a device local
		// buffer could not be mapped.
		var resultDesc = BufferDesc();
		resultDesc.Size = cQueryResultSize;
		resultDesc.Usage = .CopyDst;
		resultDesc.Memory = .GpuToCpu;
		if (!(mDevice.CreateBuffer(resultDesc) case .Ok(let results)))
			return .Err;
		mQueryResults = results;
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);

		// Read AFTER the wait, so what is in the buffer is a completed frame's. The first
		// two frames have nothing to read yet.
		if (mFrameCount > 1)
			ReportTimestamps();

		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		// Reset before use: a query that still holds last frame's value would resolve to
		// it rather than to this frame's.
		encoder.ResetQuerySet(mTimestampQueries, 0, cQueryCount);
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		encoder.WriteTimestamp(mTimestampQueries, 0);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.08f, 0.08f, 0.12f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexed(3);
		pass.End();

		encoder.WriteTimestamp(mTimestampQueries, 1);
		// Resolving copies the query values into a buffer the CPU can map; the query set
		// itself is not readable.
		encoder.ResolveQuerySet(mTimestampQueries, 0, cQueryCount, mQueryResults, 0);

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
		mFrameCount++;
	}

	/// Turns the two raw timestamps into a duration and prints it, occasionally.
	private void ReportTimestamps()
	{
		let mapped = (uint64*)mQueryResults.Map();
		if (mapped == null)
			return;
		defer mQueryResults.Unmap();

		let ticks = mapped[1] - mapped[0];
		// The period is nanoseconds PER TICK, which is what turns a difference into a
		// duration and differs between devices.
		let period = mGraphicsQueue.TimestampPeriod();
		let microseconds = (float)ticks * period / 1000.0f;

		if (mTotalTime - mLastReportTime < cReportInterval)
			return;
		Console.WriteLine(scope $"GPU render pass time: {microseconds:0.00} us ({ticks} ticks, period={period:0.00} ns)");
		mLastReportTime = mTotalTime;
	}

	protected override void OnShutdown()
	{
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mQueryResults != null) mDevice.DestroyBuffer(ref mQueryResults);
		if (mTimestampQueries != null) mDevice.DestroyQuerySet(ref mTimestampQueries);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mIndexBuffer != null) mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		if (mPixelShader != null) mDevice.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice.DestroyShaderModule(ref mVertexShader);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope QuerySample();
		return app.Run(args);
	}
}
