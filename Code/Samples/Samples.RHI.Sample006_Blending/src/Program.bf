using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample006_Blending;

/// Alpha blending: an opaque background with three translucent quads over it.
///
/// TWO pipelines from ONE pair of shaders. Blending is pipeline state, not shader code, so
/// the only difference between them is the colour target's blend, and switching between
/// them mid pass is what draws the opaque quad without blending and the rest with.
class BlendingSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position, 1.0); o.Color = i.Color; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return i.Color; }
		""";

	/// Four quads: an opaque backdrop, then three translucent ones at decreasing depth so
	/// they overlap. Position then RGBA, one vertex per row.
	private static float[112] sVertices = .(
		// Backdrop, opaque and furthest back.
		-0.9f, -0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,
		 0.9f, -0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,
		 0.9f,  0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,
		-0.9f,  0.9f, 0.5f,   0.15f, 0.15f, 0.2f, 1.0f,
		// Red, half transparent.
		-0.6f, -0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,
		 0.1f, -0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,
		 0.1f,  0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,
		-0.6f,  0.4f, 0.3f,   1.0f, 0.2f, 0.2f, 0.5f,
		// Green.
		-0.3f, -0.5f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,
		 0.4f, -0.5f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,
		 0.4f,  0.3f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,
		-0.3f,  0.3f, 0.2f,   0.2f, 1.0f, 0.2f, 0.5f,
		// Blue, nearest.
		-0.1f, -0.3f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f,
		 0.6f, -0.3f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f,
		 0.6f,  0.5f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f,
		-0.1f,  0.5f, 0.1f,   0.2f, 0.3f, 1.0f, 0.5f);

	private static uint16[24] sIndices = .(
		0, 1, 2, 0, 2, 3,
		4, 5, 6, 4, 6, 7,
		8, 9, 10, 8, 10, 11,
		12, 13, 14, 12, 14, 15);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mOpaquePipeline = null;
	private IRenderPipeline mBlendPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample006 - Alpha Blending";

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
		if (CreatePipelines() case .Err)
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

	private Result<void> CreatePipelines()
	{
		// The shaders bind nothing, so the layout is empty.
		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x4, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 28;
		vertexLayout.Attributes = attributes;
		var buffers = VertexBufferLayout[1](vertexLayout);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;

		var opaqueTarget = ColorTargetState();
		opaqueTarget.Format = mSwapChain.Format;
		var opaqueTargets = ColorTargetState[1](opaqueTarget);
		var opaqueFragment = FragmentState();
		opaqueFragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		opaqueFragment.Targets = opaqueTargets;
		desc.Fragment = opaqueFragment;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let opaquePipeline)))
			return .Err;
		mOpaquePipeline = opaquePipeline;

		// The SAME description with one field changed, which is the point: blending is
		// pipeline state rather than anything the shader knows about.
		var blendTarget = ColorTargetState();
		blendTarget.Format = mSwapChain.Format;
		blendTarget.Blend = BlendState.AlphaBlend;
		var blendTargets = ColorTargetState[1](blendTarget);
		var blendFragment = FragmentState();
		blendFragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		blendFragment.Targets = blendTargets;
		desc.Fragment = blendFragment;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let blendPipeline)))
			return .Err;
		mBlendPipeline = blendPipeline;
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

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// The backdrop first and unblended, so the translucent quads have something to
		// blend against. There is no depth buffer here, so submission order IS draw order.
		pass.SetPipeline(mOpaquePipeline);
		pass.DrawIndexed(6, 1, 0, 0, 0);

		// The three translucent quads in one call, back to front by construction.
		pass.SetPipeline(mBlendPipeline);
		pass.DrawIndexed(18, 1, 6, 0, 0);
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
		if (mBlendPipeline != null) mDevice.DestroyRenderPipeline(ref mBlendPipeline);
		if (mOpaquePipeline != null) mDevice.DestroyRenderPipeline(ref mOpaquePipeline);
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
		let app = scope BlendingSample();
		return app.Run(args);
	}
}
