namespace Sample027_3DTexture;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates 3D textures and 1D textures.
/// Generates a 3D noise volume, renders slices animated over time.
/// Uses a 1D gradient LUT for color mapping.
class Texture3DSample : SampleApp
{
	const String cShaderSource = """
		Texture3D<float4> gVolume : register(t0, space0);
		Texture1D<float4> gLUT    : register(t1, space0);
		SamplerState gSampler     : register(s0, space0);

		struct PushConstants
		{
		    float SliceZ;
		    float Time;
		    float2 _pad;
		};

		[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space1);

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 UV       : TEXCOORD0;
		};

		PSInput VSMain(uint vertexID : SV_VertexID)
		{
		    PSInput output;
		    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
		    output.Position = float4(uv * 2.0 - 1.0, 0.5, 1.0);
		    output.UV = uv;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    // Sample 3D volume at current slice
		    float3 uvw = float3(input.UV, pc.SliceZ);
		    float density = gVolume.Sample(gSampler, uvw).r;

		    // Map density through 1D LUT
		    float4 color = gLUT.Sample(gSampler, density);
		    return color;
		}
		""";

	[CRepr]
	struct PushData
	{
		public float SliceZ;
		public float Time;
		public float _pad0;
		public float _pad1;
	}

	const uint32 VolumeSize = 32;
	const uint32 LUTSize = 64;

	private ShaderCompiler mShaderCompiler;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;

	// 3D volume texture
	private ITexture mVolumeTexture;
	private ITextureView mVolumeView;

	// 1D LUT texture
	private ITexture mLUTTexture;
	private ITextureView mLUTView;

	private ISampler mSampler;
	private IBindGroupLayout mBGL;
	private IBindGroup mBG;
	private IPipelineLayout mPL;
	private IRenderPipeline mPipeline;

	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample027 — 3D Texture & 1D LUT";

