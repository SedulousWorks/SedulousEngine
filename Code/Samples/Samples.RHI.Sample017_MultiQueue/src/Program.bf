using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample017_MultiQueue;

/// Compute on a DEDICATED queue, feeding the graphics queue through a fence.
///
/// The same point grid as the compute sample, but the two halves run on different queues.
/// The graphics submission waits on the compute fence rather than on the CPU, so the two
/// queues overlap: the CPU never blocks between them.
///
/// A device without a dedicated compute queue falls back to one queue for both, which is
/// still correct, only not concurrent.
///
/// Running it on a real second queue found two defects in the shared design rather than in
/// this sample, both since fixed on both engines: barriers named ALL_GRAPHICS on a compute
/// only family, which is invalid, and the swap chain's device latched semaphores were taken
/// by whichever queue submitted first, so the compute submit signalled the present before
/// the frame was drawn.
class MultiQueueSample : SampleApp
{
	private const String cComputeSource = """
		cbuffer Params : register(b0, space0) { float Time; uint NumPoints; float Spacing; float Padding; };
		struct Vertex { float PosX, PosY, PosZ, ColR, ColG, ColB; };
		RWStructuredBuffer<Vertex> gVertices : register(u0, space0);
		[numthreads(64, 1, 1)]
		void CSMain(uint3 dtid : SV_DispatchThreadID) {
		    uint idx = dtid.x; if (idx >= NumPoints) return;
		    uint gridSize = (uint)sqrt((float)NumPoints);
		    uint row = idx / gridSize, col = idx % gridSize;
		    float fx = ((float)col / (float)(gridSize-1))*2.0 - 1.0;
		    float fz = ((float)row / (float)(gridSize-1))*2.0 - 1.0;
		    float dist = sqrt(fx*fx + fz*fz);
		    float fy = sin(dist*8.0 - Time*3.0) * 0.2;
		    gVertices[idx].PosX = fx; gVertices[idx].PosY = fy; gVertices[idx].PosZ = fz;
		    gVertices[idx].ColR = 0.5 + 0.5*sin(Time + fx*3.0);
		    gVertices[idx].ColG = 0.5 + 0.5*cos(Time + fz*3.0);
		    gVertices[idx].ColB = 0.5 + 0.5*sin(Time*0.7 + dist*4.0);
		}
		""";

	private const String cRenderSource = """
		cbuffer ViewProj : register(b0, space0) { row_major float4x4 VP; };
		struct VSInput { float3 Position : TEXCOORD0; float3 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float3 Color : COLOR0;
		                 [[vk::builtin("PointSize")]] float PointSize : PSIZE; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = mul(float4(i.Position,1), VP); o.Color = i.Color; o.PointSize = 1.0; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return float4(i.Color, 1.0); }
		""";

	private const uint32 cGrid = 64;
	private const uint32 cPointCount = cGrid * cGrid;
	private const uint32 cVertexSize = 24;
	private const uint64 cVertexBufferSize = cPointCount * cVertexSize;
	private const uint32 cThreadsPerGroup = 64;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mComputeShader = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;

	private IQueue mComputeQueue = null;
	private ICommandPool mComputePool = null;
	private IBindGroupLayout mComputeLayout = null;
	private IBindGroup mComputeBindGroup = null;
	private IPipelineLayout mComputePipelineLayout = null;
	private IComputePipeline mComputePipeline = null;
	private IBuffer mParamsBuffer = null;
	private void* mParamsMapped = null;

	private ICommandPool mGraphicsPool = null;
	private IBindGroupLayout mRenderLayout = null;
	private IBindGroup mRenderBindGroup = null;
	private IPipelineLayout mRenderPipelineLayout = null;
	private IRenderPipeline mRenderPipeline = null;
	private IBuffer mViewProjectionBuffer = null;
	private void* mViewProjectionMapped = null;

	/// Written by compute, read as geometry: the buffer both queues touch.
	private IBuffer mVertexBuffer = null;
	private DepthBuffer mDepthBuffer = new DepthBuffer() ~ delete _;

	private IFence mComputeFence = null;
	private IFence mGraphicsFence = null;
	private uint64 mComputeFenceValue = 0;
	private uint64 mGraphicsFenceValue = 0;
	private bool mHasDedicatedCompute = false;

	protected override StringView Title => "Sample017 - MultiQueue (Async Compute)";


	protected override void OnResize(uint32 width, uint32 height)
	{
		mDepthBuffer.Recreate(mDevice, width, height).IgnoreError();
	}

