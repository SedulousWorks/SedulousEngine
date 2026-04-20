namespace Sample016_Readback;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates GPU -> CPU readback.
/// Renders a colored triangle to a small offscreen texture, copies it to a
/// readback buffer, then reads pixel values on the CPU and prints them.
class ReadbackSample : SampleApp
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

	const uint32 TexSize = 16;

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private IRenderPipeline mSwapchainPipeline;
	private ITexture mOffscreenTex;
	private ITextureView mOffscreenView;
	private IBuffer mReadbackBuffer;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;
	private bool mHasReadback;
	private float mLastReportTime;

	public this() : base(.DX12)  { }

	protected override StringView Title => "Sample016 - GPU Readback";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "ReadVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "ReadPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Full-screen triangle covering the entire render target
		float[21] verts = .(
			 0.0f,  1.0f, 0.0f,   1.0f, 0.0f, 0.0f, 1.0f,
			 1.0f, -1.0f, 0.0f,   0.0f, 1.0f, 0.0f, 1.0f,
			-1.0f, -1.0f, 0.0f,   0.0f, 0.0f, 1.0f, 1.0f
		);

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = 84, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "ReadVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], 84));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "ReadPL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		// Small offscreen RGBA8 texture
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .RGBA8Unorm,
			Width = TexSize, Height = TexSize, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .RenderTarget | .CopySrc, Label = "ReadbackRT"
		});
		if (texR case .Err) return .Err;
		mOffscreenTex = texR.Value;

		let tvR = mDevice.CreateTextureView(mOffscreenTex, TextureViewDesc() { Format = .RGBA8Unorm, Dimension = .Texture2D });
		if (tvR case .Err) return .Err;
		mOffscreenView = tvR.Value;

		// Readback buffer: TexSize * TexSize * 4 bytes (RGBA8), with row alignment
		// DX12 requires 256-byte row pitch alignment
		uint32 bytesPerRow = ((TexSize * 4 + 255) / 256) * 256;
		uint32 bufSize = bytesPerRow * TexSize;
		let rbR = mDevice.CreateBuffer(BufferDesc() { Size = bufSize, Usage = .CopyDst, Memory = .GpuToCpu, Label = "ReadbackBuf" });
		if (rbR case .Err) return .Err;
		mReadbackBuffer = rbR.Value;

		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 28, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = .RGBA8Unorm, WriteMask = .All };

		let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "ReadPipeline"
		});
		if (pipR case .Err) return .Err;
		mPipeline = pipR.Value;

		// Second pipeline for rendering to the swapchain (different format)
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };
		let swpPipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "SwapchainPipeline"
		});
		if (swpPipR case .Err) return .Err;
		mSwapchainPipeline = swpPipR.Value;

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

		// Read back previous frame's data
		if (mHasReadback && (mTotalTime - mLastReportTime >= 3.0f))
		{
			ReadbackPixels();
			mLastReportTime = mTotalTime;
		}

		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		// Render triangle to offscreen texture
		{
			let barriers = scope TextureBarrier[1];
			barriers[0] = TextureBarrier() { Texture = mOffscreenTex, OldState = .CopySrc, NewState = .RenderTarget };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });

			let ca = scope ColorAttachment[1];
			ca[0] = ColorAttachment() { View = mOffscreenView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.0f, 0.0f, 0.0f, 1.0f) };

			let rp = encoder.BeginRenderPass(RenderPassDesc()
			{
				ColorAttachments = .(ca)
			});

			rp.SetPipeline(mPipeline);
			rp.SetViewport(0, 0, (float)TexSize, (float)TexSize, 0.0f, 1.0f);
			rp.SetScissor(0, 0, TexSize, TexSize);
			rp.SetVertexBuffer(0, mVertexBuffer, 0);
			rp.Draw(3);
			rp.End();

			barriers[0].OldState = .RenderTarget;
			barriers[0].NewState = .CopySrc;
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });
		}

		// Copy texture to readback buffer
		uint32 bytesPerRow = ((TexSize * 4 + 255) / 256) * 256;
		encoder.CopyTextureToBuffer(mOffscreenTex, mReadbackBuffer,
			BufferTextureCopyRegion()
			{
				BufferOffset = 0,
				BytesPerRow = bytesPerRow,
				RowsPerImage = TexSize,
				TextureExtent = Extent3D() { Width = TexSize, Height = TexSize, Depth = 1 }
			});

		// Also render to swapchain so we see something
		{
			let barriers = scope TextureBarrier[1];
			barriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });

			let ca = scope ColorAttachment[1];
			ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.08f, 0.08f, 0.12f, 1.0f) };

			let rp = encoder.BeginRenderPass(RenderPassDesc()
			{
				ColorAttachments = .(ca)
			});

			rp.SetPipeline(mSwapchainPipeline);
			rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
			rp.SetScissor(0, 0, mWidth, mHeight);
			rp.SetVertexBuffer(0, mVertexBuffer, 0);
			rp.Draw(3);
			rp.End();

			barriers[0].OldState = .RenderTarget;
			barriers[0].NewState = .Present;
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });
		}

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);

		mHasReadback = true;
	}

	private void ReadbackPixels()
	{
		let mapped = mReadbackBuffer.Map();
		if (mapped == null) return;

		uint32 bytesPerRow = ((TexSize * 4 + 255) / 256) * 256;
		uint8* data = (uint8*)mapped;

		Console.WriteLine("=== Readback: {}x{} RGBA8 texture ===", TexSize, TexSize);

		// Print center pixel and corners
		PrintPixel(data, bytesPerRow, 0, 0, "Top-left");
		PrintPixel(data, bytesPerRow, TexSize - 1, 0, "Top-right");
		PrintPixel(data, bytesPerRow, TexSize / 2, TexSize / 2, "Center");
		PrintPixel(data, bytesPerRow, 0, TexSize - 1, "Bottom-left");
		PrintPixel(data, bytesPerRow, TexSize - 1, TexSize - 1, "Bottom-right");

		// Count non-black pixels (part of the triangle)
		int nonBlack = 0;
		for (uint32 y = 0; y < TexSize; y++)
		{
			for (uint32 x = 0; x < TexSize; x++)
			{
				uint32 offset = y * bytesPerRow + x * 4;
				if (data[offset] > 0 || data[offset + 1] > 0 || data[offset + 2] > 0)
					nonBlack++;
			}
		}
		Console.WriteLine("Non-black pixels: {} / {} ({:.0}%)", nonBlack, TexSize * TexSize,
			100.0f * (float)nonBlack / (float)(TexSize * TexSize));

		mReadbackBuffer.Unmap();
	}

	private void PrintPixel(uint8* data, uint32 bytesPerRow, uint32 x, uint32 y, StringView label)
	{
		uint32 offset = y * bytesPerRow + x * 4;
		Console.WriteLine("  {} ({},{}): R={} G={} B={} A={}",
			label, x, y, data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mSwapchainPipeline != null) mDevice?.DestroyRenderPipeline(ref mSwapchainPipeline);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mReadbackBuffer != null) mDevice?.DestroyBuffer(ref mReadbackBuffer);
		if (mOffscreenView != null) mDevice?.DestroyTextureView(ref mOffscreenView);
		if (mOffscreenTex != null) mDevice?.DestroyTexture(ref mOffscreenTex);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope ReadbackSample();
		return app.Run();
	}
}
