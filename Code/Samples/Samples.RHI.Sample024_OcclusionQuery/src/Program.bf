using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample024_OcclusionQuery;

/// Occlusion queries counting the pixels two quads actually pass, plus debug labels.
///
/// A near occluder is drawn first, then two test quads: one clear of it and one hidden
/// behind it. The counts come back a frame late and show the difference, which is what a
/// renderer uses to skip work for objects nothing can see.
///
/// The debug labels are for a GPU capture: they are what turns a flat list of commands into
/// a readable tree.
class OcclusionQuerySample : SampleApp
{
	private const String cShaderSource = """
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

	/// Three quads, position then RGBA. The first is the OCCLUDER at depth 0.3; the second
	/// is off to the left and clear of it; the third sits directly behind it.
	private static float[84] sVertices = .(
		-0.30f, -0.40f, 0.3f,   0.4f, 0.4f, 0.4f, 1.0f,
		 0.30f, -0.40f, 0.3f,   0.4f, 0.4f, 0.4f, 1.0f,
		 0.30f,  0.40f, 0.3f,   0.5f, 0.5f, 0.5f, 1.0f,
		-0.30f,  0.40f, 0.3f,   0.5f, 0.5f, 0.5f, 1.0f,

		-0.70f, -0.30f, 0.7f,   1.0f, 0.3f, 0.3f, 1.0f,
		 0.00f, -0.30f, 0.7f,   1.0f, 0.3f, 0.3f, 1.0f,
		 0.00f,  0.30f, 0.7f,   1.0f, 0.5f, 0.5f, 1.0f,
		-0.70f,  0.30f, 0.7f,   1.0f, 0.5f, 0.5f, 1.0f,

		-0.15f, -0.20f, 0.7f,   0.3f, 0.3f, 1.0f, 1.0f,
		 0.15f, -0.20f, 0.7f,   0.3f, 0.3f, 1.0f, 1.0f,
		 0.15f,  0.20f, 0.7f,   0.5f, 0.5f, 1.0f, 1.0f,
		-0.15f,  0.20f, 0.7f,   0.5f, 0.5f, 1.0f, 1.0f);

	private static uint16[18] sIndices = .(
		0, 1, 2, 0, 2, 3,
		4, 5, 6, 4, 6, 7,
		8, 9, 10, 8, 10, 11);

	private const uint32 cQueryCount = 2;
	private const float cReportInterval = 2.0f;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ITexture mDepthTexture = null;
	private ITextureView mDepthView = null;
	private IQuerySet mOcclusionQueries = null;
	private IBuffer mQueryResults = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private int mFrameCount = 0;
	private float mLastReportTime = 0.0f;

	protected override StringView Title => "Sample024 - Occlusion Queries & Debug Labels";

	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.OcclusionQueries = true;
			return features;
		}
	}

	protected override void OnResize(uint32 width, uint32 height)
	{
		RecreateDepth(width, height);
	}

	private void RecreateDepth(uint32 width, uint32 height)
	{
		if (mDepthView != null)
			mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null)
			mDevice.DestroyTexture(ref mDepthTexture);

		let textureDesc = TextureDesc.DepthBuffer(.Depth24PlusStencil8, width, height, 1,
			"OcclusionDepth");
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return;
		mDepthTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .Depth24PlusStencil8;
		viewDesc.Dimension = .Texture2D;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (mDevice.CreateTextureView(mDepthTexture, viewDesc) case .Ok(let view))
			mDepthView = view;
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

		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		RecreateDepth(mWidth, mHeight);

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
		// Depth WRITING and testing: the occluder has to actually occlude, which it can
		// only do by having been recorded in the depth buffer.
		var depthStencil = DepthStencilState();
		depthStencil.Format = .Depth24PlusStencil8;
		depthStencil.DepthWriteEnabled = true;
		depthStencil.DepthCompare = .Less;
		desc.DepthStencil = depthStencil;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;
		return .Ok;
	}

	private Result<void> CreateQueries()
	{
		var querySetDesc = QuerySetDesc();
		querySetDesc.Type = .Occlusion;
		querySetDesc.Count = cQueryCount;
		querySetDesc.Label = "OcclusionQS";
		if (!(mDevice.CreateQuerySet(querySetDesc) case .Ok(let querySet)))
			return .Err;
		mOcclusionQueries = querySet;

		var resultDesc = BufferDesc();
		resultDesc.Size = 16;
		resultDesc.Usage = .CopyDst;
		resultDesc.Memory = .GpuToCpu;
		resultDesc.Label = "OccResultBuf";
		if (!(mDevice.CreateBuffer(resultDesc) case .Ok(let results)))
			return .Err;
		mQueryResults = results;
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);

		if (mFrameCount > 1)
			ReportOcclusion();

		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		// Labels bracket the work for a GPU capture. They do nothing at runtime, which is
		// why they can be left in.
		encoder.InsertDebugLabel("Frame Start", 0, 1, 0);

		encoder.ResetQuerySet(mOcclusionQueries, 0, cQueryCount);
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mDepthTexture, .Undefined, .DepthStencilWrite);

		encoder.BeginDebugLabel("Main Render Pass", 0.2f, 0.5f, 1.0f);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.08f, 0.08f, 0.12f, 1.0f);

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthView;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = 1.0f;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;
		// Declared when the pass BEGINS, not when a query starts: WebGPU requires it, and
		// the other backends accept it.
		passDesc.OcclusionQuerySet = mOcclusionQueries;

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// The occluder first, UNCOUNTED: it is what the others are tested against.
		pass.DrawIndexed(6, 1, 0, 0, 0);

		// Quad A, clear of the occluder, so it should report a large count.
		pass.BeginOcclusionQuery(mOcclusionQueries, 0);
		pass.DrawIndexed(6, 1, 6, 0, 0);
		pass.EndOcclusionQuery(mOcclusionQueries, 0);

		// Quad B, directly behind it, so it should report near zero.
		pass.BeginOcclusionQuery(mOcclusionQueries, 1);
		pass.DrawIndexed(6, 1, 12, 0, 0);
		pass.EndOcclusionQuery(mOcclusionQueries, 1);
		pass.End();

		encoder.EndDebugLabel();

		encoder.ResolveQuerySet(mOcclusionQueries, 0, cQueryCount, mQueryResults, 0);
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
		mFrameCount++;
	}

	private void ReportOcclusion()
	{
		let mapped = (uint64*)mQueryResults.Map();
		if (mapped == null)
			return;
		defer mQueryResults.Unmap();

		if (mTotalTime - mLastReportTime < cReportInterval)
			return;
		Console.WriteLine(scope $"Occlusion: QuadA={mapped[0]} pixels, QuadB={mapped[1]} pixels (B should be ~0)");
		mLastReportTime = mTotalTime;
	}

	protected override void OnShutdown()
	{
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mQueryResults != null) mDevice.DestroyBuffer(ref mQueryResults);
		if (mOcclusionQueries != null) mDevice.DestroyQuerySet(ref mOcclusionQueries);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);
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
		let app = scope OcclusionQuerySample();
		return app.Run(args);
	}
}
