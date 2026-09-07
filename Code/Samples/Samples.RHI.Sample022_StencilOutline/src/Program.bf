using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample022_StencilOutline;

/// What the vertex shader is handed each draw.
[CRepr]
struct PushData
{
	public float Scale;
	public float AspectRatio;
	public float Time;
	public float Padding;
}

/// An outlined hexagon, drawn with the stencil buffer.
///
/// The classic two pass trick: draw the shape and stamp the stencil where it covered, then
/// draw it slightly LARGER and let it through only where the stencil was NOT stamped. What
/// remains is a ring exactly the width of the difference.
///
/// The same geometry and the same shaders both times; only the pipeline's stencil state and
/// one push constant differ.
class StencilOutlineSample : SampleApp
{
	private const String cShaderSource = """
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

	/// A hexagon as a fan: the centre, then six corners. Position then RGBA.
	private static float[49] sVertices = .(
		 0.00f,  0.00f, 0.5f,   0.9f, 0.9f, 0.9f, 1.0f,
		 0.60f,  0.00f, 0.5f,   0.3f, 0.6f, 1.0f, 1.0f,
		 0.30f,  0.52f, 0.5f,   0.3f, 1.0f, 0.6f, 1.0f,
		-0.30f,  0.52f, 0.5f,   1.0f, 1.0f, 0.3f, 1.0f,
		-0.60f,  0.00f, 0.5f,   1.0f, 0.6f, 0.3f, 1.0f,
		-0.30f, -0.52f, 0.5f,   1.0f, 0.3f, 0.6f, 1.0f,
		 0.30f, -0.52f, 0.5f,   0.6f, 0.3f, 1.0f, 1.0f);

	private static uint16[18] sIndices = .(
		0, 1, 2,  0, 2, 3,  0, 3, 4,
		0, 4, 5,  0, 5, 6,  0, 6, 1);

	/// The value stamped into the stencil by the first pass and tested against by the
	/// second.
	private const uint32 cStencilReference = 1;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mStencilWritePipeline = null;
	private IRenderPipeline mStencilTestPipeline = null;
	private ITexture mDepthStencilTexture = null;
	private ITextureView mDepthStencilView = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample022 - Stencil Outline";

	protected override void OnResize(uint32 width, uint32 height)
	{
		RecreateDepthStencil(width, height);
	}

	private void RecreateDepthStencil(uint32 width, uint32 height)
	{
		if (mDepthStencilView != null)
			mDevice.DestroyTextureView(ref mDepthStencilView);
		if (mDepthStencilTexture != null)
			mDevice.DestroyTexture(ref mDepthStencilTexture);

		// A format with a STENCIL component, not just depth: the whole sample depends on
		// the eight stencil bits.
		let textureDesc = TextureDesc.DepthBuffer(.Depth24PlusStencil8, width, height, 1,
			"StencilDSTex");
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return;
		mDepthStencilTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .Depth24PlusStencil8;
		viewDesc.Dimension = .Texture2D;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (mDevice.CreateTextureView(mDepthStencilTexture, viewDesc) case .Ok(let view))
			mDepthStencilView = view;
	}

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Vertex,
			"VSMain", "StencilVS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "StencilPS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateBuffers() case .Err)
			return .Err;

		var pushConstants = PushConstantRange[1](
			.() { Stages = .Vertex, Offset = 0, Size = (uint32)sizeof(PushData) });
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.PushConstantRanges = pushConstants;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		RecreateDepthStencil(mWidth, mHeight);

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
		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x4, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 28;
		vertexLayout.Attributes = attributes;
		var buffers = VertexBufferLayout[1](vertexLayout);

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;
		var fragment = FragmentState();
		fragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;

		// Pass one: draw everywhere, and REPLACE the stencil with the reference wherever a
		// fragment lands. Depth always passes, since what is being recorded is coverage,
		// not visibility.
		var write = DepthStencilState();
		write.Format = .Depth24PlusStencil8;
		write.DepthWriteEnabled = true;
		write.DepthCompare = .Always;
		write.StencilEnabled = true;
		write.StencilReadMask = 0xFF;
		write.StencilWriteMask = 0xFF;
		write.StencilFront = .() { Compare = .Always, FailOp = .Keep, DepthFailOp = .Keep,
			PassOp = .Replace };
		write.StencilBack = write.StencilFront;
		desc.DepthStencil = write;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let writePipeline)))
			return .Err;
		mStencilWritePipeline = writePipeline;

		// Pass two: draw only where the stencil is NOT the reference, which is everywhere
		// the first pass did not cover. The write mask is zero, so this pass records
		// nothing and a third pass would see the same stencil.
		var test = DepthStencilState();
		test.Format = .Depth24PlusStencil8;
		test.DepthWriteEnabled = false;
		test.DepthCompare = .Always;
		test.StencilEnabled = true;
		test.StencilReadMask = 0xFF;
		test.StencilWriteMask = 0x00;
		test.StencilFront = .() { Compare = .NotEqual, FailOp = .Keep, DepthFailOp = .Keep,
			PassOp = .Keep };
		test.StencilBack = test.StencilFront;
		desc.DepthStencil = test;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let testPipeline)))
			return .Err;
		mStencilTestPipeline = testPipeline;
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
		encoder.TransitionTexture(mDepthStencilTexture, .Undefined, .DepthStencilWrite);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.08f, 0.08f, 0.12f, 1.0f);

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthStencilView;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = 1.0f;
		depthAttachment.StencilLoadOp = .Clear;
		depthAttachment.StencilStoreOp = .Store;
		// Cleared to ZERO, which is what makes "not equal to one" mean "not covered".
		depthAttachment.StencilClearValue = 0;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;

		let aspect = (float)mWidth / (float)mHeight;
		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// One: the hexagon at its own size, stamping the stencil.
		pass.SetPipeline(mStencilWritePipeline);
		pass.SetStencilReference(cStencilReference);
		var inner = PushData() { Scale = 1.0f, AspectRatio = aspect, Time = mTotalTime };
		pass.SetPushConstants(.Vertex, 0, (uint32)sizeof(PushData), &inner);
		pass.DrawIndexed(18);

		// Two: the same hexagon FIFTEEN PERCENT larger, kept only outside the stamp. The
		// reference is the same, since it is what the test compares against.
		pass.SetPipeline(mStencilTestPipeline);
		pass.SetStencilReference(cStencilReference);
		var outer = PushData() { Scale = 1.15f, AspectRatio = aspect, Time = mTotalTime };
		pass.SetPushConstants(.Vertex, 0, (uint32)sizeof(PushData), &outer);
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
		if (mStencilTestPipeline != null) mDevice.DestroyRenderPipeline(ref mStencilTestPipeline);
		if (mStencilWritePipeline != null) mDevice.DestroyRenderPipeline(ref mStencilWritePipeline);
		if (mDepthStencilView != null) mDevice.DestroyTextureView(ref mDepthStencilView);
		if (mDepthStencilTexture != null) mDevice.DestroyTexture(ref mDepthStencilTexture);
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
		let app = scope StencilOutlineSample();
		return app.Run(args);
	}
}
