namespace Sample018_Bindless;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates bindless texture arrays with material index via push constants.
/// Creates 4 procedural textures, binds them in a bindless array, and renders
/// 4 quads each selecting a different texture via push constant index.
class BindlessSample : SampleApp
{
	const String cShaderSource = """
		Texture2D gTextures[] : register(t0, space0);
		SamplerState gSampler : register(s0, space1);

		struct PushData
		{
		    uint TextureIndex;
		    float OffsetX;
		    float OffsetY;
		    float Padding;
		};

		[[vk::push_constant]] ConstantBuffer<PushData> gPush : register(b0, space2);

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 TexCoord : TEXCOORD0;
		};

		PSInput VSMain(uint vertexID : SV_VertexID)
		{
		    // Fullscreen-quad-style: 4 vertices for a unit quad
		    float2 positions[4] = {
		        float2(-0.4, 0.4),
		        float2( 0.4, 0.4),
		        float2(-0.4,-0.4),
		        float2( 0.4,-0.4)
		    };
		    float2 uvs[4] = {
		        float2(0, 0), float2(1, 0),
		        float2(0, 1), float2(1, 1)
		    };

		    PSInput output;
		    float2 pos = positions[vertexID];
		    pos.x += gPush.OffsetX;
		    pos.y += gPush.OffsetY;
		    output.Position = float4(pos, 0.0, 1.0);
		    output.TexCoord = uvs[vertexID];
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return gTextures[gPush.TextureIndex].Sample(gSampler, input.TexCoord);
		}
		""";

	const uint32 cTexSize = 64;
	const uint32 cNumTextures = 4;

	private ShaderCompiler mShaderCompiler;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;

	// Textures
	private ITexture[cNumTextures] mTextures;
	private ITextureView[cNumTextures] mTextureViews;
	private ISampler mSampler;

	// Bindless bind group (space0: bindless textures)
	private IBindGroupLayout mBindlessBGL;
	private IBindGroup mBindlessBG;

	// Sampler bind group (space1: sampler)
	private IBindGroupLayout mSamplerBGL;
	private IBindGroup mSamplerBG;

	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this()  { }

	protected override StringView Title => "Sample018 - Bindless Textures";

	protected override DeviceFeatures RequiredFeatures => .() { BindlessDescriptors = true };

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "BindlessVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "BindlessPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Create 4 procedural textures with different patterns
		if (CreateTextures() case .Err) return .Err;

