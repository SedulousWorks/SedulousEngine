namespace Sample014_Blit;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates render-to-texture and filtered blit.
/// Renders a spinning triangle to a small offscreen texture, then blits it to
/// the full swapchain using Blit() (scaled copy with linear filtering).
class BlitSample : SampleApp
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

	const uint32 OffscreenSize = 128;

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ITexture mOffscreenTex;
	private ITextureView mOffscreenView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() :base(.DX12)  { }

	protected override StringView Title => "Sample014 - Blit (Scaled Copy)";

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

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "BlitVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "BlitPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Triangle VB (CpuToGpu for per-frame rotation updates)
		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = 84, Usage = .Vertex, Memory = .CpuToGpu, Label = "BlitVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;

		let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "BlitPL" });
		if (plR case .Err) return .Err;
		mPipelineLayout = plR.Value;

		// Offscreen render target
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = mSwapChain.Format,
			Width = OffscreenSize, Height = OffscreenSize, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .RenderTarget | .CopySrc | .Sampled, Label = "OffscreenRT"
		});
		if (texR case .Err) return .Err;
		mOffscreenTex = texR.Value;

		let tvR = mDevice.CreateTextureView(mOffscreenTex, TextureViewDesc() { Format = mSwapChain.Format, Dimension = .Texture2D });
		if (tvR case .Err) return .Err;
		mOffscreenView = tvR.Value;

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
			Label = "BlitPipeline"
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

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		UpdateTriangle();

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		// === Pass 1: Render spinning triangle to offscreen texture ===
		{
			let barriers = scope TextureBarrier[1];
			barriers[0] = TextureBarrier() { Texture = mOffscreenTex, OldState = .CopySrc, NewState = .RenderTarget };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });

			let ca = scope ColorAttachment[1];
			ca[0] = ColorAttachment() { View = mOffscreenView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.15f, 0.1f, 0.2f, 1.0f) };

			let rp = encoder.BeginRenderPass(RenderPassDesc()
			{
				ColorAttachments = .(ca)
			});

			rp.SetPipeline(mPipeline);
			rp.SetViewport(0, 0, (float)OffscreenSize, (float)OffscreenSize, 0.0f, 1.0f);
			rp.SetScissor(0, 0, OffscreenSize, OffscreenSize);
			rp.SetVertexBuffer(0, mVertexBuffer, 0);
			rp.Draw(3);
			rp.End();

			// Transition offscreen to copy source
			barriers[0].OldState = .RenderTarget;
			barriers[0].NewState = .CopySrc;
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });
		}

		// === Pass 2: Blit offscreen to full swapchain (scaled with linear filtering) ===
		{
			let barriers = scope TextureBarrier[1];
			barriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .CopyDst };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });

			// Blit small offscreen (128x128) -> full swapchain (scaled up with linear filtering)
			encoder.Blit(mOffscreenTex, mSwapChain.CurrentTexture);

			barriers[0].OldState = .CopyDst;
			barriers[0].NewState = .Present;
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(barriers) });
		}

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	private void UpdateTriangle()
	{
		float angle = mTotalTime * 2.0f;
		float cos = Math.Cos(angle), sin = Math.Sin(angle);

		float[21] verts = default;
		float[6] basePos = .(0.0f, 0.5f, 0.433f, -0.25f, -0.433f, -0.25f);
		float[12] colors = .(1.0f, 0.2f, 0.2f, 1.0f, 0.2f, 1.0f, 0.2f, 1.0f, 0.2f, 0.4f, 1.0f, 1.0f);

		for (int i = 0; i < 3; i++)
		{
			float x = basePos[i * 2], y = basePos[i * 2 + 1];
			verts[i * 7 + 0] = x * cos - y * sin;
			verts[i * 7 + 1] = x * sin + y * cos;
			verts[i * 7 + 2] = 0.0f;
			verts[i * 7 + 3] = colors[i * 4 + 0];
			verts[i * 7 + 4] = colors[i * 4 + 1];
			verts[i * 7 + 5] = colors[i * 4 + 2];
			verts[i * 7 + 6] = colors[i * 4 + 3];
		}

		let mapped = mVertexBuffer.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, &verts[0], 84);
			mVertexBuffer.Unmap();
		}
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mOffscreenView != null) mDevice?.DestroyTextureView(ref mOffscreenView);
		if (mOffscreenTex != null) mDevice?.DestroyTexture(ref mOffscreenTex);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope BlitSample();
		return app.Run();
	}
}
