using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample008_DepthBuffer;

/// Depth testing: three overlapping quads drawn far to near, where what you see is decided
/// by depth rather than by draw order.
///
/// The quads are submitted in the order red, green, blue and their depths agree with that,
/// so the picture looks the same either way. The test is that the depth state is real:
/// without it the last drawn would simply win everywhere it overlaps.
class DepthBufferSample : SampleApp
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

	/// Three quads, position then RGBA, one vertex per row. Depth decreases with each, so
	/// each is nearer the camera than the one before.
	private static float[84] sVertices = .(
		// Red: large and furthest back.
		-0.6f, -0.6f, 0.8f,   1.0f, 0.2f, 0.2f, 1.0f,
		 0.4f, -0.6f, 0.8f,   1.0f, 0.2f, 0.2f, 1.0f,
		 0.4f,  0.6f, 0.8f,   1.0f, 0.2f, 0.2f, 1.0f,
		-0.6f,  0.6f, 0.8f,   1.0f, 0.2f, 0.2f, 1.0f,
		// Green: overlaps red, and nearer.
		-0.2f, -0.4f, 0.5f,   0.2f, 1.0f, 0.2f, 1.0f,
		 0.6f, -0.4f, 0.5f,   0.2f, 1.0f, 0.2f, 1.0f,
		 0.6f,  0.4f, 0.5f,   0.2f, 1.0f, 0.2f, 1.0f,
		-0.2f,  0.4f, 0.5f,   0.2f, 1.0f, 0.2f, 1.0f,
		// Blue: overlaps both, and nearest.
		-0.4f, -0.7f, 0.2f,   0.2f, 0.3f, 1.0f, 1.0f,
		 0.2f, -0.7f, 0.2f,   0.2f, 0.3f, 1.0f, 1.0f,
		 0.2f,  0.7f, 0.2f,   0.2f, 0.3f, 1.0f, 1.0f,
		-0.4f,  0.7f, 0.2f,   0.2f, 0.3f, 1.0f, 1.0f);

	private static uint16[18] sIndices = .(
		0, 1, 2, 0, 2, 3,
		4, 5, 6, 4, 6, 7,
		8, 9, 10, 8, 10, 11);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ITexture mDepthTexture = null;
	private ITextureView mDepthView = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample008 - Depth Buffer";

	protected override void OnResize(uint32 width, uint32 height)
	{
		RecreateDepth(width, height);
	}

	/// The depth target is built by hand here rather than through the framework's helper,
	/// since this sample is about the depth attachment itself.
	private void RecreateDepth(uint32 width, uint32 height)
	{
		if (mDepthView != null)
			mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null)
			mDevice.DestroyTexture(ref mDepthTexture);

		let textureDesc = TextureDesc.DepthBuffer(.Depth24PlusStencil8, width, height, 1,
			"DepthTex");
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

		// Writing AND testing: a pipeline that tests without writing would let every quad
		// pass, since nothing would ever have been recorded to test against.
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

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mDepthTexture, .Undefined, .DepthStencilWrite);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		// Cleared to one, the far plane, so the first quad drawn always passes.
		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthView;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = 1.0f;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexed(18);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);
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
		let app = scope DepthBufferSample();
		return app.Run(args);
	}
}
