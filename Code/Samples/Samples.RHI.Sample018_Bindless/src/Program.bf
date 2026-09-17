using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample018_Bindless;

/// Four quads sampling four different textures from ONE unbounded array, indexed by a push
/// constant.
///
/// Nothing is rebound between the draws: the bind group is set once and only the index
/// changes. That is what bindless is for, and it is what lets a renderer draw thousands of
/// differently textured objects without a descriptor set per object.
class BindlessSample : SampleApp
{
	private const String cShaderSource = """
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

	private const uint32 cTextureSize = 64;
	private const uint32 cTextureCount = 4;
	/// An unbounded array, which is what the backend turns into its bindless capacity.
	private const uint32 cUnboundedCount = 0xFFFFFFFF;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private ITexture[cTextureCount] mTextures = .(null, null, null, null);
	private ITextureView[cTextureCount] mTextureViews = .(null, null, null, null);
	private ISampler mSampler = null;
	private IBindGroupLayout mBindlessLayout = null;
	private IBindGroup mBindlessBindGroup = null;
	private IBindGroupLayout mSamplerLayout = null;
	private IBindGroup mSamplerBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample018 - Bindless Textures";

	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.BindlessDescriptors = true;
			return features;
		}
	}

	protected override Result<void> OnInit()
	{
		if (!mDevice.Features.BindlessDescriptors)
		{
			Console.Error.WriteLine("Sample018: this device does not support bindless descriptors");
			return .Err;
		}

		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Vertex,
			"VSMain", "BindlessVS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "BindlessPS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateTextures() case .Err)
			return .Err;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.AddressU = .Repeat;
		samplerDesc.AddressV = .Repeat;
		samplerDesc.Label = "BindlessSampler";
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

	private Result<void> CreateTextures()
	{
		let rowBytes = cTextureSize * 4;
		let pixels = scope uint8[rowBytes * cTextureSize];

		// One batch for all four, since they are all uploaded once at startup.
		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		defer mGraphicsQueue.DestroyTransferBatch(ref batch);

		for (uint32 t < cTextureCount)
		{
			for (uint32 y < cTextureSize)
			{
				for (uint32 x < cTextureSize)
					GeneratePixel(t, x, y, &pixels[(int)(y * cTextureSize + x) * 4]);
			}

			var textureDesc = TextureDesc();
			textureDesc.Format = .RGBA8Unorm;
			textureDesc.Width = cTextureSize;
			textureDesc.Height = cTextureSize;
			textureDesc.MipLevelCount = 1;
			textureDesc.Usage = .Sampled | .CopyDst;
			textureDesc.Label = "BindlessTex";
			if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
				return .Err;
			mTextures[t] = texture;

			var layout = TextureDataLayout();
			layout.BytesPerRow = rowBytes;
			layout.RowsPerImage = cTextureSize;
			batch.WriteTexture(mTextures[t], pixels, layout,
				.(cTextureSize, cTextureSize, 1));

			var viewDesc = TextureViewDesc();
			viewDesc.Format = .RGBA8Unorm;
			viewDesc.MipLevelCount = 1;
			viewDesc.ArrayLayerCount = 1;
			if (!(mDevice.CreateTextureView(mTextures[t], viewDesc) case .Ok(let view)))
				return .Err;
			mTextureViews[t] = view;
		}

		batch.Submit().IgnoreError();
		return .Ok;
	}

	/// Four visibly different patterns, so which slot a quad sampled is unmistakable.
	private static void GeneratePixel(uint32 textureIndex, uint32 x, uint32 y, uint8* rgba)
	{
		let fx = (float)x / (float)cTextureSize;
		let fy = (float)y / (float)cTextureSize;

		switch (textureIndex)
		{
		case 0: // A red and white checkerboard.
			let check = (((x / 8) + (y / 8)) % 2) == 0;
			rgba[0] = check ? 220 : 255;
			rgba[1] = check ? 30 : 255;
			rgba[2] = check ? 30 : 255;
			rgba[3] = 255;
		case 1: // A green gradient under horizontal stripes.
			let g = (uint8)(fx * 255.0f);
			let stripe = (y % 16) < 8;
			rgba[0] = stripe ? 30 : 10;
			rgba[1] = stripe ? g : (uint8)(g / 2);
			rgba[2] = stripe ? 50 : 30;
			rgba[3] = 255;
		case 2: // Blue concentric rings.
			let cx = fx - 0.5f;
			let cy = fy - 0.5f;
			let distance = Math.Sqrt(cx * cx + cy * cy);
			let rings = Math.Sin(distance * 30.0f) * 0.5f + 0.5f;
			rgba[0] = (uint8)(rings * 60);
			rgba[1] = (uint8)(rings * 100);
			rgba[2] = (uint8)(rings * 255);
			rgba[3] = 255;
		default: // Yellow and purple diagonals.
			let diagonal = Math.Sin((fx + fy) * 10.0f) * 0.5f + 0.5f;
			rgba[0] = (uint8)(diagonal * 255 + (1.0f - diagonal) * 120);
			rgba[1] = (uint8)(diagonal * 220);
			rgba[2] = (uint8)((1.0f - diagonal) * 200);
			rgba[3] = 255;
		}
	}

	private Result<void> CreateBindings()
	{
		// An UNBOUNDED entry: the shader declares Texture2D[] with no size, and the layout
		// says so with a count the backend reads as "as many as this device allows".
		var bindlessEntry = BindGroupLayoutEntry();
		bindlessEntry.Binding = 0;
		bindlessEntry.Visibility = .Fragment;
		bindlessEntry.Type = .BindlessTextures;
		bindlessEntry.TextureDimension = .Texture2D;
		bindlessEntry.Count = cUnboundedCount;
		var bindlessEntries = BindGroupLayoutEntry[1](bindlessEntry);

		var bindlessLayoutDesc = BindGroupLayoutDesc();
		bindlessLayoutDesc.Entries = bindlessEntries;
		bindlessLayoutDesc.Label = "BindlessBGL";
		if (!(mDevice.CreateBindGroupLayout(bindlessLayoutDesc) case .Ok(let bindlessLayout)))
			return .Err;
		mBindlessLayout = bindlessLayout;

		// Created EMPTY. A bindless group's contents are written by index afterwards
		// rather than listed up front, which is what lets slots change without rebuilding
		// the group.
		var bindlessGroupDesc = BindGroupDesc();
		bindlessGroupDesc.Layout = mBindlessLayout;
		bindlessGroupDesc.Label = "BindlessBG";
		if (!(mDevice.CreateBindGroup(bindlessGroupDesc) case .Ok(let bindlessBindGroup)))
			return .Err;
		mBindlessBindGroup = bindlessBindGroup;

		var updates = scope BindlessUpdateEntry[cTextureCount];
		for (uint32 i < cTextureCount)
		{
			updates[(int)i] = .();
			updates[(int)i].LayoutIndex = 0;
			updates[(int)i].ArrayIndex = i;
			updates[(int)i].TextureView = mTextureViews[i];
		}
		mBindlessBindGroup.UpdateBindless(updates);

		// The sampler is an ORDINARY binding in its own group: it is shared by every
		// texture, so there is nothing bindless about it.
		var samplerEntries = BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var samplerLayoutDesc = BindGroupLayoutDesc();
		samplerLayoutDesc.Entries = samplerEntries;
		samplerLayoutDesc.Label = "SamplerBGL";
		if (!(mDevice.CreateBindGroupLayout(samplerLayoutDesc) case .Ok(let samplerLayout)))
			return .Err;
		mSamplerLayout = samplerLayout;

		var samplerBindings = BindGroupEntry[1](BindGroupEntry.SamplerEntry(mSampler));
		var samplerGroupDesc = BindGroupDesc();
		samplerGroupDesc.Layout = mSamplerLayout;
		samplerGroupDesc.Entries = samplerBindings;
		samplerGroupDesc.Label = "SamplerBG";
		if (!(mDevice.CreateBindGroup(samplerGroupDesc) case .Ok(let samplerBindGroup)))
			return .Err;
		mSamplerBindGroup = samplerBindGroup;
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		var layouts = IBindGroupLayout[2](mBindlessLayout, mSamplerLayout);
		var pushConstants = PushConstantRange[1](
			.() { Stages = .Vertex | .Fragment, Offset = 0, Size = 16 });
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		pipelineLayoutDesc.PushConstantRanges = pushConstants;
		pipelineLayoutDesc.Label = "BindlessPL";
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		var targets = ColorTargetState[1](colorTarget);

		// NO vertex buffers: the quad's corners come from the vertex index.
		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		var fragment = FragmentState();
		fragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;
		desc.Primitive.Topology = .TriangleStrip;
		desc.Label = "BindlessPipeline";

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
		colorAttachment.ClearValue = .(0.08f, 0.06f, 0.12f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		// Bound ONCE for all four draws. Nothing below rebinds anything.
		pass.SetBindGroup(0, mBindlessBindGroup);
		pass.SetBindGroup(1, mSamplerBindGroup);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);

		// A two by two grid, one quad per texture.
		float[8] offsets = .(
			-0.45f,  0.45f,
			 0.45f,  0.45f,
			-0.45f, -0.45f,
			 0.45f, -0.45f);

		for (uint32 i < cTextureCount)
		{
			// The index is a uint and the offsets are floats, so the push block is built
			// as raw words rather than as one typed struct.
			uint32[4] pushData = .(i, 0, 0, 0);
			Internal.MemCpy(&pushData[1], &offsets[i * 2], 4);
			Internal.MemCpy(&pushData[2], &offsets[i * 2 + 1], 4);
			pass.SetPushConstants(.Vertex | .Fragment, 0, 16, &pushData[0]);
			pass.Draw(4);
		}
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
		if (mSamplerBindGroup != null) mDevice.DestroyBindGroup(ref mSamplerBindGroup);
		if (mBindlessBindGroup != null) mDevice.DestroyBindGroup(ref mBindlessBindGroup);
		if (mSamplerLayout != null) mDevice.DestroyBindGroupLayout(ref mSamplerLayout);
		if (mBindlessLayout != null) mDevice.DestroyBindGroupLayout(ref mBindlessLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
		for (uint32 i < cTextureCount)
		{
			if (mTextureViews[i] != null) mDevice.DestroyTextureView(ref mTextureViews[i]);
			if (mTextures[i] != null) mDevice.DestroyTexture(ref mTextures[i]);
		}
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
		let app = scope BindlessSample();
		return app.Run(args);
	}
}
