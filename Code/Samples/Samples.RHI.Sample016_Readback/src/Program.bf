using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample016_Readback;

/// Rendering to a small offscreen texture, copying it back, and printing the pixels.
///
/// The readback is what makes rendering VERIFIABLE from the CPU: a screenshot, a test that
/// checks what was drawn, or a tool that samples the frame all work this way.
class ReadbackSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position,1); o.Color = i.Color; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return i.Color; }
		""";

	/// Small enough that every pixel can be counted, which is the point.
	private const uint32 cTextureSize = 16;
	/// Rows in a copy destination are aligned, to 256 bytes for DX12 compatibility, so the
	/// stride is NOT simply the width in bytes.
	private const uint32 cRowAlignment = 256;
	private const float cReportInterval = 3.0f;

	/// A triangle covering the upper left half of clip space, so the readback has a
	/// distinct filled and empty region rather than a uniform image.
	private static float[21] sVertices = .(
		 0.0f,  1.0f, 0.0f,   1.0f, 0.0f, 0.0f, 1.0f,
		 1.0f, -1.0f, 0.0f,   0.0f, 1.0f, 0.0f, 1.0f,
		-1.0f, -1.0f, 0.0f,   0.0f, 0.0f, 1.0f, 1.0f);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mOffscreenPipeline = null;
	private IRenderPipeline mSwapChainPipeline = null;
	private ITexture mOffscreenTexture = null;
	private ITextureView mOffscreenView = null;
	private IBuffer mReadbackBuffer = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private bool mHasReadback = false;
	private float mLastReportTime = 0.0f;

	protected override StringView Title => "Sample016 - GPU Readback";

	private static uint32 BytesPerRow
		=> ((cTextureSize * 4 + cRowAlignment - 1) / cRowAlignment) * cRowAlignment;

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

		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sVertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertices[0], sizeof(float) * sVertices.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		if (CreateOffscreenTarget() case .Err)
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

	private Result<void> CreateOffscreenTarget()
	{
		var desc = TextureDesc();
		desc.Format = .RGBA8Unorm;
		desc.Width = cTextureSize;
		desc.Height = cTextureSize;
		desc.MipLevelCount = 1;
		desc.Usage = .RenderTarget | .CopySrc;
		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return .Err;
		mOffscreenTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(mOffscreenTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mOffscreenView = view;

		// Sized by the ALIGNED stride, which is larger than the image itself.
		var readbackDesc = BufferDesc();
		readbackDesc.Size = (uint64)BytesPerRow * cTextureSize;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		if (!(mDevice.CreateBuffer(readbackDesc) case .Ok(let readback)))
			return .Err;
		mReadbackBuffer = readback;
		return .Ok;
	}

	/// Two pipelines from one pair of shaders.
	///
	/// The offscreen target and the swap chain have different FORMATS, and a pipeline is
	/// built against a specific one, so the same shaders need two.
	private Result<void> CreatePipelines()
	{
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

		var offscreenTargets = ColorTargetState[1](.() { Format = .RGBA8Unorm });
		var offscreenFragment = FragmentState();
		offscreenFragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		offscreenFragment.Targets = offscreenTargets;
		desc.Fragment = offscreenFragment;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let offscreenPipeline)))
			return .Err;
		mOffscreenPipeline = offscreenPipeline;

		var swapChainTargets = ColorTargetState[1](.() { Format = mSwapChain.Format });
		var swapChainFragment = FragmentState();
		swapChainFragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		swapChainFragment.Targets = swapChainTargets;
		desc.Fragment = swapChainFragment;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let swapChainPipeline)))
			return .Err;
		mSwapChainPipeline = swapChainPipeline;
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);

		// Read AFTER the wait: the copy has to have completed for the buffer to hold
		// anything.
		if (mHasReadback && (mTotalTime - mLastReportTime >= cReportInterval))
		{
			ReadbackPixels();
			mLastReportTime = mTotalTime;
		}

		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		RecordOffscreenPass(encoder);
		RecordSwapChainPass(encoder);

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
		mHasReadback = true;
	}

	private void RecordOffscreenPass(ICommandEncoder encoder)
	{
		encoder.TransitionTexture(mOffscreenTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mOffscreenView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		// Cleared to BLACK, so counting non-black pixels counts what the triangle covered.
		colorAttachment.ClearValue = .(0.0f, 0.0f, 0.0f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mOffscreenPipeline);
		pass.SetViewport(0, 0, (float)cTextureSize, (float)cTextureSize, 0, 1);
		pass.SetScissor(0, 0, cTextureSize, cTextureSize);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.Draw(3);
		pass.End();

		encoder.TransitionTexture(mOffscreenTexture, .RenderTarget, .CopySrc);

		var region = BufferTextureCopyRegion();
		region.BufferOffset = 0;
		region.BytesPerRow = BytesPerRow;
		region.RowsPerImage = cTextureSize;
		region.TextureExtent = .(cTextureSize, cTextureSize, 1);
		encoder.CopyTextureToBuffer(mOffscreenTexture, mReadbackBuffer, region);
	}

	/// The same triangle again, at window size, so there is something on screen while the
	/// readback runs.
	private void RecordSwapChainPass(ICommandEncoder encoder)
	{
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mSwapChainPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.Draw(3);
		pass.End();
	}

	/// Prints the corners, the centre, and how much of the image the triangle covered.
	private void ReadbackPixels()
	{
		let mapped = (uint8*)mReadbackBuffer.Map();
		if (mapped == null)
			return;
		defer mReadbackBuffer.Unmap();

		let stride = BytesPerRow;
		Console.WriteLine(scope $"=== Readback: {cTextureSize}x{cTextureSize} RGBA8 texture ===");

		void PrintPixel(uint32 x, uint32 y, StringView label)
		{
			// Indexed by the ALIGNED stride, not the width: a reader using the width
			// would drift a little further into the wrong row with every line.
			let at = y * stride + x * 4;
			Console.WriteLine(scope $"  {label} ({x},{y}): R={mapped[at]} G={mapped[at + 1]} B={mapped[at + 2]} A={mapped[at + 3]}");
		}

		PrintPixel(0, 0, "Top-left");
		PrintPixel(cTextureSize - 1, 0, "Top-right");
		PrintPixel(cTextureSize / 2, cTextureSize / 2, "Center");
		PrintPixel(0, cTextureSize - 1, "Bottom-left");
		PrintPixel(cTextureSize - 1, cTextureSize - 1, "Bottom-right");

		int nonBlack = 0;
		for (uint32 y < cTextureSize)
		{
			for (uint32 x < cTextureSize)
			{
				let at = y * stride + x * 4;
				if ((mapped[at] > 0) || (mapped[at + 1] > 0) || (mapped[at + 2] > 0))
					nonBlack++;
			}
		}
		let total = cTextureSize * cTextureSize;
		let percent = 100.0f * (float)nonBlack / (float)total;
		Console.WriteLine(scope $"Non-black pixels: {nonBlack} / {total} ({percent:0}%)");
	}

	protected override void OnShutdown()
	{
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mReadbackBuffer != null) mDevice.DestroyBuffer(ref mReadbackBuffer);
		if (mOffscreenView != null) mDevice.DestroyTextureView(ref mOffscreenView);
		if (mOffscreenTexture != null) mDevice.DestroyTexture(ref mOffscreenTexture);
		if (mSwapChainPipeline != null) mDevice.DestroyRenderPipeline(ref mSwapChainPipeline);
		if (mOffscreenPipeline != null) mDevice.DestroyRenderPipeline(ref mOffscreenPipeline);
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
		let app = scope ReadbackSample();
		return app.Run(args);
	}
}
