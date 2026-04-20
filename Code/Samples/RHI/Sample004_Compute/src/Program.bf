namespace Sample004_Compute;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

class ComputeSample : SampleApp
{
	// Compute shader: generates a grid of animated points in a storage buffer.
	// Each thread writes one vertex (position + color) based on thread ID and time.
	// UAV register(u0, space0) -> Vulkan binding 2000.
	const String cComputeSource = """
		cbuffer Params : register(b0, space0)
		{
		    float Time;
		    uint  NumPoints;
		    float Spacing;
		    float Padding;
		};

		// NOTE: Using scalar floats instead of float3 because SPIR-V std430 layout
		// pads vec3 to 16-byte alignment inside structs, making this 32 bytes instead
		// of 24. DXIL packs float3 tightly at 12 bytes. Scalar floats ensure consistent
		// 24-byte layout across both backends.
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

		    // Animated wave
		    float dist = sqrt(fx * fx + fz * fz);
		    float fy = sin(dist * 6.0 - Time * 2.0) * 0.15;

		    gVertices[idx].PosX = fx;
		    gVertices[idx].PosY = fy;
		    gVertices[idx].PosZ = fz;

		    // Color from position
		    gVertices[idx].ColR = fx * 0.5 + 0.5;
		    gVertices[idx].ColG = fy * 2.0 + 0.5;
		    gVertices[idx].ColB = fz * 0.5 + 0.5;
		}
		""";

	// Simple pass-through vertex/pixel shaders for rendering the point cloud.
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
	const uint32 cNumPoints = cGridSize * cGridSize; // 4096
	const uint32 cVertexSize = 24; // 6 floats
	const uint32 cBufferSize = cNumPoints * cVertexSize; // 98304

	private ShaderCompiler mShaderCompiler;

	// Compute resources
	private IShaderModule mComputeShader;
	private IBindGroupLayout mComputeBGL;
	private IBindGroup mComputeBG;
	private IPipelineLayout mComputePL;
	private IComputePipeline mComputePipeline;

	// Render resources
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBindGroupLayout mRenderBGL;
	private IBindGroup mRenderBG;
	private IPipelineLayout mRenderPL;
	private IRenderPipeline mRenderPipeline;

	// Shared buffer: compute writes, graphics reads as vertex buffer
	private IBuffer mVertexBuffer;

	// Uniform buffer for compute params (time, numPoints, spacing)
	private IBuffer mComputeParamsBuffer;
	private void* mComputeParamsMapped;

	// Uniform buffer for view-projection matrix
	private IBuffer mViewProjBuffer;
	private void* mViewProjMapped;

	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this()  { }

	protected override StringView Title => "Sample004 - Compute Shader (Animated Point Grid)";

	protected override Result<void> OnInit()
	{
		// Shader compiler
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err)
		{
			Console.WriteLine("ERROR: ShaderCompiler.Init failed");
			return .Err;
		}

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let errors = scope String();

		// Compile compute shader
		let csBytecode = scope List<uint8>();
		if (mShaderCompiler.CompileCompute(cComputeSource, "CSMain", format, csBytecode, errors) case .Err)
		{
			Console.WriteLine("CS compile failed: {}", errors);
			return .Err;
		}

