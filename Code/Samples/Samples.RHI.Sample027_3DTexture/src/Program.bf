using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample027_3DTexture;

/// What the fragment shader is handed each frame.
[CRepr]
struct PushData
{
	public float SliceZ;
	public float Time;
	public float Pad0;
	public float Pad1;
}

/// A volume sampled slice by slice, coloured through a 1D lookup table.
///
/// The two texture DIMENSIONS a sample usually skips: a 3D texture read with three
/// coordinates, and a 1D one used as a palette. The slice sweeps back and forth so the
/// volume's interior is visible over time.
class Texture3DSample : SampleApp
{
	private const String cShaderSource = """
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
		    float3 uvw = float3(input.UV, pc.SliceZ);
		    float density = gVolume.Sample(gSampler, uvw).r;
		    float4 color = gLUT.Sample(gSampler, density);
		    return color;
		}
		""";

	private const uint32 cVolumeSize = 32;
	private const uint32 cLutSize = 64;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private ITexture mVolumeTexture = null;
	private ITextureView mVolumeView = null;
	private ITexture mLutTexture = null;
	private ITextureView mLutView = null;
	private ISampler mSampler = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample027 - 3D Texture & 1D LUT";

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

		if (CreateVolumeTexture() case .Err)
			return .Err;
		if (CreateLutTexture() case .Err)
			return .Err;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		if (CreateBindings() case .Err)
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

