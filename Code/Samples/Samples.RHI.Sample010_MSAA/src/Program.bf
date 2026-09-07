using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample010_MSAA;

/// Four times multisampling, resolved to the swap chain.
///
/// A single triangle, because what is on show is the EDGES: drawn without multisampling
/// they step, and with it they do not. The pass renders into a four sample target and names
/// the back buffer as its resolve target, so the resolve happens as the pass ends rather
/// than as a separate command.
class MSAASample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput { float3 Position : TEXCOORD0; float3 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float3 Color : COLOR0; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position,1); o.Color = i.Color; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return float4(i.Color, 1.0); }
		""";

	/// Position then colour. Deliberately not axis aligned, so every edge is a diagonal
	/// and aliasing has somewhere to show.
	private static float[18] sVertices = .(
		 0.0f,  0.7f, 0.0f,   1.0f, 0.0f, 0.0f,
		 0.7f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,
		-0.7f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f);
	private static uint16[3] sIndices = .(0, 1, 2);

	private const uint32 cSampleCount = 4;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ITexture mMultisampleTexture = null;
	private ITextureView mMultisampleView = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample010 - MSAA (4x)";

	protected override void OnResize(uint32 width, uint32 height)
	{
		RecreateMultisampleTarget(width, height);
	}

	/// The multisampled colour target, which is what is actually rendered into.
	private void RecreateMultisampleTarget(uint32 width, uint32 height)
	{
		if (mMultisampleView != null)
			mDevice.DestroyTextureView(ref mMultisampleView);
		if (mMultisampleTexture != null)
			mDevice.DestroyTexture(ref mMultisampleTexture);

		let textureDesc = TextureDesc.RenderTarget(mSwapChain.Format, width, height,
			cSampleCount, "MSAATarget");
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return;
		mMultisampleTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = mSwapChain.Format;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (mDevice.CreateTextureView(mMultisampleTexture, viewDesc) case .Ok(let view))
			mMultisampleView = view;
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

		if (CreatePipeline() case .Err)
			return .Err;

		RecreateMultisampleTarget(mWidth, mHeight);

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
			.() { Format = .Float32x3, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 24;
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
		// The pipeline's sample count must MATCH the attachment's, or the pass is refused.
		desc.Multisample.Count = cSampleCount;

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
		encoder.TransitionTexture(mMultisampleTexture, .Undefined, .RenderTarget);

		// Rendered into the MULTISAMPLED view, with the back buffer named as the resolve
		// target. The resolve is then part of ending the pass, which is cheaper than a
		// separate resolve command and is what the hardware is built for.
		var colorAttachment = ColorAttachment();
		colorAttachment.View = mMultisampleView;
		colorAttachment.ResolveTarget = mSwapChain.CurrentTextureView;
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
		if (mMultisampleView != null) mDevice.DestroyTextureView(ref mMultisampleView);
		if (mMultisampleTexture != null) mDevice.DestroyTexture(ref mMultisampleTexture);
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
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
		let app = scope MSAASample();
		return app.Run(args);
	}
}
