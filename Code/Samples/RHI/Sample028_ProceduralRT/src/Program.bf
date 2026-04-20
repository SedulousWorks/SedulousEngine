namespace Sample028_ProceduralRT;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates procedural ray tracing geometry using AABBs.
/// Renders spheres via intersection shaders inside axis-aligned bounding boxes.
/// Tests GeometryType.AABBs, ProceduralHitGroup, IntersectionShaderIndex.
class ProceduralRTSample : SampleApp
{
	const String cRtShaderSource = """
		[[vk::image_format("rgba8")]] RWTexture2D<float4> gOutput : register(u0, space0);
		RaytracingAccelerationStructure gScene : register(t0, space0);

		struct RayPayload
		{
		    float3 Color;
		    float HitT;
		    float2 UV;
		    float2 _pad;
		};

		struct SphereAttribs
		{
		    float3 Normal;
		    float HitDist;
		};

		[shader("raygeneration")]
		void RayGen()
		{
		    uint2 launchIndex = DispatchRaysIndex().xy;
		    uint2 launchDim = DispatchRaysDimensions().xy;

		    float2 uv = (float2(launchIndex) + 0.5) / float2(launchDim);
		    float2 ndc = uv * 2.0 - 1.0;
		    ndc.y = -ndc.y;
		    float aspect = float(launchDim.x) / float(launchDim.y);
		    ndc.x *= aspect;

		    RayDesc ray;
		    ray.Origin = float3(ndc.x * 2.0, ndc.y * 2.0, -3.0);
		    ray.Direction = float3(0.0, 0.0, 1.0);
		    ray.TMin = 0.001;
		    ray.TMax = 100.0;

		    RayPayload payload;
		    payload.Color = float3(0.0, 0.0, 0.0);
		    payload.HitT = -1.0;
		    payload.UV = uv;
		    payload._pad = float2(0, 0);

		    TraceRay(gScene, RAY_FLAG_FORCE_OPAQUE, 0xFF, 0, 0, 0, ray, payload);

		    gOutput[launchIndex] = float4(payload.Color, 1.0);
		}

		[shader("intersection")]
		void SphereIntersection()
		{
		    // AABB center is at origin of the geometry instance, radius 0.5
		    float3 center = float3(0, 0, 0);
		    float radius = 0.45;

		    float3 origin = ObjectRayOrigin();
		    float3 dir = ObjectRayDirection();
		    float3 oc = origin - center;

		    float a = dot(dir, dir);
		    float b = 2.0 * dot(oc, dir);
		    float c = dot(oc, oc) - radius * radius;
		    float discriminant = b * b - 4.0 * a * c;

		    if (discriminant >= 0.0)
		    {
		        float t = (-b - sqrt(discriminant)) / (2.0 * a);
		        if (t >= RayTMin() && t <= RayTCurrent())
		        {
		            float3 hitPos = origin + t * dir;
		            float3 normal = normalize(hitPos - center);

		            SphereAttribs attribs;
		            attribs.Normal = normal;
		            attribs.HitDist = t;
		            ReportHit(t, 0, attribs);
		        }
		    }
		}

		[shader("closesthit")]
		void ClosestHit(inout RayPayload payload, SphereAttribs attribs)
		{
		    // Simple diffuse shading
		    float3 lightDir = normalize(float3(0.5, 1.0, -0.5));
		    float3 normal = normalize(mul((float3x3)ObjectToWorld3x4(), attribs.Normal));
		    float ndotl = max(0.0, dot(normal, lightDir));
		    float ambient = 0.15;

		    // Color based on instance index
		    uint instID = InstanceIndex();
		    float3 baseColor;
		    if (instID == 0) baseColor = float3(1.0, 0.3, 0.3);
		    else if (instID == 1) baseColor = float3(0.3, 1.0, 0.3);
		    else if (instID == 2) baseColor = float3(0.3, 0.3, 1.0);
		    else baseColor = float3(1.0, 1.0, 0.3);

		    payload.Color = baseColor * (ndotl + ambient);
		    payload.HitT = attribs.HitDist;
		}

		[shader("miss")]
		void Miss(inout RayPayload payload)
		{
		    payload.Color = float3(0.05, 0.05, 0.1) + float3(0.0, 0.0, 0.15) * payload.UV.y;
		    payload.HitT = -1.0;
		}
		""";

