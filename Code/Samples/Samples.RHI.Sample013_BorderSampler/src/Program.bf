using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample013_BorderSampler;

/// Three quads sampled with ClampToBorder and three different border colours.
///
/// The quads' texture coordinates run from -0.5 to 1.5, so most of each quad is OUTSIDE the
/// texture and the border colour is what fills it. Side by side, transparent black, opaque
/// black and opaque white make the difference plain.
class BorderSamplerSample : SampleApp
{
	private const String cShaderSource = """
		Texture2D gTexture : register(t0, space0);
		SamplerState gSampler : register(s0, space0);
		cbuffer UBO : register(b0, space1) { float4 QuadOffset; };
		struct VSInput { float3 Position : TEXCOORD0; float2 TexCoord : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float2 TexCoord : TEXCOORD0; };
		PSInput VSMain(VSInput input) {
		    PSInput output;
		    output.Position = float4(input.Position.xy + QuadOffset.xy, input.Position.z, 1.0);
		    output.TexCoord = input.TexCoord;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET {
		    return gTexture.Sample(gSampler, input.TexCoord);
		}
		""";

	/// Texture coordinates from -0.5 to 1.5, so the texture occupies the middle half of
	/// each quad and the border fills the rest.
	private static float[20] sQuadVertices = .(
		-0.25f, -0.25f, 0.0f,   -0.5f, -0.5f,
		 0.25f, -0.25f, 0.0f,    1.5f, -0.5f,
		 0.25f,  0.25f, 0.0f,    1.5f,  1.5f,
		-0.25f,  0.25f, 0.0f,   -0.5f,  1.5f);
	private static uint16[6] sQuadIndices = .(0, 1, 2, 0, 2, 3);

