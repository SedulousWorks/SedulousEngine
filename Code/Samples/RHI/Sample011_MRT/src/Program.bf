namespace Sample011_MRT;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates multiple render targets: writes color to RT0 and brightness to RT1,
/// then displays both side by side using a fullscreen composite pass.
class MRTSample : SampleApp
{
	// First pass: output to 2 render targets
	const String cGBufferShader = """
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

		struct PSOutput
		{
		    float4 Color      : SV_TARGET0;
		    float4 Brightness : SV_TARGET1;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.Color = input.Color;
		    return output;
		}

		PSOutput PSMain(PSInput input)
		{
		    PSOutput output;
		    output.Color = input.Color;
		    float lum = dot(input.Color.rgb, float3(0.299, 0.587, 0.114));
		    output.Brightness = float4(lum, lum, lum, 1.0);
		    return output;
		}
		""";

	// Second pass: display both textures side by side
	const String cCompositeShader = """
		Texture2D gColorTex : register(t0, space0);
		Texture2D gBrightTex : register(t1, space0);
		SamplerState gSampler : register(s0, space0);

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 TexCoord : TEXCOORD0;
		};

		PSInput VSMain(uint vertexID : SV_VertexID)
		{
		    PSInput output;
		    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
		    output.Position = float4(uv * 2.0 - 1.0, 0.0, 1.0);
		    output.TexCoord = float2(uv.x, 1.0 - uv.y);
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    float2 uv = input.TexCoord;
		    if (uv.x < 0.5)
		    {
		        return gColorTex.Sample(gSampler, float2(uv.x * 2.0, uv.y));
		    }
		    else
		    {
		        return gBrightTex.Sample(gSampler, float2((uv.x - 0.5) * 2.0, uv.y));
		    }
		}
		""";

	private ShaderCompiler mShaderCompiler;
	// GBuffer pass resources
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IShaderModule mGBufVS;
	private IShaderModule mGBufPS;
	private IPipelineLayout mGBufPipelineLayout;
	private IRenderPipeline mGBufPipeline;
	// Render targets
	private ITexture mColorRT;
	private ITextureView mColorRTView;
	private ITexture mBrightRT;
	private ITextureView mBrightRTView;
	// Composite pass resources
	private IShaderModule mCompVS;
	private IShaderModule mCompPS;
	private IBindGroupLayout mCompBGL;
	private IBindGroup mCompBG;
	private IPipelineLayout mCompPipelineLayout;
	private IRenderPipeline mCompPipeline;
	private ISampler mSampler;
	// Shared
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this()  { }

	protected override StringView Title => "Sample011 — Multiple Render Targets";

