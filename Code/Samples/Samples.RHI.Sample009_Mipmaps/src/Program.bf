using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample009_Mipmaps;

/// A checkerboard floor receding into the distance, sampled through a full mip chain.
///
/// A receding plane is the case mipmaps exist for: without them the distant end aliases into
/// noise. The chain is GENERATED on the GPU rather than uploaded, which is the part being
/// exercised.
class MipmapSample : SampleApp
{
	private const String cShaderSource = """
		Texture2D gTexture : register(t0, space0);
		SamplerState gSampler : register(s0, space0);
		cbuffer UBO : register(b0, space1) { row_major float4x4 MVP; };
		struct VSInput { float3 Position : TEXCOORD0; float2 TexCoord : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float2 TexCoord : TEXCOORD0; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = mul(float4(i.Position,1), MVP); o.TexCoord = i.TexCoord; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return gTexture.Sample(gSampler, i.TexCoord); }
		""";

	/// A floor plane, position then texture coordinate. The far edge runs to z = -20 with
	/// texture coordinates up to 10, so the checker crowds into a few pixels there.
	private static float[20] sVertices = .(
		-4.0f, 0.0f,   0.0f,   0.0f,  0.0f,
		 4.0f, 0.0f,   0.0f,   8.0f,  0.0f,
		 4.0f, 0.0f, -20.0f,   8.0f, 10.0f,
		-4.0f, 0.0f, -20.0f,   0.0f, 10.0f);
	private static uint16[6] sIndices = .(0, 1, 2, 0, 2, 3);

	private const uint32 cTextureWidth = 256;
	private const uint32 cTextureHeight = 256;
	/// 256 halves down to 1 in nine levels.
	private const uint32 cMipCount = 9;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mUniformBuffer = null;
	private void* mUniformMapped = null;
	private ITexture mTexture = null;
	private ITextureView mTextureView = null;
	private ISampler mSampler = null;
	private IBindGroupLayout mTextureLayout = null;
	private IBindGroupLayout mUniformLayout = null;
	private IBindGroup mTextureBindGroup = null;
	private IBindGroup mUniformBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private DepthBuffer mDepthBuffer = new DepthBuffer() ~ delete _;

	protected override StringView Title => "Sample009 - Mipmaps";

	protected override void OnResize(uint32 width, uint32 height)
	{
		mDepthBuffer.Recreate(mDevice, width, height).IgnoreError();
	}

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

		if (CreateBuffers() case .Err)
			return .Err;
		if (CreateTexture() case .Err)
			return .Err;
		if (CreateBindings() case .Err)
			return .Err;

		mDepthBuffer.Recreate(mDevice, mWidth, mHeight).IgnoreError();

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
		vertexDesc.Size = sizeof(float) * sVertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = sizeof(uint16) * sIndices.Count;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;

