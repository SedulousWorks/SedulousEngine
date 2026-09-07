using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample025_MultiDrawIndirect;

/// One indexed indirect draw's arguments, laid out exactly as the GPU reads them.
///
/// The field ORDER and sizes are the API's, not a choice: the buffer is consumed by the
/// hardware rather than by any code here.
[CRepr]
struct DrawIndexedIndirectArgs
{
	public uint32 IndexCountPerInstance;
	public uint32 InstanceCount;
	public uint32 StartIndexLocation;
	public int32 BaseVertexLocation;
	public uint32 StartInstanceLocation;
}

/// Four quads from ONE indirect draw, with wireframe overlaid as line topology.
///
/// The draw arguments live in a GPU buffer rather than in the command, so a compute shader
/// could have written them and the CPU need never know how many objects there are. Here
/// they are uploaded once, which is enough to show the mechanism.
class MultiDrawIndirectSample : SampleApp
{
	private const String cShaderSource = """
		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float4 Color    : TEXCOORD1;
		};
		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float4 Color    : COLOR0;
		};
		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.Color = input.Color;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return input.Color;
		}
		""";

	private const uint32 cDrawCount = 4;
	/// Four quads of four edges of two vertices.
	private const uint32 cLineVertexCount = 32;

	/// Four quads, one per screen corner. Position then RGBA.
	private static float[112] sVertices = .(
		-0.9f, 0.1f, 0.5f, 0.8f, 0.2f, 0.2f, 1.0f,
		-0.1f, 0.1f, 0.5f, 0.8f, 0.2f, 0.2f, 1.0f,
		-0.1f, 0.9f, 0.5f, 1.0f, 0.4f, 0.4f, 1.0f,
		-0.9f, 0.9f, 0.5f, 1.0f, 0.4f, 0.4f, 1.0f,
		0.1f, 0.1f, 0.5f, 0.2f, 0.8f, 0.2f, 1.0f,
		0.9f, 0.1f, 0.5f, 0.2f, 0.8f, 0.2f, 1.0f,
		0.9f, 0.9f, 0.5f, 0.4f, 1.0f, 0.4f, 1.0f,
		0.1f, 0.9f, 0.5f, 0.4f, 1.0f, 0.4f, 1.0f,
		-0.9f, -0.9f, 0.5f, 0.2f, 0.2f, 0.8f, 1.0f,
		-0.1f, -0.9f, 0.5f, 0.2f, 0.2f, 0.8f, 1.0f,
		-0.1f, -0.1f, 0.5f, 0.4f, 0.4f, 1.0f, 1.0f,
		-0.9f, -0.1f, 0.5f, 0.4f, 0.4f, 1.0f, 1.0f,
		0.1f, -0.9f, 0.5f, 0.8f, 0.8f, 0.2f, 1.0f,
		0.9f, -0.9f, 0.5f, 0.8f, 0.8f, 0.2f, 1.0f,
		0.9f, -0.1f, 0.5f, 1.0f, 1.0f, 0.4f, 1.0f,
		0.1f, -0.1f, 0.5f, 1.0f, 1.0f, 0.4f, 1.0f);

	private static uint16[24] sIndices = .(
		0, 1, 2, 0, 2, 3,
		4, 5, 6, 4, 6, 7,
		8, 9, 10, 8, 10, 11,
		12, 13, 14, 12, 14, 15);

	/// The same four quads as line PAIRS: a line list needs both ends of every segment, so
	/// each corner appears twice.
	private static float[224] sLineVertices = .(
		-0.9f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.9f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.9f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.9f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, 0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, 0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.9f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.1f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.9f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.9f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.9f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.9f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, -0.1f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f,
		0.1f, -0.9f, 0.4f, 1.0f, 1.0f, 1.0f, 1.0f);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mIndirectBuffer = null;
	private IBuffer mLineVertexBuffer = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mFillPipeline = null;
	private IRenderPipeline mLinePipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample025 - Multi-Draw Indirect & Lines";

	/// Issuing several draws from one indirect call is optional, so a device without it
	/// refuses rather than drawing only the first quad.
	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.MultiDrawIndirect = true;
			return features;
		}
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
		if (CreatePipelines() case .Err)
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

		var lineDesc = BufferDesc();
		lineDesc.Size = sizeof(float) * sLineVertices.Count;
		lineDesc.Usage = .Vertex | .CopyDst;
		lineDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(lineDesc) case .Ok(let lineBuffer)))
			return .Err;
		mLineVertexBuffer = lineBuffer;

		// One argument record per quad, all reading the same vertex buffer and differing
		// only in where their indices start.
		DrawIndexedIndirectArgs[cDrawCount] args = .(
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 0 },
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 6 },
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 12 },
			.() { IndexCountPerInstance = 6, InstanceCount = 1, StartIndexLocation = 18 });

		var indirectDesc = BufferDesc();
		indirectDesc.Size = (uint64)sizeof(DrawIndexedIndirectArgs) * cDrawCount;
		// INDIRECT usage: the hardware reads this buffer as commands, which needs saying.
		indirectDesc.Usage = .Indirect | .CopyDst;
		indirectDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indirectDesc) case .Ok(let indirectBuffer)))
			return .Err;
		mIndirectBuffer = indirectBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertices[0], sizeof(float) * sVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sIndices[0], sizeof(uint16) * sIndices.Count));
		batch.WriteBuffer(mLineVertexBuffer, 0,
			.((uint8*)&sLineVertices[0], sizeof(float) * sLineVertices.Count));
		batch.WriteBuffer(mIndirectBuffer, 0,
			.((uint8*)&args[0], sizeof(DrawIndexedIndirectArgs) * cDrawCount));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	private Result<void> CreatePipelines()
	{
		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x4, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 28;
		vertexLayout.Attributes = attributes;
		var buffers = VertexBufferLayout[1](vertexLayout);

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

		desc.Primitive.Topology = .TriangleList;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let fillPipeline)))
			return .Err;
		mFillPipeline = fillPipeline;

		// The SAME shaders with a different topology: a line list draws each pair of
		// vertices as a segment rather than each triple as a triangle.
		desc.Primitive.Topology = .LineList;
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let linePipeline)))
			return .Err;
		mLinePipeline = linePipeline;
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
		colorAttachment.ClearValue = .(0.06f, 0.06f, 0.1f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);

		// FOUR quads, ONE call. The stride is what lets the hardware walk from one
		// argument record to the next.
		pass.SetPipeline(mFillPipeline);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexedIndirect(mIndirectBuffer, 0, cDrawCount,
			(uint32)sizeof(DrawIndexedIndirectArgs));

		// The wireframe on top, as ordinary lines rather than a wireframe fill mode.
		pass.SetPipeline(mLinePipeline);
		pass.SetVertexBuffer(0, mLineVertexBuffer, 0);
		pass.Draw(cLineVertexCount);
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
		if (mLinePipeline != null) mDevice.DestroyRenderPipeline(ref mLinePipeline);
		if (mFillPipeline != null) mDevice.DestroyRenderPipeline(ref mFillPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mLineVertexBuffer != null) mDevice.DestroyBuffer(ref mLineVertexBuffer);
		if (mIndirectBuffer != null) mDevice.DestroyBuffer(ref mIndirectBuffer);
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
		let app = scope MultiDrawIndirectSample();
		return app.Run(args);
	}
}