		let csResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(csBytecode.Ptr, csBytecode.Count), Label = "ComputeCS" });
		if (csResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (CS) failed"); return .Err; }
		mComputeShader = csResult.Value;

		// Compile render shaders
		let vsBytecode = scope List<uint8>();
		errors.Clear();
		if (mShaderCompiler.CompileVertex(cRenderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{
			Console.WriteLine("VS compile failed: {}", errors);
			return .Err;
		}

		let psBytecode = scope List<uint8>();
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cRenderSource, "PSMain", format, psBytecode, errors) case .Err)
		{
			Console.WriteLine("PS compile failed: {}", errors);
			return .Err;
		}

		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "RenderVS" });
		if (vsResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (VS) failed"); return .Err; }
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "RenderPS" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mPixelShader = psResult.Value;

		// Shared vertex/storage buffer
		let vbResult = mDevice.CreateBuffer(BufferDesc()
		{
			Size = cBufferSize,
			Usage = .Storage | .Vertex,
			Memory = .GpuOnly,
			Label = "ComputeVertexBuffer"
		});
		if (vbResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (VB/Storage) failed"); return .Err; }
		mVertexBuffer = vbResult.Value;

		// Compute params uniform buffer (16 bytes: float time, uint numPoints, float spacing, float pad)
		let cpResult = mDevice.CreateBuffer(BufferDesc() { Size = 16, Usage = .Uniform, Memory = .CpuToGpu, Label = "ComputeParams" });
		if (cpResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (ComputeParams) failed"); return .Err; }
		mComputeParamsBuffer = cpResult.Value;
		mComputeParamsMapped = mComputeParamsBuffer.Map();
		if (mComputeParamsMapped == null) { Console.WriteLine("ERROR: Map ComputeParams failed"); return .Err; }

		// View-projection uniform buffer (64 bytes)
		let vpResult = mDevice.CreateBuffer(BufferDesc() { Size = 64, Usage = .Uniform, Memory = .CpuToGpu, Label = "ViewProjUBO" });
		if (vpResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (ViewProj) failed"); return .Err; }
		mViewProjBuffer = vpResult.Value;
		mViewProjMapped = mViewProjBuffer.Map();
		if (mViewProjMapped == null) { Console.WriteLine("ERROR: Map ViewProj failed"); return .Err; }

		// === Compute pipeline setup ===
		// Bind group layout: b0 = uniform params, u0 = RW storage buffer
		let computeBGLEntries = scope BindGroupLayoutEntry[2];
		computeBGLEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Compute);
		computeBGLEntries[1] = BindGroupLayoutEntry.StorageBuffer(0, .Compute, readWrite: true);

		let cBGLResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(computeBGLEntries),
			Label = "ComputeBGL"
		});
		if (cBGLResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout (compute) failed"); return .Err; }
		mComputeBGL = cBGLResult.Value;

		let cBGLSpan = scope IBindGroupLayout[1];
		cBGLSpan[0] = mComputeBGL;
		let cPLResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(cBGLSpan),
			Label = "ComputePL"
		});
		if (cPLResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout (compute) failed"); return .Err; }
		mComputePL = cPLResult.Value;

		let computeBGEntries = scope BindGroupEntry[2];
		computeBGEntries[0] = BindGroupEntry.Buffer(mComputeParamsBuffer, 0, 16);
		computeBGEntries[1] = BindGroupEntry.Buffer(mVertexBuffer, 0, cBufferSize);

		let cBGResult = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mComputeBGL,
			Entries = Span<BindGroupEntry>(computeBGEntries),
			Label = "ComputeBG"
		});
		if (cBGResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup (compute) failed"); return .Err; }
		mComputeBG = cBGResult.Value;

		let cPipResult = mDevice.CreateComputePipeline(ComputePipelineDesc()
		{
			Layout = mComputePL,
			Compute = ProgrammableStage() { Module = mComputeShader, EntryPoint = "CSMain" },
			Label = "ComputePipeline"
		});
		if (cPipResult case .Err) { Console.WriteLine("ERROR: CreateComputePipeline failed"); return .Err; }
		mComputePipeline = cPipResult.Value;

		// === Render pipeline setup ===
		let renderBGLEntries = scope BindGroupLayoutEntry[1];
		renderBGLEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);

		let rBGLResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(renderBGLEntries),
			Label = "RenderBGL"
		});
		if (rBGLResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout (render) failed"); return .Err; }
		mRenderBGL = rBGLResult.Value;

		let rBGLSpan = scope IBindGroupLayout[1];
		rBGLSpan[0] = mRenderBGL;
		let rPLResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(rBGLSpan),
			Label = "RenderPL"
		});
		if (rPLResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout (render) failed"); return .Err; }
		mRenderPL = rPLResult.Value;

		let renderBGEntries = scope BindGroupEntry[1];
		renderBGEntries[0] = BindGroupEntry.Buffer(mViewProjBuffer, 0, 64);

		let rBGResult = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mRenderBGL,
			Entries = Span<BindGroupEntry>(renderBGEntries),
			Label = "RenderBG"
		});
		if (rBGResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup (render) failed"); return .Err; }
		mRenderBG = rBGResult.Value;

		// Depth buffer
		if (CreateDepthBuffer() case .Err) return .Err;

		// Render pipeline: point list
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x3, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = cVertexSize,
			StepMode = .Vertex,
			Attributes = Span<VertexAttribute>(vertexAttribs)
		};

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format,
			WriteMask = .All
		};

		let rPipResult = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mRenderPL,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .PointList },
			DepthStencil = DepthStencilState() { Format = .Depth24PlusStencil8, DepthWriteEnabled = true, DepthCompare = .Less },
			Label = "RenderPipeline"
		});
		if (rPipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline failed"); return .Err; }
		mRenderPipeline = rPipResult.Value;

		// Command pool and fence
		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) { Console.WriteLine("ERROR: CreateCommandPool failed"); return .Err; }
		mCommandPool = poolResult.Value;

		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) { Console.WriteLine("ERROR: CreateFence failed"); return .Err; }
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;
		
		var numPoints = cNumPoints;

		// Update compute params
		float[4] computeParams = .(mTotalTime, *(float*)&numPoints, 1.0f, 0.0f);
		
		// Write numPoints as uint reinterpreted
		Internal.MemCpy(&computeParams[1], &numPoints, 4);
		Internal.MemCpy(mComputeParamsMapped, &computeParams[0], 16);

		// Update view-projection
		UpdateViewProj();

		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// --- Compute pass: generate vertices ---
		let bufBarriers = scope BufferBarrier[1];

		// Barrier: vertex buffer -> shader write (for compute)
		bufBarriers[0] = BufferBarrier()
		{
			Buffer = mVertexBuffer,
			OldState = .VertexBuffer,
			NewState = .ShaderWrite
		};
		encoder.Barrier(BarrierGroup() { BufferBarriers = Span<BufferBarrier>(bufBarriers) });

		let cp = encoder.BeginComputePass("GenerateVertices");
		cp.SetPipeline(mComputePipeline);
		cp.SetBindGroup(0, mComputeBG);
		cp.Dispatch((cNumPoints + 63) / 64); // 64 threads per group
		cp.End();

		// Barrier: shader write -> vertex buffer (for rendering)
		bufBarriers[0].OldState = .ShaderWrite;
		bufBarriers[0].NewState = .VertexBuffer;
		encoder.Barrier(BarrierGroup() { BufferBarriers = Span<BufferBarrier>(bufBarriers) });

		// --- Render pass ---
		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .RenderTarget
		};
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.05f, 0.05f, 0.08f, 1.0f)
		};

		let depthAttachment = DepthStencilAttachment()
		{
			View = mDepthView,
			DepthLoadOp = .Clear,
			DepthStoreOp = .Store,
			DepthClearValue = 1.0f
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
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

		// Barrier: render target -> present
		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);

		mSwapChain.Present(mGraphicsQueue);

		mCommandPool.DestroyEncoder(ref encoder);
	}

	private void UpdateViewProj()
	{
		float aspect = (float)mWidth / (float)mHeight;

		// Camera orbits slowly around the grid
		float camAngle = mTotalTime * 0.3f;
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

		let texResult = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D,
			Format = .Depth24PlusStencil8,
			Width = mWidth,
			Height = mHeight,
			ArrayLayerCount = 1,
			MipLevelCount = 1,
			SampleCount = 1,
			Usage = .DepthStencil,
			Label = "DepthBuffer"
		});
		if (texResult case .Err) { Console.WriteLine("ERROR: CreateTexture (depth) failed"); return .Err; }
		mDepthTexture = texResult.Value;

		let viewResult = mDevice.CreateTextureView(mDepthTexture, TextureViewDesc()
		{
			Format = .Depth24PlusStencil8,
			Dimension = .Texture2D
		});
		if (viewResult case .Err) { Console.WriteLine("ERROR: CreateTextureView (depth) failed"); return .Err; }
		mDepthView = viewResult.Value;

		return .Ok;
	}

	protected override void OnResize(uint32 width, uint32 height)
	{
		CreateDepthBuffer();
	}

	// --- Math helpers (row-major, LH) ---

	private static void MakeLookAt(ref float[16] m, float eyeX, float eyeY, float eyeZ,
		float targetX, float targetY, float targetZ)
	{
		float fx = targetX - eyeX, fy = targetY - eyeY, fz = targetZ - eyeZ;
		float fLen = Math.Sqrt(fx * fx + fy * fy + fz * fz);
		fx /= fLen; fy /= fLen; fz /= fLen;

		float rx = fz, ry = 0.0f, rz = -fx;
		float rLen = Math.Sqrt(rx * rx + rz * rz);
		rx /= rLen; rz /= rLen;

		float ux = fy * rz - fz * ry;
		float uy = fz * rx - fx * rz;
		float uz = fx * ry - fy * rx;

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
		if (mComputeParamsBuffer != null && mComputeParamsMapped != null)
			mComputeParamsBuffer.Unmap();
		if (mViewProjBuffer != null && mViewProjMapped != null)
			mViewProjBuffer.Unmap();

		if (mFrameFence != null)
			mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)
			mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mRenderPipeline != null)
			mDevice?.DestroyRenderPipeline(ref mRenderPipeline);
		if (mDepthView != null)
			mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null)
			mDevice?.DestroyTexture(ref mDepthTexture);
		if (mRenderPL != null)
			mDevice?.DestroyPipelineLayout(ref mRenderPL);
		if (mRenderBG != null)
			mDevice?.DestroyBindGroup(ref mRenderBG);
		if (mRenderBGL != null)
			mDevice?.DestroyBindGroupLayout(ref mRenderBGL);
		if (mComputePipeline != null)
			mDevice?.DestroyComputePipeline(ref mComputePipeline);
		if (mComputePL != null)
			mDevice?.DestroyPipelineLayout(ref mComputePL);
		if (mComputeBG != null)
			mDevice?.DestroyBindGroup(ref mComputeBG);
		if (mComputeBGL != null)
			mDevice?.DestroyBindGroupLayout(ref mComputeBGL);
		if (mViewProjBuffer != null)
			mDevice?.DestroyBuffer(ref mViewProjBuffer);
		if (mComputeParamsBuffer != null)
			mDevice?.DestroyBuffer(ref mComputeParamsBuffer);
		if (mVertexBuffer != null)
			mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mPixelShader != null)
			mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null)
			mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mComputeShader != null)
			mDevice?.DestroyShaderModule(ref mComputeShader);
		if (mShaderCompiler != null)
		{
			mShaderCompiler.Destroy();
			delete mShaderCompiler;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope ComputeSample();
		return app.Run();
	}
}