	protected override Result<void> OnInit()
	{
		SelectComputeQueue();

		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cComputeSource, .Compute,
			"CSMain", "CS") case .Ok(let computeShader)))
			return .Err;
		mComputeShader = computeShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cRenderSource, .Vertex,
			"VSMain", "VS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cRenderSource, .Fragment,
			"PSMain", "PS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateBuffers() case .Err)
			return .Err;
		if (CreateComputePipeline() case .Err)
			return .Err;

		mDepthBuffer.Recreate(mDevice, mWidth, mHeight).IgnoreError();

		if (CreateRenderPipeline() case .Err)
			return .Err;
		if (CreatePoolsAndFences() case .Err)
			return .Err;
		return .Ok;
	}

	/// A dedicated compute queue where the device has one, the graphics queue otherwise.
	///
	/// Falling back is correct rather than degraded: the fence still orders the two
	/// submissions, they simply run on the same queue.
	private void SelectComputeQueue()
	{
		if (mDevice.GetQueueCount(.Compute) == 0)
		{
			mComputeQueue = mGraphicsQueue;
			mHasDedicatedCompute = false;
			Console.WriteLine("No dedicated compute queue, so the graphics queue serves both");
			return;
		}
		mComputeQueue = mDevice.GetQueue(.Compute, 0);
		mHasDedicatedCompute = true;
		Console.WriteLine("Using a dedicated compute queue");
	}

	private Result<void> CreateBuffers()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = cVertexBufferSize;
		vertexDesc.Usage = .Storage | .Vertex;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var paramsDesc = BufferDesc();
		paramsDesc.Size = 16;
		paramsDesc.Usage = .Uniform;
		paramsDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(paramsDesc) case .Ok(let paramsBuffer)))
			return .Err;
		mParamsBuffer = paramsBuffer;
		mParamsMapped = mParamsBuffer.Map();

		var viewProjectionDesc = BufferDesc();
		viewProjectionDesc.Size = 64;
		viewProjectionDesc.Usage = .Uniform;
		viewProjectionDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(viewProjectionDesc) case .Ok(let viewProjectionBuffer)))
			return .Err;
		mViewProjectionBuffer = viewProjectionBuffer;
		mViewProjectionMapped = mViewProjectionBuffer.Map();
		return .Ok;
	}

	private Result<void> CreateComputePipeline()
	{
		var layoutEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.UniformBuffer(0, .Compute),
			BindGroupLayoutEntry.StorageBuffer(0, .Compute, false));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mComputeLayout = layout;

		var entries = BindGroupEntry[2](
			BindGroupEntry.BufferEntry(mParamsBuffer, 0, 16),
			BindGroupEntry.BufferEntry(mVertexBuffer, 0, cVertexBufferSize));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mComputeLayout;
		groupDesc.Entries = entries;
		if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
			return .Err;
		mComputeBindGroup = bindGroup;

		var layouts = IBindGroupLayout[1](mComputeLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mComputePipelineLayout = pipelineLayout;

		var desc = ComputePipelineDesc();
		desc.Layout = mComputePipelineLayout;
		desc.Compute = .(mComputeShader, "CSMain", .Compute);
		if (!(mDevice.CreateComputePipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mComputePipeline = pipeline;
		return .Ok;
	}

	private Result<void> CreateRenderPipeline()
	{
		var layoutEntries = BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mRenderLayout = layout;

		var entries = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mViewProjectionBuffer, 0, 64));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mRenderLayout;
		groupDesc.Entries = entries;
		if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
			return .Err;
		mRenderBindGroup = bindGroup;

		var layouts = IBindGroupLayout[1](mRenderLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mRenderPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x3, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = cVertexSize;
		vertexLayout.Attributes = attributes;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;

		var buffers = VertexBufferLayout[1](vertexLayout);
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mRenderPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;
		var fragment = FragmentState();
		fragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;
		desc.Primitive.Topology = .PointList;
		var depthStencil = DepthStencilState();
		depthStencil.Format = .Depth24PlusStencil8;
		depthStencil.DepthCompare = Depth.Nearer;
		desc.DepthStencil = depthStencil;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mRenderPipeline = pipeline;
		return .Ok;
	}

	private Result<void> CreatePoolsAndFences()
	{
		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let graphicsPool)))
			return .Err;
		mGraphicsPool = graphicsPool;

		// The pool's queue type must MATCH the queue its buffers are submitted to, so it
		// follows whichever queue was selected above.
		let computePoolType = mHasDedicatedCompute ? QueueType.Compute : QueueType.Graphics;
		if (!(mDevice.CreateCommandPool(computePoolType) case .Ok(let computePool)))
			return .Err;
		mComputePool = computePool;

		if (!(mDevice.CreateFence(0) case .Ok(let computeFence)))
			return .Err;
		mComputeFence = computeFence;
		if (!(mDevice.CreateFence(0) case .Ok(let graphicsFence)))
			return .Err;
		mGraphicsFence = graphicsFence;
		return .Ok;
	}

	protected override void OnRender()
	{
		// Only the GRAPHICS fence is waited on by the CPU. The compute work is ordered
		// against it on the GPU rather than here.
		if (mGraphicsFenceValue > 0)
			mGraphicsFence.Wait(mGraphicsFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		UpdateUniforms();
		SubmitCompute();
		SubmitGraphics();

		mSwapChain.Present(mGraphicsQueue).IgnoreError();
	}

	private void UpdateUniforms()
	{
		float[4] @params = .(mTotalTime, 0, 1.0f, 0);
		var pointCount = cPointCount;
		Internal.MemCpy(&@params[1], &pointCount, 4);
		Internal.MemCpy(mParamsMapped, &@params[0], 16);

		let aspect = (float)mWidth / (float)mHeight;
		let cameraAngle = mTotalTime * 0.4f;
		let cameraDistance = 2.5f;
		var view = Float4x4.LookAtRH(
			.(Math.Sin(cameraAngle) * cameraDistance, 1.2f,
				Math.Cos(cameraAngle) * cameraDistance),
			.(0, 0, 0), .(0, 1, 0));
		var projection = Float4x4.PerspectiveFovRH(Math.DegreesToRadians(45.0f), aspect,
			0.1f, 100.0f);
		var viewProjection = view * projection;
		Internal.MemCpy(mViewProjectionMapped, viewProjection.Data, 64);
	}

	private void SubmitCompute()
	{
		mComputePool.Reset();
		if (!(mComputePool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionBuffer(mVertexBuffer, .VertexBuffer, .ShaderWrite);

		let pass = encoder.BeginComputePass("AsyncCompute");
		pass.SetPipeline(mComputePipeline);
		pass.SetBindGroup(0, mComputeBindGroup);
		pass.Dispatch((cPointCount + cThreadsPerGroup - 1) / cThreadsPerGroup);
		pass.End();

		encoder.TransitionBuffer(mVertexBuffer, .ShaderWrite, .VertexBuffer);

		let commandBuffer = encoder.Finish();
		mComputeFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		// Signals only. Nothing waits on the CPU for this.
		mComputeQueue.Submit(buffers, mComputeFence, mComputeFenceValue);
		mComputePool.DestroyEncoder(ref encoder);
	}

	private void SubmitGraphics()
	{
		mGraphicsPool.Reset();
		if (!(mGraphicsPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mDepthBuffer.Texture, .Undefined, .DepthStencilWrite);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.03f, 0.03f, 0.06f, 1.0f);

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthBuffer.View;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = Depth.ClearValue;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mRenderPipeline);
		pass.SetBindGroup(0, mRenderBindGroup);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.Draw(cPointCount);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mGraphicsFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);

		// WAITS on the compute fence and signals its own. The wait happens on the GPU, so
		// the two queues overlap and the CPU is already ahead by the time this runs.
		var waitFences = IFence[1](mComputeFence);
		var waitValues = uint64[1](mComputeFenceValue);
		mGraphicsQueue.Submit(buffers, waitFences, waitValues, mGraphicsFence,
			mGraphicsFenceValue);
		mGraphicsPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		mDepthBuffer.Destroy(mDevice);
		if (mGraphicsFence != null) mDevice.DestroyFence(ref mGraphicsFence);
		if (mComputeFence != null) mDevice.DestroyFence(ref mComputeFence);
		if (mComputePool != null) mDevice.DestroyCommandPool(ref mComputePool);
		if (mGraphicsPool != null) mDevice.DestroyCommandPool(ref mGraphicsPool);
		if (mRenderPipeline != null) mDevice.DestroyRenderPipeline(ref mRenderPipeline);
		if (mComputePipeline != null) mDevice.DestroyComputePipeline(ref mComputePipeline);
		if (mRenderPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mRenderPipelineLayout);
		if (mComputePipelineLayout != null) mDevice.DestroyPipelineLayout(ref mComputePipelineLayout);
		if (mRenderBindGroup != null) mDevice.DestroyBindGroup(ref mRenderBindGroup);
		if (mComputeBindGroup != null) mDevice.DestroyBindGroup(ref mComputeBindGroup);
		if (mRenderLayout != null) mDevice.DestroyBindGroupLayout(ref mRenderLayout);
		if (mComputeLayout != null) mDevice.DestroyBindGroupLayout(ref mComputeLayout);
		if (mViewProjectionBuffer != null) mDevice.DestroyBuffer(ref mViewProjectionBuffer);
		if (mParamsBuffer != null) mDevice.DestroyBuffer(ref mParamsBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		if (mPixelShader != null) mDevice.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice.DestroyShaderModule(ref mVertexShader);
		if (mComputeShader != null) mDevice.DestroyShaderModule(ref mComputeShader);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MultiQueueSample();
		return app.Run(args);
	}
}
