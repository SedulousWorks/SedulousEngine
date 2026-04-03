namespace Sample007_Instancing;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Per-instance data: offset + color.
[CRepr]
struct InstanceData
{
	public float[2] Offset;
	public float[4] Color;
}

class InstancingSample : SampleApp
{
	const int InstanceCount = 64;

	const String cShaderSource = """
		struct VSInput
		{
		    float3 Position  : TEXCOORD0; // Per-vertex
		    float2 Offset    : TEXCOORD1; // Per-instance
		    float4 InstColor : TEXCOORD2; // Per-instance
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

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mInstanceBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	private void* mInstanceMapped;

	public this()  { }

	protected override StringView Title => "Sample007 — Instanced Rendering";

	protected override Result<void> OnInit()
	{
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) { Console.WriteLine("ERROR: ShaderCompiler.Init failed"); return .Err; }

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("VS compile failed: {}", errors); return .Err; }
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("PS compile failed: {}", errors); return .Err; }

		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "InstVS" });
		if (vsResult case .Err) return .Err;
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "InstPS" });
		if (psResult case .Err) return .Err;
		mPixelShader = psResult.Value;

		// Unit quad vertices (pos only)
		float[12] quadVerts = .(
			-0.04f, -0.04f, 0.0f,
			 0.04f, -0.04f, 0.0f,
			 0.04f,  0.04f, 0.0f,
			-0.04f,  0.04f, 0.0f
		);
		uint16[6] quadIdx = .(0, 1, 2, 0, 2, 3);

		let vbResult = mDevice.CreateBuffer(BufferDesc() { Size = 48, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "QuadVB" });
		if (vbResult case .Err) return .Err;
		mVertexBuffer = vbResult.Value;

		let ibResult = mDevice.CreateBuffer(BufferDesc() { Size = 12, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "QuadIB" });
		if (ibResult case .Err) return .Err;
		mIndexBuffer = ibResult.Value;

		let batchResult = mGraphicsQueue.CreateTransferBatch();
		if (batchResult case .Err) return .Err;
		var transfer = batchResult.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&quadVerts[0], 48));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&quadIdx[0], 12));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Instance buffer (CpuToGpu for per-frame updates)
		uint64 instSize = (uint64)(InstanceCount * sizeof(InstanceData));
		let instResult = mDevice.CreateBuffer(BufferDesc() { Size = instSize, Usage = .Vertex, Memory = .CpuToGpu, Label = "InstanceBuf" });
		if (instResult case .Err) return .Err;
		mInstanceBuffer = instResult.Value;
		mInstanceMapped = mInstanceBuffer.Map();
		if (mInstanceMapped == null) return .Err;

		// Pipeline layout (empty)
		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "InstPL" });
		if (plResult case .Err) return .Err;
		mPipelineLayout = plResult.Value;

		// Two vertex buffer layouts: slot 0 = per-vertex, slot 1 = per-instance
		let vertexAttribs = scope VertexAttribute[1];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };

		let instanceAttribs = scope VertexAttribute[2];
		instanceAttribs[0] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x2, Offset = 0 };
		instanceAttribs[1] = VertexAttribute() { ShaderLocation = 2, Format = .Float32x4, Offset = 8 };

		let vertexLayouts = scope VertexBufferLayout[2];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = 12,
			StepMode = .Vertex,
			Attributes = Span<VertexAttribute>(vertexAttribs)
		};
		vertexLayouts[1] = VertexBufferLayout()
		{
			Stride = (uint32)sizeof(InstanceData),
			StepMode = .Instance,
			Attributes = Span<VertexAttribute>(instanceAttribs)
		};

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		let pipResult = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "InstPipeline"
		});
		if (pipResult case .Err) return .Err;
		mPipeline = pipResult.Value;

		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) return .Err;
		mCommandPool = poolResult.Value;

		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) return .Err;
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;

		UpdateInstances();

		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear, StoreOp = .Store,
			ClearValue = ClearColor(0.05f, 0.05f, 0.08f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments)
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetVertexBuffer(1, mInstanceBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		rp.DrawIndexed(6, (uint32)InstanceCount);
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

	private void UpdateInstances()
	{
		InstanceData* data = (InstanceData*)mInstanceMapped;
		int gridSize = (int)Math.Sqrt((float)InstanceCount);

		for (int i = 0; i < InstanceCount; i++)
		{
			int row = i / gridSize;
			int col = i % gridSize;

			float spacing = 2.0f / (float)gridSize;
			float baseX = -1.0f + spacing * 0.5f + col * spacing;
			float baseY = -1.0f + spacing * 0.5f + row * spacing;

			// Animate: wobble in a circle
			float phase = mTotalTime * 2.0f + i * 0.3f;
			float wobbleX = Math.Sin(phase) * 0.02f;
			float wobbleY = Math.Cos(phase * 1.3f) * 0.02f;

			data[i].Offset = .(baseX + wobbleX, baseY + wobbleY);

			// Color: hue based on index
			float t = (float)i / (float)InstanceCount;
			float r = Math.Abs(Math.Sin(t * Math.PI_f * 2.0f));
			float g = Math.Abs(Math.Sin(t * Math.PI_f * 2.0f + 2.094f));
			float b = Math.Abs(Math.Sin(t * Math.PI_f * 2.0f + 4.189f));
			data[i].Color = .(r, g, b, 1.0f);
		}
	}

	protected override void OnShutdown()
	{
		if (mInstanceBuffer != null && mInstanceMapped != null) mInstanceBuffer.Unmap();
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mInstanceBuffer != null) mDevice?.DestroyBuffer(ref mInstanceBuffer);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope InstancingSample();
		return app.Run();
	}
}
