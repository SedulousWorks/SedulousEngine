namespace Sample009_Mipmaps;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates manual mip level generation with distinct colors per level.
class MipmapSample : SampleApp
{
	const String cShaderSource = """
		Texture2D gTexture : register(t0, space0);
		SamplerState gSampler : register(s0, space0);

		cbuffer UBO : register(b0, space1)
		{
		    row_major float4x4 MVP;
		};

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
		    output.Position = mul(MVP, float4(input.Position, 1.0));
		    output.TexCoord = input.TexCoord;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return gTexture.Sample(gSampler, input.TexCoord);
		}
		""";

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mUniformBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private ITexture mMipTexture;
	private ITextureView mMipTextureView;
	private ISampler mTrilinearSampler;
	private IBindGroupLayout mTexBGL;
	private IBindGroup mTexBG;
	private IBindGroupLayout mUboBGL;
	private IBindGroup mUboBG;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;
	private void* mUniformMapped;

	public this()  { }

	protected override StringView Title => "Sample009 — Mipmaps";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "MipVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "MipPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Large floor quad (pos + uv)
		float[20] quadVerts = .(
			-5.0f, 0.0f, -5.0f,   0.0f, 0.0f,
			 5.0f, 0.0f, -5.0f,   8.0f, 0.0f,
			 5.0f, 0.0f,  5.0f,   8.0f, 8.0f,
			-5.0f, 0.0f,  5.0f,   0.0f, 8.0f
		);
		uint16[6] quadIdx = .(0, 1, 2, 0, 2, 3);

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = 80, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "MipVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = 12, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "MipIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		// Uniform buffer
		let ubR = mDevice.CreateBuffer(BufferDesc() { Size = 256, Usage = .Uniform, Memory = .CpuToGpu, Label = "MipUBO" });
		if (ubR case .Err) return .Err;
		mUniformBuffer = ubR.Value;
		mUniformMapped = mUniformBuffer.Map();

