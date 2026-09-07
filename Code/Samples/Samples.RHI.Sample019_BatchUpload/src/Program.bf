using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample019_BatchUpload;

/// One transfer batch carrying vertices, indices and a texture, submitted ASYNCHRONOUSLY.
///
/// SubmitAsync signals a fence rather than blocking, so the frame loop starts immediately
/// and polls the fence to find out when the data arrived. Nothing is drawn until it has,
/// which is what a real loading path does instead of stalling at startup.
class BatchUploadSample : SampleApp
{
	private const String cShaderSource = """
		Texture2D gTexture : register(t0, space0);
		SamplerState gSampler : register(s0, space0);
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
		cbuffer Transform : register(b0, space0)
		{
		    float Time;
		    float Pad0;
		    float Pad1;
		    float Pad2;
		};
		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    float c = cos(Time * 0.5);
		    float s = sin(Time * 0.5);
		    float3 p = input.Position;
		    float x = p.x * c - p.y * s;
		    float y = p.x * s + p.y * c;
		    output.Position = float4(x, y, p.z, 1.0);
		    output.TexCoord = input.TexCoord;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return gTexture.Sample(gSampler, input.TexCoord);
		}
		""";

	private const uint32 cTextureSize = 128;
	/// How deep the escape test goes, which is also what the colour ramp is scaled by.
	private const int cMaxIterations = 64;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private ITexture mTexture = null;
	private ITextureView mTextureView = null;
	private ISampler mSampler = null;
	private IBuffer mTransformBuffer = null;
	private void* mTransformMapped = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFrameFence = null;
	private uint64 mFrameFenceValue = 0;

	private IFence mUploadFence = null;
	private uint64 mUploadFenceValue = 0;
	private bool mUploadComplete = false;

	protected override StringView Title => "Sample019 - Batch Upload (Async Transfer)";

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

		if (CreateResources() case .Err)
			return .Err;
		if (CreateBindings() case .Err)
			return .Err;
		if (CreatePipeline() case .Err)
			return .Err;

		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return .Err;
		mPool = pool;
		if (!(mDevice.CreateFence(0) case .Ok(let frameFence)))
			return .Err;
		mFrameFence = frameFence;
		if (!(mDevice.CreateFence(0) case .Ok(let uploadFence)))
			return .Err;
		mUploadFence = uploadFence;