	protected override Result<void> OnInit()
	{
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let shaderFmt = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let errors = scope String();
		let vs = scope List<uint8>();
		let ps = scope List<uint8>();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", shaderFmt, vs, errors) case .Err)
		{ Console.WriteLine("VS: {}", errors); return .Err; }
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", shaderFmt, ps, errors) case .Err)
		{ Console.WriteLine("PS: {}", errors); return .Err; }

		let r1 = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vs.Ptr, vs.Count), Label = "Vol3DVS" });
		if (r1 case .Err) return .Err;
		mVertexShader = r1.Value;
		let r2 = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(ps.Ptr, ps.Count), Label = "Vol3DPS" });
		if (r2 case .Err) return .Err;
		mPixelShader = r2.Value;

		if (CreateVolumeTexture() case .Err) return .Err;
		if (CreateLUTTexture() case .Err) return .Err;

		{
			let r = mDevice.CreateSampler(SamplerDesc() { MinFilter = .Linear, MagFilter = .Linear, AddressU = .Repeat, AddressV = .Repeat, AddressW = .Repeat, Label = "VolSampler" });
			if (r case .Err) return .Err;
			mSampler = r.Value;
		}

		// Bind group layout: 3D tex, 1D tex, sampler
		{
			let entries = scope BindGroupLayoutEntry[3];
			entries[0] = BindGroupLayoutEntry.SampledTexture(0, .Fragment, .Texture3D);
			entries[1] = BindGroupLayoutEntry.SampledTexture(1, .Fragment, .Texture1D);
			entries[2] = BindGroupLayoutEntry.Sampler(0, .Fragment);
			let r = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(entries), Label = "VolBGL" });
			if (r case .Err) return .Err;
			mBGL = r.Value;
		}

		{
			let entries = scope BindGroupEntry[3];
			entries[0] = BindGroupEntry.Texture(mVolumeView);
			entries[1] = BindGroupEntry.Texture(mLUTView);
			entries[2] = BindGroupEntry.Sampler(mSampler);
			let r = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mBGL, Entries = Span<BindGroupEntry>(entries), Label = "VolBG" });
			if (r case .Err) return .Err;
			mBG = r.Value;
		}

		{
			let bgls = scope IBindGroupLayout[1];
			bgls[0] = mBGL;
			let pushRanges = scope PushConstantRange[1];
			pushRanges[0] = PushConstantRange() { Stages = .Fragment, Offset = 0, Size = sizeof(PushData) };
			let r = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
			{
				BindGroupLayouts = Span<IBindGroupLayout>(bgls),
				PushConstantRanges = Span<PushConstantRange>(pushRanges),
				Label = "VolPL"
			});
			if (r case .Err) return .Err;
			mPL = r.Value;
		}

		{
			let colorTargets = scope ColorTargetState[1];
			colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

			let r = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mPL,
				Vertex = .() { Shader = .(mVertexShader, "VSMain" ) },
				Fragment = .() { Shader = .(mPixelShader, "PSMain" ) , Targets = Span<ColorTargetState>(colorTargets) },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Multisample = .(),
				Label = "VolPipeline"
			});
			if (r case .Err) return .Err;
			mPipeline = r.Value;
		}

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateVolumeTexture()
	{
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture3D,
			Format = .R8Unorm,
			Width = VolumeSize, Height = VolumeSize, Depth = VolumeSize,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .Sampled | .CopyDst,
			Label = "VolumeTex3D"
		});
		if (texR case .Err) return .Err;
		mVolumeTexture = texR.Value;

		let viewR = mDevice.CreateTextureView(mVolumeTexture, TextureViewDesc()
		{
			Format = .R8Unorm, Dimension = .Texture3D
		});
		if (viewR case .Err) return .Err;
		mVolumeView = viewR.Value;

		// Generate procedural 3D noise data
		let dataSize = (int)(VolumeSize * VolumeSize * VolumeSize);
		let data = scope uint8[dataSize];

		for (uint32 z = 0; z < VolumeSize; z++)
		{
			for (uint32 y = 0; y < VolumeSize; y++)
			{
				for (uint32 x = 0; x < VolumeSize; x++)
				{
					float fx = (float)x / (float)VolumeSize;
					float fy = (float)y / (float)VolumeSize;
					float fz = (float)z / (float)VolumeSize;

					// Simple 3D pattern: spherical blobs + frequency pattern
					float cx = fx - 0.5f, cy = fy - 0.5f, cz = fz - 0.5f;
					float dist = Math.Sqrt(cx * cx + cy * cy + cz * cz);
					float sphere = Math.Max(0.0f, 1.0f - dist * 3.0f);
					float pattern = Math.Sin(fx * 12.0f) * Math.Sin(fy * 12.0f) * Math.Sin(fz * 12.0f);
					float v = Math.Clamp(sphere + pattern * 0.3f, 0.0f, 1.0f);

					int idx = (int)(z * VolumeSize * VolumeSize + y * VolumeSize + x);
					data[idx] = (uint8)(v * 255.0f);
				}
			}
		}

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var xfer = batchR.Value;
		xfer.WriteTexture(mVolumeTexture,
			Span<uint8>(&data[0], dataSize),
			TextureDataLayout() { Offset = 0, BytesPerRow = VolumeSize, RowsPerImage = VolumeSize },
			Extent3D() { Width = VolumeSize, Height = VolumeSize, Depth = VolumeSize });
		xfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref xfer);

		return .Ok;
	}

	private Result<void> CreateLUTTexture()
	{
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture1D,
			Format = .RGBA8UnormSrgb,
			Width = LUTSize, Height = 1, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .Sampled | .CopyDst,
			Label = "LUTTex1D"
		});
		if (texR case .Err) return .Err;
		mLUTTexture = texR.Value;

		let viewR = mDevice.CreateTextureView(mLUTTexture, TextureViewDesc()
		{
			Format = .RGBA8UnormSrgb, Dimension = .Texture1D
		});
		if (viewR case .Err) return .Err;
		mLUTView = viewR.Value;

		// Generate gradient LUT: dark blue -> cyan -> green -> yellow -> red -> white
		let data = scope uint8[LUTSize * 4];
		for (uint32 i = 0; i < LUTSize; i++)
		{
			float t = (float)i / (float)(LUTSize - 1);
			float r, g, b;
			if (t < 0.2f)
			{
				float s = t / 0.2f;
				r = 0.05f; g = 0.05f + s * 0.4f; b = 0.3f + s * 0.5f;
			}
			else if (t < 0.4f)
			{
				float s = (t - 0.2f) / 0.2f;
				r = 0.05f; g = 0.45f + s * 0.5f; b = 0.8f - s * 0.5f;
			}
			else if (t < 0.6f)
			{
				float s = (t - 0.4f) / 0.2f;
				r = s * 0.8f; g = 0.95f; b = 0.3f - s * 0.3f;
			}
			else if (t < 0.8f)
			{
				float s = (t - 0.6f) / 0.2f;
				r = 0.8f + s * 0.2f; g = 0.95f - s * 0.6f; b = 0.0f;
			}
			else
			{
				float s = (t - 0.8f) / 0.2f;
				r = 1.0f; g = 0.35f + s * 0.65f; b = s * 0.8f;
			}

			int idx = (int)(i * 4);
			data[idx + 0] = (uint8)(r * 255.0f);
			data[idx + 1] = (uint8)(g * 255.0f);
			data[idx + 2] = (uint8)(b * 255.0f);
			data[idx + 3] = 255;
		}

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var xfer = batchR.Value;
		xfer.WriteTexture(mLUTTexture,
			Span<uint8>(&data[0], (int)(LUTSize * 4)),
			TextureDataLayout() { Offset = 0, BytesPerRow = LUTSize * 4, RowsPerImage = 1 },
			Extent3D() { Width = LUTSize, Height = 1, Depth = 1 });
		xfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref xfer);

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
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.02f, 0.02f, 0.05f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca)
		});

		rp.SetPipeline(mPipeline);
		rp.SetBindGroup(0, mBG);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);

		// Animate slice through 3D volume
		float sliceZ = 0.5f + 0.5f * Math.Sin(mTotalTime * 0.5f);
		var pc = PushData() { SliceZ = sliceZ, Time = mTotalTime };
		rp.SetPushConstants(.Fragment, 0, sizeof(PushData), &pc);

		rp.Draw(3); // Fullscreen triangle

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
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPL != null) mDevice?.DestroyPipelineLayout(ref mPL);
		if (mBG != null) mDevice?.DestroyBindGroup(ref mBG);
		if (mBGL != null) mDevice?.DestroyBindGroupLayout(ref mBGL);
		if (mSampler != null) mDevice?.DestroySampler(ref mSampler);
		if (mLUTView != null) mDevice?.DestroyTextureView(ref mLUTView);
		if (mLUTTexture != null) mDevice?.DestroyTexture(ref mLUTTexture);
		if (mVolumeView != null) mDevice?.DestroyTextureView(ref mVolumeView);
		if (mVolumeTexture != null) mDevice?.DestroyTexture(ref mVolumeTexture);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope Texture3DSample();
		return app.Run();
	}
}
