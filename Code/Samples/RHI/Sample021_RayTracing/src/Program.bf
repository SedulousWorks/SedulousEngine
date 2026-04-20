namespace Sample021_RayTracing;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

class RayTracingSample : SampleApp
{
	// Ray tracing shader library (compiled as lib_6_3).
	// All RT entry points are in a single source compiled once as a library.
	const String cRtShaderSource = """
		[[vk::image_format("rgba8")]] RWTexture2D<float4> gOutput : register(u0, space0);
		RaytracingAccelerationStructure gScene : register(t0, space0);

		struct RayPayload
		{
		    float3 Color;
		};

		[shader("raygeneration")]
		void RayGen()
		{
		    uint2 launchIndex = DispatchRaysIndex().xy;
		    uint2 launchDim = DispatchRaysDimensions().xy;

		    float2 uv = (float2(launchIndex) + 0.5) / float2(launchDim);
		    float2 ndc = uv * 2.0 - 1.0;
		    ndc.y = -ndc.y;

		    RayDesc ray;
		    ray.Origin = float3(ndc.x, ndc.y, -1.0);
		    ray.Direction = float3(0.0, 0.0, 1.0);
		    ray.TMin = 0.001;
		    ray.TMax = 100.0;

		    RayPayload payload;
		    payload.Color = float3(0.0, 0.0, 0.0);

		    TraceRay(gScene, RAY_FLAG_FORCE_OPAQUE, 0xFF, 0, 0, 0, ray, payload);

		    gOutput[launchIndex] = float4(payload.Color, 1.0);
		}

		[shader("closesthit")]
		void ClosestHit(inout RayPayload payload, BuiltInTriangleIntersectionAttributes attribs)
		{
		    float3 bary = float3(1.0 - attribs.barycentrics.x - attribs.barycentrics.y,
		                         attribs.barycentrics.x,
		                         attribs.barycentrics.y);

		    payload.Color = float3(bary.x, bary.y, bary.z);
		}

		[shader("miss")]
		void Miss(inout RayPayload payload)
		{
		    float2 uv = (float2(DispatchRaysIndex().xy) + 0.5) / float2(DispatchRaysDimensions().xy);
		    payload.Color = float3(0.1, 0.1, 0.2) + float3(0.0, 0.0, 0.3) * uv.y;
		}
		""";

	// BLAS triangle positions only (float3 per vertex, no color)
	static float[9] sBlasVertexData = .(
		 0.0f,  0.5f, 0.0f,
		-0.5f, -0.5f, 0.0f,
		 0.5f, -0.5f, 0.0f
	);

	private ShaderCompiler mShaderCompiler;
	private IRayTracingExt mRtExt;

	// RT resources
	private IShaderModule mRtShaderModule;
	private IRayTracingPipeline mRtPipeline;
	private IAccelStruct mBlas;
	private IAccelStruct mTlas;
	private IBuffer mScratchBuffer;
	private IBuffer mRtVertexBuffer;   // Triangle for BLAS
	private IBuffer mInstanceBuffer;   // TLAS instance data
	private IBuffer mSbtBuffer;        // Shader binding table
	private IPipelineLayout mRtPipelineLayout;
	private IBindGroupLayout mRtBindGroupLayout;
	private IBindGroup mRtBindGroup;

	// RT output texture
	private ITexture mOutputTexture;
	private ITextureView mOutputTextureView;
	private ResourceState mOutputTextureState = .Undefined;

	// SBT layout info (cached for TraceRays)
	private uint32 mSbtAlignedStride;

	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample021 - Ray Tracing (TraceRays)";

	protected override DeviceFeatures RequiredFeatures => .() { RayTracing = true };

	protected override Result<void> OnInit()
	{
		// ---- Check ray tracing extension availability ----
		mRtExt = mDevice.GetRayTracingExt();
		if (mRtExt == null)
		{
			Console.WriteLine("ERROR: Ray tracing is not supported by this device/backend");
			return .Err;
		}

		Console.WriteLine("Ray tracing extension available:");
		Console.WriteLine("  ShaderGroupHandleSize:      {}", mRtExt.ShaderGroupHandleSize);
		Console.WriteLine("  ShaderGroupHandleAlignment: {}", mRtExt.ShaderGroupHandleAlignment);
		Console.WriteLine("  ShaderGroupBaseAlignment:   {}", mRtExt.ShaderGroupBaseAlignment);

		// ---- Shader compiler ----
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err)
		{
			Console.WriteLine("ERROR: ShaderCompiler.Init failed");
			return .Err;
		}

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let errors = scope String();

