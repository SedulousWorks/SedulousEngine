namespace SR001_ReflectedPBR;

using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.RHI;
using Sedulous.ShaderReflection;
using SampleFramework;

/// PBR sphere sample that uses shader reflection to automatically derive
/// bind group layouts, pipeline layout, and vertex attributes.
///
/// Instead of manually specifying BindGroupLayoutEntry arrays, PushConstantRanges,
/// and VertexAttributes, this sample:
///   1. Compiles the PBR shader (HLSL -> SPIR-V or DXIL)
///   2. Reflects the compiled bytecode to discover bindings, inputs, push constants
///   3. Uses ReflectionUtils to derive BindGroupLayouts, PushConstantRanges, VertexAttributes
///   4. Creates the pipeline layout and pipeline from the reflected data
class ReflectedPBRSample : SampleApp
{
	const String cShaderSource = """
		cbuffer SceneUBO : register(b0, space0)
		{
		    row_major float4x4 ViewProjection;
		    float3 CameraPos;
		    float _pad0;
		    float3 LightDir;
		    float _pad1;
		    float3 LightColor;
		    float LightIntensity;
		};

		struct MaterialData
		{
		    float3 Albedo;
		    float Metallic;
		    float Roughness;
		};

		[[vk::push_constant]]
		ConstantBuffer<MaterialData> Material : register(b0, space1);

		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float3 Normal   : TEXCOORD1;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float3 WorldPos : TEXCOORD0;
		    float3 Normal   : TEXCOORD1;
		};

		// --- Vertex Shader ---

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.WorldPos = input.Position;
		    output.Normal = input.Normal;
		    output.Position = mul(ViewProjection, float4(input.Position, 1.0));
		    return output;
		}

		// --- PBR helpers ---

		static const float PI = 3.14159265359;

		float DistributionGGX(float3 N, float3 H, float roughness)
		{
		    float a = roughness * roughness;
		    float a2 = a * a;
		    float NdotH = max(dot(N, H), 0.0);
		    float denom = NdotH * NdotH * (a2 - 1.0) + 1.0;
		    return a2 / (PI * denom * denom);
		}

		float GeometrySchlickGGX(float NdotV, float roughness)
		{
		    float r = roughness + 1.0;
		    float k = (r * r) / 8.0;
		    return NdotV / (NdotV * (1.0 - k) + k);
		}

		float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
		{
		    return GeometrySchlickGGX(max(dot(N, V), 0.0), roughness)
		         * GeometrySchlickGGX(max(dot(N, L), 0.0), roughness);
		}

		float3 FresnelSchlick(float cosTheta, float3 F0)
		{
		    return F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
		}

		// --- Pixel Shader ---

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    float3 N = normalize(input.Normal);
		    float3 V = normalize(CameraPos - input.WorldPos);
		    float3 L = normalize(-LightDir);
		    float3 H = normalize(V + L);

		    float3 albedo = Material.Albedo;
		    float metallic = Material.Metallic;
		    float roughness = Material.Roughness;

		    float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);

		    float NDF = DistributionGGX(N, H, roughness);
		    float G = GeometrySmith(N, V, L, roughness);
		    float3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);

		    float3 kD = (1.0 - F) * (1.0 - metallic);
		    float NdotL = max(dot(N, L), 0.0);

		    float3 numerator = NDF * G * F;
		    float denom = 4.0 * max(dot(N, V), 0.0) * NdotL + 0.0001;
		    float3 specular = numerator / denom;

		    float3 Lo = (kD * albedo / PI + specular) * LightColor * LightIntensity * NdotL;

		    // Simple ambient
		    float3 ambient = 0.03 * albedo;
		    float3 color = ambient + Lo;

		    // Tonemap (Reinhard) + gamma
		    color = color / (color + 1.0);
		    color = pow(color, 1.0 / 2.2);

		    return float4(color, 1.0);
		}
		""";