		// Create mipmapped texture (64x64, 7 mip levels, each a different solid color)
		uint32 mipCount = 7; // 64, 32, 16, 8, 4, 2, 1
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .RGBA8Unorm,
			Width = 64, Height = 64, ArrayLayerCount = 1,
			MipLevelCount = mipCount, SampleCount = 1,
			Usage = .Sampled | .CopyDst, Label = "MipTex"
		});
		if (texR case .Err) return .Err;
		mMipTexture = texR.Value;

		// Upload geometry and mip data
		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;

		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&quadVerts[0], 80));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&quadIdx[0], 12));

		// Mip level colors (RGBA): red, green, blue, yellow, magenta, cyan, white
		// Flat array: 7 mips * 4 components
		uint8[28] mipColors = .(
			255, 50, 50, 255,    // Mip 0: Red (64x64)
			50, 255, 50, 255,    // Mip 1: Green (32x32)
			50, 50, 255, 255,    // Mip 2: Blue (16x16)
			255, 255, 50, 255,   // Mip 3: Yellow (8x8)
			255, 50, 255, 255,   // Mip 4: Magenta (4x4)
			50, 255, 255, 255,   // Mip 5: Cyan (2x2)
			255, 255, 255, 255   // Mip 6: White (1x1)
		);

		for (uint32 mip = 0; mip < mipCount; mip++)
		{
			uint32 mipW = 64 >> mip;
			uint32 mipH = 64 >> mip;
			uint32 pixelCount = mipW * mipH;
			uint32 dataSize = pixelCount * 4;
			uint32 ci = mip * 4;

			uint8[] mipData = scope uint8[dataSize];
			for (uint32 p = 0; p < pixelCount; p++)
			{
				mipData[p * 4 + 0] = mipColors[ci + 0];
				mipData[p * 4 + 1] = mipColors[ci + 1];
				mipData[p * 4 + 2] = mipColors[ci + 2];
				mipData[p * 4 + 3] = mipColors[ci + 3];
			}

			transfer.WriteTexture(mMipTexture, Span<uint8>(mipData.CArray(), (int)dataSize),
				TextureDataLayout() { Offset = 0, BytesPerRow = mipW * 4, RowsPerImage = mipH },
				Extent3D() { Width = mipW, Height = mipH, Depth = 1 },
				mip);
		}

		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Texture view
		let tvR = mDevice.CreateTextureView(mMipTexture, TextureViewDesc()
		{
			Format = .RGBA8Unorm, Dimension = .Texture2D,
			BaseMipLevel = 0, MipLevelCount = mipCount
		});
		if (tvR case .Err) return .Err;
		mMipTextureView = tvR.Value;

		// Trilinear sampler
		let sampR = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Linear, MagFilter = .Linear, MipmapFilter = .Linear,
			AddressU = .Repeat, AddressV = .Repeat, AddressW = .Repeat,
			MaxAnisotropy = 1, Label = "TrilinearSampler"
		});
		if (sampR case .Err) return .Err;
		mTrilinearSampler = sampR.Value;

		// Bind group layouts
		let texEntries = scope BindGroupLayoutEntry[2];
		texEntries[0] = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		texEntries[1] = BindGroupLayoutEntry.Sampler(0, .Fragment);
		let texBglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(texEntries), Label = "TexBGL" });
		if (texBglR case .Err) return .Err;
		mTexBGL = texBglR.Value;

		let uboEntries = scope BindGroupLayoutEntry[1];
		uboEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
		let uboBglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(uboEntries), Label = "UboBGL" });
		if (uboBglR case .Err) return .Err;
		mUboBGL = uboBglR.Value;

		// Pipeline layout
		let bgls = scope IBindGroupLayout[2];
		bgls[0] = mTexBGL;
		bgls[1] = mUboBGL;
		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { BindGroupLayouts = Span<IBindGroupLayout>(bgls), Label = "MipPL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		// Bind groups
		let texBgEntries = scope BindGroupEntry[2];
		texBgEntries[0] = BindGroupEntry.Texture(mMipTextureView);
		texBgEntries[1] = BindGroupEntry.Sampler(mTrilinearSampler);
		let texBgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mTexBGL, Entries = Span<BindGroupEntry>(texBgEntries), Label = "TexBG" });
		if (texBgR case .Err) return .Err;
		mTexBG = texBgR.Value;

		let uboBgEntries = scope BindGroupEntry[1];
		uboBgEntries[0] = BindGroupEntry.Buffer(mUniformBuffer, 0, 64);
		let uboBgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mUboBGL, Entries = Span<BindGroupEntry>(uboBgEntries), Label = "UboBG" });
		if (uboBgR case .Err) return .Err;
		mUboBG = uboBgR.Value;

		if (CreateDepthBuffer() case .Err) return .Err;

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
			DepthStencil = DepthStencilState() { Format = .Depth24PlusStencil8, DepthWriteEnabled = true, DepthCompare = .Less },
			Label = "MipPipeline"
		});
		if (pipR case .Err) return .Err;
		mPipeline = pipR.Value;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateDepthBuffer()
	{
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .Depth24PlusStencil8,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1, Usage = .DepthStencil, Label = "DepthTex"
		});
		if (texR case .Err) return .Err;
		mDepthTexture = texR.Value;
		let viewR = mDevice.CreateTextureView(mDepthTexture, TextureViewDesc() { Format = .Depth24PlusStencil8, Dimension = .Texture2D });
		if (viewR case .Err) return .Err;
		mDepthView = viewR.Value;
		return .Ok;
	}

	protected override void OnResize(uint32 w, uint32 h) { CreateDepthBuffer(); }

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		UpdateMVP();

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.4f, 0.6f, 0.8f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca),
			DepthStencilAttachment = DepthStencilAttachment() { View = mDepthView, DepthLoadOp = .Clear, DepthStoreOp = .Store, DepthClearValue = 1.0f }
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetBindGroup(0, mTexBG);
		rp.SetBindGroup(1, mUboBG);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(6);
		rp.End();

		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	private void UpdateMVP()
	{
		float aspect = (float)mWidth / (float)mHeight;

		// Camera looking down at the floor from an angle
		float camY = 3.0f;
		float camZ = -1.0f;
		float[16] view = default;
		MakeLookAt(ref view, 0.0f, camY, camZ, 0.0f, 0.0f, 2.0f);

		float[16] proj = default;
		MakePerspective(ref proj, 60.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);

		float[16] mvp = default;
		MatMul4x4(ref mvp, ref proj, ref view);
		Internal.MemCpy(mUniformMapped, &mvp[0], 64);
	}

	private static void MakeLookAt(ref float[16] m, float eyeX, float eyeY, float eyeZ, float tx, float ty, float tz)
	{
		float fx = tx - eyeX, fy = ty - eyeY, fz = tz - eyeZ;
		float fLen = Math.Sqrt(fx*fx + fy*fy + fz*fz);
		fx /= fLen; fy /= fLen; fz /= fLen;
		float rx = fz, ry = 0.0f, rz = -fx;
		float rLen = Math.Sqrt(rx*rx + rz*rz);
		if (rLen > 0.0001f) { rx /= rLen; rz /= rLen; }
		float ux = fy*rz - fz*ry, uy = fz*rx - fx*rz, uz = fx*ry - fy*rx;
		m[0]=rx; m[1]=ry; m[2]=rz; m[3]=-(rx*eyeX+ry*eyeY+rz*eyeZ);
		m[4]=ux; m[5]=uy; m[6]=uz; m[7]=-(ux*eyeX+uy*eyeY+uz*eyeZ);
		m[8]=fx; m[9]=fy; m[10]=fz; m[11]=-(fx*eyeX+fy*eyeY+fz*eyeZ);
		m[12]=0; m[13]=0; m[14]=0; m[15]=1;
	}

	private static void MakePerspective(ref float[16] m, float fovY, float aspect, float nearZ, float farZ)
	{
		float h = 1.0f / Math.Tan(fovY * 0.5f), w = h / aspect, range = farZ / (farZ - nearZ);
		m[0]=w; m[1]=0; m[2]=0; m[3]=0;
		m[4]=0; m[5]=h; m[6]=0; m[7]=0;
		m[8]=0; m[9]=0; m[10]=range; m[11]=-nearZ*range;
		m[12]=0; m[13]=0; m[14]=1; m[15]=0;
	}

	private static void MatMul4x4(ref float[16] r, ref float[16] a, ref float[16] b)
	{
		for (int row < 4) for (int col < 4)
		{
			float s = 0;
			for (int k < 4) s += a[row*4+k] * b[k*4+col];
			r[row*4+col] = s;
		}
	}

	protected override void OnShutdown()
	{
		if (mUniformBuffer != null && mUniformMapped != null) mUniformBuffer.Unmap();
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mDepthView != null) mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice?.DestroyTexture(ref mDepthTexture);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mUboBG != null) mDevice?.DestroyBindGroup(ref mUboBG);
		if (mTexBG != null) mDevice?.DestroyBindGroup(ref mTexBG);
		if (mUboBGL != null) mDevice?.DestroyBindGroupLayout(ref mUboBGL);
		if (mTexBGL != null) mDevice?.DestroyBindGroupLayout(ref mTexBGL);
		if (mTrilinearSampler != null) mDevice?.DestroySampler(ref mTrilinearSampler);
		if (mMipTextureView != null) mDevice?.DestroyTextureView(ref mMipTextureView);
		if (mMipTexture != null) mDevice?.DestroyTexture(ref mMipTexture);
		if (mUniformBuffer != null) mDevice?.DestroyBuffer(ref mUniformBuffer);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MipmapSample();
		return app.Run();
	}
}