	const int SphereCount = 4;

	private ShaderCompiler mShaderCompiler;
	private IRayTracingExt mRtExt;
	private IShaderModule mRtShaderModule;
	private IRayTracingPipeline mRtPipeline;
	private IAccelStruct mBlas;
	private IAccelStruct mTlas;
	private IBuffer mScratchBuffer;
	private IBuffer mAabbBuffer;
	private IBuffer mInstanceBuffer;
	private IBuffer mSbtBuffer;
	private IPipelineLayout mRtPipelineLayout;
	private IBindGroupLayout mRtBindGroupLayout;
	private IBindGroup mRtBindGroup;
	private ITexture mOutputTexture;
	private ITextureView mOutputTextureView;
	private ResourceState mOutputTextureState = .Undefined;
	private uint32 mSbtAlignedStride;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() : base(.DX12) { }

	protected override StringView Title => "Sample028 - Procedural RT (AABB Spheres)";
	protected override DeviceFeatures RequiredFeatures => .() { RayTracing = true };

	protected override Result<void> OnInit()
	{
		mRtExt = mDevice.GetRayTracingExt();
		if (mRtExt == null)
		{
			Console.WriteLine("ERROR: Ray tracing not supported");
			return .Err;
		}

		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let errors = scope String();

		let rtBytecode = scope List<uint8>();
		if (mShaderCompiler.CompileRayTracingLib(cRtShaderSource, "", format, rtBytecode, errors) case .Err)
		{
			Console.WriteLine("RT compile: {}", errors);
			return .Err;
		}

		let modR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(rtBytecode.Ptr, rtBytecode.Count), Label = "ProcRTLib" });
		if (modR case .Err) return .Err;
		mRtShaderModule = modR.Value;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		// Output texture
		let texR = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D, Format = .RGBA8Unorm,
			Width = mWidth, Height = mHeight, ArrayLayerCount = 1,
			MipLevelCount = 1, SampleCount = 1,
			Usage = .Storage | .CopySrc, Label = "ProcRTOutput"
		});
		if (texR case .Err) return .Err;
		mOutputTexture = texR.Value;

		let tvR = mDevice.CreateTextureView(mOutputTexture, TextureViewDesc() { Label = "ProcRTOutputView" });
		if (tvR case .Err) return .Err;
		mOutputTextureView = tvR.Value;

		// AABB buffer: one AABB per sphere (6 floats: minX, minY, minZ, maxX, maxY, maxZ)
		// All AABBs are unit cubes [-0.5, 0.5] centered at origin - instance transforms position them
		{
			float[?] aabbs = .(
				-0.5f, -0.5f, -0.5f, 0.5f, 0.5f, 0.5f
			);
			uint32 aabbSize = sizeof(decltype(aabbs));

			let r = mDevice.CreateBuffer(BufferDesc()
			{
				Size = aabbSize, Usage = .AccelStructInput | .CopyDst, Memory = .GpuOnly, Label = "AABBBuffer"
			});
			if (r case .Err) return .Err;
			mAabbBuffer = r.Value;

			let batchR = mGraphicsQueue.CreateTransferBatch();
			if (batchR case .Err) return .Err;
			var xfer = batchR.Value;
			xfer.WriteBuffer(mAabbBuffer, 0, Span<uint8>((uint8*)&aabbs[0], aabbSize));
			xfer.Submit();
			mGraphicsQueue.DestroyTransferBatch(ref xfer);
		}

		// Acceleration structures
		let blasR = mRtExt.CreateAccelStruct(AccelStructDesc() { Type = .BottomLevel, Label = "ProcBLAS" });
		if (blasR case .Err) return .Err;
		mBlas = blasR.Value;

		let tlasR = mRtExt.CreateAccelStruct(AccelStructDesc() { Type = .TopLevel, Label = "ProcTLAS" });
		if (tlasR case .Err) return .Err;
		mTlas = tlasR.Value;

		// Scratch buffer
		let scrR = mDevice.CreateBuffer(BufferDesc()
		{
			Size = 256 * 1024, Usage = .AccelStructScratch, Memory = .GpuOnly, Label = "ProcScratch"
		});
		if (scrR case .Err) return .Err;
		mScratchBuffer = scrR.Value;

		// Instance buffer: 4 spheres at different positions
		{
			let instR = mDevice.CreateBuffer(BufferDesc()
			{
				Size = (uint32)(64 * SphereCount), Usage = .AccelStructInput, Memory = .CpuToGpu, Label = "ProcInstances"
			});
			if (instR case .Err) return .Err;
			mInstanceBuffer = instR.Value;

			uint8* ptr = (uint8*)mInstanceBuffer.Map();
			if (ptr == null) return .Err;

			float[4][3] positions = .(
				.(-1.0f,  0.5f, 0.0f),
				.( 1.0f,  0.5f, 0.0f),
				.(-1.0f, -0.5f, 0.0f),
				.( 1.0f, -0.5f, 0.0f)
			);

			for (int i = 0; i < SphereCount; i++)
			{
				uint8* inst = ptr + i * 64;
				Internal.MemSet(inst, 0, 64);

				// 3x4 row-major transform
				float* xform = (float*)inst;
				xform[0] = 1.0f; xform[3] = positions[i][0];
				xform[5] = 1.0f; xform[7] = positions[i][1];
				xform[10] = 1.0f; xform[11] = positions[i][2];

				// Instance custom index + mask
				inst[48] = 0; inst[49] = 0; inst[50] = 0;
				inst[51] = 0xFF;

				// SBT offset + flags
				inst[52] = 0; inst[53] = 0; inst[54] = 0;
				inst[55] = 0x04; // FORCE_OPAQUE

				*(uint64*)(inst + 56) = mBlas.DeviceAddress;
			}

			mInstanceBuffer.Unmap();
		}

		// Build BLAS from AABB geometry, then TLAS
		{
			let encR = mCommandPool.CreateEncoder();
			if (encR case .Err) return .Err;
			var encoder = encR.Value;

			if (let rtEnc = encoder as IRayTracingEncoderExt)
			{
				let aabbGeoms = scope AccelStructGeometryAABBs[1];
				aabbGeoms[0] = AccelStructGeometryAABBs()
				{
					AABBBuffer = mAabbBuffer,
					Offset = 0,
					Count = 1,
					Stride = 24,
					Flags = .Opaque
				};

				rtEnc.BuildBottomLevelAccelStruct(mBlas, mScratchBuffer, 0,
					default, Span<AccelStructGeometryAABBs>(aabbGeoms));

				let memBarriers = scope MemoryBarrier[1];
				memBarriers[0] = MemoryBarrier() { OldState = .AccelStructWrite, NewState = .AccelStructRead };
				encoder.Barrier(BarrierGroup() { MemoryBarriers = Span<MemoryBarrier>(memBarriers) });

				rtEnc.BuildTopLevelAccelStruct(mTlas, mScratchBuffer, 0,
					mInstanceBuffer, 0, (uint32)SphereCount);
			}
			else
			{
				mCommandPool.DestroyEncoder(ref encoder);
				return .Err;
			}

			var cmdBuf = encoder.Finish();
			mFrameFenceValue++;
			mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
			mFrameFence.Wait(mFrameFenceValue);
			mCommandPool.Reset();
			mCommandPool.DestroyEncoder(ref encoder);
		}

		Console.WriteLine("Procedural BLAS/TLAS built.");

		// Bind group
		{
			let layoutEntries = scope BindGroupLayoutEntry[2];
			layoutEntries[0] = BindGroupLayoutEntry.StorageTexture(0, .RayGen, .RGBA8Unorm, readWrite: true);
			layoutEntries[1] = BindGroupLayoutEntry()
			{
				Binding = 0, Visibility = .RayGen | .ClosestHit, Type = .AccelerationStructure, Count = 1
			};

			let bglR = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
			{
				Entries = Span<BindGroupLayoutEntry>(layoutEntries), Label = "ProcRTBGL"
			});
			if (bglR case .Err) return .Err;
			mRtBindGroupLayout = bglR.Value;

			let bgEntries = scope BindGroupEntry[2];
			bgEntries[0] = BindGroupEntry.Texture(mOutputTextureView);
			bgEntries[1] = BindGroupEntry.AccelStruct(mTlas);

			let bgR = mDevice.CreateBindGroup(BindGroupDesc()
			{
				Layout = mRtBindGroupLayout, Entries = Span<BindGroupEntry>(bgEntries), Label = "ProcRTBG"
			});
			if (bgR case .Err) return .Err;
			mRtBindGroup = bgR.Value;
		}

		// RT pipeline
		{
			let bglSpan = scope IBindGroupLayout[1];
			bglSpan[0] = mRtBindGroupLayout;

			let plR = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
			{
				BindGroupLayouts = Span<IBindGroupLayout>(bglSpan), Label = "ProcRTPL"
			});
			if (plR case .Err) return .Err;
			mRtPipelineLayout = plR.Value;

			// 4 stages: RayGen, Intersection, ClosestHit, Miss
			let stages = scope ProgrammableStage[4];
			stages[0] = ProgrammableStage() { Module = mRtShaderModule, EntryPoint = "RayGen", Stage = .RayGen };
			stages[1] = ProgrammableStage() { Module = mRtShaderModule, EntryPoint = "SphereIntersection", Stage = .Intersection };
			stages[2] = ProgrammableStage() { Module = mRtShaderModule, EntryPoint = "ClosestHit", Stage = .ClosestHit };
			stages[3] = ProgrammableStage() { Module = mRtShaderModule, EntryPoint = "Miss", Stage = .Miss };

			// 3 groups: raygen, procedural hit group (intersection + closest hit), miss
			let groups = scope RayTracingShaderGroup[3];
			groups[0] = RayTracingShaderGroup() { Type = .General, GeneralShaderIndex = 0 };
			groups[1] = RayTracingShaderGroup()
			{
				Type = .ProceduralHitGroup,
				IntersectionShaderIndex = 1,
				ClosestHitShaderIndex = 2
			};
			groups[2] = RayTracingShaderGroup() { Type = .General, GeneralShaderIndex = 3 };

			let pipR = mRtExt.CreateRayTracingPipeline(RayTracingPipelineDesc()
			{
				Layout = mRtPipelineLayout,
				Stages = Span<ProgrammableStage>(stages),
				Groups = Span<RayTracingShaderGroup>(groups),
				MaxRecursionDepth = 1,
				MaxPayloadSize = 32, // RayPayload: float3 + float + float2 + float2
				MaxAttributeSize = 16, // SphereAttribs: float3 Normal + float HitDist
				Label = "ProcRTPipeline"
			});
			if (pipR case .Err) { Console.WriteLine("ERROR: CreateRayTracingPipeline failed"); return .Err; }
			mRtPipeline = pipR.Value;
		}

		// SBT
		{
			let handleSize = mRtExt.ShaderGroupHandleSize;
			let baseAlignment = mRtExt.ShaderGroupBaseAlignment;
			uint32 groupCount = 3;
			mSbtAlignedStride = (handleSize + baseAlignment - 1) & ~(baseAlignment - 1);

			let handleData = scope uint8[handleSize * groupCount];
			if (mRtExt.GetShaderGroupHandles(mRtPipeline, 0, groupCount, Span<uint8>(handleData)) case .Err)
			{
				Console.WriteLine("ERROR: GetShaderGroupHandles failed");
				return .Err;
			}

			let sbtSize = mSbtAlignedStride * groupCount;
			let sbtR = mDevice.CreateBuffer(BufferDesc()
			{
				Size = sbtSize, Usage = .ShaderBindingTable, Memory = .CpuToGpu, Label = "ProcSBT"
			});
			if (sbtR case .Err) return .Err;
			mSbtBuffer = sbtR.Value;

			uint8* sbtPtr = (uint8*)mSbtBuffer.Map();
			if (sbtPtr == null) return .Err;
			Internal.MemSet(sbtPtr, 0, (.)sbtSize);
			for (uint32 i = 0; i < groupCount; i++)
				Internal.MemCpy(sbtPtr + (i * mSbtAlignedStride), &handleData[(int)(i * handleSize)], (.)handleSize);
			mSbtBuffer.Unmap();
		}

		Console.WriteLine("Procedural RT sample ready.");
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

		// Transition output to ShaderWrite
		let texBarriers = scope TextureBarrier[2];
		texBarriers[0] = TextureBarrier() { Texture = mOutputTexture, OldState = mOutputTextureState, NewState = .ShaderWrite };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(&texBarriers[0], 1) });

		// TraceRays
		if (let rtEnc = encoder as IRayTracingEncoderExt)
		{
			rtEnc.SetRayTracingPipeline(mRtPipeline);
			rtEnc.SetBindGroup(0, mRtBindGroup);

			let stride = (uint64)mSbtAlignedStride;
			rtEnc.TraceRays(
				mSbtBuffer, 0, stride,
				mSbtBuffer, (uint64)(2 * mSbtAlignedStride), stride,
				mSbtBuffer, (uint64)(1 * mSbtAlignedStride), stride,
				mWidth, mHeight);
		}

		// Copy to swapchain
		texBarriers[0] = TextureBarrier() { Texture = mOutputTexture, OldState = .ShaderWrite, NewState = .CopySrc };
		texBarriers[1] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .CopyDst };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		mOutputTextureState = .CopySrc;
		encoder.CopyTextureToTexture(mOutputTexture, mSwapChain.CurrentTexture,
			TextureCopyRegion() { Extent = Extent3D(mWidth, mHeight, 1) });

		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .CopyDst, NewState = .Present };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(&texBarriers[0], 1) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mRtBindGroup != null) mDevice?.DestroyBindGroup(ref mRtBindGroup);
		if (mRtBindGroupLayout != null) mDevice?.DestroyBindGroupLayout(ref mRtBindGroupLayout);
		if (mOutputTextureView != null) mDevice?.DestroyTextureView(ref mOutputTextureView);
		if (mOutputTexture != null) mDevice?.DestroyTexture(ref mOutputTexture);
		if (mSbtBuffer != null) mDevice?.DestroyBuffer(ref mSbtBuffer);
		if (mRtPipeline != null && mRtExt != null) mRtExt.DestroyRayTracingPipeline(ref mRtPipeline);
		if (mRtPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mRtPipelineLayout);
		if (mInstanceBuffer != null) mDevice?.DestroyBuffer(ref mInstanceBuffer);
		if (mScratchBuffer != null) mDevice?.DestroyBuffer(ref mScratchBuffer);
		if (mTlas != null && mRtExt != null) mRtExt.DestroyAccelStruct(ref mTlas);
		if (mBlas != null && mRtExt != null) mRtExt.DestroyAccelStruct(ref mBlas);
		if (mAabbBuffer != null) mDevice?.DestroyBuffer(ref mAabbBuffer);
		if (mRtShaderModule != null) mDevice?.DestroyShaderModule(ref mRtShaderModule);
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope ProceduralRTSample();
		return app.Run();
	}
}
