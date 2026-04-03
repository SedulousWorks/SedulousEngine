namespace Sample017_MultiQueue;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates async compute on a separate queue with timeline fence synchronization.
/// A compute shader generates an animated vertex grid on the compute queue,
/// then the graphics queue waits for it and renders the result.
class MultiQueueSample : SampleApp
{
	const String cComputeSource = """
		cbuffer Params : register(b0, space0)
		{
		    float Time;
		    uint  NumPoints;
		    float Spacing;
		    float Padding;
		};

		// NOTE: Using scalar floats instead of float3 because SPIR-V std430 layout
		// pads vec3 to 16-byte alignment inside structs, breaking the 24-byte stride.
		struct Vertex
		{
		    float PosX, PosY, PosZ;
		    float ColR, ColG, ColB;
		};

		RWStructuredBuffer<Vertex> gVertices : register(u0, space0);

		[numthreads(64, 1, 1)]
		void CSMain(uint3 dtid : SV_DispatchThreadID)
		{
		    uint idx = dtid.x;
		    if (idx >= NumPoints) return;

		    uint gridSize = (uint)sqrt((float)NumPoints);
		    uint row = idx / gridSize;
		    uint col = idx % gridSize;

		    float fx = ((float)col / (float)(gridSize - 1)) * 2.0 - 1.0;
		    float fz = ((float)row / (float)(gridSize - 1)) * 2.0 - 1.0;

		    float dist = sqrt(fx * fx + fz * fz);
		    float fy = sin(dist * 8.0 - Time * 3.0) * 0.2;

		    gVertices[idx].PosX = fx;
		    gVertices[idx].PosY = fy;
		    gVertices[idx].PosZ = fz;
		    gVertices[idx].ColR = 0.5 + 0.5 * sin(Time + fx * 3.0);
		    gVertices[idx].ColG = 0.5 + 0.5 * cos(Time + fz * 3.0);
		    gVertices[idx].ColB = 0.5 + 0.5 * sin(Time * 0.7 + dist * 4.0);
		}
		""";

	const String cRenderSource = """
		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float3 Color    : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float3 Color    : COLOR0;
		    // Vulkan requires PointSize written for PointList topology.
		    // DXC ignores [[vk::builtin(...)]] when targeting DXIL.
		    [[vk::builtin("PointSize")]] float PointSize : PSIZE;
		};

		cbuffer ViewProj : register(b0, space0)
		{
		    row_major float4x4 VP;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = mul(VP, float4(input.Position, 1.0));
		    output.Color = input.Color;
		    output.PointSize = 1.0;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return float4(input.Color, 1.0);
		}
		""";

	const uint32 cGridSize = 64;
	const uint32 cNumPoints = cGridSize * cGridSize;
	const uint32 cVertexSize = 24;
	const uint32 cBufferSize = cNumPoints * cVertexSize;

	private ShaderCompiler mShaderCompiler;

	// Compute resources
	private IQueue mComputeQueue;
	private ICommandPool mComputePool;
	private IShaderModule mComputeShader;
	private IBindGroupLayout mComputeBGL;
	private IBindGroup mComputeBG;
	private IPipelineLayout mComputePL;
	private IComputePipeline mComputePipeline;
	private IBuffer mComputeParamsBuffer;
	private void* mComputeParamsMapped;

	// Graphics resources
	private ICommandPool mGraphicsPool;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBindGroupLayout mRenderBGL;
	private IBindGroup mRenderBG;
	private IPipelineLayout mRenderPL;
	private IRenderPipeline mRenderPipeline;
	private IBuffer mViewProjBuffer;
	private void* mViewProjMapped;

	// Shared
	private IBuffer mVertexBuffer;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;

	// Synchronization
	private IFence mComputeFence;
	private IFence mGraphicsFence;
	private uint64 mComputeFenceValue;
	private uint64 mGraphicsFenceValue;

	private float mLastReportTime;
	private bool mHasDedicatedCompute;

