using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample028_ProceduralRT;

/// Four lit spheres traced from AABBs and an INTERSECTION SHADER, not from triangles.
///
/// Procedural geometry: the acceleration structure holds only a box per sphere, and the
/// intersection shader solves the ray against an analytic sphere inside it. That is how ray
/// tracing renders shapes no mesh describes exactly.
class ProceduralRTSample : SampleApp
{
	private const uint32 cSphereCount = 4;
	private const uint32 cShaderGroupCount = 3;
	private const uint64 cInstanceSize = 64;
	/// Six floats: the minimum and maximum corner.
	private const uint32 cAabbStride = 24;

	private IShaderModule mShaderLibrary = null;
	private IRayTracingPipeline mPipeline = null;
	private IAccelStruct mBottomLevel = null;
	private IAccelStruct mTopLevel = null;
	private IBuffer mScratchBuffer = null;
	private IBuffer mAabbBuffer = null;
	private IBuffer mInstanceBuffer = null;
	private IBuffer mShaderBindingTable = null;
	private IPipelineLayout mPipelineLayout = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private ITexture mOutputTexture = null;
	private ITextureView mOutputTextureView = null;
	private ResourceState mOutputTextureState = .Undefined;
	private uint32 mShaderBindingTableStride = 0;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample028 - Procedural RT (AABB Spheres)";

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
			Console.Error.WriteLine("Sample028: this device does not support ray tracing");
			return .Err;
		}

		if (!(LoadShader("Sample028_ProceduralRT/RtShader.hlsl", .RayGen,
			"", "ProcRTShaderLib", "6_3") case .Ok(let library)))
			return .Err;
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

		Console.WriteLine("Procedural RT sample ready.");
		return .Ok;
	}

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
		textureDesc.Label = "ProcRTOutput";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mOutputTexture = texture;
		mOutputTextureState = .Undefined;

		var viewDesc = TextureViewDesc();
		viewDesc.Label = "ProcRTOutputView";
		if (!(mDevice.CreateTextureView(mOutputTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mOutputTextureView = view;
		return .Ok;
	}

	private Result<void> CreateGeometry()
	{
		// ONE box, shared by all four spheres: the instances place copies of it, so the
		// bottom level structure describes a single unit sphere's bounds.
		float[6] aabb = .(-0.5f, -0.5f, -0.5f, 0.5f, 0.5f, 0.5f);

		var aabbDesc = BufferDesc();
		aabbDesc.Size = cAabbStride;
		aabbDesc.Usage = .AccelStructInput | .CopyDst;
		aabbDesc.Memory = .GpuOnly;
		aabbDesc.Label = "AABBBuffer";
		if (!(mDevice.CreateBuffer(aabbDesc) case .Ok(let aabbBuffer)))
			return .Err;
		mAabbBuffer = aabbBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mAabbBuffer, 0, .((uint8*)&aabb[0], (int)cAabbStride));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		var scratchDesc = BufferDesc();
		scratchDesc.Size = 256 * 1024;
		scratchDesc.Usage = .AccelStructScratch;
		scratchDesc.Memory = .GpuOnly;
		scratchDesc.Label = "ProcScratch";
		if (!(mDevice.CreateBuffer(scratchDesc) case .Ok(let scratchBuffer)))
			return .Err;
		mScratchBuffer = scratchBuffer;

		var instanceDesc = BufferDesc();
		instanceDesc.Size = cInstanceSize * cSphereCount;
		instanceDesc.Usage = .AccelStructInput;
		instanceDesc.Memory = .CpuToGpu;
		instanceDesc.Label = "ProcInstances";
		if (!(mDevice.CreateBuffer(instanceDesc) case .Ok(let instanceBuffer)))
			return .Err;
		mInstanceBuffer = instanceBuffer;
		return .Ok;
	}

	private Result<void> BuildAccelerationStructures()
	{
		var bottomDesc = AccelStructDesc();
		bottomDesc.Type = .BottomLevel;
		bottomDesc.Label = "ProcBLAS";
		if (!(mDevice.CreateAccelStruct(bottomDesc) case .Ok(let bottomLevel)))
			return .Err;
		mBottomLevel = bottomLevel;

		var topDesc = AccelStructDesc();
		topDesc.Type = .TopLevel;
		topDesc.Label = "ProcTLAS";
		if (!(mDevice.CreateAccelStruct(topDesc) case .Ok(let topLevel)))
			return .Err;
		mTopLevel = topLevel;

		WriteInstanceRecords();

		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return .Err;

		let rayTracing = encoder as IRayTracingEncoderExt;
		if (rayTracing == null)
		{
			Console.Error.WriteLine("Sample028: the encoder does not support ray tracing");
			mPool.DestroyEncoder(ref encoder);
			return .Err;
		}

		// AABBs rather than triangles: the triangle span is empty and the AABB one is not,
		// which is what makes this a procedural structure.
		var aabbs = AccelStructGeometryAABBs();
		aabbs.AabbBuffer = mAabbBuffer;
		aabbs.Offset = 0;
		aabbs.Count = 1;
		aabbs.Stride = cAabbStride;
		aabbs.Flags = .Opaque;
		rayTracing.BuildBottomLevelAccelStruct(mBottomLevel, mScratchBuffer, 0, .(),
			.(&aabbs, 1));

		var memoryBarrier = MemoryBarrier();
		memoryBarrier.OldState = .AccelStructWrite;
		memoryBarrier.NewState = .AccelStructRead;
		var group = BarrierGroup();
		group.MemoryBarriers = .(&memoryBarrier, 1);
		encoder.Barrier(group);

		rayTracing.BuildTopLevelAccelStruct(mTopLevel, mScratchBuffer, 0, mInstanceBuffer, 0,
			cSphereCount);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mFence.Wait(mFenceValue);
		mPool.Reset();
		mPool.DestroyEncoder(ref encoder);

		Console.WriteLine("Procedural BLAS/TLAS built.");
		return .Ok;
	}

	/// Four instance records, one per sphere, each a translation of the same box.
	private void WriteInstanceRecords()
	{
		let bytes = (uint8*)mInstanceBuffer.Map();
		if (bytes == null)
			return;

		float[4][3] positions = .(
			.(-1.0f,  0.5f, 0.0f),
			.( 1.0f,  0.5f, 0.0f),
			.(-1.0f, -0.5f, 0.0f),
			.( 1.0f, -0.5f, 0.0f));

		for (uint32 i < cSphereCount)
		{
			let instance = bytes + i * cInstanceSize;
			Internal.MemSet(instance, 0, (int)cInstanceSize);

			// A 3x4 ROW MAJOR transform: the diagonal is the scale and the fourth column
			// of each row is the translation.
			let transform = (float*)instance;
			transform[0] = 1.0f;
			transform[3] = positions[i][0];
			transform[5] = 1.0f;
			transform[7] = positions[i][1];
			transform[10] = 1.0f;
			transform[11] = positions[i][2];

			instance[51] = 0xFF;
			instance[55] = 0x04;
			*(uint64*)(instance + 56) = mBottomLevel.DeviceAddress;
		}
		mInstanceBuffer.Unmap();
	}

	private Result<void> CreateBindings()
	{
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
		layoutDesc.Label = "ProcRTBGL";
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mBindGroupLayout = layout;
		return CreateBindGroup();
	}

	private Result<void> CreateBindGroup()
	{
		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(mOutputTextureView),
			BindGroupEntry.AccelStructEntry(mTopLevel));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mBindGroupLayout;
		groupDesc.Entries = entries;
		groupDesc.Label = "ProcRTBG";
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
		pipelineLayoutDesc.Label = "ProcRTPL";
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		// FOUR stages but THREE groups: the intersection and closest hit shaders are one
		// procedural hit group, which is what the binding table indexes.
		var stages = ProgrammableStage[4](
			.(mShaderLibrary, "RayGen", .RayGen),
			.(mShaderLibrary, "SphereIntersection", .Intersection),
			.(mShaderLibrary, "ClosestHit", .ClosestHit),
			.(mShaderLibrary, "Miss", .Miss));

		var groups = RayTracingShaderGroup[3](.(), .(), .());
		groups[0].Type = .General;
		groups[0].GeneralShaderIndex = 0;
		groups[1].Type = .ProceduralHitGroup;
		groups[1].IntersectionShaderIndex = 1;
		groups[1].ClosestHitShaderIndex = 2;
		groups[2].Type = .General;
		groups[2].GeneralShaderIndex = 3;

		var desc = RayTracingPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Stages = stages;
		desc.Groups = groups;
		desc.MaxRecursionDepth = 1;
		// Both declared explicitly, because the payload and the intersection attributes are
		// larger than the defaults and the driver sizes its stack from them.
		desc.MaxPayloadSize = 32;
		desc.MaxAttributeSize = 16;
		desc.Label = "ProcRTPipeline";

		if (!(mDevice.CreateRayTracingPipeline(desc) case .Ok(let pipeline)))
		{
			Console.Error.WriteLine("Sample028: the ray tracing pipeline could not be created");
			return .Err;
		}
		mPipeline = pipeline;
		Console.WriteLine("Procedural RT pipeline created successfully.");
		return .Ok;
	}

	private Result<void> BuildShaderBindingTable()
	{
		let handleSize = mDevice.ShaderGroupHandleSize;
		let baseAlignment = mDevice.ShaderGroupBaseAlignment;
		mShaderBindingTableStride = (handleSize + baseAlignment - 1) & ~(baseAlignment - 1);

		let handles = scope uint8[handleSize * cShaderGroupCount];
		if (mDevice.GetShaderGroupHandles(mPipeline, 0, cShaderGroupCount, handles) case .Err)
			return .Err;

		let tableSize = (uint64)mShaderBindingTableStride * cShaderGroupCount;
		var tableDesc = BufferDesc();
		tableDesc.Size = tableSize;
		tableDesc.Usage = .ShaderBindingTable;
		tableDesc.Memory = .CpuToGpu;
		tableDesc.Label = "ProcSBT";
		if (!(mDevice.CreateBuffer(tableDesc) case .Ok(let table)))
			return .Err;
		mShaderBindingTable = table;

		let mapped = (uint8*)mShaderBindingTable.Map();
		if (mapped == null)
			return .Err;
		Internal.MemSet(mapped, 0, (int)tableSize);
		for (uint32 i < cShaderGroupCount)
		{
			Internal.MemCpy(mapped + (i * mShaderBindingTableStride),
				&handles[(int)i * (int)handleSize], (int)handleSize);
		}
		mShaderBindingTable.Unmap();
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

			let stride = (uint64)mShaderBindingTableStride;
			rayTracing.TraceRays(
				mShaderBindingTable, 0, stride,
				mShaderBindingTable, stride * 2, stride,
				mShaderBindingTable, stride * 1, stride,
				mWidth, mHeight, 1);
		}

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
		if (mFence != null)
			mFence.Wait(mFenceValue);

		if (mBindGroup != null) mDevice.DestroyBindGroup(ref mBindGroup);
		if (mOutputTextureView != null) mDevice.DestroyTextureView(ref mOutputTextureView);
		if (mOutputTexture != null) mDevice.DestroyTexture(ref mOutputTexture);

		if (CreateOutputTexture(width, height) case .Err)
			return;
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
		if (mAabbBuffer != null) mDevice.DestroyBuffer(ref mAabbBuffer);
		if (mShaderLibrary != null) mDevice.DestroyShaderModule(ref mShaderLibrary);
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope ProceduralRTSample();
		return app.Run(args);
	}
}