	/// A single channel volume: a sphere with a sine lattice through it, so slices differ
	/// from one another rather than looking like one image.
	private Result<void> CreateVolumeTexture()
	{
		var textureDesc = TextureDesc();
		textureDesc.Dimension = .Texture3D;
		textureDesc.Format = .R8Unorm;
		textureDesc.Width = cVolumeSize;
		textureDesc.Height = cVolumeSize;
		// DEPTH, which is what makes it a volume rather than an array of slices.
		textureDesc.Depth = cVolumeSize;
		textureDesc.MipLevelCount = 1;
		textureDesc.SampleCount = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "VolumeTex3D";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mVolumeTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .R8Unorm;
		viewDesc.Dimension = .Texture3D;
		if (!(mDevice.CreateTextureView(mVolumeTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mVolumeView = view;

		let data = scope uint8[cVolumeSize * cVolumeSize * cVolumeSize];
		for (uint32 z < cVolumeSize)
		{
			for (uint32 y < cVolumeSize)
			{
				for (uint32 x < cVolumeSize)
				{
					let fx = (float)x / (float)cVolumeSize;
					let fy = (float)y / (float)cVolumeSize;
					let fz = (float)z / (float)cVolumeSize;

					let cx = fx - 0.5f;
					let cy = fy - 0.5f;
					let cz = fz - 0.5f;
					let distance = Math.Sqrt(cx * cx + cy * cy + cz * cz);
					let sphere = Math.Max(0.0f, 1.0f - distance * 3.0f);
					let lattice = Math.Sin(fx * 12.0f) * Math.Sin(fy * 12.0f)
						* Math.Sin(fz * 12.0f);
					let value = Math.Clamp(sphere + lattice * 0.3f, 0.0f, 1.0f);

					data[((int)z * cVolumeSize * cVolumeSize) + ((int)y * cVolumeSize) + (int)x] =
						(uint8)(value * 255.0f);
				}
			}
		}

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		var layout = TextureDataLayout();
		layout.BytesPerRow = cVolumeSize;
		layout.RowsPerImage = cVolumeSize;
		// The extent's DEPTH is what makes this one write cover every slice rather than
		// only the first.
		batch.WriteTexture(mVolumeTexture, data, layout,
			.(cVolumeSize, cVolumeSize, cVolumeSize));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	/// A 1D palette from deep blue through green and yellow to white.
	private Result<void> CreateLutTexture()
	{
		var textureDesc = TextureDesc();
		textureDesc.Dimension = .Texture1D;
		textureDesc.Format = .RGBA8UnormSrgb;
		textureDesc.Width = cLutSize;
		textureDesc.Height = 1;
		textureDesc.ArrayLayerCount = 1;
		textureDesc.MipLevelCount = 1;
		textureDesc.SampleCount = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "LUTTex1D";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mLutTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8UnormSrgb;
		viewDesc.Dimension = .Texture1D;
		if (!(mDevice.CreateTextureView(mLutTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mLutView = view;

		let data = scope uint8[cLutSize * 4];
		for (uint32 i < cLutSize)
		{
			let t = (float)i / (float)(cLutSize - 1);
			float r = 0, g = 0, b = 0;
			// Five bands, each interpolating within itself, which is what makes the ramp
			// read as a heat scale rather than a single gradient.
			if (t < 0.2f)
			{
				let s = t / 0.2f;
				r = 0.05f; g = 0.05f + s * 0.4f; b = 0.3f + s * 0.5f;
			}
			else if (t < 0.4f)
			{
				let s = (t - 0.2f) / 0.2f;
				r = 0.05f; g = 0.45f + s * 0.5f; b = 0.8f - s * 0.5f;
			}
			else if (t < 0.6f)
			{
				let s = (t - 0.4f) / 0.2f;
				r = s * 0.8f; g = 0.95f; b = 0.3f - s * 0.3f;
			}
			else if (t < 0.8f)
			{
				let s = (t - 0.6f) / 0.2f;
				r = 0.8f + s * 0.2f; g = 0.95f - s * 0.6f; b = 0.0f;
			}
			else
			{
				let s = (t - 0.8f) / 0.2f;
				r = 1.0f; g = 0.35f + s * 0.65f; b = s * 0.8f;
			}

			let at = i * 4;
			data[(int)at + 0] = (uint8)(r * 255.0f);
			data[(int)at + 1] = (uint8)(g * 255.0f);
			data[(int)at + 2] = (uint8)(b * 255.0f);
			data[(int)at + 3] = 255;
		}

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		var layout = TextureDataLayout();
		layout.BytesPerRow = cLutSize * 4;
		layout.RowsPerImage = 1;
		batch.WriteTexture(mLutTexture, data, layout, .(cLutSize, 1, 1));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		var layoutEntries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment, .Texture3D),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment, .Texture1D),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mBindGroupLayout = layout;

		var entries = BindGroupEntry[3](
			BindGroupEntry.TextureEntry(mVolumeView),
			BindGroupEntry.TextureEntry(mLutView),
			BindGroupEntry.SamplerEntry(mSampler));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mBindGroupLayout;
		groupDesc.Entries = entries;
		if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
			return .Err;
		mBindGroup = bindGroup;
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		var layouts = IBindGroupLayout[1](mBindGroupLayout);
		var pushConstants = PushConstantRange[1](
			.() { Stages = .Vertex | .Fragment, Offset = 0, Size = (uint32)sizeof(PushData) });
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		pipelineLayoutDesc.PushConstantRanges = pushConstants;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		var fragment = FragmentState();
		fragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.02f, 0.02f, 0.05f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetBindGroup(0, mBindGroup);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);

		// The slice sweeps back and forth, so the whole volume is seen over time rather
		// than one still cross section.
		var pushData = PushData();
		pushData.SliceZ = 0.5f + 0.5f * Math.Sin(mTotalTime * 0.5f);
		pushData.Time = mTotalTime;
		pass.SetPushConstants(.Vertex | .Fragment, 0, (uint32)sizeof(PushData), &pushData);
		pass.Draw(3);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

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
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null) mDevice.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
		if (mLutView != null) mDevice.DestroyTextureView(ref mLutView);
		if (mLutTexture != null) mDevice.DestroyTexture(ref mLutTexture);
		if (mVolumeView != null) mDevice.DestroyTextureView(ref mVolumeView);
		if (mVolumeTexture != null) mDevice.DestroyTexture(ref mVolumeTexture);
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
		let app = scope Texture3DSample();
		return app.Run(args);
	}
}
