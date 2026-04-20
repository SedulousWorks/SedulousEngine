namespace Sample005_BindGroups;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Vertex with position and normal for simple lighting.
[CRepr]
struct Vertex
{
	public float[3] Position;
	public float[3] Normal;

	public this(float px, float py, float pz, float nx, float ny, float nz)
	{
		Position = .(px, py, pz);
		Normal = .(nx, ny, nz);
	}
}

/// Per-object data: model matrix + color. Padded to 256-byte alignment for DX12 CBV.
[CRepr]
struct ObjectData
{
	public float[16] Model;
	public float[4] Color;
	public float[44] _pad; // Pad to 256 bytes total (64 + 16 + 176 = 256)
}

class BindGroupSample : SampleApp
{
	const int GridSize = 4;
	const int ObjectCount = GridSize * GridSize;
	const uint32 ObjectDataStride = 256; // DX12 CBV alignment

	// Two bind groups in HLSL:
	// space0 = global VP matrix (shared)
	// space1 = per-object model matrix + color
	const String cShaderSource = """
		cbuffer GlobalUBO : register(b0, space0)
		{
		    row_major float4x4 VP;
		};

		cbuffer ObjectUBO : register(b0, space1)
		{
		    row_major float4x4 Model;
		    float4 ObjColor;
		};

		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float3 Normal   : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float3 Normal   : NORMAL;
		    float4 Color    : COLOR;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    float4 worldPos = mul(Model, float4(input.Position, 1.0));
		    output.Position = mul(VP, worldPos);
		    // Transform normal by model matrix (ignoring scale for simplicity)
		    output.Normal = mul((float3x3)Model, input.Normal);
		    output.Color = ObjColor;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    // Simple directional light
		    float3 lightDir = normalize(float3(0.5, 1.0, -0.7));
		    float3 n = normalize(input.Normal);
		    float ndotl = max(dot(n, lightDir), 0.0);
		    float3 lit = input.Color.rgb * (0.2 + 0.8 * ndotl);
		    return float4(lit, 1.0);
		}
		""";

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mGlobalUBO; // VP matrix (64 bytes, CpuToGpu)
	private IBuffer mObjectUBO; // Per-object data (ObjectCount * 256 bytes, CpuToGpu)
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;

	// Set 0: global VP
	private IBindGroupLayout mGlobalBGL;
	private IBindGroup mGlobalBG;

	// Set 1: per-object - single bind group with dynamic offset
	private IBindGroupLayout mObjectBGL;
	private IBindGroup mObjectBG;

	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	private void* mGlobalMapped;
	private void* mObjectMapped;

	public this()  { }

	protected override StringView Title => "Sample005 - Multiple Bind Groups";

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

		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{
			Console.WriteLine("VS compile failed: {}", errors);
			return .Err;
		}

		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{
			Console.WriteLine("PS compile failed: {}", errors);
			return .Err;
		}