	protected override Result<void> OnInit()
	{
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		// Compile GBuffer shaders
		if (mShaderCompiler.CompileVertex(cGBufferShader, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("GBuf VS: {}", errors); return .Err; }
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cGBufferShader, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("GBuf PS: {}", errors); return .Err; }

		let gvR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "GBufVS" });
		if (gvR case .Err) return .Err;
		mGBufVS = gvR.Value;
		let gpR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "GBufPS" });
		if (gpR case .Err) return .Err;
		mGBufPS = gpR.Value;

		// Compile composite shaders
		vsBytecode.Clear(); psBytecode.Clear(); errors.Clear();
		if (mShaderCompiler.CompileVertex(cCompositeShader, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("Comp VS: {}", errors); return .Err; }
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cCompositeShader, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("Comp PS: {}", errors); return .Err; }

		let cvR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "CompVS" });
		if (cvR case .Err) return .Err;
		mCompVS = cvR.Value;
		let cpR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "CompPS" });
		if (cpR case .Err) return .Err;
		mCompPS = cpR.Value;

		// Geometry: two overlapping triangles
		float[?] verts = .(
			// Triangle 1: Red
			-0.5f, -0.5f, 0.0f,   1.0f, 0.2f, 0.2f, 1.0f,
			 0.5f, -0.5f, 0.0f,   1.0f, 0.2f, 0.2f, 1.0f,
			 0.0f,  0.6f, 0.0f,   1.0f, 0.8f, 0.2f, 1.0f,
			// Triangle 2: Blue
			-0.3f, -0.3f, 0.0f,   0.2f, 0.3f, 1.0f, 1.0f,
			 0.7f, -0.1f, 0.0f,   0.2f, 0.3f, 1.0f, 1.0f,
			 0.2f,  0.5f, 0.0f,   0.2f, 0.8f, 1.0f, 1.0f
		);
		uint16[6] indices = .(0, 1, 2, 3, 4, 5);

		uint32 vbSize = sizeof(decltype(verts));
		uint32 ibSize = sizeof(decltype(indices));

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "MrtVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "MrtIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Sampler for composite pass
		let sampR = mDevice.CreateSampler(SamplerDesc()
		{
			MinFilter = .Nearest, MagFilter = .Nearest, MipmapFilter = .Nearest,
			AddressU = .ClampToEdge, AddressV = .ClampToEdge, AddressW = .ClampToEdge,
			Label = "CompSampler"
		});
		if (sampR case .Err) return .Err;
		mSampler = sampR.Value;

		// GBuffer pipeline layout (empty)
		let gPlR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { Label = "GBufPL" });
		if (gPlR case .Err) return .Err;
		mGBufPipelineLayout = gPlR.Value;

		// GBuffer pipeline - 2 color targets
		{
			let vertexAttribs = scope VertexAttribute[2];
			vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
			vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x4, Offset = 12 };

			let vertexLayouts = scope VertexBufferLayout[1];
			vertexLayouts[0] = VertexBufferLayout() { Stride = 28, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

			let colorTargets = scope ColorTargetState[2];
			colorTargets[0] = ColorTargetState() { Format = .RGBA8Unorm, WriteMask = .All };
			colorTargets[1] = ColorTargetState() { Format = .RGBA8Unorm, WriteMask = .All };

			let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mGBufPipelineLayout,
				Vertex = .() { Shader = .(mGBufVS, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mGBufPS, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Label = "GBufPipeline"
			});
			if (pipR case .Err) return .Err;
			mGBufPipeline = pipR.Value;
		}

		// Composite bind group layout: 2 textures + 1 sampler
		let compEntries = scope BindGroupLayoutEntry[3];
		compEntries[0] = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		compEntries[1] = BindGroupLayoutEntry.SampledTexture(1, .Fragment);
		compEntries[2] = BindGroupLayoutEntry.Sampler(0, .Fragment);
		let compBglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(compEntries), Label = "CompBGL" });
		if (compBglR case .Err) return .Err;
		mCompBGL = compBglR.Value;

		// Composite pipeline layout
		let compBgls = scope IBindGroupLayout[1];
		compBgls[0] = mCompBGL;
		let cPlR = mDevice.CreatePipelineLayout(PipelineLayoutDesc() { BindGroupLayouts = Span<IBindGroupLayout>(compBgls), Label = "CompPL" });
		if (cPlR case .Err) return .Err;
		mCompPipelineLayout = cPlR.Value;

		// Composite pipeline - fullscreen triangle, no vertex input
		{
			let colorTargets = scope ColorTargetState[1];
			colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

			let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mCompPipelineLayout,
				Vertex = .() { Shader = .(mCompVS, "VSMain" ) },
				Fragment = .() { Shader = .(mCompPS, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Label = "CompPipeline"
			});
			if (pipR case .Err) return .Err;
			mCompPipeline = pipR.Value;
		}

		if (CreateRenderTargets() case .Err) return .Err;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateRenderTargets()
	{
		// Clean up old
		if (mCompBG != null) mDevice.DestroyBindGroup(ref mCompBG);
		if (mColorRTView != null) mDevice.DestroyTextureView(ref mColorRTView);
		if (mColorRT != null) mDevice.DestroyTexture(ref mColorRT);
		if (mBrightRTView != null) mDevice.DestroyTextureView(ref mBrightRTView);
		if (mBrightRT != null) mDevice.DestroyTexture(ref mBrightRT);

		// Color RT
		let cTexR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .RGBA8Unorm,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .RenderTarget | .Sampled, Label = "ColorRT"
		});
		if (cTexR case .Err) return .Err;
		mColorRT = cTexR.Value;
		let cViewR = mDevice.CreateTextureView(mColorRT, TextureViewDesc() { Format = .RGBA8Unorm, Dimension = .Texture2D });
		if (cViewR case .Err) return .Err;
		mColorRTView = cViewR.Value;

		// Brightness RT
		let bTexR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .RGBA8Unorm,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .RenderTarget | .Sampled, Label = "BrightRT"
		});
		if (bTexR case .Err) return .Err;
		mBrightRT = bTexR.Value;
		let bViewR = mDevice.CreateTextureView(mBrightRT, TextureViewDesc() { Format = .RGBA8Unorm, Dimension = .Texture2D });
		if (bViewR case .Err) return .Err;
		mBrightRTView = bViewR.Value;

		// Create composite bind group
		let bgEntries = scope BindGroupEntry[3];
		bgEntries[0] = BindGroupEntry.Texture(mColorRTView);
		bgEntries[1] = BindGroupEntry.Texture(mBrightRTView);
		bgEntries[2] = BindGroupEntry.Sampler(mSampler);
		let bgR = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mCompBGL, Entries = Span<BindGroupEntry>(bgEntries), Label = "CompBG" });
		if (bgR case .Err) return .Err;
		mCompBG = bgR.Value;

		return .Ok;
	}

	protected override void OnResize(uint32 w, uint32 h) { CreateRenderTargets(); }

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		// === Pass 1: Render geometry to 2 render targets ===
		{
			let rtBarriers = scope TextureBarrier[2];
			rtBarriers[0] = TextureBarrier() { Texture = mColorRT, OldState = .ShaderRead, NewState = .RenderTarget };
			rtBarriers[1] = TextureBarrier() { Texture = mBrightRT, OldState = .ShaderRead, NewState = .RenderTarget };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(rtBarriers) });

			let ca = scope ColorAttachment[2];
			ca[0] = ColorAttachment() { View = mColorRTView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.1f, 0.1f, 0.15f, 1.0f) };
			ca[1] = ColorAttachment() { View = mBrightRTView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.0f, 0.0f, 0.0f, 1.0f) };

			let rp = encoder.BeginRenderPass(RenderPassDesc()
			{
				ColorAttachments = .(ca)
			});

			rp.SetPipeline(mGBufPipeline);
			rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
			rp.SetScissor(0, 0, mWidth, mHeight);
			rp.SetVertexBuffer(0, mVertexBuffer, 0);
			rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
			rp.DrawIndexed(6);
			rp.End();

			// Transition RTs to shader resource
			rtBarriers[0].OldState = .RenderTarget;
			rtBarriers[0].NewState = .ShaderRead;
			rtBarriers[1].OldState = .RenderTarget;
			rtBarriers[1].NewState = .ShaderRead;
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(rtBarriers) });
		}

		// === Pass 2: Composite both textures to swapchain ===
		{
			let texBarriers = scope TextureBarrier[1];
			texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

			let ca = scope ColorAttachment[1];
			ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.0f, 0.0f, 0.0f, 1.0f) };

			let rp = encoder.BeginRenderPass(RenderPassDesc()
			{
				ColorAttachments = .(ca)
			});

			rp.SetPipeline(mCompPipeline);
			rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
			rp.SetScissor(0, 0, mWidth, mHeight);
			rp.SetBindGroup(0, mCompBG);
			rp.Draw(3); // Fullscreen triangle
			rp.End();

			texBarriers[0].OldState = .RenderTarget;
			texBarriers[0].NewState = .Present;
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });
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
		if (mCompPipeline != null) mDevice?.DestroyRenderPipeline(ref mCompPipeline);
		if (mCompPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mCompPipelineLayout);
		if (mCompBG != null) mDevice?.DestroyBindGroup(ref mCompBG);
		if (mCompBGL != null) mDevice?.DestroyBindGroupLayout(ref mCompBGL);
		if (mGBufPipeline != null) mDevice?.DestroyRenderPipeline(ref mGBufPipeline);
		if (mGBufPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mGBufPipelineLayout);
		if (mBrightRTView != null) mDevice?.DestroyTextureView(ref mBrightRTView);
		if (mBrightRT != null) mDevice?.DestroyTexture(ref mBrightRT);
		if (mColorRTView != null) mDevice?.DestroyTextureView(ref mColorRTView);
		if (mColorRT != null) mDevice?.DestroyTexture(ref mColorRT);
		if (mSampler != null) mDevice?.DestroySampler(ref mSampler);
		if (mGBufPS != null) mDevice?.DestroyShaderModule(ref mGBufPS);
		if (mGBufVS != null) mDevice?.DestroyShaderModule(ref mGBufVS);
		if (mCompPS != null) mDevice?.DestroyShaderModule(ref mCompPS);
		if (mCompVS != null) mDevice?.DestroyShaderModule(ref mCompVS);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MRTSample();
		return app.Run();
	}
}
