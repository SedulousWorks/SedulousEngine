namespace Sample002_Textures;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

class TextureSample : SampleApp
{
	// Textured quad HLSL — texture + sampler in bind group 0.
	const String cShaderSource = """
		Texture2D gTexture : register(t0, space0);
		SamplerState gSampler : register(s0, space0);

		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float2 TexCoord : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 TexCoord : TEXCOORD0;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.TexCoord = input.TexCoord;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return gTexture.Sample(gSampler, input.TexCoord);
		}
		""";

	// Quad: 4 vertices (pos xyz + uv), indexed.
	static float[20] sVertexData = .(
		// pos                  uv
		-0.5f,  0.5f, 0.0f,   0.0f, 0.0f, // top-left
		 0.5f,  0.5f, 0.0f,   1.0f, 0.0f, // top-right
		 0.5f, -0.5f, 0.0f,   1.0f, 1.0f, // bottom-right
		-0.5f, -0.5f, 0.0f,   0.0f, 1.0f  // bottom-left
	);

	static uint16[6] sIndexData = .(
		0, 1, 2,
		0, 2, 3
	);

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private ITexture mTexture;
	private ITextureView mTextureView;
	private ISampler mSampler;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mBindGroup;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this()  { }

	protected override StringView Title => "Sample002 — Textured Quad";

	protected override Result<void> OnInit()
	{
		// Shader compiler
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err)
		{
			Console.WriteLine("ERROR: ShaderCompiler.Init failed");
			return .Err;
		}

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;

		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{
			Console.WriteLine("VS compile failed: {}", errors);
			return .Err;
		}

		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{
			Console.WriteLine("PS compile failed: {}", errors);
			return .Err;
		}

