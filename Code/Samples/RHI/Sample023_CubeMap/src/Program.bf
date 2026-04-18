namespace Sample023_CubeMap;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates cube map textures and comparison samplers.
/// Renders a fullscreen quad that samples a procedural cube map (skybox),
/// plus a second pass with a depth texture sampled via comparison sampler
/// to demonstrate shadow-map-style sampling.
class CubeMapSample : SampleApp
{
	// Skybox shader: fullscreen quad -> ray direction -> cube map lookup
	const String cSkyboxShader = """
		TextureCube<float4> gCubeMap : register(t0, space0);
		SamplerState gSampler : register(s0, space0);

		struct PushConstants
		{
		    float Time;
		    float AspectRatio;
		    float2 _pad;
		};

		[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space1);

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 UV       : TEXCOORD0;
		};

		PSInput VSMain(uint vertexID : SV_VertexID)
		{
		    PSInput output;
		    // Fullscreen triangle
		    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
		    output.Position = float4(uv * 2.0 - 1.0, 0.5, 1.0);
		    output.UV = uv;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    // Convert UV to ray direction
		    float2 ndc = input.UV * 2.0 - 1.0;
		    ndc.x *= pc.AspectRatio;
		    ndc.y = -ndc.y;

		    // Simple rotation around Y
		    float c = cos(pc.Time * 0.3);
		    float s = sin(pc.Time * 0.3);

		    float3 dir = normalize(float3(ndc.x, ndc.y, 1.0));
		    float3 rotDir = float3(dir.x * c + dir.z * s, dir.y, -dir.x * s + dir.z * c);

		    return gCubeMap.Sample(gSampler, rotDir);
		}
		""";

	// Shadow test shader: renders a quad, samples a depth texture with comparison sampler
	const String cShadowShader = """
		Texture2D<float> gShadowMap : register(t0, space0);
		SamplerComparisonState gShadowSampler : register(s0, space0);

		struct PushConstants
		{
		    float Time;
		    float AspectRatio;
		    float2 _pad;
		};

		[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space1);

		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float2 TexCoord : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 TexCoord : TEXCOORD0;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.TexCoord = input.TexCoord;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    // Compare at varying depth based on time for animated shadow boundary
		    float compareValue = 0.5 + 0.4 * sin(pc.Time);
		    float shadow = gShadowMap.SampleCmpLevelZero(gShadowSampler, input.TexCoord, compareValue);
		    float3 litColor = float3(0.9, 0.85, 0.7);
		    float3 shadowColor = float3(0.1, 0.1, 0.2);
		    float3 color = lerp(shadowColor, litColor, shadow);
		    return float4(color, 1.0);
		}
		""";

	[CRepr]
	struct PushData
	{
		public float Time;
		public float AspectRatio;
		public float _pad0;
		public float _pad1;
	}

	private ShaderCompiler mShaderCompiler;

	// Skybox resources
	private IShaderModule mSkyboxVS;
	private IShaderModule mSkyboxPS;
	private ITexture mCubeTexture;
	private ITextureView mCubeView;
	private ISampler mLinearSampler;
	private IBindGroupLayout mSkyboxBGL;
	private IBindGroup mSkyboxBG;
	private IPipelineLayout mSkyboxPL;
	private IRenderPipeline mSkyboxPipeline;

	// Shadow comparison resources
	private IShaderModule mShadowVS;
	private IShaderModule mShadowPS;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private ISampler mComparisonSampler;
	private IBuffer mQuadVB;
	private IBindGroupLayout mShadowBGL;
	private IBindGroup mShadowBG;
	private IPipelineLayout mShadowPL;
	private IRenderPipeline mShadowPipeline;

	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample023 — Cube Map & Comparison Sampler";

