namespace Sample019_BatchUpload;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates batched GPU uploads using TransferBatch with async fence signaling.
/// Uploads a vertex buffer, index buffer, and a procedural texture in a single
/// batched transfer with SubmitAsync, then renders a textured quad once the
/// upload fence signals completion.
class BatchUploadSample : SampleApp
{
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

		cbuffer Transform : register(b0, space0)
		{
		    float Time;
		    float Pad0;
		    float Pad1;
		    float Pad2;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    // Gentle rotation
		    float c = cos(Time * 0.5);
		    float s = sin(Time * 0.5);
		    float3 p = input.Position;
		    float x = p.x * c - p.y * s;
		    float y = p.x * s + p.y * c;
		    output.Position = float4(x, y, p.z, 1.0);
		    output.TexCoord = input.TexCoord;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return gTexture.Sample(gSampler, input.TexCoord);
		}
		""";

	const uint32 cTexSize = 128;

	private ShaderCompiler mShaderCompiler;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;

	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private ITexture mTexture;
	private ITextureView mTextureView;
	private ISampler mSampler;

	private IBuffer mTransformBuffer;
	private void* mTransformMapped;

	private IBindGroupLayout mBGL;
	private IBindGroup mBG;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	// Upload tracking
	private IFence mUploadFence;
	private uint64 mUploadFenceValue;
	private bool mUploadComplete;
	private float mUploadStartTime;

	public this()  { }

	protected override StringView Title => "Sample019 — Batch Upload (Async Transfer)";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "BatchVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "BatchPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Vertex buffer: 4 vertices × (pos3 + uv2) × 4 = 80 bytes
		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = 80, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "BatchVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;

		// Index buffer: 6 uint16 = 12 bytes
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = 12, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "BatchIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		// Texture
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .RGBA8Unorm,
			Width = cTexSize, Height = cTexSize, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .Sampled | .CopyDst, Label = "BatchTex"
		});
		if (texR case .Err) return .Err;
		mTexture = texR.Value;

		let tvR = mDevice.CreateTextureView(mTexture, TextureViewDesc() { Format = .RGBA8Unorm, Dimension = .Texture2D });
		if (tvR case .Err) return .Err;
		mTextureView = tvR.Value;

		let sampR = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Linear, MagFilter = .Linear,
			AddressU = .Repeat, AddressV = .Repeat,
			Label = "BatchSampler"
		});
		if (sampR case .Err) return .Err;
		mSampler = sampR.Value;

		// Transform UBO
		let tbR = mDevice.CreateBuffer(BufferDesc() { Size = 16, Usage = .Uniform, Memory = .CpuToGpu, Label = "BatchTransform" });
		if (tbR case .Err) return .Err;
		mTransformBuffer = tbR.Value;
		mTransformMapped = mTransformBuffer.Map();

		// Bind group layout: UBO + texture + sampler
		let bglEntries = scope BindGroupLayoutEntry[3];
		bglEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
		bglEntries[1] = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		bglEntries[2] = BindGroupLayoutEntry.Sampler(0, .Fragment);

		let bglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(bglEntries), Label = "BatchBGL"
		});
		if (bglR case .Err) return .Err;
		mBGL = bglR.Value;

		let bgEntries = scope BindGroupEntry[3];
		bgEntries[0] = BindGroupEntry.Buffer(mTransformBuffer, 0, 16);
		bgEntries[1] = BindGroupEntry.Texture(mTextureView);
		bgEntries[2] = BindGroupEntry.Sampler(mSampler);

		let bgR = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mBGL, Entries = Span<BindGroupEntry>(bgEntries), Label = "BatchBG"
		});
		if (bgR case .Err) return .Err;
		mBG = bgR.Value;

		// Pipeline layout
		let bgls = scope IBindGroupLayout[1];
		bgls[0] = mBGL;
		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(bgls), Label = "BatchPL"
		});
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		// Render pipeline
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x2, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 20, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "BatchPipeline"
		});
		if (pipR case .Err) return .Err;
		mPipeline = pipR.Value;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		// Upload fence
		let ufR = mDevice.CreateFence(0);
		if (ufR case .Err) return .Err;
		mUploadFence = ufR.Value;

		// === Batch upload: VB + IB + texture in one submission ===
		if (DoBatchUpload() case .Err) return .Err;

		return .Ok;
	}

	private Result<void> DoBatchUpload()
	{
		mUploadStartTime = mTotalTime;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;

		// Vertex data: quad
		float[20] verts = .(
			-0.6f,  0.6f, 0.0f,   0.0f, 0.0f,
			 0.6f,  0.6f, 0.0f,   1.0f, 0.0f,
			 0.6f, -0.6f, 0.0f,   1.0f, 1.0f,
			-0.6f, -0.6f, 0.0f,   0.0f, 1.0f
		);
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], 80));

		// Index data
		uint16[6] indices = .(0, 1, 2, 0, 2, 3);
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], 12));

		// Texture data: procedural mandelbrot-ish pattern
		uint32 texBytes = cTexSize * cTexSize * 4;
		uint8* pixels = new uint8[texBytes]*;
		defer delete pixels;

		for (uint32 y = 0; y < cTexSize; y++)
		{
			for (uint32 x = 0; x < cTexSize; x++)
			{
				float cr = (float)x / (float)cTexSize * 3.0f - 2.0f;
				float ci = (float)y / (float)cTexSize * 2.4f - 1.2f;
				float zr = 0, zi = 0;
				int iter = 0;
				for (iter = 0; iter < 64; iter++)
				{
					float zr2 = zr * zr - zi * zi + cr;
					float zi2 = 2.0f * zr * zi + ci;
					zr = zr2; zi = zi2;
					if (zr * zr + zi * zi > 4.0f) break;
				}

				uint32 off = (y * cTexSize + x) * 4;
				if (iter == 64)
				{
					pixels[off] = 10; pixels[off + 1] = 10; pixels[off + 2] = 30; pixels[off + 3] = 255;
				}
				else
				{
					float t = (float)iter / 64.0f;
					pixels[off]     = (uint8)(t * 200 + 55);
					pixels[off + 1] = (uint8)(t * t * 255);
					pixels[off + 2] = (uint8)(Math.Sqrt(t) * 255);
					pixels[off + 3] = 255;
				}
			}
		}

		transfer.WriteTexture(mTexture, Span<uint8>(pixels, (.)texBytes),
			TextureDataLayout() { BytesPerRow = cTexSize * 4, RowsPerImage = cTexSize },
			Extent3D() { Width = cTexSize, Height = cTexSize, Depth = 1 });

		// Async submit — signals fence when GPU transfer completes
		mUploadFenceValue = 1;
		if (transfer.SubmitAsync(mUploadFence, mUploadFenceValue) case .Err)
		{
			mGraphicsQueue.DestroyTransferBatch(ref transfer);
			return .Err;
		}

		Console.WriteLine("Batch upload submitted asynchronously (VB: 80B, IB: 12B, Tex: {}B)", texBytes);
		mGraphicsQueue.DestroyTransferBatch(ref transfer);
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);

		// Check if async upload has completed
		if (!mUploadComplete)
		{
			if (mUploadFence.CompletedValue >= mUploadFenceValue)
			{
				mUploadComplete = true;
				Console.WriteLine("Batch upload completed! Rendering enabled.");
			}
		}

		if (mSwapChain.AcquireNextImage() case .Err) return;

		// Update transform
		float[4] transform = .(mTotalTime, 0, 0, 0);
		Internal.MemCpy(mTransformMapped, &transform[0], 16);

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		let barriers = scope TextureBarrier[1];
		barriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store,
			ClearValue = ClearColor(0.05f, 0.05f, 0.08f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc() { ColorAttachments = .(ca) });

		if (mUploadComplete)
		{
			rp.SetPipeline(mPipeline);
			rp.SetBindGroup(0, mBG);
			rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
			rp.SetScissor(0, 0, mWidth, mHeight);
			rp.SetVertexBuffer(0, mVertexBuffer, 0);
			rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
			rp.DrawIndexed(6);
		}

		rp.End();

		barriers[0].OldState = .RenderTarget;
		barriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mTransformBuffer != null && mTransformMapped != null) mTransformBuffer.Unmap();

		if (mUploadFence != null) mDevice?.DestroyFence(ref mUploadFence);
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBG != null) mDevice?.DestroyBindGroup(ref mBG);
		if (mBGL != null) mDevice?.DestroyBindGroupLayout(ref mBGL);
		if (mSampler != null) mDevice?.DestroySampler(ref mSampler);
		if (mTextureView != null) mDevice?.DestroyTextureView(ref mTextureView);
		if (mTexture != null) mDevice?.DestroyTexture(ref mTexture);
		if (mTransformBuffer != null) mDevice?.DestroyBuffer(ref mTransformBuffer);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope BatchUploadSample();
		return app.Run();
	}
}
