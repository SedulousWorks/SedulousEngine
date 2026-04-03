namespace Sample003_UniformBuffers;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Vertex structure with position and color for 3D cube
[CRepr]
struct Vertex
{
	public float[3] Position;
	public float[3] Color;

	public this(float x, float y, float z, float r, float g, float b)
	{
		Position = .(x, y, z);
		Color = .(r, g, b);
	}
}

class UniformBufferSample : SampleApp
{
	// HLSL: uniform buffer in bind group 0, push constants for color tint.
	// register(b0, space0) → Vulkan binding 0 (CBV shift = +0)
	const String cShaderSource = """
		cbuffer UBO : register(b0, space0)
		{
		    row_major float4x4 MVP;
		};

		struct PushData
		{
		    float4 Tint;
		};

		// DX12: root constants via register. Vulkan: push constants via attribute.
		[[vk::push_constant]]
		ConstantBuffer<PushData> gPush : register(b0, space1);

		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float3 Color    : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float3 Color    : COLOR0;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = mul(MVP, float4(input.Position, 1.0));
		    output.Color = input.Color;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return float4(input.Color * gPush.Tint.rgb, 1.0);
		}
		""";

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mUniformBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mBindGroup;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	// Mapped pointer for per-frame UBO updates
	private void* mUniformMapped;

	public this()  { }