	protected override Result<void> OnInit()
	{
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let shaderFmt = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let errors = scope String();

		// Compile skybox shaders
		{
			let vs = scope List<uint8>();
			let ps = scope List<uint8>();
			if (mShaderCompiler.CompileVertex(cSkyboxShader, "VSMain", shaderFmt, vs, errors) case .Err)
			{ Console.WriteLine("SkyboxVS: {}", errors); return .Err; }
			errors.Clear();
			if (mShaderCompiler.CompilePixel(cSkyboxShader, "PSMain", shaderFmt, ps, errors) case .Err)
			{ Console.WriteLine("SkyboxPS: {}", errors); return .Err; }

			let r1 = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vs.Ptr, vs.Count), Label = "SkyboxVS" });
			if (r1 case .Err) return .Err;
			mSkyboxVS = r1.Value;
			let r2 = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(ps.Ptr, ps.Count), Label = "SkyboxPS" });
			if (r2 case .Err) return .Err;
			mSkyboxPS = r2.Value;
		}

		// Compile shadow shaders
		{
			let vs = scope List<uint8>();
			let ps = scope List<uint8>();
			errors.Clear();
			if (mShaderCompiler.CompileVertex(cShadowShader, "VSMain", shaderFmt, vs, errors) case .Err)
			{ Console.WriteLine("ShadowVS: {}", errors); return .Err; }
			errors.Clear();
			if (mShaderCompiler.CompilePixel(cShadowShader, "PSMain", shaderFmt, ps, errors) case .Err)
			{ Console.WriteLine("ShadowPS: {}", errors); return .Err; }

			let r1 = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vs.Ptr, vs.Count), Label = "ShadowVS" });
			if (r1 case .Err) return .Err;
			mShadowVS = r1.Value;
			let r2 = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(ps.Ptr, ps.Count), Label = "ShadowPS" });
			if (r2 case .Err) return .Err;
			mShadowPS = r2.Value;
		}

		// Create procedural cube map (6 faces, 64x64, each a solid color)
		if (CreateCubeMap() case .Err) return .Err;

		// Create depth texture for comparison sampler (gradient)
		if (CreateDepthTexture() case .Err) return .Err;

		// Create samplers
		{
			let r = mDevice.CreateSampler(SamplerDesc() { MinFilter = .Linear, MagFilter = .Linear, Label = "LinearSampler" });
			if (r case .Err) return .Err;
			mLinearSampler = r.Value;
		}
		{
			let r = mDevice.CreateSampler(SamplerDesc()
			{
				MinFilter = .Linear, MagFilter = .Linear,
				Compare = .LessEqual,
				Label = "ComparisonSampler"
			});
			if (r case .Err) return .Err;
			mComparisonSampler = r.Value;
		}

		// Skybox bind group layout: cube texture + sampler
		{
			let entries = scope BindGroupLayoutEntry[2];
			entries[0] = BindGroupLayoutEntry.SampledTexture(0, .Vertex | .Fragment, .TextureCube);
			entries[1] = BindGroupLayoutEntry.Sampler(0, .Fragment);
			let r = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(entries), Label = "SkyboxBGL" });
			if (r case .Err) return .Err;
			mSkyboxBGL = r.Value;
		}

		// Skybox bind group
		{
			let entries = scope BindGroupEntry[2];
			entries[0] = BindGroupEntry.Texture(mCubeView);
			entries[1] = BindGroupEntry.Sampler(mLinearSampler);
			let r = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mSkyboxBGL, Entries = Span<BindGroupEntry>(entries), Label = "SkyboxBG" });
			if (r case .Err) return .Err;
			mSkyboxBG = r.Value;
		}

		// Skybox pipeline layout
		{
			let bgls = scope IBindGroupLayout[1];
			bgls[0] = mSkyboxBGL;
			let pushRanges = scope PushConstantRange[1];
			pushRanges[0] = PushConstantRange() { Stages = .Vertex | .Fragment, Offset = 0, Size = sizeof(PushData) };
			let r = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
			{
				BindGroupLayouts = Span<IBindGroupLayout>(bgls),
				PushConstantRanges = Span<PushConstantRange>(pushRanges),
				Label = "SkyboxPL"
			});
			if (r case .Err) return .Err;
			mSkyboxPL = r.Value;
		}

		// Skybox pipeline (fullscreen triangle, no vertex input)
		{
			let colorTargets = scope ColorTargetState[1];
			colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

			let r = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mSkyboxPL,
				Vertex = .() { Shader = .(mSkyboxVS, "VSMain" ) },
				Fragment = .() { Shader = .(mSkyboxPS, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Multisample = .(),
				Label = "SkyboxPipeline"
			});
			if (r case .Err) return .Err;
			mSkyboxPipeline = r.Value;
		}

		// Shadow test quad vertices (bottom-right corner overlay)
		{
			float[?] quadVerts = .(
				// pos xyz, uv
				 0.3f, -0.9f, 0.0f,   0.0f, 1.0f,
				 0.9f, -0.9f, 0.0f,   1.0f, 1.0f,
				 0.9f, -0.3f, 0.0f,   1.0f, 0.0f,
				 0.3f, -0.9f, 0.0f,   0.0f, 1.0f,
				 0.9f, -0.3f, 0.0f,   1.0f, 0.0f,
				 0.3f, -0.3f, 0.0f,   0.0f, 0.0f
			);

			uint32 vbSize = sizeof(decltype(quadVerts));
			let r = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "ShadowQuadVB" });
			if (r case .Err) return .Err;
			mQuadVB = r.Value;

			let batchR = mGraphicsQueue.CreateTransferBatch();
			if (batchR case .Err) return .Err;
			var xfer = batchR.Value;
			xfer.WriteBuffer(mQuadVB, 0, Span<uint8>((uint8*)&quadVerts[0], vbSize));
			xfer.Submit();
			mGraphicsQueue.DestroyTransferBatch(ref xfer);
		}

		// Shadow bind group layout: depth texture + comparison sampler
		{
			let entries = scope BindGroupLayoutEntry[2];
			entries[0] = BindGroupLayoutEntry.SampledTexture(0, .Fragment, .Texture2D);
			entries[1] = BindGroupLayoutEntry.ComparisonSampler(0, .Fragment);
			let r = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(entries), Label = "ShadowBGL" });
			if (r case .Err) return .Err;
			mShadowBGL = r.Value;
		}

		// Shadow bind group
		{
			let entries = scope BindGroupEntry[2];
			entries[0] = BindGroupEntry.Texture(mDepthView);
			entries[1] = BindGroupEntry.Sampler(mComparisonSampler);
			let r = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mShadowBGL, Entries = Span<BindGroupEntry>(entries), Label = "ShadowBG" });
			if (r case .Err) return .Err;
			mShadowBG = r.Value;
		}

		// Shadow pipeline layout
		{
			let bgls = scope IBindGroupLayout[1];
			bgls[0] = mShadowBGL;
			let pushRanges = scope PushConstantRange[1];
			pushRanges[0] = PushConstantRange() { Stages = .Vertex | .Fragment, Offset = 0, Size = sizeof(PushData) };
			let r = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
			{
				BindGroupLayouts = Span<IBindGroupLayout>(bgls),
				PushConstantRanges = Span<PushConstantRange>(pushRanges),
				Label = "ShadowPL"
			});
			if (r case .Err) return .Err;
			mShadowPL = r.Value;
		}

		// Shadow pipeline
		{
			let vertexAttribs = scope VertexAttribute[2];
			vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
			vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x2, Offset = 12 };
			let vertexLayouts = scope VertexBufferLayout[1];
			vertexLayouts[0] = VertexBufferLayout() { Stride = 20, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

			let colorTargets = scope ColorTargetState[1];
			colorTargets[0] = ColorTargetState() { Format = mSwapChain.Format, WriteMask = .All };

			let r = mDevice.CreateRenderPipeline(RenderPipelineDesc()
			{
				Layout = mShadowPL,
				Vertex = .() { Shader = .(mShadowVS, "VSMain"), Buffers = vertexLayouts },
				Fragment = .() { Shader = .(mShadowPS, "PSMain"), Targets = colorTargets },
				Primitive = PrimitiveState() { Topology = .TriangleList },
				Multisample = .(),
				Label = "ShadowPipeline"
			});
			if (r case .Err) return .Err;
			mShadowPipeline = r.Value;
		}

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private Result<void> CreateCubeMap()
	{
		const uint32 FaceSize = 64;
		const uint32 BytesPerPixel = 4;
		const uint32 FaceBytes = FaceSize * FaceSize * BytesPerPixel;

		// Create cube map texture: 2D array with 6 layers
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D,
			Format = .RGBA8UnormSrgb,
			Width = FaceSize,
			Height = FaceSize,
			ArrayLayerCount = 6,
			MipLevelCount = 1,
			SampleCount = 1,
			Usage = .Sampled | .CopyDst,
			Label = "CubeMapTex"
		});
		if (texR case .Err) return .Err;
		mCubeTexture = texR.Value;

		// Create cube view
		let viewR = mDevice.CreateTextureView(mCubeTexture, TextureViewDesc()
		{
			Format = .RGBA8UnormSrgb,
			Dimension = .TextureCube,
			BaseMipLevel = 0,
			MipLevelCount = 1,
			BaseArrayLayer = 0,
			ArrayLayerCount = 6
		});
		if (viewR case .Err) return .Err;
		mCubeView = viewR.Value;

		// Generate 6 face colors: +X red, -X cyan, +Y green, -Y magenta, +Z blue, -Z yellow
		uint8[6][4] faceColors = .(
			.(200, 60, 60, 255),    // +X: red
			.(60, 200, 200, 255),   // -X: cyan
			.(60, 200, 60, 255),    // +Y: green
			.(200, 60, 200, 255),   // -Y: magenta
			.(60, 60, 200, 255),    // +Z: blue
			.(200, 200, 60, 255)    // -Z: yellow
		);

		let stagingBuf = scope uint8[FaceBytes];
		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var xfer = batchR.Value;

		for (int face = 0; face < 6; face++)
		{
			// Fill face with gradient from face color to white at center
			for (uint32 y = 0; y < FaceSize; y++)
			{
				for (uint32 x = 0; x < FaceSize; x++)
				{
					float fx = ((float)x / (float)FaceSize) * 2.0f - 1.0f;
					float fy = ((float)y / (float)FaceSize) * 2.0f - 1.0f;
					float dist = Math.Min(1.0f, Math.Sqrt(fx * fx + fy * fy));
					float t = 1.0f - dist * 0.5f;

					int idx = (int)((y * FaceSize + x) * BytesPerPixel);
					stagingBuf[idx + 0] = (uint8)(faceColors[face][0] * t + 40 * (1.0f - t));
					stagingBuf[idx + 1] = (uint8)(faceColors[face][1] * t + 40 * (1.0f - t));
					stagingBuf[idx + 2] = (uint8)(faceColors[face][2] * t + 40 * (1.0f - t));
					stagingBuf[idx + 3] = 255;
				}
			}

			xfer.WriteTexture(mCubeTexture,
				Span<uint8>(&stagingBuf[0], (int)FaceBytes),
				TextureDataLayout() { Offset = 0, BytesPerRow = FaceSize * BytesPerPixel, RowsPerImage = FaceSize },
				Extent3D() { Width = FaceSize, Height = FaceSize, Depth = 1 },
				0, (uint32)face);
		}

		xfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref xfer);

		return .Ok;
	}

	private Result<void> CreateDepthTexture()
	{
		const uint32 TexSize = 64;

		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D,
			Format = .Depth32Float,
			Width = TexSize,
			Height = TexSize,
			ArrayLayerCount = 1,
			MipLevelCount = 1,
			SampleCount = 1,
			Usage = .DepthStencil | .Sampled,
			Label = "ShadowDepthTex"
		});
		if (texR case .Err) return .Err;
		mDepthTexture = texR.Value;

		let viewR = mDevice.CreateTextureView(mDepthTexture, TextureViewDesc()
		{
			Format = .Depth32Float,
			Dimension = .Texture2D
		});
		if (viewR case .Err) return .Err;
		mDepthView = viewR.Value;

		// We'll render a gradient depth in a render pass
		// For simplicity, just clear to 0.5 so the comparison sampler has something to compare against
		// (A real sample would render shadow casters here)

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		float aspect = (float)mWidth / (float)mHeight;

		// Render a depth value into the shadow depth texture
		{
			let dsAttach = DepthStencilAttachment()
			{
				View = mDepthView,
				DepthLoadOp = .Clear,
				DepthStoreOp = .Store,
				DepthClearValue = 0.5f
			};
			let rp = encoder.BeginRenderPass(RenderPassDesc()
			{
				DepthStencilAttachment = dsAttach
			});
			rp.End();
		}

		// Transition depth texture from DepthStencilWrite -> ShaderRead for sampling
		{
			let depthBarriers = scope TextureBarrier[1];
			depthBarriers[0] = TextureBarrier() { Texture = mDepthTexture, OldState = .DepthStencilWrite, NewState = .ShaderRead };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(depthBarriers) });
		}

		// Transition swapchain
		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.05f, 0.05f, 0.08f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca)
		});

		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);

		// Draw skybox (fullscreen triangle, no VB needed — SV_VertexID)
		rp.SetPipeline(mSkyboxPipeline);
		rp.SetBindGroup(0, mSkyboxBG);
		var pc = PushData() { Time = mTotalTime, AspectRatio = aspect };
		rp.SetPushConstants(.Vertex | .Fragment, 0, sizeof(PushData), &pc);
		rp.Draw(3);

		// Draw shadow comparison overlay quad
		rp.SetPipeline(mShadowPipeline);
		rp.SetBindGroup(0, mShadowBG);
		rp.SetPushConstants(.Vertex | .Fragment, 0, sizeof(PushData), &pc);
		rp.SetVertexBuffer(0, mQuadVB, 0);
		rp.Draw(6);

		rp.End();

		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		// Transition depth texture back to DepthStencilWrite for next frame
		{
			let depthBarriers = scope TextureBarrier[1];
			depthBarriers[0] = TextureBarrier() { Texture = mDepthTexture, OldState = .ShaderRead, NewState = .DepthStencilWrite };
			encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(depthBarriers) });
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
		if (mShadowPipeline != null) mDevice?.DestroyRenderPipeline(ref mShadowPipeline);
		if (mSkyboxPipeline != null) mDevice?.DestroyRenderPipeline(ref mSkyboxPipeline);
		if (mShadowPL != null) mDevice?.DestroyPipelineLayout(ref mShadowPL);
		if (mSkyboxPL != null) mDevice?.DestroyPipelineLayout(ref mSkyboxPL);
		if (mShadowBG != null) mDevice?.DestroyBindGroup(ref mShadowBG);
		if (mSkyboxBG != null) mDevice?.DestroyBindGroup(ref mSkyboxBG);
		if (mShadowBGL != null) mDevice?.DestroyBindGroupLayout(ref mShadowBGL);
		if (mSkyboxBGL != null) mDevice?.DestroyBindGroupLayout(ref mSkyboxBGL);
		if (mComparisonSampler != null) mDevice?.DestroySampler(ref mComparisonSampler);
		if (mLinearSampler != null) mDevice?.DestroySampler(ref mLinearSampler);
		if (mQuadVB != null) mDevice?.DestroyBuffer(ref mQuadVB);
		if (mDepthView != null) mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice?.DestroyTexture(ref mDepthTexture);
		if (mCubeView != null) mDevice?.DestroyTextureView(ref mCubeView);
		if (mCubeTexture != null) mDevice?.DestroyTexture(ref mCubeTexture);
		if (mShadowPS != null) mDevice?.DestroyShaderModule(ref mShadowPS);
		if (mShadowVS != null) mDevice?.DestroyShaderModule(ref mShadowVS);
		if (mSkyboxPS != null) mDevice?.DestroyShaderModule(ref mSkyboxPS);
		if (mSkyboxVS != null) mDevice?.DestroyShaderModule(ref mSkyboxVS);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope CubeMapSample();
		return app.Run();
	}
}