	// --- GPU resources ---
	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mSceneUBO;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private List<IBindGroupLayout> mBindGroupLayouts = new .() ~ delete _;
	private IBindGroup mSceneBindGroup;
	private IBindGroup mMaterialBindGroup;
	private IBuffer mMaterialUBO;
	private void* mMaterialUBOMapped;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ITexture mDepthTexture;
	private ITextureView mDepthView;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;
	private void* mSceneUBOMapped;

	// Sphere geometry
	private uint32 mIndexCount;

	// Reflected metadata
	private uint32 mReflectedVertexStride;
	private int mReflectedBindingCount;
	private int mReflectedPushConstantSize;
	private ShaderStage mPushConstantStages;
	private bool mUsePushConstants;

	// Reflection backends must be instantiated to force registration
	static Sedulous.ShaderReflection.SPIRV.SPIRVReflectionBackend sSpirvBackend = new .() ~ delete _;
	static Sedulous.ShaderReflection.DXIL.DXILReflectionBackend sDxilBackend = new .() ~ delete _;
	static this()
	{
		ShaderReflection.RegisterBackend(sSpirvBackend);
		ShaderReflection.RegisterBackend(sDxilBackend);
	}

	public this() :base(.DX12) { }

	protected override StringView Title => "SR001 - Reflected PBR Sphere";

	protected override Result<void> OnInit()
	{
		// --- 1. Compile shaders ---
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

		// --- 2. Reflect both shaders ---
		let reflFormat = (mBackendType == .Vulkan) ? ShaderFormat.SPIRV : ShaderFormat.DXIL;

		let vsReflResult = ShaderReflection.Reflect(reflFormat, Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), "VSMain");
		if (vsReflResult case .Err)
		{
			Console.WriteLine("ERROR: VS reflection failed");
			return .Err;
		}
		let vsRefl = vsReflResult.Value;
		defer delete vsRefl;

		let psReflResult = ShaderReflection.Reflect(reflFormat, Span<uint8>(psBytecode.Ptr, psBytecode.Count), "PSMain");
		if (psReflResult case .Err)
		{
			Console.WriteLine("ERROR: PS reflection failed");
			return .Err;
		}
		let psRefl = psReflResult.Value;
		defer delete psRefl;

		// --- 3. Print reflected info ---
		Console.WriteLine("=== Shader Reflection Results ===");
		Console.WriteLine("VS stage: {}, entry: {}", vsRefl.Stage, vsRefl.EntryPoint);
		Console.WriteLine("PS stage: {}, entry: {}", psRefl.Stage, psRefl.EntryPoint);

		Console.WriteLine("\nVS vertex inputs ({}):", vsRefl.VertexInputs.Count);
		for (let input in vsRefl.VertexInputs)
			Console.WriteLine("  location={} format={} name={}", input.Location, input.Format, input.Name);

		Console.WriteLine("\nVS bindings ({}):", vsRefl.Bindings.Count);
		for (let b in vsRefl.Bindings)
			Console.WriteLine("  set={} binding={} type={} name={}", b.Set, b.Binding, b.Type, b.Name);

		Console.WriteLine("\nPS bindings ({}):", psRefl.Bindings.Count);
		for (let b in psRefl.Bindings)
			Console.WriteLine("  set={} binding={} type={} name={}", b.Set, b.Binding, b.Type, b.Name);

		Console.WriteLine("\nVS push constants ({}):", vsRefl.PushConstants.Count);
		for (let pc in vsRefl.PushConstants)
			Console.WriteLine("  offset={} size={} stages={}", pc.Offset, pc.Size, pc.Stages);

		Console.WriteLine("\nPS push constants ({}):", psRefl.PushConstants.Count);
		for (let pc in psRefl.PushConstants)
			Console.WriteLine("  offset={} size={} stages={}", pc.Offset, pc.Size, pc.Stages);

		// --- 4. Derive vertex attributes from reflection ---
		let vertexAttribs = scope List<VertexAttribute>();
		ReflectionUtils.DeriveVertexAttributes(vsRefl, vertexAttribs);