		var uniformDesc = BufferDesc();
		uniformDesc.Size = 64;
		uniformDesc.Usage = .Uniform;
		uniformDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(uniformDesc) case .Ok(let uniformBuffer)))
			return .Err;
		mUniformBuffer = uniformBuffer;
		mUniformMapped = mUniformBuffer.Map();
		return .Ok;
	}

	private Result<void> CreateTexture()
	{
		// CopySrc AND CopyDst: generating the chain blits each level from the one above,
		// so every level is both a source and a destination in turn.
		var desc = TextureDesc();
		desc.Format = .RGBA8Unorm;
		desc.Width = cTextureWidth;
		desc.Height = cTextureHeight;
		desc.MipLevelCount = cMipCount;
		desc.Usage = .Sampled | .CopySrc | .CopyDst | .RenderTarget;
		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return .Err;
		mTexture = texture;

		let pixels = scope uint8[cTextureWidth * cTextureHeight * 4];
		for (uint32 y < cTextureHeight)
		{
			for (uint32 x < cTextureWidth)
			{
				let light = (((x / 16) + (y / 16)) % 2) == 0;
				let at = (y * cTextureWidth + x) * 4;
				pixels[at + 0] = light ? 255 : 30;
				pixels[at + 1] = light ? 255 : 30;
				pixels[at + 2] = light ? 255 : 200;
				pixels[at + 3] = 255;
			}
		}

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertices[0], sizeof(float) * sVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sIndices[0], sizeof(uint16) * sIndices.Count));
		var layout = TextureDataLayout();
		layout.BytesPerRow = cTextureWidth * 4;
		layout.RowsPerImage = cTextureHeight;
		// Only the BASE level is uploaded; the rest are derived from it below.
		batch.WriteTexture(mTexture, pixels, layout, .(cTextureWidth, cTextureHeight, 1));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		if (GenerateMipChain() case .Err)
			return .Err;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		// The view spans EVERY level, or the sampler has nothing to drop to.
		viewDesc.MipLevelCount = cMipCount;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(mTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mTextureView = view;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		// Linear BETWEEN levels as well as within them, so the transition does not band.
		samplerDesc.MipmapFilter = .Linear;
		samplerDesc.MaxLod = (float)cMipCount;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;
		return .Ok;
	}

	/// Builds the chain on the GPU and leaves every level readable by a shader.
	///
	/// Its own throwaway pool and a blocking wait, because this happens once at startup and
	/// the frame loop's pool has not been created yet.
	private Result<void> GenerateMipChain()
	{
		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return .Err;
		defer mDevice.DestroyCommandPool(ref pool);

		if (!(pool.CreateEncoder() case .Ok(var encoder)))
			return .Err;

		encoder.GenerateMipmaps(mTexture);

		// Generating leaves EVERY level as a copy source, which is not something a shader
		// can sample, so all of them are transitioned together.
		var barrier = TextureBarrier();
		barrier.Texture = mTexture;
		barrier.OldState = .CopySrc;
		barrier.NewState = .ShaderRead;
		barrier.BaseMipLevel = 0;
		barrier.MipLevelCount = cMipCount;
		barrier.BaseArrayLayer = 0;
		barrier.ArrayLayerCount = 1;
		var group = BarrierGroup();
		group.TextureBarriers = .(&barrier, 1);
		encoder.Barrier(group);

		var buffers = ICommandBuffer[1](encoder.Finish());
		mGraphicsQueue.Submit(buffers);
		mGraphicsQueue.WaitIdle();
		pool.DestroyEncoder(ref encoder);
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		var textureEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var textureLayoutDesc = BindGroupLayoutDesc();
		textureLayoutDesc.Entries = textureEntries;
		if (!(mDevice.CreateBindGroupLayout(textureLayoutDesc) case .Ok(let textureLayout)))
			return .Err;
		mTextureLayout = textureLayout;

		var textureBindings = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(mTextureView),
			BindGroupEntry.SamplerEntry(mSampler));
		var textureGroupDesc = BindGroupDesc();
		textureGroupDesc.Layout = mTextureLayout;
		textureGroupDesc.Entries = textureBindings;
		if (!(mDevice.CreateBindGroup(textureGroupDesc) case .Ok(let textureBindGroup)))
			return .Err;
		mTextureBindGroup = textureBindGroup;

		var uniformEntries = BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var uniformLayoutDesc = BindGroupLayoutDesc();
		uniformLayoutDesc.Entries = uniformEntries;
		if (!(mDevice.CreateBindGroupLayout(uniformLayoutDesc) case .Ok(let uniformLayout)))
			return .Err;
		mUniformLayout = uniformLayout;

		var uniformBindings = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mUniformBuffer, 0, 64));
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

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;

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
		var depthStencil = DepthStencilState();
		depthStencil.Format = .Depth24PlusStencil8;
		depthStencil.DepthCompare = .Less;
		desc.DepthStencil = depthStencil;

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

		let aspect = (float)mWidth / (float)mHeight;
		// Low and looking down the plane, which is what makes the far end recede sharply
		// enough for the mip levels to matter.
		var view = Float4x4.LookAtRH(.(0, 2, 2), .(0, 0, -5), .(0, 1, 0));
		var projection = Float4x4.PerspectiveFovRH(Math.DegreesToRadians(60.0f), aspect,
			0.1f, 100.0f);
		var mvp = view * projection;
		Internal.MemCpy(mUniformMapped, mvp.Data, 64);

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mDepthBuffer.Texture, .Undefined, .DepthStencilWrite);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.1f, 0.1f, 0.15f, 1.0f);

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthBuffer.View;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = 1.0f;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetBindGroup(0, mTextureBindGroup);
		pass.SetBindGroup(1, mUniformBindGroup);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexed(6);
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
		mDepthBuffer.Destroy(mDevice);
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mUniformBindGroup != null) mDevice.DestroyBindGroup(ref mUniformBindGroup);
		if (mTextureBindGroup != null) mDevice.DestroyBindGroup(ref mTextureBindGroup);
		if (mUniformLayout != null) mDevice.DestroyBindGroupLayout(ref mUniformLayout);
		if (mTextureLayout != null) mDevice.DestroyBindGroupLayout(ref mTextureLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
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
		let app = scope MipmapSample();
		return app.Run(args);
	}
}