		// Sampler
		let sampR = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Linear, MagFilter = .Linear,
			AddressU = .Repeat, AddressV = .Repeat,
			Label = "BindlessSampler"
		});
		if (sampR case .Err) return .Err;
		mSampler = sampR.Value;

		// Bindless BGL (space0): unbounded texture array
		let bindlessEntries = scope BindGroupLayoutEntry[1];
		bindlessEntries[0] = BindGroupLayoutEntry()
		{
			Binding = 0,
			Visibility = .Fragment,
			Type = .BindlessTextures,
			TextureDimension = .Texture2D,
			Count = uint32.MaxValue
		};

		let blBGLR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(bindlessEntries), Label = "BindlessBGL"
		});
		if (blBGLR case .Err) return .Err;
		mBindlessBGL = blBGLR.Value;

		// Create bindless bind group (no entries at creation - populated via UpdateBindless)
		let blBGR = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mBindlessBGL, Label = "BindlessBG"
		});
		if (blBGR case .Err) return .Err;
		mBindlessBG = blBGR.Value;

		// Populate bindless slots
		let bindlessUpdates = scope BindlessUpdateEntry[cNumTextures];
		for (uint32 i = 0; i < cNumTextures; i++)
			bindlessUpdates[i] = BindlessUpdateEntry.Texture(0, i, mTextureViews[i]);
		mBindlessBG.UpdateBindless(Span<BindlessUpdateEntry>(bindlessUpdates));

		// Sampler BGL (space1)
		let samplerEntries = scope BindGroupLayoutEntry[1];
		samplerEntries[0] = BindGroupLayoutEntry.Sampler(0, .Fragment);

		let sBGLR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(samplerEntries), Label = "SamplerBGL"
		});
		if (sBGLR case .Err) return .Err;
		mSamplerBGL = sBGLR.Value;

		let sBGEntries = scope BindGroupEntry[1];
		sBGEntries[0] = BindGroupEntry.Sampler(mSampler);

		let sBGR = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mSamplerBGL, Entries = Span<BindGroupEntry>(sBGEntries), Label = "SamplerBG"
		});
		if (sBGR case .Err) return .Err;
		mSamplerBG = sBGR.Value;

		// Pipeline layout: group 0 = bindless textures, group 1 = sampler, push constants
		let bgls = scope IBindGroupLayout[2];
		bgls[0] = mBindlessBGL;
		bgls[1] = mSamplerBGL;

		let pushRanges = scope PushConstantRange[1];
		pushRanges[0] = PushConstantRange() { Stages = .Vertex | .Fragment, Offset = 0, Size = 16 };

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(bgls),
			PushConstantRanges = Span<PushConstantRange>(pushRanges),
			Label = "BindlessPL"
		});
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		// Render pipeline (no vertex buffers - SV_VertexID driven)
		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain" ) },
			Fragment = .() { Shader = .(mPixelShader, "PSMain" ) , Targets = Span<ColorTargetState>(colorTargets) },
			Primitive = PrimitiveState() { Topology = .TriangleStrip },
			Label = "BindlessPipeline"
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

	private Result<void> CreateTextures()
	{
		uint32 rowBytes = cTexSize * 4;
		uint32 texBytes = rowBytes * cTexSize;
		uint8* pixels = new uint8[texBytes]*;
		defer delete pixels;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;

		for (uint32 t = 0; t < cNumTextures; t++)
		{
			// Generate pattern
			for (uint32 y = 0; y < cTexSize; y++)
			{
				for (uint32 x = 0; x < cTexSize; x++)
				{
					uint32 offset = (y * cTexSize + x) * 4;
					GeneratePixel(t, x, y, &pixels[offset]);
				}
			}

			let texR = mDevice.CreateTexture(TextureDesc()
			{
				Dimension = .Texture2D, Format = .RGBA8Unorm,
				Width = cTexSize, Height = cTexSize, ArrayLayerCount = 1,
				MipLevelCount = 1, SampleCount = 1,
				Usage = .Sampled | .CopyDst, Label = "BindlessTex"
			});
			if (texR case .Err) { mGraphicsQueue.DestroyTransferBatch(ref transfer); return .Err; }
			mTextures[t] = texR.Value;

			transfer.WriteTexture(mTextures[t], Span<uint8>(pixels, (.)texBytes),
				TextureDataLayout() { BytesPerRow = rowBytes, RowsPerImage = cTexSize },
				Extent3D() { Width = cTexSize, Height = cTexSize, Depth = 1 });

			let tvR = mDevice.CreateTextureView(mTextures[t], TextureViewDesc() { Format = .RGBA8Unorm, Dimension = .Texture2D });
			if (tvR case .Err) { mGraphicsQueue.DestroyTransferBatch(ref transfer); return .Err; }
			mTextureViews[t] = tvR.Value;
		}

		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);
		return .Ok;
	}

	private void GeneratePixel(uint32 texIndex, uint32 x, uint32 y, uint8* rgba)
	{
		float fx = (float)x / (float)cTexSize;
		float fy = (float)y / (float)cTexSize;

		switch (texIndex)
		{
		case 0: // Red/white checkerboard
			bool check = ((x / 8) + (y / 8)) % 2 == 0;
			rgba[0] = check ? 220 : 255;
			rgba[1] = check ? 30 : 255;
			rgba[2] = check ? 30 : 255;
			rgba[3] = 255;

		case 1: // Green gradient with stripes
			uint8 g = (uint8)(fx * 255.0f);
			bool stripe = (y % 16) < 8;
			rgba[0] = stripe ? 30 : 10;
			rgba[1] = stripe ? g : (uint8)(g / 2);
			rgba[2] = stripe ? 50 : 30;
			rgba[3] = 255;

		case 2: // Blue circles
			float cx = fx - 0.5f, cy = fy - 0.5f;
			float dist = Math.Sqrt(cx * cx + cy * cy);
			float rings = Math.Sin(dist * 30.0f) * 0.5f + 0.5f;
			rgba[0] = (uint8)(rings * 60);
			rgba[1] = (uint8)(rings * 100);
			rgba[2] = (uint8)(rings * 255);
			rgba[3] = 255;

		default: // Yellow/purple diagonal
			float diag = Math.Sin((fx + fy) * 10.0f) * 0.5f + 0.5f;
			rgba[0] = (uint8)(diag * 255 + (1.0f - diag) * 120);
			rgba[1] = (uint8)(diag * 220);
			rgba[2] = (uint8)((1.0f - diag) * 200);
			rgba[3] = 255;
		}
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

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
			ClearValue = ClearColor(0.08f, 0.06f, 0.12f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc() { ColorAttachments = .(ca) });
		rp.SetPipeline(mPipeline);
		rp.SetBindGroup(0, mBindlessBG);
		rp.SetBindGroup(1, mSamplerBG);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);

		// Draw 4 quads, each with a different texture index via push constants
		// Layout: 2x2 grid
		float[8] offsets = .(-0.45f, 0.45f, 0.45f, 0.45f, -0.45f, -0.45f, 0.45f, -0.45f);

		for (uint32 i = 0; i < cNumTextures; i++)
		{
			uint32[4] pushData = .(i, 0, 0, 0);
			Internal.MemCpy(&pushData[1], &offsets[i * 2], 4);
			Internal.MemCpy(&pushData[2], &offsets[i * 2 + 1], 4);
			rp.SetPushConstants(.Vertex | .Fragment, 0, 16, &pushData[0]);
			rp.Draw(4);
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
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mSamplerBG != null) mDevice?.DestroyBindGroup(ref mSamplerBG);
		if (mSamplerBGL != null) mDevice?.DestroyBindGroupLayout(ref mSamplerBGL);
		if (mBindlessBG != null) mDevice?.DestroyBindGroup(ref mBindlessBG);
		if (mBindlessBGL != null) mDevice?.DestroyBindGroupLayout(ref mBindlessBGL);
		if (mSampler != null) mDevice?.DestroySampler(ref mSampler);
		for (int i = cNumTextures - 1; i >= 0; i--)
		{
			if (mTextureViews[i] != null) mDevice?.DestroyTextureView(ref mTextureViews[i]);
			if (mTextures[i] != null) mDevice?.DestroyTexture(ref mTextures[i]);
		}
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope BindlessSample();
		return app.Run();
	}
}
