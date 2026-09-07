using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample029_ResolveTexture;

/// Four times multisampling resolved EXPLICITLY, as a command rather than as part of ending
/// the pass.
///
/// The contrast with Sample010: there the pass named a resolve target and the hardware did
/// it on the way out. Here the pass resolves nothing and ResolveTexture does it afterwards,
/// which is what a renderer needs when the multisampled result has to be used for something
/// else before it is flattened.
class ResolveTextureSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput {
		    float3 Position : TEXCOORD0;
		    float4 Color    : TEXCOORD1;
		};
		struct PSInput {
		    float4 Position : SV_POSITION;
		    float4 Color    : COLOR0;
		};
		PSInput VSMain(VSInput input) {
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.Color = input.Color;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET {
		    return input.Color;
		}
		""";

	/// A star: a centre, five outer points and five inner ones. Every edge is a diagonal,
	/// which is what makes the multisampling visible.
	private static float[77] sVertices = .(
		 0.000f,  0.000f, 0.0f,   1.0f, 1.0f, 1.0f, 1.0f,
		 0.000f,  0.700f, 0.0f,   1.0f, 0.2f, 0.2f, 1.0f,
		 0.665f,  0.216f, 0.0f,   0.2f, 1.0f, 0.2f, 1.0f,
		 0.411f, -0.566f, 0.0f,   0.2f, 0.3f, 1.0f, 1.0f,
		-0.411f, -0.566f, 0.0f,   1.0f, 1.0f, 0.2f, 1.0f,
		-0.665f,  0.216f, 0.0f,   1.0f, 0.2f, 1.0f, 1.0f,
		 0.238f,  0.327f, 0.0f,   0.8f, 0.7f, 0.5f, 1.0f,
		 0.385f, -0.125f, 0.0f,   0.5f, 0.8f, 0.7f, 1.0f,
		 0.000f, -0.405f, 0.0f,   0.5f, 0.5f, 0.9f, 1.0f,
		-0.385f, -0.125f, 0.0f,   0.9f, 0.8f, 0.5f, 1.0f,
		-0.238f,  0.327f, 0.0f,   0.9f, 0.5f, 0.8f, 1.0f);

	private static uint16[30] sIndices = .(
		0, 1, 6,  0, 6, 2,  0, 2, 7,  0, 7, 3,  0, 3, 8,
		0, 8, 4,  0, 4, 9,  0, 9, 5,  0, 5, 10, 0, 10, 1);

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

	protected override StringView Title => "Sample029 - ResolveTexture (Explicit 4x MSAA)";

	protected override void OnResize(uint32 width, uint32 height)
	{
		RecreateMultisampleTarget(width, height);
	}

	private void RecreateMultisampleTarget(uint32 width, uint32 height)
	{
		if (mMultisampleView != null)
			mDevice.DestroyTextureView(ref mMultisampleView);
		if (mMultisampleTexture != null)
			mDevice.DestroyTexture(ref mMultisampleTexture);

		// RenderTarget to draw into and CopySrc because the RESOLVE reads it, which an
		// automatic resolve would not have needed.
		var textureDesc = TextureDesc();
		textureDesc.Format = mSwapChain.Format;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.SampleCount = cSampleCount;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "MsaaRT";
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

		// From CopySrc, which is where the previous frame's resolve left it. The first
		// frame's texture is fresh, and a backend treats an unwritten image as discardable
		// either way.
		encoder.TransitionTexture(mMultisampleTexture, .CopySrc, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mMultisampleView;
		// NO resolve target: that is the whole difference from the automatic path.
		colorAttachment.ResolveTarget = null;
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
		pass.DrawIndexed(30);
		pass.End();

		// The resolve is a COPY, so both sides move to copy states. The back buffer is
		// never a render target in this frame at all.
		encoder.TransitionTexture(mMultisampleTexture, .RenderTarget, .CopySrc);
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Present, .CopyDst);
		encoder.ResolveTexture(mMultisampleTexture, mSwapChain.CurrentTexture);
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .CopyDst, .Present);

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
		let app = scope ResolveTextureSample();
		return app.Run(args);
	}
}