	public this() { }

	protected override StringView Title => "Sample017 — MultiQueue (Async Compute)";

	protected override Result<void> OnInit()
	{
		// Check for compute queue
		if (mDevice.GetQueueCount(.Compute) == 0)
		{
			Console.WriteLine("No dedicated compute queue — using graphics queue for both");
			mComputeQueue = mGraphicsQueue;
			mHasDedicatedCompute = false;
		}
		else
		{
			mComputeQueue = mDevice.GetQueue(.Compute, 0);
			mHasDedicatedCompute = true;
			Console.WriteLine("Using dedicated compute queue");
		}

		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let errors = scope String();

		// Compile shaders
		let csBytecode = scope List<uint8>();
		if (mShaderCompiler.CompileCompute(cComputeSource, "CSMain", format, csBytecode, errors) case .Err)
		{ Console.WriteLine("CS: {}", errors); return .Err; }

		let vsBytecode = scope List<uint8>();
		errors.Clear();
		if (mShaderCompiler.CompileVertex(cRenderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("VS: {}", errors); return .Err; }

		let psBytecode = scope List<uint8>();
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cRenderSource, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("PS: {}", errors); return .Err; }

		let csR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(csBytecode.Ptr, csBytecode.Count), Label = "MQ_CS" });
		if (csR case .Err) return .Err;
		mComputeShader = csR.Value;

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "MQ_VS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;

		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "MQ_PS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Shared vertex/storage buffer
		let vbR = mDevice.CreateBuffer(BufferDesc()
		{
			Size = cBufferSize, Usage = .Storage | .Vertex,
			Memory = .GpuOnly, Label = "MQ_VertexStorage"
		});
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;

		// Compute params UBO
		let cpR = mDevice.CreateBuffer(BufferDesc() { Size = 16, Usage = .Uniform, Memory = .CpuToGpu, Label = "MQ_ComputeParams" });
		if (cpR case .Err) return .Err;
		mComputeParamsBuffer = cpR.Value;
		mComputeParamsMapped = mComputeParamsBuffer.Map();

		// View-projection UBO
		let vpR = mDevice.CreateBuffer(BufferDesc() { Size = 64, Usage = .Uniform, Memory = .CpuToGpu, Label = "MQ_ViewProj" });
		if (vpR case .Err) return .Err;
		mViewProjBuffer = vpR.Value;
		mViewProjMapped = mViewProjBuffer.Map();

		// === Compute pipeline ===
		let cBGLEntries = scope BindGroupLayoutEntry[2];
		cBGLEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Compute);
		cBGLEntries[1] = BindGroupLayoutEntry.StorageBuffer(0, .Compute, readWrite: true);

		let cBGLR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(cBGLEntries), Label = "MQ_ComputeBGL" });
		if (cBGLR case .Err) return .Err;
		mComputeBGL = cBGLR.Value;

		let cBGLSpan = scope IBindGroupLayout[1];
		cBGLSpan[0] = mComputeBGL;
		let cPLR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { BindGroupLayouts = Span<IBindGroupLayout>(cBGLSpan), Label = "MQ_ComputePL" });
		if (cPLR case .Err) return .Err;
		mComputePL = cPLR.Value;

		let cBGEntries = scope BindGroupEntry[2];
		cBGEntries[0] = BindGroupEntry.Buffer(mComputeParamsBuffer, 0, 16);
		cBGEntries[1] = BindGroupEntry.Buffer(mVertexBuffer, 0, cBufferSize);

		let cBGR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mComputeBGL, Entries = Span<BindGroupEntry>(cBGEntries), Label = "MQ_ComputeBG" });
		if (cBGR case .Err) return .Err;
		mComputeBG = cBGR.Value;

		let cPipR = mDevice.CreateComputePipeline(ComputePipelineDesc()
		{
			Layout = mComputePL,
			Compute = ProgrammableStage() { Module = mComputeShader, EntryPoint = "CSMain" },
			Label = "MQ_ComputePipeline"
		});
		if (cPipR case .Err) return .Err;
		mComputePipeline = cPipR.Value;

		// === Render pipeline ===
		let rBGLEntries = scope BindGroupLayoutEntry[1];
		rBGLEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);

		let rBGLR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(rBGLEntries), Label = "MQ_RenderBGL" });
		if (rBGLR case .Err) return .Err;
		mRenderBGL = rBGLR.Value;

		let rBGLSpan = scope IBindGroupLayout[1];
		rBGLSpan[0] = mRenderBGL;
		let rPLR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { BindGroupLayouts = Span<IBindGroupLayout>(rBGLSpan), Label = "MQ_RenderPL" });
		if (rPLR case .Err) return .Err;
		mRenderPL = rPLR.Value;

		let rBGEntries = scope BindGroupEntry[1];
		rBGEntries[0] = BindGroupEntry.Buffer(mViewProjBuffer, 0, 64);

		let rBGR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mRenderBGL, Entries = Span<BindGroupEntry>(rBGEntries), Label = "MQ_RenderBG" });
		if (rBGR case .Err) return .Err;
		mRenderBG = rBGR.Value;

		if (CreateDepthBuffer() case .Err) return .Err;

		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x3, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = cVertexSize, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		let rPipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mRenderPL,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .PointList },
			DepthStencil = DepthStencilState() { Format = .Depth24PlusStencil8, DepthWriteEnabled = true, DepthCompare = .Less },
			Label = "MQ_RenderPipeline"
		});
		if (rPipR case .Err) return .Err;
		mRenderPipeline = rPipR.Value;

		// Command pools — one per queue type
		let gPoolR = mDevice.CreateCommandPool(.Graphics);
		if (gPoolR case .Err) return .Err;
		mGraphicsPool = gPoolR.Value;

		let computePoolType = mHasDedicatedCompute ? QueueType.Compute : QueueType.Graphics;
		let cPoolR = mDevice.CreateCommandPool(computePoolType);
		if (cPoolR case .Err) return .Err;
		mComputePool = cPoolR.Value;

		// Fences
		let cfR = mDevice.CreateFence(0);
		if (cfR case .Err) return .Err;
		mComputeFence = cfR.Value;

		let gfR = mDevice.CreateFence(0);
		if (gfR case .Err) return .Err;
		mGraphicsFence = gfR.Value;

		return .Ok;
	}

	protected override void OnRender()
	{
		// Wait for previous frame's graphics work
		if (mGraphicsFenceValue > 0) mGraphicsFence.Wait(mGraphicsFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;

		// Update compute params
		var numPoints = cNumPoints;
		float[4] computeParams = default;
		computeParams[0] = mTotalTime;
		Internal.MemCpy(&computeParams[1], &numPoints, 4);
		computeParams[2] = 1.0f;
		computeParams[3] = 0.0f;
		Internal.MemCpy(mComputeParamsMapped, &computeParams[0], 16);

		UpdateViewProj();

		// === Compute pass on compute queue ===
		mComputePool.Reset();
		let cEncR = mComputePool.CreateEncoder();
		if (cEncR case .Err) return;
		var computeEncoder = cEncR.Value;

		let bufBarriers = scope BufferBarrier[1];
		bufBarriers[0] = BufferBarrier() { Buffer = mVertexBuffer, OldState = .VertexBuffer, NewState = .ShaderWrite };
		computeEncoder.Barrier(BarrierGroup() { BufferBarriers = Span<BufferBarrier>(bufBarriers) });

		let cp = computeEncoder.BeginComputePass("AsyncCompute");
		cp.SetPipeline(mComputePipeline);
		cp.SetBindGroup(0, mComputeBG);
		cp.Dispatch((cNumPoints + 63) / 64);
		cp.End();

		bufBarriers[0].OldState = .ShaderWrite;
		bufBarriers[0].NewState = .VertexBuffer;
		computeEncoder.Barrier(BarrierGroup() { BufferBarriers = Span<BufferBarrier>(bufBarriers) });

		var computeCmdBuf = computeEncoder.Finish();
		mComputeFenceValue++;

		// Submit compute work — signals compute fence when done
		mComputeQueue.Submit(Span<ICommandBuffer>(&computeCmdBuf, 1), mComputeFence, mComputeFenceValue);
		mComputePool.DestroyEncoder(ref computeEncoder);

		// === Graphics pass — waits on compute fence before executing ===
		mGraphicsPool.Reset();
		let gEncR = mGraphicsPool.CreateEncoder();
		if (gEncR case .Err) return;
		var gfxEncoder = gEncR.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		gfxEncoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store,
			ClearValue = ClearColor(0.03f, 0.03f, 0.06f, 1.0f)
		};

		let depthAttachment = DepthStencilAttachment()
		{
			View = mDepthView, DepthLoadOp = .Clear, DepthStoreOp = .Store, DepthClearValue = 1.0f
		};

		let rp = gfxEncoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments),
			DepthStencilAttachment = depthAttachment
		});

		rp.SetPipeline(mRenderPipeline);
		rp.SetBindGroup(0, mRenderBG);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.Draw(cNumPoints);
		rp.End();

		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		gfxEncoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var gfxCmdBuf = gfxEncoder.Finish();
		mGraphicsFenceValue++;

		// Submit graphics work — wait on compute fence, signal graphics fence
		let waitFences = scope IFence[1];
		waitFences[0] = mComputeFence;
		let waitValues = scope uint64[1];
		waitValues[0] = mComputeFenceValue;

		mGraphicsQueue.Submit(
			Span<ICommandBuffer>(&gfxCmdBuf, 1),
			Span<IFence>(waitFences),
			Span<uint64>(waitValues),
			mGraphicsFence,
			mGraphicsFenceValue
		);

		mSwapChain.Present(mGraphicsQueue);
		mGraphicsPool.DestroyEncoder(ref gfxEncoder);

		// Print status periodically
		if (mTotalTime - mLastReportTime >= 3.0f)
		{
			Console.WriteLine("MultiQueue: compute fence={}, graphics fence={}, dt={:.2}ms",
				mComputeFenceValue, mGraphicsFenceValue, mDeltaTime * 1000.0f);
			mLastReportTime = mTotalTime;
		}
	}

	private void UpdateViewProj()
	{
		float aspect = (float)mWidth / (float)mHeight;
		float camAngle = mTotalTime * 0.4f;
		float camDist = 2.5f;
		float camX = Math.Sin(camAngle) * camDist;
		float camZ = Math.Cos(camAngle) * camDist;

		float[16] view = default;
		MakeLookAt(ref view, camX, 1.2f, camZ, 0.0f, 0.0f, 0.0f);

		float[16] proj = default;
		MakePerspective(ref proj, 45.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);

		float[16] vp = default;
		MatMul4x4(ref vp, ref proj, ref view);

		Internal.MemCpy(mViewProjMapped, &vp[0], 64);
	}

	private Result<void> CreateDepthBuffer()
	{
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);

		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .Depth24PlusStencil8,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .DepthStencil, Label = "MQ_Depth"
		});
		if (texR case .Err) return .Err;
		mDepthTexture = texR.Value;

		let tvR = mDevice.CreateTextureView(mDepthTexture, TextureViewDesc() { Format = .Depth24PlusStencil8, Dimension = .Texture2D });
		if (tvR case .Err) return .Err;
		mDepthView = tvR.Value;

		return .Ok;
	}

	protected override void OnResize(uint32 width, uint32 height) { CreateDepthBuffer(); }

	private static void MakeLookAt(ref float[16] m, float eyeX, float eyeY, float eyeZ, float tx, float ty, float tz)
	{
		float fx = tx - eyeX, fy = ty - eyeY, fz = tz - eyeZ;
		float fLen = Math.Sqrt(fx * fx + fy * fy + fz * fz);
		fx /= fLen; fy /= fLen; fz /= fLen;
		float rx = fz, ry = 0.0f, rz = -fx;
		float rLen = Math.Sqrt(rx * rx + rz * rz);
		rx /= rLen; rz /= rLen;
		float ux = fy * rz - fz * ry, uy = fz * rx - fx * rz, uz = fx * ry - fy * rx;
		m[0]  = rx;  m[1]  = ry;  m[2]  = rz;  m[3]  = -(rx * eyeX + ry * eyeY + rz * eyeZ);
		m[4]  = ux;  m[5]  = uy;  m[6]  = uz;  m[7]  = -(ux * eyeX + uy * eyeY + uz * eyeZ);
		m[8]  = fx;  m[9]  = fy;  m[10] = fz;  m[11] = -(fx * eyeX + fy * eyeY + fz * eyeZ);
		m[12] = 0;   m[13] = 0;   m[14] = 0;   m[15] = 1;
	}

	private static void MakePerspective(ref float[16] m, float fovY, float aspect, float nearZ, float farZ)
	{
		float h = 1.0f / Math.Tan(fovY * 0.5f);
		float w = h / aspect;
		float range = farZ / (farZ - nearZ);
		m[0]  = w;    m[1]  = 0;    m[2]  = 0;               m[3]  = 0;
		m[4]  = 0;    m[5]  = h;    m[6]  = 0;               m[7]  = 0;
		m[8]  = 0;    m[9]  = 0;    m[10] = range;            m[11] = -nearZ * range;
		m[12] = 0;    m[13] = 0;    m[14] = 1;               m[15] = 0;
	}

	private static void MatMul4x4(ref float[16] result, ref float[16] a, ref float[16] b)
	{
		for (int row = 0; row < 4; row++)
			for (int col = 0; col < 4; col++)
			{
				float sum = 0;
				for (int k = 0; k < 4; k++)
					sum += a[row * 4 + k] * b[k * 4 + col];
				result[row * 4 + col] = sum;
			}
	}

	protected override void OnShutdown()
	{
		if (mComputeParamsBuffer != null && mComputeParamsMapped != null) mComputeParamsBuffer.Unmap();
		if (mViewProjBuffer != null && mViewProjMapped != null) mViewProjBuffer.Unmap();

		if (mGraphicsFence != null) mDevice?.DestroyFence(ref mGraphicsFence);
		if (mComputeFence != null) mDevice?.DestroyFence(ref mComputeFence);
		if (mGraphicsPool != null) mDevice?.DestroyCommandPool(ref mGraphicsPool);
		if (mComputePool != null) mDevice?.DestroyCommandPool(ref mComputePool);
		if (mRenderPipeline != null) mDevice?.DestroyRenderPipeline(ref mRenderPipeline);
		if (mDepthView != null) mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice?.DestroyTexture(ref mDepthTexture);
		if (mRenderPL != null) mDevice?.DestroyPipelineLayout(ref mRenderPL);
		if (mRenderBG != null) mDevice?.DestroyBindGroup(ref mRenderBG);
		if (mRenderBGL != null) mDevice?.DestroyBindGroupLayout(ref mRenderBGL);
		if (mComputePipeline != null) mDevice?.DestroyComputePipeline(ref mComputePipeline);
		if (mComputePL != null) mDevice?.DestroyPipelineLayout(ref mComputePL);
		if (mComputeBG != null) mDevice?.DestroyBindGroup(ref mComputeBG);
		if (mComputeBGL != null) mDevice?.DestroyBindGroupLayout(ref mComputeBGL);
		if (mViewProjBuffer != null) mDevice?.DestroyBuffer(ref mViewProjBuffer);
		if (mComputeParamsBuffer != null) mDevice?.DestroyBuffer(ref mComputeParamsBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mComputeShader != null) mDevice?.DestroyShaderModule(ref mComputeShader);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MultiQueueSample();
		return app.Run();
	}
}
