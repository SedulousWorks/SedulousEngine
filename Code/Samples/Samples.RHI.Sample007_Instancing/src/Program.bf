using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample007_Instancing;

/// Per instance data, laid out to match the shader's second vertex buffer.
///
/// A struct rather than loose floats, because its size IS the instance stride the pipeline
/// declares, and keeping the two in one place is what stops them drifting apart.
[CRepr]
struct InstanceData
{
	public float[2] Offset;
	public float[4] Color;
}

/// Sixty four wobbling quads from ONE draw call.
///
/// The geometry is uploaded once and never changes; only the instance buffer moves. The two
/// are separate vertex buffers with different step modes, which is what makes the difference
/// between a per vertex and a per instance attribute.
class InstancingSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput
		{
		    float3 Position  : TEXCOORD0;
		    float2 Offset    : TEXCOORD1;
		    float4 InstColor : TEXCOORD2;
		};
		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float4 Color    : COLOR0;
		};
		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = float4(input.Position.xy + input.Offset, input.Position.z, 1.0);
		    output.Color = input.InstColor;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return input.Color;
		}
		""";

	private const int cInstanceCount = 64;

	/// A small unit quad, positions only. Everything that differs between instances lives
	/// in the instance buffer.
	private static float[12] sQuadVertices = .(
		-0.04f, -0.04f, 0.0f,
		 0.04f, -0.04f, 0.0f,
		 0.04f,  0.04f, 0.0f,
		-0.04f,  0.04f, 0.0f);
	private static uint16[6] sQuadIndices = .(0, 1, 2, 0, 2, 3);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mInstanceBuffer = null;
	private void* mInstanceMapped = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample007 - Instanced Rendering";

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

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sQuadVertices[0], sizeof(float) * sQuadVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sQuadIndices[0], sizeof(uint16) * sQuadIndices.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		// CpuToGpu and mapped, because every instance moves every frame.
		var instanceDesc = BufferDesc();
		instanceDesc.Size = (uint64)cInstanceCount * sizeof(InstanceData);
		instanceDesc.Usage = .Vertex;
		instanceDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(instanceDesc) case .Ok(let instanceBuffer)))
			return .Err;
		mInstanceBuffer = instanceBuffer;
		mInstanceMapped = mInstanceBuffer.Map();
		if (mInstanceMapped == null)
			return .Err;
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		// Slot 0 steps PER VERTEX: the same four corners for every instance.
		var vertexAttributes = VertexAttribute[1](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 12;
		vertexLayout.StepMode = .Vertex;
		vertexLayout.Attributes = vertexAttributes;

		// Slot 1 steps PER INSTANCE: advanced once per quad rather than once per corner,
		// which is the whole mechanism.
		var instanceAttributes = VertexAttribute[2](
			.() { Format = .Float32x2, Offset = 0, ShaderLocation = 1 },
			.() { Format = .Float32x4, Offset = 8, ShaderLocation = 2 });
		var instanceLayout = VertexBufferLayout();
		instanceLayout.Stride = (uint32)sizeof(InstanceData);
		instanceLayout.StepMode = .Instance;
		instanceLayout.Attributes = instanceAttributes;

		var buffers = VertexBufferLayout[2](vertexLayout, instanceLayout);

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
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

	/// Rewrites every instance for this frame straight into the mapped buffer.
	private void UpdateInstances()
	{
		let data = (InstanceData*)mInstanceMapped;
		let gridSize = (int)Math.Sqrt((float)cInstanceCount);

		for (int i < cInstanceCount)
		{
			let row = i / gridSize;
			let column = i % gridSize;

			let spacing = 2.0f / (float)gridSize;
			let baseX = -1.0f + spacing * 0.5f + column * spacing;
			let baseY = -1.0f + spacing * 0.5f + row * spacing;

			// Each wobbles on its own phase, so a buffer that stopped updating shows as a
			// frozen grid rather than a still image.
			let phase = mTotalTime * 2.0f + i * 0.3f;
			data[i].Offset[0] = baseX + Math.Sin(phase) * 0.02f;
			data[i].Offset[1] = baseY + Math.Cos(phase * 1.3f) * 0.02f;

			// A hue sweep across the grid: three sines a third of a turn apart.
			let t = (float)i / (float)cInstanceCount;
			const float cTwoPi = 3.14159265f * 2.0f;
			data[i].Color[0] = Math.Abs(Math.Sin(t * cTwoPi));
			data[i].Color[1] = Math.Abs(Math.Sin(t * cTwoPi + 2.094f));
			data[i].Color[2] = Math.Abs(Math.Sin(t * cTwoPi + 4.189f));
			data[i].Color[3] = 1.0f;
		}
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		UpdateInstances();

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
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetVertexBuffer(1, mInstanceBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		// SIX indices, sixty four instances: one call for the whole grid.
		pass.DrawIndexed(6, cInstanceCount);
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
		if (mInstanceBuffer != null) mDevice.DestroyBuffer(ref mInstanceBuffer);
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
		let app = scope InstancingSample();
		return app.Run(args);
	}
}