		// Shader modules
		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "QuadVS" });
		if (vsResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (VS) failed"); return .Err; }
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "QuadPS" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mPixelShader = psResult.Value;

		// Vertex buffer (4 verts * 5 floats * 4 bytes = 80)
		let vbResult = mDevice.CreateBuffer(BufferDesc() { Size = 80, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "QuadVB" });
		if (vbResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (VB) failed"); return .Err; }
		mVertexBuffer = vbResult.Value;

		// Index buffer (6 uint16 = 12 bytes)
		let ibResult = mDevice.CreateBuffer(BufferDesc() { Size = 12, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "QuadIB" });
		if (ibResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (IB) failed"); return .Err; }
		mIndexBuffer = ibResult.Value;

		// Generate checkerboard texture (64x64, RGBA8)
		let texWidth = 64;
		let texHeight = 64;
		uint8[64 * 64 * 4] texPixels = default;
		for (int y = 0; y < texHeight; y++)
		{
			for (int x = 0; x < texWidth; x++)
			{
				let checker = ((x / 8) + (y / 8)) % 2 == 0;
				let idx = (y * texWidth + x) * 4;
				texPixels[idx + 0] = checker ? 255 : 50;
				texPixels[idx + 1] = checker ? 255 : 50;
				texPixels[idx + 2] = checker ? 255 : 200;
				texPixels[idx + 3] = 255;
			}
		}

		// Create texture
		let texResult = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D,
			Format = .RGBA8Unorm,
			Width = (.)texWidth,
			Height = (.)texHeight,
			ArrayLayerCount = 1,
			MipLevelCount = 1,
			SampleCount = 1,
			Usage = .Sampled | .CopyDst,
			Label = "CheckerTex"
		});
		if (texResult case .Err) { Console.WriteLine("ERROR: CreateTexture failed"); return .Err; }
		mTexture = texResult.Value;

		// Upload vertex, index, and texture data
		let batchResult = mGraphicsQueue.CreateTransferBatch();
		if (batchResult case .Err) { Console.WriteLine("ERROR: CreateTransferBatch failed"); return .Err; }
		var transfer = batchResult.Value;

		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&sVertexData[0], 80));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&sIndexData[0], 12));
		transfer.WriteTexture(mTexture, Span<uint8>(&texPixels[0], texWidth * texHeight * 4),
			TextureDataLayout() { Offset = 0, BytesPerRow = (.)texWidth * 4, RowsPerImage = (.)texHeight },
			Extent3D() { Width = (.)texWidth, Height = (.)texHeight, Depth = 1 });
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Create texture view
		let tvResult = mDevice.CreateTextureView(mTexture, TextureViewDesc()
		{
			Format = .RGBA8Unorm,
			Dimension = .Texture2D,
			BaseMipLevel = 0,
			MipLevelCount = 1,
			BaseArrayLayer = 0,
			ArrayLayerCount = 1
		});
		if (tvResult case .Err) { Console.WriteLine("ERROR: CreateTextureView failed"); return .Err; }
		mTextureView = tvResult.Value;

		// Create sampler
		let samplerResult = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Nearest,
			MagFilter = .Nearest,
			MipmapFilter = .Nearest,
			AddressU = .Repeat,
			AddressV = .Repeat,
			AddressW = .Repeat,
			Label = "LinearSampler"
		});
		if (samplerResult case .Err) { Console.WriteLine("ERROR: CreateSampler failed"); return .Err; }
		mSampler = samplerResult.Value;

		// Bind group layout: texture at binding 0, sampler at binding 1
		let bglEntries = scope BindGroupLayoutEntry[2];
		bglEntries[0] = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		bglEntries[1] = BindGroupLayoutEntry.Sampler(0, .Fragment);

		let bglResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(bglEntries),
			Label = "TextureBGL"
		});
		if (bglResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout failed"); return .Err; }
		mBindGroupLayout = bglResult.Value;

		// Pipeline layout
		let bglSpan = scope IBindGroupLayout[1];
		bglSpan[0] = mBindGroupLayout;
		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(bglSpan),
			Label = "TexturePL"
		});
		if (plResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout failed"); return .Err; }
		mPipelineLayout = plResult.Value;

		// Bind group
		let bgEntries = scope BindGroupEntry[2];
		bgEntries[0] = BindGroupEntry.Texture(mTextureView);
		bgEntries[1] = BindGroupEntry.Sampler(mSampler);

		let bgResult = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mBindGroupLayout,
			Entries = Span<BindGroupEntry>(bgEntries),
			Label = "TextureBG"
		});
		if (bgResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup failed"); return .Err; }
		mBindGroup = bgResult.Value;

		// Render pipeline
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x2, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = 20, // 5 floats
			StepMode = .Vertex,
			Attributes = Span<VertexAttribute>(vertexAttribs)
		};

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format,
			WriteMask = .All
		};

		let pipResult = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "TexturePipeline"
		});
		if (pipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline failed"); return .Err; }
		mPipeline = pipResult.Value;

		// Command pool and frame fence
		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) { Console.WriteLine("ERROR: CreateCommandPool failed"); return .Err; }
		mCommandPool = poolResult.Value;

		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) { Console.WriteLine("ERROR: CreateFence failed"); return .Err; }
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// Barrier: present → render target
		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .RenderTarget
		};
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		// Render pass
		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.2f, 0.2f, 0.25f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments)
		});

		rp.SetPipeline(mPipeline);
		rp.SetBindGroup(0, mBindGroup);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(6);
		rp.End();

		// Barrier: render target → present
		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);

		mSwapChain.Present(mGraphicsQueue);

		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null)
			mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)
			mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null)
			mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null)
			mDevice?.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null)
			mDevice?.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mSampler != null)
			mDevice?.DestroySampler(ref mSampler);
		if (mTextureView != null)
			mDevice?.DestroyTextureView(ref mTextureView);
		if (mTexture != null)
			mDevice?.DestroyTexture(ref mTexture);
		if (mPixelShader != null)
			mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null)
			mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null)
			mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null)
			mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null)
		{
			mShaderCompiler.Destroy();
			delete mShaderCompiler;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope TextureSample();
		return app.Run();
	}
}