		// ---- Compile RT shader library (lib_6_3) ----
		let rtBytecode = scope List<uint8>();
		if (mShaderCompiler.CompileRayTracingLib(cRtShaderSource, "", format, rtBytecode, errors) case .Err)
		{
			Console.WriteLine("RT lib compile failed: {}", errors);
			return .Err;
		}

		let rtModResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(rtBytecode.Ptr, rtBytecode.Count), Label = "RTShaderLib" });
		if (rtModResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (RT) failed"); return .Err; }
		mRtShaderModule = rtModResult.Value;

		// ---- Command pool and fence ----
		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) { Console.WriteLine("ERROR: CreateCommandPool failed"); return .Err; }
		mCommandPool = poolResult.Value;

		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) { Console.WriteLine("ERROR: CreateFence failed"); return .Err; }
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		// ---- Create RT output texture (storage + copy source) ----
		let texResult = mDevice.CreateTexture(TextureDesc()
		{
			Dimension = .Texture2D,
			Format = .RGBA8Unorm,
			Width = (.)mWidth,
			Height = (.)mHeight,
			ArrayLayerCount = 1,
			MipLevelCount = 1,
			SampleCount = 1,
			Usage = .Storage | .CopySrc,
			Label = "RTOutputTex"
		});
		if (texResult case .Err) { Console.WriteLine("ERROR: CreateTexture (RT output) failed"); return .Err; }
		mOutputTexture = texResult.Value;

		let tvResult = mDevice.CreateTextureView(mOutputTexture, TextureViewDesc() { Label = "RTOutputView" });
		if (tvResult case .Err) { Console.WriteLine("ERROR: CreateTextureView (RT output) failed"); return .Err; }
		mOutputTextureView = tvResult.Value;

		// ---- Create BLAS vertex buffer (3 vertices * 12 bytes = 36 bytes) ----
		let rtVbResult = mDevice.CreateBuffer(BufferDesc()
		{
			Size = 36,
			Usage = .AccelStructInput | .CopyDst,
			Memory = .GpuOnly,
			Label = "BLAS_VB"
		});
		if (rtVbResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (BLAS VB) failed"); return .Err; }
		mRtVertexBuffer = rtVbResult.Value;

		// Upload BLAS vertex data
		{
			let batch = mGraphicsQueue.CreateTransferBatch();
			if (batch case .Err) { Console.WriteLine("ERROR: CreateTransferBatch failed"); return .Err; }
			var transfer = batch.Value;
			transfer.WriteBuffer(mRtVertexBuffer, 0, Span<uint8>((uint8*)&sBlasVertexData[0], 36));
			transfer.Submit();
			mGraphicsQueue.DestroyTransferBatch(ref transfer);
		}

		// ---- Create acceleration structures ----
		let blasResult = mRtExt.CreateAccelStruct(AccelStructDesc() { Type = .BottomLevel, Label = "BLAS" });
		if (blasResult case .Err) { Console.WriteLine("ERROR: CreateAccelStruct (BLAS) failed"); return .Err; }
		mBlas = blasResult.Value;

		let tlasResult = mRtExt.CreateAccelStruct(AccelStructDesc() { Type = .TopLevel, Label = "TLAS" });
		if (tlasResult case .Err) { Console.WriteLine("ERROR: CreateAccelStruct (TLAS) failed"); return .Err; }
		mTlas = tlasResult.Value;

		// ---- Create scratch buffer (256 KB) ----
		let scratchResult = mDevice.CreateBuffer(BufferDesc()
		{
			Size = 256 * 1024,
			Usage = .AccelStructScratch,
			Memory = .GpuOnly,
			Label = "ScratchBuffer"
		});
		if (scratchResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (scratch) failed"); return .Err; }
		mScratchBuffer = scratchResult.Value;

		// ---- Create instance buffer (64 bytes = sizeof(VkAccelerationStructureInstanceKHR)) ----
		let instResult = mDevice.CreateBuffer(BufferDesc()
		{
			Size = 64,
			Usage = .AccelStructInput,
			Memory = .CpuToGpu,
			Label = "InstanceBuffer"
		});
		if (instResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (instance) failed"); return .Err; }
		mInstanceBuffer = instResult.Value;

		// Fill instance data
		{
			uint8* ptr = (uint8*)mInstanceBuffer.Map();
			if (ptr == null) { Console.WriteLine("ERROR: Failed to map instance buffer"); return .Err; }
			Internal.MemSet(ptr, 0, 64);

			// Identity transform (3x4 row-major float matrix)
			float* transform = (float*)ptr;
			transform[0] = 1.0f;  // row 0, col 0
			transform[5] = 1.0f;  // row 1, col 1
			transform[10] = 1.0f; // row 2, col 2

			// instanceCustomIndex (24 bit) + mask (8 bit) at offset 48
			ptr[48] = 0; ptr[49] = 0; ptr[50] = 0; // customIndex = 0
			ptr[51] = 0xFF; // mask

			// SBT offset (24 bit) + flags (8 bit) at offset 52
			ptr[52] = 0; ptr[53] = 0; ptr[54] = 0; // sbtOffset = 0
			ptr[55] = 0x04; // VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_KHR

			// accelerationStructureReference at offset 56
			*(uint64*)(ptr + 56) = mBlas.DeviceAddress;

			mInstanceBuffer.Unmap();
		}

		// ---- Build BLAS and TLAS ----
		{
			let encoderResult = mCommandPool.CreateEncoder();
			if (encoderResult case .Err) { Console.WriteLine("ERROR: CreateEncoder (accel build) failed"); return .Err; }
			var encoder = encoderResult.Value;

			if (let rtEnc = encoder as IRayTracingEncoderExt)
			{
				// Build BLAS from triangle geometry
				let triGeoms = scope AccelStructGeometryTriangles[1];
				triGeoms[0] = AccelStructGeometryTriangles()
				{
					VertexBuffer = mRtVertexBuffer,
					VertexOffset = 0,
					VertexCount = 3,
					VertexStride = 12,
					VertexFormat = .Float32x3,
					Flags = .Opaque
				};

				rtEnc.BuildBottomLevelAccelStruct(mBlas, mScratchBuffer, 0,
					Span<AccelStructGeometryTriangles>(triGeoms), default);

				// Barrier between BLAS and TLAS build
				let memBarriers = scope MemoryBarrier[1];
				memBarriers[0] = MemoryBarrier()
				{
					OldState = .AccelStructWrite,
					NewState = .AccelStructRead
				};
				encoder.Barrier(BarrierGroup()
				{
					MemoryBarriers = Span<MemoryBarrier>(memBarriers)
				});

				// Build TLAS from instances
				rtEnc.BuildTopLevelAccelStruct(mTlas, mScratchBuffer, 0,
					mInstanceBuffer, 0, 1);
			}
			else
			{
				Console.WriteLine("ERROR: Command encoder does not support ray tracing");
				mCommandPool.DestroyEncoder(ref encoder);
				return .Err;
			}

			var cmdBuf = encoder.Finish();
			mFrameFenceValue++;
			mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);

			// Wait for build to complete
			mFrameFence.Wait(mFrameFenceValue);
			mCommandPool.Reset();

			mCommandPool.DestroyEncoder(ref encoder);
		}

		Console.WriteLine("BLAS and TLAS built successfully.");
		Console.WriteLine("  BLAS DeviceAddress: 0x{0:X}", mBlas.DeviceAddress);
		Console.WriteLine("  TLAS DeviceAddress: 0x{0:X}", mTlas.DeviceAddress);

		// ---- Create RT bind group layout and bind group ----
		{
			// binding 0 (u0): RWTexture2D - storage texture, read-write
			// binding 0 (t0): RaytracingAccelerationStructure - TLAS
			// Both use register 0 in different HLSL spaces (u vs t),
			// mapped to different Vulkan bindings via shifts (UAV=2000, SRV=1000).
			let layoutEntries = scope BindGroupLayoutEntry[2];
			layoutEntries[0] = BindGroupLayoutEntry.StorageTexture(0, .RayGen, .RGBA8Unorm, readWrite: true);
			layoutEntries[1] = BindGroupLayoutEntry()
			{
				Binding = 0,
				Visibility = .RayGen,
				Type = .AccelerationStructure,
				Count = 1
			};

			let bglResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
			{
				Entries = Span<BindGroupLayoutEntry>(layoutEntries),
				Label = "RTBindGroupLayout"
			});
			if (bglResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout (RT) failed"); return .Err; }
			mRtBindGroupLayout = bglResult.Value;

			// Create bind group with output texture + TLAS
			let bgEntries = scope BindGroupEntry[2];
			bgEntries[0] = BindGroupEntry.Texture(mOutputTextureView);
			bgEntries[1] = BindGroupEntry.AccelStruct(mTlas);

			let bgResult = mDevice.CreateBindGroup(BindGroupDesc()
			{
				Layout = mRtBindGroupLayout,
				Entries = Span<BindGroupEntry>(bgEntries),
				Label = "RTBindGroup"
			});
			if (bgResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup (RT) failed"); return .Err; }
			mRtBindGroup = bgResult.Value;
		}

		// ---- Create RT pipeline layout with bind group ----
		{
			let bglSpan = scope IBindGroupLayout[1];
			bglSpan[0] = mRtBindGroupLayout;

			let rtPlResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
			{
				BindGroupLayouts = Span<IBindGroupLayout>(bglSpan),
				Label = "RTPipelineLayout"
			});
			if (rtPlResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout (RT) failed"); return .Err; }
			mRtPipelineLayout = rtPlResult.Value;

			// 3 stages: RayGen, ClosestHit, Miss - all from the same shader module
			let stages = scope ProgrammableStage[3];
			stages[0] = ProgrammableStage() { Module = mRtShaderModule, EntryPoint = "RayGen", Stage = .RayGen };
			stages[1] = ProgrammableStage() { Module = mRtShaderModule, EntryPoint = "ClosestHit", Stage = .ClosestHit };
			stages[2] = ProgrammableStage() { Module = mRtShaderModule, EntryPoint = "Miss", Stage = .Miss };

			// 3 groups: raygen (general), hit group (triangles), miss (general)
			let groups = scope RayTracingShaderGroup[3];
			groups[0] = RayTracingShaderGroup() { Type = .General, GeneralShaderIndex = 0 };
			groups[1] = RayTracingShaderGroup() { Type = .TrianglesHitGroup, ClosestHitShaderIndex = 1 };
			groups[2] = RayTracingShaderGroup() { Type = .General, GeneralShaderIndex = 2 };

			let rtPipResult = mRtExt.CreateRayTracingPipeline(RayTracingPipelineDesc()
			{
				Layout = mRtPipelineLayout,
				Stages = Span<ProgrammableStage>(stages),
				Groups = Span<RayTracingShaderGroup>(groups),
				MaxRecursionDepth = 1,
				Label = "RTPipeline"
			});
			if (rtPipResult case .Err) { Console.WriteLine("ERROR: CreateRayTracingPipeline failed"); return .Err; }
			mRtPipeline = rtPipResult.Value;
		}

		Console.WriteLine("Ray tracing pipeline created successfully.");

		// ---- Build Shader Binding Table ----
		{
			let handleSize = mRtExt.ShaderGroupHandleSize;
			let baseAlignment = mRtExt.ShaderGroupBaseAlignment;
			uint32 groupCount = 3;

			// Aligned handle stride (round up to base alignment)
			mSbtAlignedStride = (handleSize + baseAlignment - 1) & ~(baseAlignment - 1);

			// Get shader group handles
			let handleData = scope uint8[handleSize * groupCount];
			if (mRtExt.GetShaderGroupHandles(mRtPipeline, 0, groupCount, Span<uint8>(handleData)) case .Err)
			{
				Console.WriteLine("ERROR: GetShaderGroupHandles failed");
				return .Err;
			}

			// Create SBT buffer: 3 entries, each aligned to baseAlignment
			let sbtSize = mSbtAlignedStride * groupCount;
			let sbtResult = mDevice.CreateBuffer(BufferDesc()
			{
				Size = sbtSize,
				Usage = .ShaderBindingTable,
				Memory = .CpuToGpu,
				Label = "SBTBuffer"
			});
			if (sbtResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (SBT) failed"); return .Err; }
			mSbtBuffer = sbtResult.Value;

			// Copy handles into SBT with proper alignment
			uint8* sbtPtr = (uint8*)mSbtBuffer.Map();
			if (sbtPtr == null) { Console.WriteLine("ERROR: Failed to map SBT buffer"); return .Err; }
			Internal.MemSet(sbtPtr, 0, (.)sbtSize);

			for (uint32 i = 0; i < groupCount; i++)
			{
				Internal.MemCpy(sbtPtr + (i * mSbtAlignedStride), &handleData[(int)(i * handleSize)], (.)handleSize);
			}
			mSbtBuffer.Unmap();

			Console.WriteLine("SBT built: handleSize={}, baseAlignment={}, alignedStride={}, totalSize={}",
				handleSize, baseAlignment, mSbtAlignedStride, sbtSize);
		}

		Console.WriteLine("RT sample ready - TraceRays rendering active.");

		return .Ok;
	}

	protected override void OnRender()
	{
		// Wait for previous frame
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		// Acquire next swap chain image
		if (mSwapChain.AcquireNextImage() case .Err) return;

		// Reset and create encoder
		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// ---- Transition output texture to ShaderWrite for TraceRays ----
		let texBarriers = scope TextureBarrier[2];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mOutputTexture,
			OldState = mOutputTextureState,
			NewState = .ShaderWrite
		};
		encoder.Barrier(BarrierGroup()
		{
			TextureBarriers = Span<TextureBarrier>(&texBarriers[0], 1)
		});

		// ---- Dispatch TraceRays ----
		if (let rtEnc = encoder as IRayTracingEncoderExt)
		{
			rtEnc.SetRayTracingPipeline(mRtPipeline);
			rtEnc.SetBindGroup(0, mRtBindGroup);

			// SBT layout: [0] = raygen, [1] = hit, [2] = miss
			let raygenOffset = (uint64)0;
			let hitOffset = (uint64)(1 * mSbtAlignedStride);
			let missOffset = (uint64)(2 * mSbtAlignedStride);
			let stride = (uint64)mSbtAlignedStride;

			rtEnc.TraceRays(
				mSbtBuffer, raygenOffset, stride,
				mSbtBuffer, missOffset, stride,
				mSbtBuffer, hitOffset, stride,
				(.)mWidth, (.)mHeight);
		}

		// ---- Transition: output texture ShaderWrite -> CopySrc, swapchain Present -> CopyDst ----
		texBarriers[0] = TextureBarrier()
		{
			Texture = mOutputTexture,
			OldState = .ShaderWrite,
			NewState = .CopySrc
		};
		texBarriers[1] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .CopyDst
		};
		encoder.Barrier(BarrierGroup()
		{
			TextureBarriers = Span<TextureBarrier>(texBarriers)
		});

		// ---- Copy RT output to swapchain ----
		mOutputTextureState = .CopySrc;
		encoder.CopyTextureToTexture(mOutputTexture, mSwapChain.CurrentTexture,
			TextureCopyRegion()
			{
				Extent = Extent3D((.)mWidth, (.)mHeight, 1)
			});

		// ---- Transition swapchain CopyDst -> Present ----
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .CopyDst,
			NewState = .Present
		};
		encoder.Barrier(BarrierGroup()
		{
			TextureBarriers = Span<TextureBarrier>(&texBarriers[0], 1)
		});

		// Finish and submit
		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);

		// Present
		mSwapChain.Present(mGraphicsQueue);

		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		// RT bind group
		if (mRtBindGroup != null)
			mDevice?.DestroyBindGroup(ref mRtBindGroup);
		if (mRtBindGroupLayout != null)
			mDevice?.DestroyBindGroupLayout(ref mRtBindGroupLayout);

		// RT output texture
		if (mOutputTextureView != null)
			mDevice?.DestroyTextureView(ref mOutputTextureView);
		if (mOutputTexture != null)
			mDevice?.DestroyTexture(ref mOutputTexture);

		// RT resources
		if (mSbtBuffer != null)
			mDevice?.DestroyBuffer(ref mSbtBuffer);
		if (mRtPipeline != null && mRtExt != null)
			mRtExt.DestroyRayTracingPipeline(ref mRtPipeline);
		if (mRtPipelineLayout != null)
			mDevice?.DestroyPipelineLayout(ref mRtPipelineLayout);
		if (mInstanceBuffer != null)
			mDevice?.DestroyBuffer(ref mInstanceBuffer);
		if (mScratchBuffer != null)
			mDevice?.DestroyBuffer(ref mScratchBuffer);
		if (mTlas != null && mRtExt != null)
			mRtExt.DestroyAccelStruct(ref mTlas);
		if (mBlas != null && mRtExt != null)
			mRtExt.DestroyAccelStruct(ref mBlas);
		if (mRtVertexBuffer != null)
			mDevice?.DestroyBuffer(ref mRtVertexBuffer);
		if (mRtShaderModule != null)
			mDevice?.DestroyShaderModule(ref mRtShaderModule);

		if (mFrameFence != null)
			mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)
			mDevice?.DestroyCommandPool(ref mCommandPool);

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
		let app = scope RayTracingSample();
		return app.Run();
	}
}
