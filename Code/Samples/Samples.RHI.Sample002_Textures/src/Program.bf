using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample002_Textures;

/// A textured quad: a checkerboard sampled through a bind group.
///
/// What Sample001 adds up to plus the binding model, which is the part every later sample
/// builds on.
class TextureSample : SampleApp
{
	private const String cShaderSource = """
		Texture2D gTexture : register(t0, space0);
		SamplerState gSampler : register(s0, space0);
		struct VSInput { float3 Position : TEXCOORD0; float2 TexCoord : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float2 TexCoord : TEXCOORD0; };
		PSInput VSMain(VSInput input) {
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.TexCoord = input.TexCoord;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET {
		    return gTexture.Sample(gSampler, input.TexCoord);
		}
		""";

	/// Position then texture coordinate, one vertex per row.
	private static float[20] sVertexData = .(
		-0.5f,  0.5f, 0.0f,   0.0f, 0.0f,
		 0.5f,  0.5f, 0.0f,   1.0f, 0.0f,
		 0.5f, -0.5f, 0.0f,   1.0f, 1.0f,
		-0.5f, -0.5f, 0.0f,   0.0f, 1.0f);
	private static uint16[6] sIndexData = .(0, 1, 2, 0, 2, 3);

	private const uint32 cTextureWidth = 64;
	private const uint32 cTextureHeight = 64;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private ITexture mTexture = null;
	private ITextureView mTextureView = null;
	private ISampler mSampler = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample002 - Textures";

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Vertex,
			"VSMain", "QuadVS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "QuadPS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateGeometry() case .Err)
			return .Err;
		if (CreateTexture() case .Err)
			return .Err;
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

	private Result<void> CreateGeometry()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sVertexData.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = sizeof(uint16) * sIndexData.Count;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;
		return .Ok;
	}

	private Result<void> CreateTexture()
	{
		var desc = TextureDesc();
		desc.Format = .RGBA8Unorm;
		desc.Width = cTextureWidth;
		desc.Height = cTextureHeight;
		desc.Usage = .Sampled | .CopyDst;
		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return .Err;
		mTexture = texture;

		// Eight pixel squares, so nearest filtering shows crisp edges and a wrong sampler
		// or a wrong stride is obvious rather than subtle.
		let pixels = scope uint8[cTextureWidth * cTextureHeight * 4];
		for (uint32 y < cTextureHeight)
		{
			for (uint32 x < cTextureWidth)
			{
				let light = (((x / 8) + (y / 8)) % 2) == 0;
				let at = (y * cTextureWidth + x) * 4;
				pixels[(int)at + 0] = light ? 255 : 50;
				pixels[(int)at + 1] = light ? 255 : 50;
				pixels[(int)at + 2] = light ? 255 : 200;
				pixels[(int)at + 3] = 255;
			}
		}

		// One batch for everything, which is what it is for: three writes and one
		// submission rather than three.
		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertexData[0], sizeof(float) * sVertexData.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sIndexData[0], sizeof(uint16) * sIndexData.Count));

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

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Nearest;
		samplerDesc.MagFilter = .Nearest;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		// A texture and a sampler both at binding zero: they are different HLSL register
		// classes, t0 and s0, which the backend's shifts push apart.
		var layoutEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let bindGroupLayout)))
			return .Err;
		mBindGroupLayout = bindGroupLayout;

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(mTextureView),
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
		colorTarget.WriteMask = .All;

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
		pass.SetBindGroup(0, mBindGroup);
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
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null) mDevice.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
		if (mTextureView != null) mDevice.DestroyTextureView(ref mTextureView);
		if (mTexture != null) mDevice.DestroyTexture(ref mTexture);
		if (mPixelShader != null) mDevice.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null) mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope TextureSample();
		return app.Run(args);
	}
}
