namespace Sample013_BorderSampler;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates sampler border colors: TransparentBlack, OpaqueBlack, OpaqueWhite.
/// Three quads with UVs extending beyond [0,1] to show the border region.
class BorderSamplerSample : SampleApp
{
	const String cShaderSource = """
		Texture2D gTexture : register(t0, space0);
		SamplerState gSampler : register(s0, space0);

		cbuffer UBO : register(b0, space1)
		{
		    float4 QuadOffset; // xy = offset, zw = unused
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
		    output.Position = float4(input.Position.xy + QuadOffset.xy, input.Position.z, 1.0);
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
	private ITexture mTexture;
	private ITextureView mTextureView;
	// Three samplers with different border colors
	private ISampler mSamplerTransparent;
	private ISampler mSamplerOpaqueBlack;
	private ISampler mSamplerOpaqueWhite;
	// Bind group layouts and pipeline
	private IBindGroupLayout mTexBGL;
	private IBindGroup mBGTransparent;
	private IBindGroup mBGOpaqueBlack;
	private IBindGroup mBGOpaqueWhite;
	private IBindGroupLayout mUboBGL;
	private IBindGroup mUboBG;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;
	private void* mUniformMapped;

	public this()  { }

	protected override StringView Title => "Sample013 — Border Sampler";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "BorderVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "BorderPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Quad with UVs from -0.5 to 1.5 to show border region
		float[20] quadVerts = .(
			-0.25f, -0.25f, 0.0f,  -0.5f, -0.5f,
			 0.25f, -0.25f, 0.0f,   1.5f, -0.5f,
			 0.25f,  0.25f, 0.0f,   1.5f,  1.5f,
			-0.25f,  0.25f, 0.0f,  -0.5f,  1.5f
		);
		uint16[6] quadIdx = .(0, 1, 2, 0, 2, 3);

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = 80, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "BorderVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = 12, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "BorderIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		// Uniform buffer: 3 slots * 256 bytes (DX12 CBV alignment)
		let ubR = mDevice.CreateBuffer(BufferDesc() { Size = 768, Usage = .Uniform, Memory = .CpuToGpu, Label = "BorderUBO" });
		if (ubR case .Err) return .Err;
		mUniformBuffer = ubR.Value;
		mUniformMapped = mUniformBuffer.Map();

		// Write all 3 offsets upfront
		float[4] off0 = .(-0.55f, 0.0f, 0.0f, 0.0f);
		float[4] off1 = .( 0.0f,  0.0f, 0.0f, 0.0f);
		float[4] off2 = .( 0.55f, 0.0f, 0.0f, 0.0f);
		Internal.MemCpy((uint8*)mUniformMapped, &off0[0], 16);
		Internal.MemCpy((uint8*)mUniformMapped + 256, &off1[0], 16);
		Internal.MemCpy((uint8*)mUniformMapped + 512, &off2[0], 16);

		// Create a simple 8x8 checkerboard texture (red/white)
		uint32 texW = 8, texH = 8;
		uint8[256] texData = default;
		for (uint32 y = 0; y < texH; y++)
		{
			for (uint32 x = 0; x < texW; x++)
			{
				uint32 i = (y * texW + x) * 4;
				bool isWhite = ((x + y) % 2) == 0;
				texData[i + 0] = isWhite ? 255 : 220;
				texData[i + 1] = isWhite ? 255 : 60;
				texData[i + 2] = isWhite ? 255 : 60;
				texData[i + 3] = 255;
			}
		}

		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .RGBA8Unorm,
			Width = texW, Height = texH, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .Sampled | .CopyDst, Label = "CheckerTex"
		});
		if (texR case .Err) return .Err;
		mTexture = texR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&quadVerts[0], 80));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&quadIdx[0], 12));
		transfer.WriteTexture(mTexture, Span<uint8>(&texData[0], 256),
			TextureDataLayout() { Offset = 0, BytesPerRow = texW * 4, RowsPerImage = texH },
			Extent3D() { Width = texW, Height = texH, Depth = 1 });
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		let tvR = mDevice.CreateTextureView(mTexture, TextureViewDesc() { Format = .RGBA8Unorm, Dimension = .Texture2D });
		if (tvR case .Err) return .Err;
		mTextureView = tvR.Value;

		// Three samplers with ClampToBorder and different border colors
		let s1R = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Nearest, MagFilter = .Nearest, MipmapFilter = .Nearest,
			AddressU = .ClampToBorder, AddressV = .ClampToBorder, AddressW = .ClampToBorder,
			BorderColor = .TransparentBlack, Label = "TransparentBorderSampler"
		});
		if (s1R case .Err) return .Err;
		mSamplerTransparent = s1R.Value;

		let s2R = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Nearest, MagFilter = .Nearest, MipmapFilter = .Nearest,
			AddressU = .ClampToBorder, AddressV = .ClampToBorder, AddressW = .ClampToBorder,
			BorderColor = .OpaqueBlack, Label = "OpaqueBlackSampler"
		});
		if (s2R case .Err) return .Err;
		mSamplerOpaqueBlack = s2R.Value;

		let s3R = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Nearest, MagFilter = .Nearest, MipmapFilter = .Nearest,
			AddressU = .ClampToBorder, AddressV = .ClampToBorder, AddressW = .ClampToBorder,
			BorderColor = .OpaqueWhite, Label = "OpaqueWhiteSampler"
		});
		if (s3R case .Err) return .Err;
		mSamplerOpaqueWhite = s3R.Value;

		// Bind group layout: set 0 = texture + sampler
		let texEntries = scope BindGroupLayoutEntry[2];
		texEntries[0] = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		texEntries[1] = BindGroupLayoutEntry.Sampler(0, .Fragment);
		let texBglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(texEntries), Label = "TexBGL" });
		if (texBglR case .Err) return .Err;
		mTexBGL = texBglR.Value;

		// Three bind groups, one per sampler
		{
			let bgEntries = scope BindGroupEntry[2];
			bgEntries[0] = BindGroupEntry.Texture(mTextureView);
			bgEntries[1] = BindGroupEntry.Sampler(mSamplerTransparent);
			let bgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mTexBGL, Entries = Span<BindGroupEntry>(bgEntries), Label = "BG_Transparent" });
			if (bgR case .Err) return .Err;
			mBGTransparent = bgR.Value;
		}
		{
			let bgEntries = scope BindGroupEntry[2];
			bgEntries[0] = BindGroupEntry.Texture(mTextureView);
			bgEntries[1] = BindGroupEntry.Sampler(mSamplerOpaqueBlack);
			let bgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mTexBGL, Entries = Span<BindGroupEntry>(bgEntries), Label = "BG_OpaqueBlack" });
			if (bgR case .Err) return .Err;
			mBGOpaqueBlack = bgR.Value;
		}
		{
			let bgEntries = scope BindGroupEntry[2];
			bgEntries[0] = BindGroupEntry.Texture(mTextureView);
			bgEntries[1] = BindGroupEntry.Sampler(mSamplerOpaqueWhite);
			let bgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mTexBGL, Entries = Span<BindGroupEntry>(bgEntries), Label = "BG_OpaqueWhite" });
			if (bgR case .Err) return .Err;
			mBGOpaqueWhite = bgR.Value;
		}

		// Bind group layout: set 1 = uniform buffer with dynamic offset
		let uboEntries = scope BindGroupLayoutEntry[1];
		uboEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex, true);
		let uboBglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(uboEntries), Label = "UboBGL" });
		if (uboBglR case .Err) return .Err;
		mUboBGL = uboBglR.Value;

		let uboBgEntries = scope BindGroupEntry[1];
		uboBgEntries[0] = BindGroupEntry.Buffer(mUniformBuffer, 0, 16);
		let uboBgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mUboBGL, Entries = Span<BindGroupEntry>(uboBgEntries), Label = "UboBG" });
		if (uboBgR case .Err) return .Err;
		mUboBG = uboBgR.Value;

		// Pipeline layout
		let bgls = scope IBindGroupLayout[2];
		bgls[0] = mTexBGL;
		bgls[1] = mUboBGL;
		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { BindGroupLayouts = Span<IBindGroupLayout>(bgls), Label = "BorderPL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x2, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 20, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format, WriteMask = .All,
			Blend = BlendState()
			{
				Color = BlendComponent() { SrcFactor = .SrcAlpha, DstFactor = .OneMinusSrcAlpha, Operation = .Add },
				Alpha = BlendComponent() { SrcFactor = .One, DstFactor = .OneMinusSrcAlpha, Operation = .Add }
			}
		};

		let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "BorderPipeline"
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

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.2f, 0.2f, 0.25f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca)
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// Draw 3 quads side by side with different samplers and dynamic UBO offsets
		IBindGroup[3] texBindGroups = .(mBGTransparent, mBGOpaqueBlack, mBGOpaqueWhite);
		uint32[3] dynOffsets = .(0, 256, 512);

		for (int i = 0; i < 3; i++)
		{
			rp.SetBindGroup(0, texBindGroups[i]);
			let offset = scope uint32[1];
			offset[0] = dynOffsets[i];
			rp.SetBindGroup(1, mUboBG, Span<uint32>(offset));
			rp.DrawIndexed(6);
		}

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

	protected override void OnShutdown()
	{
		if (mUniformBuffer != null && mUniformMapped != null) mUniformBuffer.Unmap();
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mUboBG != null) mDevice?.DestroyBindGroup(ref mUboBG);
		if (mUboBGL != null) mDevice?.DestroyBindGroupLayout(ref mUboBGL);
		if (mBGOpaqueWhite != null) mDevice?.DestroyBindGroup(ref mBGOpaqueWhite);
		if (mBGOpaqueBlack != null) mDevice?.DestroyBindGroup(ref mBGOpaqueBlack);
		if (mBGTransparent != null) mDevice?.DestroyBindGroup(ref mBGTransparent);
		if (mTexBGL != null) mDevice?.DestroyBindGroupLayout(ref mTexBGL);
		if (mSamplerOpaqueWhite != null) mDevice?.DestroySampler(ref mSamplerOpaqueWhite);
		if (mSamplerOpaqueBlack != null) mDevice?.DestroySampler(ref mSamplerOpaqueBlack);
		if (mSamplerTransparent != null) mDevice?.DestroySampler(ref mSamplerTransparent);
		if (mTextureView != null) mDevice?.DestroyTextureView(ref mTextureView);
		if (mTexture != null) mDevice?.DestroyTexture(ref mTexture);
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
		let app = scope BorderSamplerSample();
		return app.Run();
	}
}
