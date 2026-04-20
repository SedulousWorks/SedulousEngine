namespace Sample029_ResolveTexture;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates explicit MSAA resolve via ICommandEncoder.ResolveTexture().
/// Unlike Sample010 (which uses ColorAttachment.ResolveTarget for automatic
/// render-pass resolve), this sample renders to a 4x MSAA target and then
/// manually resolves to the swapchain using the ResolveTexture command.
class ResolveTextureSample : SampleApp
{
	const String cShaderSource = """
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

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ITexture mMsaaTexture;
	private ITextureView mMsaaView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample029 - ResolveTexture (Explicit 4x MSAA)";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "ResolveVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "ResolvePS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Star shape: great for showing MSAA on diagonal edges
		float[?] verts = .(
			// Center
			0.0f, 0.0f, 0.0f,   1.0f, 1.0f, 1.0f, 1.0f,
			// Outer tips (radius 0.7)
			 0.0f,    0.7f,   0.0f,   1.0f, 0.2f, 0.2f, 1.0f,
			 0.665f,  0.216f, 0.0f,   0.2f, 1.0f, 0.2f, 1.0f,
			 0.411f, -0.566f, 0.0f,   0.2f, 0.3f, 1.0f, 1.0f,
			-0.411f, -0.566f, 0.0f,   1.0f, 1.0f, 0.2f, 1.0f,
			-0.665f,  0.216f, 0.0f,   1.0f, 0.2f, 1.0f, 1.0f,
			// Inner notches (radius 0.25)
			 0.238f,  0.327f, 0.0f,   0.8f, 0.7f, 0.5f, 1.0f,
			 0.385f, -0.125f, 0.0f,   0.5f, 0.8f, 0.7f, 1.0f,
			 0.0f,   -0.405f, 0.0f,   0.5f, 0.5f, 0.9f, 1.0f,
			-0.385f, -0.125f, 0.0f,   0.9f, 0.8f, 0.5f, 1.0f,
			-0.238f,  0.327f, 0.0f,   0.9f, 0.5f, 0.8f, 1.0f
		);

		uint16[30] indices = .(
			0, 1, 6,   0, 6, 2,
			0, 2, 7,   0, 7, 3,
			0, 3, 8,   0, 8, 4,
			0, 4, 9,   0, 9, 5,
			0, 5, 10,  0, 10, 1
		);

		uint32 vbSize = sizeof(decltype(verts));
		uint32 ibSize = sizeof(decltype(indices));

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "ResolveVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "ResolveIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "ResolvePL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		if (CreateMsaaTarget() case .Err) return .Err;

		let vertexAttribs = scope VertexAttribute[2];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 28, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

		let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Multisample = MultisampleState() { Count = 4 },
			Label = "ResolvePipeline"
		});
		if (pipR case .Err) return .Err;
		mPipeline = pipR.Value;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateMsaaTarget()
	{
		if (mMsaaView != null) mDevice.DestroyTextureView(ref mMsaaView);
		if (mMsaaTexture != null) mDevice.DestroyTexture(ref mMsaaTexture);

		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = mSwapChain.Format,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 4,
			Usage = .RenderTarget | .CopySrc, Label = "MsaaRT"
		});
		if (texR case .Err) return .Err;
		mMsaaTexture = texR.Value;

		let viewR = mDevice.CreateTextureView(mMsaaTexture, TextureViewDesc() { Format = mSwapChain.Format, Dimension = .Texture2D });
		if (viewR case .Err) return .Err;
		mMsaaView = viewR.Value;
		return .Ok;
	}

	protected override void OnResize(uint32 w, uint32 h) { CreateMsaaTarget(); }

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		// === Step 1: Render star to MSAA texture ===
		{
			let barriers = scope TextureBarrier[1];
			barriers[0] = TextureBarrier() { Texture = mMsaaTexture, OldState = .CopySrc, NewState = .RenderTarget };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });

			let ca = scope ColorAttachment[1];
			ca[0] = ColorAttachment()
			{
				View = mMsaaView,
				ResolveTarget = null,  // No auto-resolve - we do it manually
				LoadOp = .Clear, StoreOp = .Store,
				ClearValue = ClearColor(0.08f, 0.08f, 0.12f, 1.0f)
			};

			let rp = encoder.BeginRenderPass(RenderPassDesc()
			{
				ColorAttachments = .(ca)
			});

			rp.SetPipeline(mPipeline);
			rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
			rp.SetScissor(0, 0, mWidth, mHeight);
			rp.SetVertexBuffer(0, mVertexBuffer, 0);
			rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
			rp.DrawIndexed(30);
			rp.End();
		}

		// === Step 2: Transition for resolve ===
		{
			let barriers = scope TextureBarrier[2];
			// MSAA texture: RenderTarget -> CopySrc
			barriers[0] = TextureBarrier() { Texture = mMsaaTexture, OldState = .RenderTarget, NewState = .CopySrc };
			// Swapchain: Present -> CopyDst
			barriers[1] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .CopyDst };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });
		}

		// === Step 3: Explicit resolve MSAA -> swapchain ===
		encoder.ResolveTexture(mMsaaTexture, mSwapChain.CurrentTexture);

		// === Step 4: Transition swapchain back to Present ===
		{
			let barriers = scope TextureBarrier[1];
			barriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .CopyDst, NewState = .Present };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });
		}

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mMsaaView != null) mDevice?.DestroyTextureView(ref mMsaaView);
		if (mMsaaTexture != null) mDevice?.DestroyTexture(ref mMsaaTexture);
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
		let app = scope ResolveTextureSample();
		return app.Run();
	}
}