		mReflectedVertexStride = 0;
		for (let attr in vertexAttribs)
			mReflectedVertexStride += ReflectionUtils.FormatByteSize(attr.Format);

		Console.WriteLine("\nDerived vertex layout (stride={}):", mReflectedVertexStride);
		for (let attr in vertexAttribs)
			Console.WriteLine("  location={} offset={} format={}", attr.ShaderLocation, attr.Offset, attr.Format);

		// --- 5. Derive bind group layouts from reflection ---
		ReflectedShader[2] shaders = .(vsRefl, psRefl);
		let entriesPerSet = scope List<List<BindGroupLayoutEntry>>();
		if (ReflectionUtils.DeriveBindGroupLayouts(Span<ReflectedShader>(&shaders[0], 2), entriesPerSet) case .Err)
		{
			Console.WriteLine("ERROR: DeriveBindGroupLayouts failed (binding conflict)");
			return .Err;
		}
		defer { for (let l in entriesPerSet) delete l; }

		Console.WriteLine("\nDerived bind group layouts ({} sets):", entriesPerSet.Count);
		for (int s = 0; s < entriesPerSet.Count; s++)
		{
			Console.WriteLine("  Set {}:", s);
			for (let entry in entriesPerSet[s])
				Console.WriteLine("    binding={} type={} visibility={}", entry.Binding, entry.Type, entry.Visibility);
		}

		mReflectedBindingCount = 0;
		for (let set in entriesPerSet)
			mReflectedBindingCount += set.Count;

		// --- 6. Derive push constant ranges from reflection ---
		let pushRanges = scope List<PushConstantRange>();
		ReflectionUtils.DerivePushConstantRanges(Span<ReflectedShader>(&shaders[0], 2), pushRanges);

		Console.WriteLine("\nDerived push constant ranges ({}):", pushRanges.Count);
		for (let range in pushRanges)
		{
			Console.WriteLine("  offset={} size={} stages={}", range.Offset, range.Size, range.Stages);
			mReflectedPushConstantSize = (int)range.Size;
			mPushConstantStages = range.Stages;
		}

		Console.WriteLine("=================================\n");

		// --- 7. Create GPU resources using reflected data ---

		// Shader modules
		mVertexShader = mDevice.CreateShaderModule(.() { Code = .(&vsBytecode[0], vsBytecode.Count), Label = "PBR_VS" }).Value;
		mPixelShader = mDevice.CreateShaderModule(.() { Code = .(&psBytecode[0], psBytecode.Count), Label = "PBR_PS" }).Value;

		// Generate sphere geometry
		GenerateSphere(32, 32);

		// Scene uniform buffer (CpuToGpu for per-frame updates)
		let uboSize = (uint64)(sizeof(float) * 28); // ViewProj(16) + CameraPos(3) + pad + LightDir(3) + pad + LightColor(3) + Intensity
		mSceneUBO = mDevice.CreateBuffer(.() { Size = uboSize, Usage = .Uniform, Memory = .CpuToGpu, Label = "SceneUBO" }).Value;
		mSceneUBOMapped = mSceneUBO.Map();

		// Create bind group layouts for ALL reflected sets
		for (int s = 0; s < entriesPerSet.Count; s++)
		{
			let setEntries = entriesPerSet[s];
			let label = scope String()..AppendF("BGL_Set{}", s);
			IBindGroupLayout bgl;
			if (setEntries.Count > 0)
				bgl = mDevice.CreateBindGroupLayout(.()
				{
					Entries = Span<BindGroupLayoutEntry>(&setEntries[0], setEntries.Count),
					Label = label
				}).Value;
			else
				bgl = mDevice.CreateBindGroupLayout(.() { Label = label }).Value;
			mBindGroupLayouts.Add(bgl);
		}

		// Scene bind group (set 0)
		let bgEntries = scope BindGroupEntry[1];
		bgEntries[0] = BindGroupEntry.Buffer(mSceneUBO, 0, uboSize);
		mSceneBindGroup = mDevice.CreateBindGroup(.()
		{
			Layout = mBindGroupLayouts[0],
			Entries = .(&bgEntries[0], 1),
			Label = "SceneBG"
		}).Value;