	private const uint32 cTextureWidth = 8;
	private const uint32 cTextureHeight = 8;
	/// DX12's constant buffer view alignment, which is the stride between the three slots.
	private const uint32 cUniformStride = 256;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mUniformBuffer = null;
	private void* mUniformMapped = null;
	private ITexture mTexture = null;
	private ITextureView mTextureView = null;
	private ISampler[3] mSamplers = .(null, null, null);
	private IBindGroup[3] mTextureBindGroups = .(null, null, null);
	private IBindGroupLayout mTextureLayout = null;
	private IBindGroupLayout mUniformLayout = null;
	private IBindGroup mUniformBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample013 - Border Sampler";

	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.BorderSampling = true;
			return features;
		}
	}

	protected override Result<void> OnInit()
	{
		// Checked as well as requested: a backend that ignored the request would otherwise
		// fail later at sampler creation with nothing explaining why.
		if (!mDevice.Features.BorderSampling)
		{
			Console.Error.WriteLine("Sample013: this device does not support border sampling");
			return .Err;
		}

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

		if (CreateBuffers() case .Err)
			return .Err;
		if (CreateTexture() case .Err)
			return .Err;
		if (CreateSamplersAndBindings() case .Err)
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

	private Result<void> CreateBuffers()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sQuadVertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = sizeof(uint16) * sQuadIndices.Count;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;

		// Three slots, one per quad, written ONCE: the offsets never change, so only the
		// dynamic offset differs between the three draws.
		var uniformDesc = BufferDesc();
		uniformDesc.Size = 3 * cUniformStride;
		uniformDesc.Usage = .Uniform;
		uniformDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(uniformDesc) case .Ok(let uniformBuffer)))
			return .Err;
		mUniformBuffer = uniformBuffer;
		mUniformMapped = mUniformBuffer.Map();

		float[4] left = .(-0.55f, 0.0f, 0.0f, 0.0f);
		float[4] middle = .(0.0f, 0.0f, 0.0f, 0.0f);
		float[4] right = .(0.55f, 0.0f, 0.0f, 0.0f);
		Internal.MemCpy((uint8*)mUniformMapped, &left[0], 16);
		Internal.MemCpy((uint8*)mUniformMapped + cUniformStride, &middle[0], 16);
		Internal.MemCpy((uint8*)mUniformMapped + cUniformStride * 2, &right[0], 16);
		return .Ok;
	}

	private Result<void> CreateTexture()
	{
		var desc = TextureDesc();
		desc.Format = .RGBA8Unorm;
		desc.Width = cTextureWidth;
		desc.Height = cTextureHeight;
		desc.MipLevelCount = 1;
		desc.Usage = .Sampled | .CopyDst;
		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return .Err;
		mTexture = texture;

		// Small and high contrast, so where the texture ends and the border begins is
		// unmistakable.
		let pixels = scope uint8[cTextureWidth * cTextureHeight * 4];
		for (uint32 y < cTextureHeight)
		{
			for (uint32 x < cTextureWidth)
			{
				let at = (y * cTextureWidth + x) * 4;
				let white = ((x + y) % 2) == 0;
				pixels[(int)at + 0] = white ? 255 : 220;
				pixels[(int)at + 1] = white ? 255 : 60;
				pixels[(int)at + 2] = white ? 255 : 60;
				pixels[(int)at + 3] = 255;
			}
		}

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sQuadVertices[0], sizeof(float) * sQuadVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sQuadIndices[0], sizeof(uint16) * sQuadIndices.Count));
		var layout = TextureDataLayout();
		layout.BytesPerRow = cTextureWidth * 4;
		layout.RowsPerImage = cTextureHeight;
		batch.WriteTexture(mTexture, pixels, layout, .(cTextureWidth, cTextureHeight, 1));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(mTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mTextureView = view;
		return .Ok;
	}

	private Result<void> CreateSamplersAndBindings()
	{
		SamplerBorderColor[3] borderColors = .(.TransparentBlack, .OpaqueBlack, .OpaqueWhite);

		var textureEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var textureLayoutDesc = BindGroupLayoutDesc();
		textureLayoutDesc.Entries = textureEntries;
		if (!(mDevice.CreateBindGroupLayout(textureLayoutDesc) case .Ok(let textureLayout)))
			return .Err;
		mTextureLayout = textureLayout;

		for (int i < 3)
		{
			var samplerDesc = SamplerDesc();
			// Nearest, so the border does not blend into the texture and blur exactly the
			// edge under examination.
			samplerDesc.MinFilter = .Nearest;
			samplerDesc.MagFilter = .Nearest;
			samplerDesc.AddressU = .ClampToBorder;
			samplerDesc.AddressV = .ClampToBorder;
			samplerDesc.AddressW = .ClampToBorder;
			samplerDesc.BorderColor = borderColors[i];
			if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
				return .Err;
			mSamplers[i] = sampler;

			var entries = BindGroupEntry[2](
				BindGroupEntry.TextureEntry(mTextureView),
				BindGroupEntry.SamplerEntry(mSamplers[i]));
			var groupDesc = BindGroupDesc();
			groupDesc.Layout = mTextureLayout;
			groupDesc.Entries = entries;
			if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
				return .Err;
			mTextureBindGroups[i] = bindGroup;
		}

		var uniformEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
		uniformEntry.HasDynamicOffset = true;
		var uniformEntries = BindGroupLayoutEntry[1](uniformEntry);
		var uniformLayoutDesc = BindGroupLayoutDesc();
		uniformLayoutDesc.Entries = uniformEntries;
		if (!(mDevice.CreateBindGroupLayout(uniformLayoutDesc) case .Ok(let uniformLayout)))
			return .Err;
		mUniformLayout = uniformLayout;

		var uniformBindings = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mUniformBuffer, 0, 16));
		var uniformGroupDesc = BindGroupDesc();
		uniformGroupDesc.Layout = mUniformLayout;
		uniformGroupDesc.Entries = uniformBindings;
		if (!(mDevice.CreateBindGroup(uniformGroupDesc) case .Ok(let uniformBindGroup)))
			return .Err;
		mUniformBindGroup = uniformBindGroup;
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		var layouts = IBindGroupLayout[2](mTextureLayout, mUniformLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x2, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 20;
		vertexLayout.Attributes = attributes;

		// BLENDED, so the transparent black border shows as the clear colour rather than
		// as black. Without it all three quads would look the same in the border region.
		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		colorTarget.Blend = BlendState.AlphaBlend;

		var buffers = VertexBufferLayout[1](vertexLayout);
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;
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
		colorAttachment.ClearValue = .(0.2f, 0.2f, 0.25f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// The SAME geometry three times: only the sampler and the position offset change.
		for (int i < 3)
		{
			pass.SetBindGroup(0, mTextureBindGroups[i]);
			uint32 dynamicOffset = (uint32)i * cUniformStride;
			pass.SetBindGroup(1, mUniformBindGroup, .(&dynamicOffset, 1));
			pass.DrawIndexed(6);
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
		if (mUniformBindGroup != null) mDevice.DestroyBindGroup(ref mUniformBindGroup);
		for (int i < 3)
		{
			if (mTextureBindGroups[i] != null) mDevice.DestroyBindGroup(ref mTextureBindGroups[i]);
			if (mSamplers[i] != null) mDevice.DestroySampler(ref mSamplers[i]);
		}
		if (mUniformLayout != null) mDevice.DestroyBindGroupLayout(ref mUniformLayout);
		if (mTextureLayout != null) mDevice.DestroyBindGroupLayout(ref mTextureLayout);
		if (mTextureView != null) mDevice.DestroyTextureView(ref mTextureView);
		if (mTexture != null) mDevice.DestroyTexture(ref mTexture);
		if (mUniformBuffer != null) mDevice.DestroyBuffer(ref mUniformBuffer);
		if (mIndexBuffer != null) mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
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
		let app = scope BorderSamplerSample();
		return app.Run(args);
	}
}
