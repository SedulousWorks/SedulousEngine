namespace Sample012_Wireframe;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates wireframe rendering using FillMode.Wireframe.
/// Shows a rotating icosahedron in wireframe with solid faces behind it.
class WireframeSample : SampleApp
{
	const String cShaderSource = """
		cbuffer UBO : register(b0, space0)
		{
		    row_major float4x4 MVP;
		};

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
		    output.Position = mul(MVP, float4(input.Position, 1.0));
		    output.Color = input.Color;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return input.Color;
		}
		""";

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mUniformBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBindGroupLayout mBGL;
	private IBindGroup mBG;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mSolidPipeline;
	private IRenderPipeline mWirePipeline;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;
	private void* mUniformMapped;
	private uint32 mIndexCount;

	public this()  { }

	protected override StringView Title => "Sample012 — Wireframe";

	protected override Result<void> OnInit()
	{
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("VS: {}", errors); return .Err; }
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("PS: {}", errors); return .Err; }

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "WireVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "WirePS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Build icosahedron
		if (CreateIcosahedron() case .Err) return .Err;

		// Uniform buffer
		let ubR = mDevice.CreateBuffer(BufferDesc() { Size = 256, Usage = .Uniform, Memory = .CpuToGpu, Label = "WireUBO" });
		if (ubR case .Err) return .Err;
		mUniformBuffer = ubR.Value;
		mUniformMapped = mUniformBuffer.Map();

		// Bind group
		let bglEntries = scope BindGroupLayoutEntry[1];
		bglEntries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
		let bglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(bglEntries), Label = "WireBGL" });
		if (bglR case .Err) return .Err;
		mBGL = bglR.Value;

		let bgEntries = scope BindGroupEntry[1];
		bgEntries[0] = BindGroupEntry.Buffer(mUniformBuffer, 0, 64);
		let bgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mBGL, Entries = Span<BindGroupEntry>(bgEntries), Label = "WireBG" });
		if (bgR case .Err) return .Err;
		mBG = bgR.Value;

		let bgls = scope IBindGroupLayout[1];
		bgls[0] = mBGL;
		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { BindGroupLayouts = Span<IBindGroupLayout>(bgls), Label = "WirePL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		if (CreateDepthBuffer() case .Err) return .Err;

		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 28, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		// Solid pipeline
		let solidR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList, CullMode = .Back, FrontFace = .CCW },
			DepthStencil = DepthStencilState() { Format = .Depth24PlusStencil8, DepthWriteEnabled = true, DepthCompare = .Less },
			Label = "SolidPipeline"
		});
		if (solidR case .Err) return .Err;
		mSolidPipeline = solidR.Value;

		// Wireframe pipeline
		let wireR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList, CullMode = .None, FillMode = .Wireframe },
			DepthStencil = DepthStencilState() { Format = .Depth24PlusStencil8, DepthWriteEnabled = false, DepthCompare = .LessEqual },
			Label = "WirePipeline"
		});
		if (wireR case .Err) return .Err;
		mWirePipeline = wireR.Value;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateIcosahedron()
	{
		// Icosahedron vertices
		float t = (1.0f + Math.Sqrt(5.0f)) / 2.0f;
		float s = 1.0f / Math.Sqrt(1.0f + t * t); // normalize
		float a = s;
		float b = t * s;

		// 12 vertices, each with pos(3) + color(4) = 7 floats
		// Bright colors so wireframe edges are clearly visible
		float[84] vertData = .(
			-a,  b, 0.0f,  1.0f, 0.3f, 0.3f, 1.0f,  // 0
			 a,  b, 0.0f,  0.3f, 1.0f, 0.3f, 1.0f,  // 1
			-a, -b, 0.0f,  0.3f, 0.3f, 1.0f, 1.0f,  // 2
			 a, -b, 0.0f,  1.0f, 1.0f, 0.3f, 1.0f,  // 3
			0.0f, -a,  b,  1.0f, 0.3f, 1.0f, 1.0f,  // 4
			0.0f,  a,  b,  0.3f, 1.0f, 1.0f, 1.0f,  // 5
			0.0f, -a, -b,  1.0f, 0.6f, 0.3f, 1.0f,  // 6
			0.0f,  a, -b,  0.6f, 0.3f, 1.0f, 1.0f,  // 7
			 b, 0.0f, -a,  0.3f, 1.0f, 0.6f, 1.0f,  // 8
			 b, 0.0f,  a,  1.0f, 0.6f, 0.6f, 1.0f,  // 9
			-b, 0.0f, -a,  0.6f, 1.0f, 0.3f, 1.0f,  // 10
			-b, 0.0f,  a,  0.6f, 0.3f, 0.6f, 1.0f   // 11
		);

		uint16[60] idxData = .(
			0,11, 5,  0, 5, 1,  0, 1, 7,  0, 7,10,  0,10,11,
			1, 5, 9,  5,11, 4, 11,10, 2, 10, 7, 6,  7, 1, 8,
			3, 9, 4,  3, 4, 2,  3, 2, 6,  3, 6, 8,  3, 8, 9,
			4, 9, 5,  2, 4,11,  6, 2,10,  8, 6, 7,  9, 8, 1
		);

		mIndexCount = 60;
		uint32 vbSize = sizeof(decltype(vertData));
		uint32 ibSize = sizeof(decltype(idxData));

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "IcoVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "IcoIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&vertData[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&idxData[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		return .Ok;
	}

	private Result<void> CreateDepthBuffer()
	{
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .Depth24PlusStencil8,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1, Usage = .DepthStencil, Label = "DepthTex"
		});
		if (texR case .Err) return .Err;
		mDepthTexture = texR.Value;
		let viewR = mDevice.CreateTextureView(mDepthTexture, TextureViewDesc() { Format = .Depth24PlusStencil8, Dimension = .Texture2D });
		if (viewR case .Err) return .Err;
		mDepthView = viewR.Value;
		return .Ok;
	}

	protected override void OnResize(uint32 w, uint32 h) { CreateDepthBuffer(); }

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		UpdateMVP();

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.06f, 0.06f, 0.1f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca),
			DepthStencilAttachment = DepthStencilAttachment() { View = mDepthView, DepthLoadOp = .Clear, DepthStoreOp = .Store, DepthClearValue = 1.0f }
		});

		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);

		// Draw wireframe
		rp.SetPipeline(mWirePipeline);
		rp.SetBindGroup(0, mBG);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(mIndexCount);

		rp.End();

		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	private void UpdateMVP()
	{
		float aspect = (float)mWidth / (float)mHeight;
		float angle = mTotalTime * 0.8f;

		// Rotate around Y axis
		float cosA = Math.Cos(angle), sinA = Math.Sin(angle);
		float[16] model = .(
			cosA, 0, sinA, 0,
			0, 1, 0, 0,
			-sinA, 0, cosA, 0,
			0, 0, 0, 1
		);

		// Simple view: pull back on Z (positive Z is into the screen for this projection)
		float[16] view = .(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 3.0f,
			0, 0, 0, 1
		);

		float[16] proj = default;
		MakePerspective(ref proj, 45.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);

		float[16] mv = default;
		MatMul4x4(ref mv, ref view, ref model);
		float[16] mvp = default;
		MatMul4x4(ref mvp, ref proj, ref mv);

		Internal.MemCpy(mUniformMapped, &mvp[0], 64);
	}

	private static void MakePerspective(ref float[16] m, float fovY, float aspect, float nearZ, float farZ)
	{
		float h = 1.0f / Math.Tan(fovY * 0.5f), w = h / aspect, range = farZ / (farZ - nearZ);
		m[0]=w; m[1]=0; m[2]=0; m[3]=0;
		m[4]=0; m[5]=h; m[6]=0; m[7]=0;
		m[8]=0; m[9]=0; m[10]=range; m[11]=-nearZ*range;
		m[12]=0; m[13]=0; m[14]=1; m[15]=0;
	}

	private static void MatMul4x4(ref float[16] r, ref float[16] a, ref float[16] b)
	{
		for (int row < 4) for (int col < 4)
		{
			float s = 0;
			for (int k < 4) s += a[row*4+k] * b[k*4+col];
			r[row*4+col] = s;
		}
	}

	protected override void OnShutdown()
	{
		if (mUniformBuffer != null && mUniformMapped != null) mUniformBuffer.Unmap();
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mWirePipeline != null) mDevice?.DestroyRenderPipeline(ref mWirePipeline);
		if (mSolidPipeline != null) mDevice?.DestroyRenderPipeline(ref mSolidPipeline);
		if (mDepthView != null) mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice?.DestroyTexture(ref mDepthTexture);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBG != null) mDevice?.DestroyBindGroup(ref mBG);
		if (mBGL != null) mDevice?.DestroyBindGroupLayout(ref mBGL);
		if (mUniformBuffer != null) mDevice?.DestroyBuffer(ref mUniformBuffer);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope WireframeSample();
		return app.Run();
	}
}