	protected override StringView Title => "Sample003 — Rotating Cube (Uniform Buffers)";

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
		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "CubeVS" });
		if (vsResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (VS) failed"); return .Err; }
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "CubePS" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mPixelShader = psResult.Value;

		// Define cube vertices (position + color)
		Vertex[8] vertices = .(
			.(-0.5f, -0.5f, -0.5f, 1.0f, 0.0f, 0.0f),  // 0: Front-bottom-left - Red
			.( 0.5f, -0.5f, -0.5f, 0.0f, 1.0f, 0.0f),  // 1: Front-bottom-right - Green
			.( 0.5f,  0.5f, -0.5f, 0.0f, 0.0f, 1.0f),  // 2: Front-top-right - Blue
			.(-0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 0.0f),  // 3: Front-top-left - Yellow
			.(-0.5f, -0.5f,  0.5f, 1.0f, 0.0f, 1.0f),  // 4: Back-bottom-left - Magenta
			.( 0.5f, -0.5f,  0.5f, 0.0f, 1.0f, 1.0f),  // 5: Back-bottom-right - Cyan
			.( 0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f),  // 6: Back-top-right - White
			.(-0.5f,  0.5f,  0.5f, 0.5f, 0.5f, 0.5f)   // 7: Back-top-left - Gray
		);

		// Cube indices (36 indices for 12 triangles)
		uint16[36] indices = .(
			// Front face
			0, 2, 1, 0, 3, 2,
			// Back face
			4, 5, 6, 4, 6, 7,
			// Left face
			4, 7, 3, 4, 3, 0,
			// Right face
			1, 2, 6, 1, 6, 5,
			// Top face
			3, 7, 6, 3, 6, 2,
			// Bottom face
			4, 0, 1, 4, 1, 5
		);

		// Vertex buffer (8 verts * 6 floats * 4 bytes = 192)
		let vbResult = mDevice.CreateBuffer(BufferDesc() { Size = 192, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "CubeVB" });
		if (vbResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (VB) failed"); return .Err; }
		mVertexBuffer = vbResult.Value;

		// Index buffer (36 uint16 = 72 bytes)
		let ibResult = mDevice.CreateBuffer(BufferDesc() { Size = 72, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "CubeIB" });
		if (ibResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (IB) failed"); return .Err; }
		mIndexBuffer = ibResult.Value;

		// Uniform buffer (64 bytes for 4x4 matrix, CpuToGpu for per-frame mapping)
		let ubResult = mDevice.CreateBuffer(BufferDesc() { Size = 64, Usage = .Uniform, Memory = .CpuToGpu, Label = "CubeUBO" });
		if (ubResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (UBO) failed"); return .Err; }
		mUniformBuffer = ubResult.Value;

		// Map uniform buffer (persistent mapping)
		mUniformMapped = mUniformBuffer.Map();
		if (mUniformMapped == null)
		{
			Console.WriteLine("ERROR: Failed to map uniform buffer");
			return .Err;
		}

		// Upload vertex and index data
		let batchResult = mGraphicsQueue.CreateTransferBatch();
		if (batchResult case .Err) { Console.WriteLine("ERROR: CreateTransferBatch failed"); return .Err; }
		var transfer = batchResult.Value;

		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&vertices[0], 192));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], 72));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Bind group layout: uniform buffer at binding 0
		let bglEntries = scope BindGroupLayoutEntry[1];
		bglEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment);

		let bglResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(bglEntries),
			Label = "CubeBGL"
		});
		if (bglResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout failed"); return .Err; }
		mBindGroupLayout = bglResult.Value;

		// Pipeline layout with bind group + push constants
		let bglSpan = scope IBindGroupLayout[1];
		bglSpan[0] = mBindGroupLayout;

		let pushRanges = scope PushConstantRange[1];
		pushRanges[0] = PushConstantRange()
		{
			Stages = .Vertex | .Fragment,
			Offset = 0,
			Size = 16 // float4 tint = 16 bytes
		};

		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(bglSpan),
			PushConstantRanges = Span<PushConstantRange>(pushRanges),
			Label = "CubePL"
		});
		if (plResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout failed"); return .Err; }
		mPipelineLayout = plResult.Value;

		// Bind group
		let bgEntries = scope BindGroupEntry[1];
		bgEntries[0] = BindGroupEntry.Buffer(mUniformBuffer, 0, 64);

		let bgResult = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mBindGroupLayout,
			Entries = Span<BindGroupEntry>(bgEntries),
			Label = "CubeBG"
		});
		if (bgResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup failed"); return .Err; }
		mBindGroup = bgResult.Value;

		// Depth buffer
		if (CreateDepthBuffer() case .Err) return .Err;

		// Render pipeline
		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x3, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = 24, // 6 floats
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
			Label = "CubePipeline"
		});
		if (pipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline failed"); return .Err; }
		mPipeline = pipResult.Value;

		// Command pool and frame fence
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

		// Update MVP matrix
		UpdateUniformBuffer();

		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// Barrier: present → render target
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
			ClearValue = ClearColor(0.1f, 0.1f, 0.15f, 1.0f)
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

		rp.SetPipeline(mPipeline);
		rp.SetBindGroup(0, mBindGroup);

		// Push constants: color tint (pulsing white)
		float pulse = (Math.Sin(mTotalTime * 2.0f) * 0.3f + 0.7f);
		float[4] tint = .(pulse, pulse, pulse, 1.0f);
		rp.SetPushConstants(.Vertex | .Fragment, 0, 16, &tint[0]);

		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(36);
		rp.End();

		// Barrier: render target → present
		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);

		mSwapChain.Present(mGraphicsQueue);

		mCommandPool.DestroyEncoder(ref encoder);
	}

	private Result<void> CreateDepthBuffer()
	{
		// Destroy old if resizing
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
			Dimension = .Texture2D,
			BaseMipLevel = 0,
			MipLevelCount = 1,
			BaseArrayLayer = 0,
			ArrayLayerCount = 1
		});
		if (viewResult case .Err) { Console.WriteLine("ERROR: CreateTextureView (depth) failed"); return .Err; }
		mDepthView = viewResult.Value;

		return .Ok;
	}

	protected override void OnResize(uint32 width, uint32 height)
	{
		CreateDepthBuffer();
	}

	private void UpdateUniformBuffer()
	{
		float aspect = (float)mWidth / (float)mHeight;
		float angle = mTotalTime * 1.2f; // radians per second

		// Model: rotate around Y and X axes
		float[16] model = default;
		MakeRotationYX(ref model, angle, angle * 0.7f);

		// View: camera at (0, 1.5, -3) looking at origin
		float[16] view = default;
		MakeLookAt(ref view, 0.0f, 1.5f, -3.0f, 0.0f, 0.0f, 0.0f);

		// Projection: perspective
		float[16] proj = default;
		MakePerspective(ref proj, 45.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);

		// MVP = proj * view * model
		float[16] viewModel = default;
		MatMul4x4(ref viewModel, ref view, ref model);
		float[16] mvp = default;
		MatMul4x4(ref mvp, ref proj, ref viewModel);

		// Write to mapped UBO (row-major, HLSL expects row-major by default with float4x4)
		Internal.MemCpy(mUniformMapped, &mvp[0], 64);
	}

	// --- Simple math helpers (row-major 4x4) ---

	private static void MakeRotationYX(ref float[16] m, float yAngle, float xAngle)
	{
		float cy = Math.Cos(yAngle), sy = Math.Sin(yAngle);
		float cx = Math.Cos(xAngle), sx = Math.Sin(xAngle);

		// Ry * Rx (row-major)
		m[0]  = cy;           m[1]  = sy * sx;      m[2]  = sy * cx;      m[3]  = 0;
		m[4]  = 0;            m[5]  = cx;            m[6]  = -sx;          m[7]  = 0;
		m[8]  = -sy;          m[9]  = cy * sx;       m[10] = cy * cx;      m[11] = 0;
		m[12] = 0;            m[13] = 0;             m[14] = 0;            m[15] = 1;
	}

	private static void MakeLookAt(ref float[16] m, float eyeX, float eyeY, float eyeZ,
		float targetX, float targetY, float targetZ)
	{
		// Forward (eye to target, normalized)
		float fx = targetX - eyeX, fy = targetY - eyeY, fz = targetZ - eyeZ;
		float fLen = Math.Sqrt(fx * fx + fy * fy + fz * fz);
		fx /= fLen; fy /= fLen; fz /= fLen;

		// Right = forward × up(0,1,0)
		float rx = fz, ry = 0.0f, rz = -fx;
		float rLen = Math.Sqrt(rx * rx + rz * rz);
		rx /= rLen; rz /= rLen;

		// True up = forward × right (left-handed: f × r gives up)
		float ux = fy * rz - fz * ry;
		float uy = fz * rx - fx * rz;
		float uz = fx * ry - fy * rx;

		// Row-major LH view matrix for mul(M, v)
		// Row0 = right, Row1 = up, Row2 = forward (not negated — LH, depth [0,1])
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

		// Row-major perspective for mul(M, v), DX depth [0,1]
		// w_clip = z (from row 3, col 2 = 1), z_clip = range*z - near*range (row 2)
		m[0]  = w;    m[1]  = 0;    m[2]  = 0;               m[3]  = 0;
		m[4]  = 0;    m[5]  = h;    m[6]  = 0;               m[7]  = 0;
		m[8]  = 0;    m[9]  = 0;    m[10] = range;            m[11] = -nearZ * range;
		m[12] = 0;    m[13] = 0;    m[14] = 1;               m[15] = 0;
	}

	private static void MatMul4x4(ref float[16] result, ref float[16] a, ref float[16] b)
	{
		for (int row = 0; row < 4; row++)
		{
			for (int col = 0; col < 4; col++)
			{
				float sum = 0;
				for (int k = 0; k < 4; k++)
					sum += a[row * 4 + k] * b[k * 4 + col];
				result[row * 4 + col] = sum;
			}
		}
	}

	protected override void OnShutdown()
	{
		if (mUniformBuffer != null && mUniformMapped != null)
			mUniformBuffer.Unmap();

		if (mFrameFence != null)
			mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)
			mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null)
			mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mDepthView != null)
			mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null)
			mDevice?.DestroyTexture(ref mDepthTexture);
		if (mPipelineLayout != null)
			mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null)
			mDevice?.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null)
			mDevice?.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mUniformBuffer != null)
			mDevice?.DestroyBuffer(ref mUniformBuffer);
		if (mPixelShader != null)
			mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null)
			mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null)
			mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null)
			mDevice?.DestroyBuffer(ref mVertexBuffer);
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
		let app = scope UniformBufferSample();
		return app.Run();
	}
}