		// Material: push constants on Vulkan, UBO on DX12
		mUsePushConstants = pushRanges.Count > 0;
		if (!mUsePushConstants && mBindGroupLayouts.Count > 1)
		{
			// DX12 path: Material is a regular UBO at set 1
			let matSize = (uint64)(sizeof(float) * 5); // Albedo(3) + Metallic + Roughness
			mMaterialUBO = mDevice.CreateBuffer(.() { Size = matSize, Usage = .Uniform, Memory = .CpuToGpu, Label = "MaterialUBO" }).Value;
			mMaterialUBOMapped = mMaterialUBO.Map();

			let matBgEntries = scope BindGroupEntry[1];
			matBgEntries[0] = BindGroupEntry.Buffer(mMaterialUBO, 0, matSize);
			mMaterialBindGroup = mDevice.CreateBindGroup(.()
			{
				Layout = mBindGroupLayouts[1],
				Entries = .(&matBgEntries[0], 1),
				Label = "MaterialBG"
			}).Value;
		}

		// Pipeline layout using all reflected bind group layouts + push constant ranges
		let bglSpan = scope IBindGroupLayout[mBindGroupLayouts.Count];
		for (int i = 0; i < mBindGroupLayouts.Count; i++)
			bglSpan[i] = mBindGroupLayouts[i];
		mPipelineLayout = mDevice.CreatePipelineLayout(.()
		{
			BindGroupLayouts = .(bglSpan),
			PushConstantRanges = pushRanges.Count > 0 ? .(&pushRanges[0], pushRanges.Count) : default,
			Label = "PBR_PL"
		}).Value;

		// Vertex buffer layout from reflected attributes
		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = .()
		{
			Stride = mReflectedVertexStride,
			StepMode = .Vertex,
			Attributes = .(&vertexAttribs[0], vertexAttribs.Count)
		};

		// Depth buffer
		if (CreateDepthBuffer() case .Err) return .Err;

		// Color target
		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = .() { Format = mSwapChain.Format, WriteMask = .All };

