using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample030_RenderBundles;

/// A triangle recorded into a RENDER BUNDLE and executed from a pass.
///
/// A bundle is a reusable piece of a pass: the draws are recorded once and then replayed
/// without re-issuing each command. A pass that executes bundles declares that its body
/// comes from them, which is what lets a backend implement them as secondary command
/// buffers.
class RenderBundlesSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput { float3 Position : TEXCOORD0; float3 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float3 Color : TEXCOORD0; };
		PSInput VSMain(VSInput input) {
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.Color = input.Color;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET { return float4(input.Color, 1.0); }
		""";

	private static float[18] sVertexData = .(
		 0.0f,  0.5f, 0.0f,   1.0f, 0.0f, 0.0f,
		 0.5f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,
		-0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IBuffer mVertexBuffer = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample030 - Render Bundles";

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Vertex,
			"VSMain", "BundleVS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "BundlePS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sVertexData.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertexData[0], sizeof(float) * sVertexData.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

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

	private Result<void> CreatePipeline()
	{
		var bindGroupLayoutDesc = BindGroupLayoutDesc();
		if (!(mDevice.CreateBindGroupLayout(bindGroupLayoutDesc) case .Ok(let bindGroupLayout)))
			return .Err;
		mBindGroupLayout = bindGroupLayout;

		var layouts = IBindGroupLayout[1](mBindGroupLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x3, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 24;
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
		desc.Primitive.Topology = .TriangleList;

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

		// The bundle declares the formats and size it will be replayed against, because a
		// backend recording it as a secondary buffer has to know them BEFORE the pass it
		// will run inside has begun.
		var bundleDesc = RenderBundleDesc();
		bundleDesc.ColorFormats[0] = mSwapChain.Format;
		bundleDesc.ColorFormatCount = 1;
		bundleDesc.Width = mWidth;
		bundleDesc.Height = mHeight;
		bundleDesc.Label = "TriangleBundle";

		IRenderBundle bundle = null;
		if (let bundleEncoder = encoder.CreateRenderBundleEncoder(bundleDesc))
		{
			bundleEncoder.SetPipeline(mPipeline);
			bundleEncoder.SetVertexBuffer(0, mVertexBuffer, 0);
			bundleEncoder.Draw(3);
			bundle = bundleEncoder.Finish();
		}

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.1f, 0.1f, 0.15f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		// The pass body comes from BUNDLES rather than from inline commands, which the
		// pass has to declare up front.
		passDesc.Contents = .SecondaryCommandBuffers;

		let pass = encoder.BeginRenderPass(passDesc);
		// Viewport and scissor still come from the PASS: a bundle inherits no dynamic
		// state, so setting them inside it would not carry.
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		if (bundle != null)
		{
			var bundles = IRenderBundle[1](bundle);
			pass.ExecuteBundles(bundles);
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
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
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
		let app = scope RenderBundlesSample();
		return app.Run(args);
	}
}