		// Shader modules
		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "BindGroupVS" });
		if (vsResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (VS) failed"); return .Err; }
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "BindGroupPS" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mPixelShader = psResult.Value;

		// Build cube mesh with face normals (24 unique verts for 6 faces)
		if (CreateCubeMesh() case .Err) return .Err;

		// Global UBO (64 bytes VP matrix)
		let globalResult = mDevice.CreateBuffer(BufferDesc() { Size = 256, Usage = .Uniform, Memory = .CpuToGpu, Label = "GlobalUBO" });
		if (globalResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (GlobalUBO) failed"); return .Err; }
		mGlobalUBO = globalResult.Value;
		mGlobalMapped = mGlobalUBO.Map();
		if (mGlobalMapped == null) { Console.WriteLine("ERROR: Failed to map GlobalUBO"); return .Err; }

		// Object UBO (ObjectCount * 256 bytes)
		let objSize = (uint64)(ObjectCount * ObjectDataStride);
		let objResult = mDevice.CreateBuffer(BufferDesc() { Size = objSize, Usage = .Uniform, Memory = .CpuToGpu, Label = "ObjectUBO" });
		if (objResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (ObjectUBO) failed"); return .Err; }
		mObjectUBO = objResult.Value;
		mObjectMapped = mObjectUBO.Map();
		if (mObjectMapped == null) { Console.WriteLine("ERROR: Failed to map ObjectUBO"); return .Err; }

		// Bind group layout: Set 0 = global VP
		let globalEntries = scope BindGroupLayoutEntry[1];
		globalEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);

		let globalBglResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(globalEntries),
			Label = "GlobalBGL"
		});
		if (globalBglResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout (global) failed"); return .Err; }
		mGlobalBGL = globalBglResult.Value;

		// Bind group layout: Set 1 = per-object model+color (dynamic offset)
		let objEntries = scope BindGroupLayoutEntry[1];
		objEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment, dynamicOffset: true);

		let objBglResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(objEntries),
			Label = "ObjectBGL"
		});
		if (objBglResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout (object) failed"); return .Err; }
		mObjectBGL = objBglResult.Value;

		// Pipeline layout with 2 bind groups
		let bgls = scope IBindGroupLayout[2];
		bgls[0] = mGlobalBGL;
		bgls[1] = mObjectBGL;

		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(bgls),
			Label = "BindGroupPL"
		});
		if (plResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout failed"); return .Err; }
		mPipelineLayout = plResult.Value;

		// Global bind group (set 0)
		let globalBgEntries = scope BindGroupEntry[1];
		globalBgEntries[0] = BindGroupEntry.Buffer(mGlobalUBO, 0, 64);

		let globalBgResult = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mGlobalBGL,
			Entries = Span<BindGroupEntry>(globalBgEntries),
			Label = "GlobalBG"
		});
		if (globalBgResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup (global) failed"); return .Err; }
		mGlobalBG = globalBgResult.Value;

		// Per-object bind group (set 1) - single bind group, dynamic offset selects object
		{
			let objBgEntries = scope BindGroupEntry[1];
			objBgEntries[0] = BindGroupEntry.Buffer(mObjectUBO, 0, ObjectDataStride);

			let objBgResult = mDevice.CreateBindGroup(BindGroupDesc()
			{
				Layout = mObjectBGL,
				Entries = Span<BindGroupEntry>(objBgEntries),
				Label = "ObjectBG"
			});
			if (objBgResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup (object) failed"); return .Err; }
			mObjectBG = objBgResult.Value;
		}

		// Depth buffer
		if (CreateDepthBuffer() case .Err) return .Err;

		// Render pipeline
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x3, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = 24,
			StepMode = .Vertex,
			Attributes = Span<VertexAttribute>(vertexAttribs)
		};

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format,
			WriteMask = .All
		};

		let pipResult = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList, CullMode = .Back, FrontFace = .CW },
			DepthStencil = DepthStencilState() { Format = .Depth24PlusStencil8, DepthWriteEnabled = true, DepthCompare = .Less },
			Label = "BindGroupPipeline"
		});
		if (pipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline failed"); return .Err; }
		mPipeline = pipResult.Value;

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

		UpdateUniforms();

		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// Barrier: present -> render target
		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .RenderTarget
		};
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		// Render pass
		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.08f, 0.08f, 0.12f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments),
			DepthStencilAttachment = DepthStencilAttachment()
			{
				View = mDepthView,
				DepthLoadOp = .Clear,
				DepthStoreOp = .Store,
				DepthClearValue = 1.0f
			}
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// Set 0: global VP (shared across all draws)
		rp.SetBindGroup(0, mGlobalBG);

		// Draw each object using set 1 with dynamic offset
		for (int i = 0; i < ObjectCount; i++)
		{
			uint32[1] dynOffsets = .((uint32)(i * ObjectDataStride));
			rp.SetBindGroup(1, mObjectBG, Span<uint32>(&dynOffsets[0], 1));
			rp.DrawIndexed(36);
		}

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

	private void UpdateUniforms()
	{
		float aspect = (float)mWidth / (float)mHeight;

		// View: orbiting camera looking at center of grid
		float camDist = 8.0f;
		float camAngle = mTotalTime * 0.3f;
		float camX = Math.Sin(camAngle) * camDist;
		float camZ = -Math.Cos(camAngle) * camDist;
		float camY = 5.0f;

		float[16] view = default;
		MakeLookAt(ref view, camX, camY, camZ, 0.0f, 0.0f, 0.0f);

		float[16] proj = default;
		MakePerspective(ref proj, 45.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);

		float[16] vp = default;
		MatMul4x4(ref vp, ref proj, ref view);

		Internal.MemCpy(mGlobalMapped, &vp[0], 64);

		// Per-object: 4x4 grid of cubes
		float spacing = 2.0f;
		float halfGrid = (GridSize - 1) * spacing * 0.5f;

		// Predefined colors
		float[ObjectCount * 4] colors = .(
			1.0f, 0.3f, 0.3f, 1.0f,  // red
			0.3f, 1.0f, 0.3f, 1.0f,  // green
			0.3f, 0.3f, 1.0f, 1.0f,  // blue
			1.0f, 1.0f, 0.3f, 1.0f,  // yellow
			1.0f, 0.3f, 1.0f, 1.0f,  // magenta
			0.3f, 1.0f, 1.0f, 1.0f,  // cyan
			1.0f, 0.6f, 0.2f, 1.0f,  // orange
			0.6f, 0.2f, 1.0f, 1.0f,  // purple
			0.2f, 0.8f, 0.6f, 1.0f,  // teal
			0.8f, 0.8f, 0.8f, 1.0f,  // light gray
			0.5f, 0.3f, 0.1f, 1.0f,  // brown
			0.9f, 0.5f, 0.7f, 1.0f,  // pink
			0.4f, 0.7f, 0.2f, 1.0f,  // lime
			0.2f, 0.4f, 0.8f, 1.0f,  // steel blue
			0.8f, 0.4f, 0.4f, 1.0f,  // salmon
			0.6f, 0.6f, 0.3f, 1.0f   // olive
		);

		for (int row = 0; row < GridSize; row++)
		{
			for (int col = 0; col < GridSize; col++)
			{
				int idx = row * GridSize + col;

				float x = col * spacing - halfGrid;
				float z = row * spacing - halfGrid;

				// Each cube rotates at a different speed
				float angle = mTotalTime * (0.5f + idx * 0.1f);

				float[16] model = default;
				MakeRotationY(ref model, angle);
				// Apply translation
				model[3] = x;
				model[7] = 0.0f;
				model[11] = z;

				// Write into the mapped UBO at the correct offset
				uint8* dest = (uint8*)mObjectMapped + idx * ObjectDataStride;
				Internal.MemCpy(dest, &model[0], 64);
				Internal.MemCpy(dest + 64, &colors[idx * 4], 16);
			}
		}
	}

	private Result<void> CreateCubeMesh()
	{
		// 24 unique vertices (4 per face, each with face normal)
		Vertex[24] vertices = .(
			// Front face (Z = -0.5, normal 0,0,-1)
			.(-0.5f, -0.5f, -0.5f, 0, 0, -1), .(0.5f, -0.5f, -0.5f, 0, 0, -1),
			.(0.5f, 0.5f, -0.5f, 0, 0, -1), .(-0.5f, 0.5f, -0.5f, 0, 0, -1),
			// Back face (Z = +0.5, normal 0,0,+1)
			.(0.5f, -0.5f, 0.5f, 0, 0, 1), .(-0.5f, -0.5f, 0.5f, 0, 0, 1),
			.(-0.5f, 0.5f, 0.5f, 0, 0, 1), .(0.5f, 0.5f, 0.5f, 0, 0, 1),
			// Left face (X = -0.5, normal -1,0,0)
			.(-0.5f, -0.5f, 0.5f, -1, 0, 0), .(-0.5f, -0.5f, -0.5f, -1, 0, 0),
			.(-0.5f, 0.5f, -0.5f, -1, 0, 0), .(-0.5f, 0.5f, 0.5f, -1, 0, 0),
			// Right face (X = +0.5, normal +1,0,0)
			.(0.5f, -0.5f, -0.5f, 1, 0, 0), .(0.5f, -0.5f, 0.5f, 1, 0, 0),
			.(0.5f, 0.5f, 0.5f, 1, 0, 0), .(0.5f, 0.5f, -0.5f, 1, 0, 0),
			// Top face (Y = +0.5, normal 0,+1,0)
			.(-0.5f, 0.5f, -0.5f, 0, 1, 0), .(0.5f, 0.5f, -0.5f, 0, 1, 0),
			.(0.5f, 0.5f, 0.5f, 0, 1, 0), .(-0.5f, 0.5f, 0.5f, 0, 1, 0),
			// Bottom face (Y = -0.5, normal 0,-1,0)
			.(-0.5f, -0.5f, 0.5f, 0, -1, 0), .(0.5f, -0.5f, 0.5f, 0, -1, 0),
			.(0.5f, -0.5f, -0.5f, 0, -1, 0), .(-0.5f, -0.5f, -0.5f, 0, -1, 0)
		);

		uint16[36] indices = .(
			 0,  1,  2,  0,  2,  3,  // front
			 4,  5,  6,  4,  6,  7,  // back
			 8,  9, 10,  8, 10, 11,  // left
			12, 13, 14, 12, 14, 15,  // right
			16, 17, 18, 16, 18, 19,  // top
			20, 21, 22, 20, 22, 23   // bottom
		);

		uint32 vbSize = (uint32)(sizeof(Vertex) * 24);
		uint32 ibSize = (uint32)(sizeof(uint16) * 36);

		let vbResult = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "CubeVB" });
		if (vbResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (VB) failed"); return .Err; }
		mVertexBuffer = vbResult.Value;

		let ibResult = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "CubeIB" });
		if (ibResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (IB) failed"); return .Err; }
		mIndexBuffer = ibResult.Value;

		let batchResult = mGraphicsQueue.CreateTransferBatch();
		if (batchResult case .Err) { Console.WriteLine("ERROR: CreateTransferBatch failed"); return .Err; }
		var transfer = batchResult.Value;

		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&vertices[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		return .Ok;
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

	// --- Matrix helpers (row-major, LH) ---

	private static void MakeRotationY(ref float[16] m, float angle)
	{
		float c = Math.Cos(angle), s = Math.Sin(angle);
		m[0]  = c;  m[1]  = 0;  m[2]  = s;  m[3]  = 0;
		m[4]  = 0;  m[5]  = 1;  m[6]  = 0;  m[7]  = 0;
		m[8]  = -s; m[9]  = 0;  m[10] = c;  m[11] = 0;
		m[12] = 0;  m[13] = 0;  m[14] = 0;  m[15] = 1;
	}

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
		if (mGlobalUBO != null && mGlobalMapped != null) mGlobalUBO.Unmap();
		if (mObjectUBO != null && mObjectMapped != null) mObjectUBO.Unmap();

		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mDepthView != null) mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice?.DestroyTexture(ref mDepthTexture);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);

		if (mObjectBG != null) mDevice?.DestroyBindGroup(ref mObjectBG);
		if (mGlobalBG != null) mDevice?.DestroyBindGroup(ref mGlobalBG);
		if (mObjectBGL != null) mDevice?.DestroyBindGroupLayout(ref mObjectBGL);
		if (mGlobalBGL != null) mDevice?.DestroyBindGroupLayout(ref mGlobalBGL);
		if (mObjectUBO != null) mDevice?.DestroyBuffer(ref mObjectUBO);
		if (mGlobalUBO != null) mDevice?.DestroyBuffer(ref mGlobalUBO);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
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
		let app = scope BindGroupSample();
		return app.Run();
	}
}
