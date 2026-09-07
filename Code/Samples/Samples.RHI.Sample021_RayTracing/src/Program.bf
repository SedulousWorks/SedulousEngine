using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample021_RayTracing;

/// A triangle traced with real rays rather than rasterised.
///
/// The whole ray tracing path in one place: a bottom level structure over the triangle, a
/// top level one over a single instance of it, a pipeline of three shader groups, a shader
/// binding table wiring the groups to the trace, and a storage image the rays write into
/// which is then copied to the screen.
class RayTracingSample : SampleApp
{
	/// ONE library, compiled once. Every ray tracing entry point lives in it and the
	/// pipeline picks them out by name, which is why the profile is `lib` rather than a
	/// per stage one.
	private const String cRayTracingSource = """
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

	/// Positions only: an acceleration structure needs geometry, not shading data.
	private static float[9] sTriangleVertices = .(
		 0.0f,  0.5f, 0.0f,
		-0.5f, -0.5f, 0.0f,
		 0.5f, -0.5f, 0.0f);

	/// Raygen, hit group, miss.
	private const uint32 cShaderGroupCount = 3;
	/// A VkAccelerationStructureInstanceKHR.
	private const uint64 cInstanceSize = 64;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mShaderLibrary = null;
	private IRayTracingPipeline mPipeline = null;
	private IAccelStruct mBottomLevel = null;
	private IAccelStruct mTopLevel = null;
	private IBuffer mScratchBuffer = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mInstanceBuffer = null;
	private IBuffer mShaderBindingTable = null;
	private IPipelineLayout mPipelineLayout = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private ITexture mOutputTexture = null;
	private ITextureView mOutputTextureView = null;
	/// Tracked across frames, because the first frame's old state is Undefined and every
	/// later frame's is the copy source it was left in.
	private ResourceState mOutputTextureState = .Undefined;
	private uint32 mShaderBindingTableStride = 0;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample021 - Ray Tracing (TraceRays)";

	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.RayTracing = true;
			return features;
		}
	}

	protected override Result<void> OnInit()
	{
		if (!mDevice.Features.RayTracing)
		{
			Console.Error.WriteLine("Sample021: this device does not support ray tracing");
			return .Err;
		}

		Console.WriteLine("Ray tracing extension available:");
		Console.WriteLine(scope $"  shaderGroupHandleSize:      {mDevice.ShaderGroupHandleSize}");
		Console.WriteLine(scope $"  shaderGroupHandleAlignment: {mDevice.ShaderGroupHandleAlignment}");
		Console.WriteLine(scope $"  shaderGroupBaseAlignment:   {mDevice.ShaderGroupBaseAlignment}");

		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		// An EMPTY entry point and shader model 6.3: a library has no single entry, and
		// the ray tracing stages do not exist below 6.3.
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cRayTracingSource, .RayGen,
			"", "RTShaderLib", "6_3") case .Ok(let library)))
		{
			Console.Error.WriteLine("Sample021: the ray tracing library did not compile");
			return .Err;
		}
		mShaderLibrary = library;

		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return .Err;
		mPool = pool;
		if (!(mDevice.CreateFence(0) case .Ok(let fence)))
			return .Err;
		mFence = fence;

		if (CreateOutputTexture(mWidth, mHeight) case .Err)
			return .Err;
		if (CreateGeometry() case .Err)
			return .Err;
		if (BuildAccelerationStructures() case .Err)
			return .Err;
		if (CreateBindings() case .Err)
			return .Err;
		if (CreatePipeline() case .Err)
			return .Err;
		if (BuildShaderBindingTable() case .Err)
			return .Err;

		Console.WriteLine("RT sample ready, TraceRays rendering active.");
		return .Ok;
	}

	/// Storage, because rays WRITE into it, and a copy source because it is then copied to
	/// the screen. It is never a render target: nothing rasterises here.
	private Result<void> CreateOutputTexture(uint32 width, uint32 height)
	{
		var textureDesc = TextureDesc();
		textureDesc.Dimension = .Texture2D;
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.ArrayLayerCount = 1;
		textureDesc.MipLevelCount = 1;
		textureDesc.SampleCount = 1;
		textureDesc.Usage = .Storage | .CopySrc;
		textureDesc.Label = "RTOutputTex";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mOutputTexture = texture;
		mOutputTextureState = .Undefined;

		var viewDesc = TextureViewDesc();
		viewDesc.Label = "RTOutputView";
		if (!(mDevice.CreateTextureView(mOutputTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mOutputTextureView = view;
		return .Ok;
	}

	private Result<void> CreateGeometry()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = 36;
		// AccelStructInput, so the buffer can be reached by device address during a build.
		vertexDesc.Usage = .AccelStructInput | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		vertexDesc.Label = "BLAS_VB";
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0, .((uint8*)&sTriangleVertices[0], 36));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		var scratchDesc = BufferDesc();
		scratchDesc.Size = 256 * 1024;
		scratchDesc.Usage = .AccelStructScratch;
		scratchDesc.Memory = .GpuOnly;
		scratchDesc.Label = "ScratchBuffer";
		if (!(mDevice.CreateBuffer(scratchDesc) case .Ok(let scratchBuffer)))
			return .Err;
		mScratchBuffer = scratchBuffer;

		var instanceDesc = BufferDesc();
		instanceDesc.Size = cInstanceSize;
		instanceDesc.Usage = .AccelStructInput;
		instanceDesc.Memory = .CpuToGpu;
		instanceDesc.Label = "InstanceBuffer";
		if (!(mDevice.CreateBuffer(instanceDesc) case .Ok(let instanceBuffer)))
			return .Err;
		mInstanceBuffer = instanceBuffer;
		return .Ok;
	}

	private Result<void> BuildAccelerationStructures()
	{
		var bottomDesc = AccelStructDesc();
		bottomDesc.Type = .BottomLevel;
		bottomDesc.Label = "BLAS";
		if (!(mDevice.CreateAccelStruct(bottomDesc) case .Ok(let bottomLevel)))
			return .Err;
		mBottomLevel = bottomLevel;

		var topDesc = AccelStructDesc();
		topDesc.Type = .TopLevel;
		topDesc.Label = "TLAS";
		if (!(mDevice.CreateAccelStruct(topDesc) case .Ok(let topLevel)))
			return .Err;
		mTopLevel = topLevel;

		WriteInstanceRecord();

		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return .Err;

		let rayTracing = encoder as IRayTracingEncoderExt;
		if (rayTracing == null)
		{
			Console.Error.WriteLine("Sample021: the encoder does not support ray tracing");
			mPool.DestroyEncoder(ref encoder);
			return .Err;
		}

		var triangles = AccelStructGeometryTriangles();
		triangles.VertexBuffer = mVertexBuffer;
		triangles.VertexOffset = 0;
		triangles.VertexCount = 3;
		triangles.VertexStride = 12;
		triangles.VertexFormat = .Float32x3;
		triangles.Flags = .Opaque;
		rayTracing.BuildBottomLevelAccelStruct(mBottomLevel, mScratchBuffer, 0,
			.(&triangles, 1), .());

		// The top level build READS what the bottom level build wrote, and both use the
		// same scratch buffer, so they cannot overlap.
		var memoryBarrier = MemoryBarrier();
		memoryBarrier.OldState = .AccelStructWrite;
		memoryBarrier.NewState = .AccelStructRead;
		var group = BarrierGroup();
		group.MemoryBarriers = .(&memoryBarrier, 1);
		encoder.Barrier(group);

		rayTracing.BuildTopLevelAccelStruct(mTopLevel, mScratchBuffer, 0, mInstanceBuffer, 0, 1);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		// BLOCKING: nothing else can proceed until the structures exist.
		mFence.Wait(mFenceValue);
		mPool.Reset();
		mPool.DestroyEncoder(ref encoder);

		Console.WriteLine("BLAS and TLAS built successfully.");
		Console.WriteLine(scope $"  BLAS DeviceAddress: 0x{mBottomLevel.DeviceAddress:X}");
		Console.WriteLine(scope $"  TLAS DeviceAddress: 0x{mTopLevel.DeviceAddress:X}");
		return .Ok;
	}

	/// Fills the one instance record by hand.
	///
	/// The layout is a Vulkan and DXR ABI rather than an RHI type, so it is written as raw
	/// bytes: a 3x4 row major transform, then packed index and mask, then packed offset and
	/// flags, then the bottom level structure's device address.
	private void WriteInstanceRecord()
	{
		let bytes = (uint8*)mInstanceBuffer.Map();
		if (bytes == null)
			return;
		Internal.MemSet(bytes, 0, (int)cInstanceSize);

		let transform = (float*)bytes;
		transform[0] = 1.0f;
		transform[5] = 1.0f;
		transform[10] = 1.0f;

		// A mask of zero would make the instance invisible to every ray.
		bytes[51] = 0xFF;
		// VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_KHR, matching the ray flags in the shader.
		bytes[55] = 0x04;
		*(uint64*)(bytes + 56) = mBottomLevel.DeviceAddress;

		mInstanceBuffer.Unmap();
	}

	private Result<void> CreateBindings()
	{
		// Both at register zero but in different HLSL classes, u0 and t0, which the
		// backend's binding shifts push onto different Vulkan bindings.
		// Each element is .(), not a bare array: Beef's Type[N]() zero-fills, while a
		// struct's field initialisers only run for .().
		var layoutEntries = BindGroupLayoutEntry[2](.(), .());
		layoutEntries[0].Binding = 0;
		layoutEntries[0].Visibility = .RayGen;
		layoutEntries[0].Type = .StorageTextureReadWrite;
		layoutEntries[0].StorageTextureFormat = .RGBA8Unorm;
		layoutEntries[0].Count = 1;
		layoutEntries[1].Binding = 0;
		layoutEntries[1].Visibility = .RayGen;
		layoutEntries[1].Type = .AccelerationStructure;
		layoutEntries[1].Count = 1;

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		layoutDesc.Label = "RTBindGroupLayout";
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mBindGroupLayout = layout;

		return CreateBindGroup();
	}

	/// Rebuilt on resize as well as at startup, because it names the output view.
	private Result<void> CreateBindGroup()
	{
		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(mOutputTextureView),
			BindGroupEntry.AccelStructEntry(mTopLevel));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mBindGroupLayout;
		groupDesc.Entries = entries;
		groupDesc.Label = "RTBindGroup";
		if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
			return .Err;
		mBindGroup = bindGroup;
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		var layouts = IBindGroupLayout[1](mBindGroupLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		pipelineLayoutDesc.Label = "RTPipelineLayout";
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		// Three stages, ALL from the one library, told apart by entry point name.
		var stages = ProgrammableStage[3](
			.(mShaderLibrary, "RayGen", .RayGen),
			.(mShaderLibrary, "ClosestHit", .ClosestHit),
			.(mShaderLibrary, "Miss", .Miss));

		// Groups are what the binding table indexes, and they are not the same as stages:
		// a hit group can gather several stages under one entry.
		// .() per element, so UnusedShader actually lands in the slots this group does
		// not use. A zero-filled array would name shader zero in every slot instead.
		var groups = RayTracingShaderGroup[3](.(), .(), .());
		groups[0].Type = .General;
		groups[0].GeneralShaderIndex = 0;
		groups[1].Type = .TrianglesHitGroup;
		groups[1].ClosestHitShaderIndex = 1;
		groups[2].Type = .General;
		groups[2].GeneralShaderIndex = 2;

		var desc = RayTracingPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Stages = stages;
		desc.Groups = groups;
		// One: the shader traces a ray and never traces another from a hit.
		desc.MaxRecursionDepth = 1;
		desc.Label = "RTPipeline";

		if (!(mDevice.CreateRayTracingPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;

		Console.WriteLine("Ray tracing pipeline created successfully.");
		return .Ok;
	}

	/// Builds the table that maps a trace's group indices to actual shaders.
	///
	/// The handles come from the driver and must sit at the ALIGNMENT it asks for, which is
	/// usually larger than a handle, so the table is strided rather than packed.
	private Result<void> BuildShaderBindingTable()
	{
		let handleSize = mDevice.ShaderGroupHandleSize;
		let baseAlignment = mDevice.ShaderGroupBaseAlignment;
		mShaderBindingTableStride = (handleSize + baseAlignment - 1) & ~(baseAlignment - 1);

		let handles = scope uint8[handleSize * cShaderGroupCount];
		if (mDevice.GetShaderGroupHandles(mPipeline, 0, cShaderGroupCount, handles) case .Err)
		{
			Console.Error.WriteLine("Sample021: GetShaderGroupHandles failed");
			return .Err;
		}

		let tableSize = (uint64)mShaderBindingTableStride * cShaderGroupCount;
		var tableDesc = BufferDesc();
		tableDesc.Size = tableSize;
		tableDesc.Usage = .ShaderBindingTable;
		tableDesc.Memory = .CpuToGpu;
		tableDesc.Label = "SBTBuffer";
		if (!(mDevice.CreateBuffer(tableDesc) case .Ok(let table)))
			return .Err;
		mShaderBindingTable = table;

		let mapped = (uint8*)mShaderBindingTable.Map();
		if (mapped == null)
		{
			Console.Error.WriteLine("Sample021: the shader binding table could not be mapped");
			return .Err;
		}
		Internal.MemSet(mapped, 0, (int)tableSize);
		for (uint32 i < cShaderGroupCount)
		{
			// Handles are read packed and written STRIDED: the gap between them is what
			// the alignment requires.
			Internal.MemCpy(mapped + (i * mShaderBindingTableStride),
				&handles[i * handleSize], handleSize);
		}
		mShaderBindingTable.Unmap();

		Console.WriteLine(scope $"SBT built: handleSize={handleSize}, baseAlignment={baseAlignment}, alignedStride={mShaderBindingTableStride}, totalSize={tableSize}");
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mOutputTexture, mOutputTextureState, .ShaderWrite);

		if (let rayTracing = encoder as IRayTracingEncoderExt)
		{
			rayTracing.SetRayTracingPipeline(mPipeline);
			rayTracing.SetBindGroup(0, mBindGroup, default);

			// The table's three slots in the order they were written: raygen, hit, miss.
			let stride = (uint64)mShaderBindingTableStride;
			rayTracing.TraceRays(
				mShaderBindingTable, 0, stride,
				mShaderBindingTable, stride * 2, stride,
				mShaderBindingTable, stride * 1, stride,
				mWidth, mHeight, 1);
		}

		// Both sides of the copy in ONE barrier, since they are independent and issuing
		// two would only add a second pipeline stall.
				var barriers = TextureBarrier[2](.(), .());
		barriers[0].Texture = mOutputTexture;
		barriers[0].OldState = .ShaderWrite;
		barriers[0].NewState = .CopySrc;
		barriers[1].Texture = mSwapChain.CurrentTexture;
		barriers[1].OldState = .Present;
		barriers[1].NewState = .CopyDst;
		var group = BarrierGroup();
		group.TextureBarriers = barriers;
		encoder.Barrier(group);
		mOutputTextureState = .CopySrc;

		var region = TextureCopyRegion();
		region.Extent = .(mWidth, mHeight, 1);
		encoder.CopyTextureToTexture(mOutputTexture, mSwapChain.CurrentTexture, region);

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .CopyDst, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	protected override void OnResize(uint32 width, uint32 height)
	{
		// The output texture is being destroyed, and the GPU may still be reading it.
		if (mFence != null)
			mFence.Wait(mFenceValue);

		if (mBindGroup != null) mDevice.DestroyBindGroup(ref mBindGroup);
		if (mOutputTextureView != null) mDevice.DestroyTextureView(ref mOutputTextureView);
		if (mOutputTexture != null) mDevice.DestroyTexture(ref mOutputTexture);

		if (CreateOutputTexture(width, height) case .Err)
			return;
		// The bind group named the old view, so it is rebuilt over the new one.
		CreateBindGroup().IgnoreError();
	}

	protected override void OnShutdown()
	{
		if (mShaderBindingTable != null) mDevice.DestroyBuffer(ref mShaderBindingTable);
		if (mPipeline != null) mDevice.DestroyRayTracingPipeline(ref mPipeline);
		if (mBindGroup != null) mDevice.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mOutputTextureView != null) mDevice.DestroyTextureView(ref mOutputTextureView);
		if (mOutputTexture != null) mDevice.DestroyTexture(ref mOutputTexture);
		if (mTopLevel != null) mDevice.DestroyAccelStruct(ref mTopLevel);
		if (mBottomLevel != null) mDevice.DestroyAccelStruct(ref mBottomLevel);
		if (mInstanceBuffer != null) mDevice.DestroyBuffer(ref mInstanceBuffer);
		if (mScratchBuffer != null) mDevice.DestroyBuffer(ref mScratchBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		if (mShaderLibrary != null) mDevice.DestroyShaderModule(ref mShaderLibrary);
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope RayTracingSample();
		return app.Run(args);
	}
}
