namespace Sample009_Mipmaps;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using GraphicsFramework;

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
		    output.Position = mul(float4(input.Position, 1.0), MVP);
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

	protected override StringView Title => "Sample009 - Mipmaps";

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

		// Receding floor quad (pos + uv) — stretches into the distance to show mip transitions.
		float[20] quadVerts = .(
			-4.0f, 0.0f,   0.0f,   0.0f, 0.0f,
			 4.0f, 0.0f,   0.0f,   8.0f, 0.0f,
			 4.0f, 0.0f, -20.0f,   8.0f, 10.0f,
			-4.0f, 0.0f, -20.0f,   0.0f, 10.0f
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

		// Create checkerboard texture (256x256, 9 mip levels)
		// Only upload base mip, then call GenerateMipmaps to fill the rest.
		uint32 mipCount = 9; // 256 -> 1
		let texR = mDevice.CreateTexture(TextureDesc()
		{
		    Dimension = .Texture2D, Format = .RGBA8Unorm,
		    Width = 256, Height = 256, ArrayLayerCount = 1,
		    MipLevelCount = mipCount, SampleCount = 1,
		    // Need CopySrc for blit source during mipmap generation
		    Usage = .Sampled | .CopyDst | .CopySrc | .RenderTarget,
		    Label = "MipTex"
		});
		if (texR case .Err) return .Err;
		mMipTexture = texR.Value;

		// Generate checkerboard base mip
		uint8[256 * 256 * 4] texPixels = default;
		for (int y = 0; y < 256; y++)
		    for (int x = 0; x < 256; x++)
		    {
		        let checker = ((x / 16) + (y / 16)) % 2 == 0;
		        let idx = (y * 256 + x) * 4;
		        texPixels[idx + 0] = checker ? 255 : 30;
		        texPixels[idx + 1] = checker ? 255 : 30;
		        texPixels[idx + 2] = checker ? 255 : 200;
		        texPixels[idx + 3] = 255;
		    }

		// Upload base mip only
		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;

		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&quadVerts[0], 80));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&quadIdx[0], 12));
		transfer.WriteTexture(mMipTexture, Span<uint8>(&texPixels[0], 256 * 256 * 4),
		    TextureDataLayout() { Offset = 0, BytesPerRow = 256 * 4, RowsPerImage = 256 },
		    Extent3D() { Width = 256, Height = 256, Depth = 1 });
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Generate mipmaps via encoder
		var tmpPool = mDevice.CreateCommandPool(.Graphics).Value;
		var enc = tmpPool.CreateEncoder().Value;
		enc.GenerateMipmaps(mMipTexture);
		// Transition to shader-read
		enc.TransitionTexture(mMipTexture, .CopySrc, .ShaderRead);
		var cb = enc.Finish();
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cb, 1));
		mGraphicsQueue.WaitIdle();
		tmpPool.DestroyEncoder(ref enc);
		mDevice.DestroyCommandPool(ref tmpPool);

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
		encoder.TransitionTexture(mDepthTexture, .Undefined, .DepthStencilWrite);

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

		// Camera looking down the receding floor
		Matrix view = Matrix.CreateLookAt(Vector3(0.0f, 2.0f, 2.0f), Vector3(0.0f, 0.0f, -5.0f), Vector3(0.0f, 1.0f, 0.0f));
		Matrix proj = Matrix.CreatePerspectiveFieldOfView(60.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);
		Matrix mvp = view * proj;
		Internal.MemCpy(mUniformMapped, &mvp, 64);
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
