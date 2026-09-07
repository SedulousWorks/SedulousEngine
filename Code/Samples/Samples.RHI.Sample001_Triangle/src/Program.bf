using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample001_Triangle;

/// A coloured triangle from a vertex buffer through a render pipeline.
///
/// The smallest thing that exercises the whole path: compile, upload, build a pipeline,
/// record a pass, submit, present.
class TriangleSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput {
		    float3 Position : TEXCOORD0;
		    float3 Color    : TEXCOORD1;
		};
		struct PSInput {
		    float4 Position : SV_POSITION;
		    float3 Color    : TEXCOORD0;
		};
		PSInput VSMain(VSInput input) {
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.Color = input.Color;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET {
		    return float4(input.Color, 1.0);
		}
		""";

	/// Position then colour, interleaved, one vertex per row.
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

	protected override StringView Title => "Sample001 - Triangle";

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Vertex,
			"VSMain", "TriangleVS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "TrianglePS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateVertexBuffer() case .Err)
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

	private Result<void> CreateVertexBuffer()
	{
		var desc = BufferDesc();
		desc.Size = sizeof(float) * sVertexData.Count;
		desc.Usage = .Vertex | .CopyDst;
		desc.Memory = .GpuOnly;
		desc.Label = "TriangleVB";
		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
			return .Err;
		mVertexBuffer = buffer;

		// Device local memory cannot be written directly, so the data goes through a
		// staging batch. Submit BLOCKS, which is what a one time upload at startup wants.
		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0, .((uint8*)&sVertexData[0], (int)desc.Size));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		// The shaders bind nothing, but a pipeline still needs a layout to be built from.
		var bindGroupLayoutDesc = BindGroupLayoutDesc();
		bindGroupLayoutDesc.Label = "EmptyBGL";
		if (!(mDevice.CreateBindGroupLayout(bindGroupLayoutDesc) case .Ok(let bindGroupLayout)))
			return .Err;
		mBindGroupLayout = bindGroupLayout;

		var layouts = IBindGroupLayout[1](mBindGroupLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		pipelineLayoutDesc.Label = "TrianglePL";
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		// Position at offset zero, colour twelve bytes later, both three floats.
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
		desc.Label = "TrianglePipeline";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;
		return .Ok;
	}

	protected override void OnRender()
	{
		// Waits for the PREVIOUS frame before reusing the pool, since resetting it while
		// the GPU is still reading its buffers is a use after free.
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		// A freshly acquired image has undefined contents, so there is nothing to preserve.
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.1f, 0.1f, 0.15f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.Draw(3);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		// The fence signalling overload, which is also what picks up the swap chain's
		// acquire and present semaphores.
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);

		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mFence != null)
			mDevice.DestroyFence(ref mFence);
		if (mPool != null)
			mDevice.DestroyCommandPool(ref mPool);
		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mPixelShader != null)
			mDevice.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null)
			mDevice.DestroyShaderModule(ref mVertexShader);
		if (mVertexBuffer != null)
			mDevice.DestroyBuffer(ref mVertexBuffer);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope TriangleSample();
		return app.Run(args);
	}
}