		return DoBatchUpload();
	}

	private Result<void> CreateResources()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = 80;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = 12;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cTextureSize;
		textureDesc.Height = cTextureSize;
		textureDesc.MipLevelCount = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(mTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mTextureView = view;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		var transformDesc = BufferDesc();
		transformDesc.Size = 256;
		transformDesc.Usage = .Uniform;
		transformDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(transformDesc) case .Ok(let transformBuffer)))
			return .Err;
		mTransformBuffer = transformBuffer;
		mTransformMapped = mTransformBuffer.Map();
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		var layoutEntries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment),
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mBindGroupLayout = layout;

		var entries = BindGroupEntry[3](
			BindGroupEntry.TextureEntry(mTextureView),
			BindGroupEntry.SamplerEntry(mSampler),
			BindGroupEntry.BufferEntry(mTransformBuffer, 0, 16));
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

	/// Stages everything into one batch and submits it WITHOUT waiting.
	private Result<void> DoBatchUpload()
	{
		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		defer mGraphicsQueue.DestroyTransferBatch(ref batch);

		float[20] vertices = .(
			-0.6f,  0.6f, 0.0f,   0.0f, 0.0f,
			 0.6f,  0.6f, 0.0f,   1.0f, 0.0f,
			 0.6f, -0.6f, 0.0f,   1.0f, 1.0f,
			-0.6f, -0.6f, 0.0f,   0.0f, 1.0f);
		batch.WriteBuffer(mVertexBuffer, 0, .((uint8*)&vertices[0], 80));

		uint16[6] indices = .(0, 1, 2, 0, 2, 3);
		batch.WriteBuffer(mIndexBuffer, 0, .((uint8*)&indices[0], 12));

		let textureBytes = cTextureSize * cTextureSize * 4;
		let pixels = scope uint8[textureBytes];
		GenerateFractal(pixels);

		var layout = TextureDataLayout();
		layout.BytesPerRow = cTextureSize * 4;
		layout.RowsPerImage = cTextureSize;
		batch.WriteTexture(mTexture, pixels, layout, .(cTextureSize, cTextureSize, 1));

		// ASYNCHRONOUS: this returns before the GPU has copied anything, and the fence is
		// what says when it has. The staging buffer stays alive because the batch owns it
		// and waits on the fence before freeing it.
		mUploadFenceValue = 1;
		if (batch.SubmitAsync(mUploadFence, mUploadFenceValue) case .Err)
			return .Err;

		Console.WriteLine(scope $"Batch upload submitted asynchronously (VB: 80B, IB: 12B, Tex: {textureBytes}B)");
		return .Ok;
	}

	/// Something expensive enough to be worth uploading rather than computing per frame.
	private static void GenerateFractal(Span<uint8> pixels)
	{
		for (uint32 y < cTextureSize)
		{
			for (uint32 x < cTextureSize)
			{
				let cr = (float)x / (float)cTextureSize * 3.0f - 2.0f;
				let ci = (float)y / (float)cTextureSize * 2.4f - 1.2f;
				var zr = 0.0f;
				var zi = 0.0f;
				int iteration = 0;
				for (iteration = 0; iteration < cMaxIterations; iteration++)
				{
					let nextR = zr * zr - zi * zi + cr;
					let nextI = 2.0f * zr * zi + ci;
					zr = nextR;
					zi = nextI;
					if (zr * zr + zi * zi > 4.0f)
						break;
				}

				let at = (y * cTextureSize + x) * 4;
				if (iteration == cMaxIterations)
				{
					// Inside the set: near black, so the boundary stands out.
					pixels[at + 0] = 10;
					pixels[at + 1] = 10;
					pixels[at + 2] = 30;
					pixels[at + 3] = 255;
					continue;
				}
				let t = (float)iteration / (float)cMaxIterations;
				pixels[at + 0] = (uint8)(t * 200 + 55);
				pixels[at + 1] = (uint8)(t * t * 255);
				pixels[at + 2] = (uint8)(Math.Sqrt(t) * 255);
				pixels[at + 3] = 255;
			}
		}
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		// POLLED, not waited on: the frame loop keeps running while the upload is still in
		// flight, which is the whole point of submitting it asynchronously.
		if (!mUploadComplete && (mUploadFence.CompletedValue() >= mUploadFenceValue))
		{
			mUploadComplete = true;
			Console.WriteLine("Batch upload completed, so rendering is enabled");
		}

		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		float[4] transform = .(mTotalTime, 0, 0, 0);
		Internal.MemCpy(mTransformMapped, &transform[0], 16);

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		// The pass runs either way, so the window is cleared and responsive while the
		// upload is still in flight. Only the DRAW waits for the data.
		if (mUploadComplete)
		{
			pass.SetPipeline(mPipeline);
			pass.SetBindGroup(0, mBindGroup);
			pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
			pass.SetScissor(0, 0, mWidth, mHeight);
			pass.SetVertexBuffer(0, mVertexBuffer, 0);
			pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
			pass.DrawIndexed(6);
		}
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFrameFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mUploadFence != null) mDevice.DestroyFence(ref mUploadFence);
		if (mFrameFence != null) mDevice.DestroyFence(ref mFrameFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null) mDevice.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mTransformBuffer != null) mDevice.DestroyBuffer(ref mTransformBuffer);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
		if (mTextureView != null) mDevice.DestroyTextureView(ref mTextureView);
		if (mTexture != null) mDevice.DestroyTexture(ref mTexture);
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
		let app = scope BatchUploadSample();
		return app.Run(args);
	}
}
