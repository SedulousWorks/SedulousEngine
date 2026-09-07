using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample004_Compute;

/// A grid of points animated by a compute shader and drawn as a point list.
///
/// The buffer is written by compute and then read as vertex data in the same command buffer,
/// so the barriers between the two passes are the point of the sample.
class ComputeSample : SampleApp
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
		    float fy = sin(dist*6.0 - Time*2.0) * 0.15;
		    gVertices[idx].PosX = fx; gVertices[idx].PosY = fy; gVertices[idx].PosZ = fz;
		    gVertices[idx].ColR = fx*0.5+0.5; gVertices[idx].ColG = fy*2.0+0.5; gVertices[idx].ColB = fz*0.5+0.5;
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
	/// Three floats of position and three of colour.
	private const uint32 cVertexSize = 24;
	private const uint64 cVertexBufferSize = cPointCount * cVertexSize;
	/// The compute shader's local size, which the dispatch count is rounded up to.
	private const uint32 cThreadsPerGroup = 64;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mComputeShader = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mParamsBuffer = null;
	private IBuffer mViewProjectionBuffer = null;
	private void* mParamsMapped = null;
	private void* mViewProjectionMapped = null;
	private IBindGroupLayout mComputeLayout = null;
	private IBindGroupLayout mRenderLayout = null;
	private IBindGroup mComputeBindGroup = null;
	private IBindGroup mRenderBindGroup = null;
	private IPipelineLayout mComputePipelineLayout = null;
	private IPipelineLayout mRenderPipelineLayout = null;
	private IComputePipeline mComputePipeline = null;
	private IRenderPipeline mRenderPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private DepthBuffer mDepthBuffer = new DepthBuffer() ~ delete _;

	protected override StringView Title => "Sample004 - Compute (Animated Point Grid)";

	protected override void OnResize(uint32 width, uint32 height)
	{
		mDepthBuffer.Recreate(mDevice, width, height).IgnoreError();
	}

	protected override Result<void> OnInit()
	{
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
		// BOTH storage and vertex: compute writes it, then the draw reads it as geometry
		// without a copy in between.
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
		depthStencil.DepthCompare = .Less;
		desc.DepthStencil = depthStencil;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mRenderPipeline = pipeline;
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		UpdateUniforms();

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		RecordComputePass(encoder);
		RecordRenderPass(encoder);

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	private void UpdateUniforms()
	{
		// Time, then the point count as raw bits in the second slot, since the shader
		// declares it as a uint next to floats.
		float[4] @params = .(mTotalTime, 0, 1.0f, 0);
		var pointCount = cPointCount;
		Internal.MemCpy(&@params[1], &pointCount, 4);
		Internal.MemCpy(mParamsMapped, &@params[0], 16);

		let aspect = (float)mWidth / (float)mHeight;
		let cameraAngle = mTotalTime * 0.3f;
		let cameraDistance = 2.5f;
		var view = Float4x4.LookAtRH(
			.(Math.Sin(cameraAngle) * cameraDistance, 1.2f, Math.Cos(cameraAngle) * cameraDistance),
			.(0, 0, 0), .(0, 1, 0));
		var projection = Float4x4.PerspectiveFovRH(Math.DegreesToRadians(45.0f), aspect,
			0.1f, 100.0f);
		var viewProjection = view * projection;
		Internal.MemCpy(mViewProjectionMapped, viewProjection.Data, 64);
	}

	/// The compute half, bracketed by the barriers that make the handover legal.
	///
	/// The buffer alternates between being written by compute and read as geometry, so it
	/// is transitioned both ways every frame: the first barrier is what stops the dispatch
	/// racing the previous frame's draw.
	private void RecordComputePass(ICommandEncoder encoder)
	{
		encoder.TransitionBuffer(mVertexBuffer, .VertexBuffer, .ShaderWrite);

		let pass = encoder.BeginComputePass("GenerateVertices");
		pass.SetPipeline(mComputePipeline);
		pass.SetBindGroup(0, mComputeBindGroup);
		// Rounded UP, so a count that is not a multiple of the group size still covers
		// every point; the shader discards the overshoot.
		pass.Dispatch((cPointCount + cThreadsPerGroup - 1) / cThreadsPerGroup);
		pass.End();

		encoder.TransitionBuffer(mVertexBuffer, .ShaderWrite, .VertexBuffer);
	}

	private void RecordRenderPass(ICommandEncoder encoder)
	{
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mDepthBuffer.Texture, .Undefined, .DepthStencilWrite);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthBuffer.View;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = 1.0f;

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
	}

	protected override void OnShutdown()
	{
		mDepthBuffer.Destroy(mDevice);
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
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
		let app = scope ComputeSample();
		return app.Run(args);
	}
}