		// Render pipeline
		mPipeline = mDevice.CreateRenderPipeline(.()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList, CullMode = .Back, FrontFace = .CW },
			DepthStencil = .() { Format = .Depth24PlusStencil8, DepthWriteEnabled = true, DepthCompare = .Less },
			Label = "PBR_Pipeline"
		}).Value;

		// Command pool and fence
		mCommandPool = mDevice.CreateCommandPool(.Graphics).Value;
		mFrameFence = mDevice.CreateFence(0).Value;
		mFrameFenceValue = 0;

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;

		UpdateSceneUBO();

		mCommandPool.Reset();
		var encoder = mCommandPool.CreateEncoder().Value;

		// Barrier: present -> render target
		TextureBarrier[1] texBarriers = .(.() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget });
		encoder.Barrier(.() { TextureBarriers = .(&texBarriers[0], 1) });

		// Render pass
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear, StoreOp = .Store,
			ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f)
		});

		let rp = encoder.BeginRenderPass(.()
		{
			ColorAttachments = .(colorAttachments),
			DepthStencilAttachment = .()
			{
				View = mDepthView,
				DepthLoadOp = .Clear, DepthStoreOp = .Store, DepthClearValue = 1.0f
			}
		});

		rp.SetPipeline(mPipeline);
		rp.SetBindGroup(0, mSceneBindGroup);
		rp.SetViewport(0, 0, (.)mWidth, (.)mHeight, 0, 1);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// Material parameters (animated)
		float t = mTotalTime * 0.3f;
		float[5] material = .(
			0.9f, 0.2f, 0.2f,                          // Albedo (red)
			(Math.Sin(t) * 0.5f + 0.5f),               // Metallic: 0..1
			Math.Clamp(Math.Cos(t * 0.7f) * 0.4f + 0.5f, 0.05f, 0.95f) // Roughness: 0.05..0.95
		);

		if (mUsePushConstants)
		{
			// Vulkan: push constants
			rp.SetPushConstants(mPushConstantStages, 0, 20, &material[0]);
		}
		else if (mMaterialUBO != null)
		{
			// DX12: update Material UBO and bind set 1
			Internal.MemCpy(mMaterialUBOMapped, &material[0], 20);
			rp.SetBindGroup(1, mMaterialBindGroup);
		}

		rp.DrawIndexed(mIndexCount);
		rp.End();

		// Barrier: render target -> present
		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(.() { TextureBarriers = .(&texBarriers[0], 1) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(.(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);

		mCommandPool.DestroyEncoder(ref encoder);
	}

	private void UpdateSceneUBO()
	{
		float aspect = (float)mWidth / (float)mHeight;
		float angle = mTotalTime * 0.5f;

		// Camera orbits around the sphere
		float camDist = 3.0f;
		float camX = Math.Sin(angle) * camDist;
		float camZ = Math.Cos(angle) * camDist;
		float camY = 1.5f;

		float[16] view = default;
		MakeLookAt(ref view, camX, camY, camZ, 0, 0, 0);
		float[16] proj = default;
		MakePerspective(ref proj, 45.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);
		float[16] viewProj = default;
		MatMul4x4(ref viewProj, ref proj, ref view);

		// Layout: ViewProjection(64) + CameraPos(12) + pad(4) + LightDir(12) + pad(4) + LightColor(12) + Intensity(4)
		float* ptr = (float*)mSceneUBOMapped;
		Internal.MemCpy(ptr, &viewProj[0], 64);
		ptr[16] = camX; ptr[17] = camY; ptr[18] = camZ; ptr[19] = 0;
		ptr[20] = -0.5f; ptr[21] = -1.0f; ptr[22] = -0.3f; ptr[23] = 0;
		ptr[24] = 1.0f; ptr[25] = 0.95f; ptr[26] = 0.9f; ptr[27] = 3.0f;
	}

	private void GenerateSphere(int stacks, int slices)
	{
		let vertCount = (stacks + 1) * (slices + 1);
		let idxCount = stacks * slices * 6;
		mIndexCount = (uint32)idxCount;

		let vertData = scope float[vertCount * 6]; // pos(3) + normal(3)
		let indexData = scope uint16[idxCount];

		int v = 0;
		for (int i = 0; i <= stacks; i++)
		{
			float phi = Math.PI_f * (float)i / (float)stacks;
			float sinPhi = Math.Sin(phi);
			float cosPhi = Math.Cos(phi);

			for (int j = 0; j <= slices; j++)
			{
				float theta = 2.0f * Math.PI_f * (float)j / (float)slices;
				float x = sinPhi * Math.Cos(theta);
				float y = cosPhi;
				float z = sinPhi * Math.Sin(theta);

				vertData[v++] = x; vertData[v++] = y; vertData[v++] = z; // position
				vertData[v++] = x; vertData[v++] = y; vertData[v++] = z; // normal = position (unit sphere)
			}
		}

		int idx = 0;
		for (int i = 0; i < stacks; i++)
		{
			for (int j = 0; j < slices; j++)
			{
				int a = i * (slices + 1) + j;
				int b = a + slices + 1;
				indexData[idx++] = (uint16)a;
				indexData[idx++] = (uint16)(b + 1);
				indexData[idx++] = (uint16)b;
				indexData[idx++] = (uint16)a;
				indexData[idx++] = (uint16)(a + 1);
				indexData[idx++] = (uint16)(b + 1);
			}
		}

		let vbSize = (uint64)(vertCount * 6 * sizeof(float));
		let ibSize = (uint64)(idxCount * sizeof(uint16));

		mVertexBuffer = mDevice.CreateBuffer(.() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "SphereVB" }).Value;
		mIndexBuffer = mDevice.CreateBuffer(.() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "SphereIB" }).Value;

		var transfer = mGraphicsQueue.CreateTransferBatch().Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&vertData[0], (int)vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indexData[0], (int)ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);
	}

	private Result<void> CreateDepthBuffer()
	{
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);

		mDepthTexture = mDevice.CreateTexture(.()
		{
			Dimension = .Texture2D, Format = .Depth24PlusStencil8,
			Width = mWidth, Height = mHeight,
			Usage = .DepthStencil, Label = "DepthBuffer"
		}).Value;

		mDepthView = mDevice.CreateTextureView(mDepthTexture, .()
		{
			Format = .Depth24PlusStencil8, Dimension = .Texture2D
		}).Value;

		return .Ok;
	}

	protected override void OnResize(uint32 width, uint32 height)
	{
		CreateDepthBuffer();
	}

	// --- Math helpers (row-major 4x4) ---

	private static void MakeLookAt(ref float[16] m, float ex, float ey, float ez, float tx, float ty, float tz)
	{
		float fx = tx - ex, fy = ty - ey, fz = tz - ez;
		float fl = Math.Sqrt(fx*fx + fy*fy + fz*fz);
		fx /= fl; fy /= fl; fz /= fl;

		float rx = fz, ry = 0, rz = -fx;
		float rl = Math.Sqrt(rx*rx + rz*rz);
		rx /= rl; rz /= rl;

		float ux = fy*rz - fz*ry, uy = fz*rx - fx*rz, uz = fx*ry - fy*rx;

		m[0] = rx;  m[1] = ry;  m[2] = rz;  m[3] = -(rx*ex + ry*ey + rz*ez);
		m[4] = ux;  m[5] = uy;  m[6] = uz;  m[7] = -(ux*ex + uy*ey + uz*ez);
		m[8] = fx;  m[9] = fy;  m[10]= fz;  m[11]= -(fx*ex + fy*ey + fz*ez);
		m[12]= 0;   m[13]= 0;   m[14]= 0;   m[15]= 1;
	}

	private static void MakePerspective(ref float[16] m, float fov, float aspect, float near, float far)
	{
		float h = 1.0f / Math.Tan(fov * 0.5f);
		float w = h / aspect;
		float r = far / (far - near);
		m[0] = w; m[1] = 0; m[2] = 0;  m[3] = 0;
		m[4] = 0; m[5] = h; m[6] = 0;  m[7] = 0;
		m[8] = 0; m[9] = 0; m[10]= r;  m[11]= -near * r;
		m[12]= 0; m[13]= 0; m[14]= 1;  m[15]= 0;
	}

	private static void MatMul4x4(ref float[16] o, ref float[16] a, ref float[16] b)
	{
		for (int row < 4)
			for (int col < 4)
			{
				float s = 0;
				for (int k < 4)
					s += a[row*4+k] * b[k*4+col];
				o[row*4+col] = s;
			}
	}

	protected override void OnShutdown()
	{
		if (mSceneUBO != null && mSceneUBOMapped != null) mSceneUBO.Unmap();
		if (mMaterialUBO != null && mMaterialUBOMapped != null) mMaterialUBO.Unmap();
		if (mFrameFence != null)       mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)      mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null)         mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mDepthView != null)        mDevice?.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null)     mDevice?.DestroyTexture(ref mDepthTexture);
		if (mPipelineLayout != null)   mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mMaterialBindGroup != null) mDevice?.DestroyBindGroup(ref mMaterialBindGroup);
		if (mSceneBindGroup != null)   mDevice?.DestroyBindGroup(ref mSceneBindGroup);
		for (var bgl in ref mBindGroupLayouts)
			if (bgl != null) mDevice?.DestroyBindGroupLayout(ref bgl);
		if (mMaterialUBO != null)      mDevice?.DestroyBuffer(ref mMaterialUBO);
		if (mSceneUBO != null)         mDevice?.DestroyBuffer(ref mSceneUBO);
		if (mPixelShader != null)      mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null)     mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null)      mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null)     mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope ReflectedPBRSample();
		return app.Run();
	}
}
