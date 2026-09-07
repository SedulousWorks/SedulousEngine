using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample014_Blit;

/// A spinning triangle rendered small and blitted up to fill the window.
///
/// The blit is a SCALED copy, not a draw: no pipeline, no shader, no pass. A small offscreen
/// target enlarged to the whole window makes the filtering obvious.
class BlitSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position,1); o.Color = i.Color; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return i.Color; }
		""";

	/// Deliberately small, so the blit is scaling UP by a large factor.
	private const uint32 cOffscreenSize = 128;
	/// Three vertices of three position floats and four colour floats.
	private const uint64 cVertexBufferSize = 84;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ITexture mOffscreenTexture = null;
	private ITextureView mOffscreenView = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample014 - Blit (Scaled Copy)";

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

		// Rewritten every frame with the rotated triangle, so it is host visible.
		var vertexDesc = BufferDesc();
		vertexDesc.Size = cVertexBufferSize;
		vertexDesc.Usage = .Vertex;
		vertexDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		if (CreateOffscreenTarget() case .Err)
			return .Err;
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

	private Result<void> CreateOffscreenTarget()
	{
		// The SWAP CHAIN's format, because a blit between differing formats is not
		// guaranteed and this one is a straight scale.
		var desc = TextureDesc();
		desc.Format = mSwapChain.Format;
		desc.Width = cOffscreenSize;
		desc.Height = cOffscreenSize;
		desc.MipLevelCount = 1;
		desc.Usage = .RenderTarget | .CopySrc | .Sampled;
		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return .Err;
		mOffscreenTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = mSwapChain.Format;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(mOffscreenTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mOffscreenView = view;
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

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;
		return .Ok;
	}

	/// Rotates the triangle on the CPU and writes it into the mapped buffer.
	///
	/// There is no uniform buffer here, so the rotation is baked into the positions: the
	/// sample is about the blit, not about transforms.
	private void UpdateTriangle()
	{
		let angle = mTotalTime * 2.0f;
		let cosine = Math.Cos(angle);
		let sine = Math.Sin(angle);

		float[6] basePositions = .(0.0f, 0.5f, 0.433f, -0.25f, -0.433f, -0.25f);
		float[12] colors = .(
			1.0f, 0.2f, 0.2f, 1.0f,
			0.2f, 1.0f, 0.2f, 1.0f,
			0.2f, 0.4f, 1.0f, 1.0f);

		float[21] vertices = default;
		for (int i < 3)
		{
			let x = basePositions[i * 2];
			let y = basePositions[i * 2 + 1];
			vertices[i * 7 + 0] = x * cosine - y * sine;
			vertices[i * 7 + 1] = x * sine + y * cosine;
			vertices[i * 7 + 2] = 0.0f;
			vertices[i * 7 + 3] = colors[i * 4 + 0];
			vertices[i * 7 + 4] = colors[i * 4 + 1];
			vertices[i * 7 + 5] = colors[i * 4 + 2];
			vertices[i * 7 + 6] = colors[i * 4 + 3];
		}

		let mapped = mVertexBuffer.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, &vertices[0], (int)cVertexBufferSize);
			mVertexBuffer.Unmap();
		}
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		UpdateTriangle();

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		// Drawn at the OFFSCREEN size, not the window's: the viewport is what decides how
		// much of the small target the triangle fills.
		encoder.TransitionTexture(mOffscreenTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mOffscreenView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.15f, 0.1f, 0.2f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)cOffscreenSize, (float)cOffscreenSize, 0, 1);
		pass.SetScissor(0, 0, cOffscreenSize, cOffscreenSize);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.Draw(3);
		pass.End();

		// The blit is a COPY, so both sides move to copy states rather than to anything a
		// pass would use. The back buffer is never a render target this frame.
		encoder.TransitionTexture(mOffscreenTexture, .RenderTarget, .CopySrc);
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .CopyDst);
		encoder.Blit(mOffscreenTexture, mSwapChain.CurrentTexture);
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
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mOffscreenView != null) mDevice.DestroyTextureView(ref mOffscreenView);
		if (mOffscreenTexture != null) mDevice.DestroyTexture(ref mOffscreenTexture);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
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
		let app = scope BlitSample();
		return app.Run(args);
	}
}
