namespace Sedulous.Renderer;

using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Profiler;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;

/// Manages compute skinning for animated meshes.
/// Owned by Renderer (shared infrastructure). Maintains sub-allocations of
/// the shared output pool and dispatches compute shaders to transform
/// skinned vertices.
///
/// RenderSubsystem.DispatchSkinning() invokes DispatchAllForView() once per
/// frame BEFORE probe captures and the main pipeline render, so both
/// consumers see the same skinned vertex buffers. Forward/depth passes call
/// TryGetSkinnedBinding() to bind the pre-skinned output (shared pool buffer
/// + per-instance offset).
///
/// A.4 collapsed the per-character bind group into a frame-scoped mega
/// bind group: bones, source verts, output verts, and a SkinningRecords
/// StructuredBuffer all bound once. Per dispatch we only push the record
/// index (4 bytes) and call Dispatch. The shader reads its record at that
/// index and computes absolute offsets into each pool.
class SkinningSystem : IDisposable
{
	private IDevice mDevice;
	private IComputePipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;

	/// Active skinning instances keyed by mesh handle.
	/// Multiple entities sharing the same mesh get separate instances
	/// (different bone transforms -> different output).
	private Dictionary<SkinningKey, SkinningInstance> mInstances = new .() ~ delete _;

	/// One shared output buffer for every skinned-mesh instance. Each
	/// SkinningInstance gets a sub-range, exposed to consumers via
	/// TryGetSkinnedBinding so the forward / depth / shadow / pick passes
	/// can SetVertexBuffer(pool, offset) instead of binding a per-instance
	/// VkBuffer.
	private SkinnedVertexPool mOutputPool = new .() ~ delete _;

	/// Initial output pool size. 256 MB covers ~5.4M vertices @ 48B,
	/// which is well past the EngineAnimationSandbox stress-test target
	/// (5-10k skinned instance dispatches). Growth is deferred; an
	/// overflow logs once and skinning skips further instances until
	/// slots free.
	private const uint64 OutputPoolInitialSize = 256 * 1024 * 1024;

	/// Output vertex stride (standard Mesh layout: 48 bytes).
	private const uint32 OutputVertexStride = 48;

	/// Compute workgroup size (must match shader).
	private const uint32 WorkgroupSize = 64;

	/// Bone matrix stride (matches StructuredBuffer<BoneMatrix> layout).
	private const uint32 BoneMatrixSize = 64;

	// ==================== Frame-scoped bind group + records buffer ====================

	/// Per-frame record list (rebuilt every frame, written to mRecordsBuffer).
	private List<SkinningRecord> mFrameRecords = new .() ~ delete _;

	/// CpuToGpu StructuredBuffer<SkinningRecord> holding this frame's records.
	private IBuffer mRecordsBuffer;
	private const uint64 RecordsBufferSize = 4 * 1024 * 1024; // 4 MB = 256k records

	/// Frame bind group. Created lazily; reused as long as pool buffers
	/// and the records buffer are stable (pool growth would invalidate it).
	private IBindGroup mFrameBindGroup;
	private IBuffer mLastBonePool;
	private IBuffer mLastSourcePool;

	// Manual stage timing - accumulated each frame, printed every N frames.
	// Profiler scopes are too coarse (per-call overhead drowns the signal at
	// herd scales). Raw Stopwatch ticks have <100ns overhead per pair.
	private int64 mTBuildRecordsTicks;
	private int64 mTWriteRecordsTicks;
	private int64 mTSetBindGroupTicks;
	private int64 mTPushConstantsTicks;
	private int64 mTDispatchTicks;
	private uint32 mDispatchCount;
	private uint32 mFrameCounter;
	private const uint32 PrintEveryNFrames = 120;

	// ==================== Lifecycle ====================

	public Result<void> Initialize(IDevice device, ShaderSystem shaderSystem)
	{
		mDevice = device;

		if (mOutputPool.Initialize(device, OutputPoolInitialSize) case .Err)
		{
			Console.WriteLine("[SkinningSystem] Failed to allocate output pool ({0} MB).",
				OutputPoolInitialSize / (1024 * 1024));
			return .Err;
		}

		// Per-frame records buffer. Mapped CpuToGpu so we can rewrite it each
		// frame without ping-ponging staging buffers.
		BufferDesc recordsDesc = .()
		{
			Label = "Skinning Records",
			Size = RecordsBufferSize,
			Usage = .StorageRead,
			Memory = .CpuToGpu
		};
		if (device.CreateBuffer(recordsDesc) case .Ok(let buf))
			mRecordsBuffer = buf;
		else
		{
			Console.WriteLine("[SkinningSystem] Failed to allocate records buffer.");
			return .Err;
		}

		if (shaderSystem == null)
			return .Ok; // Deferred init

		let shaderResult = shaderSystem.GetShader("skinning", .Compute);
		if (shaderResult case .Err)
			return .Err;

		let computeModule = shaderResult.Value;

		// Bind group layout - ONE frame-scoped set covering every dispatch:
		//   t0: BoneMatrices       (StructuredBuffer<BoneMatrix>, stride 64)
		//   t1: SourceVertices     (ByteAddressBuffer)
		//   t2: SkinningRecords    (StructuredBuffer<SkinningRecord>, stride 16)
		//   u0: OutputVertices     (RWByteAddressBuffer)
		BindGroupLayoutEntry[4] entries = .(
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadOnly, StorageBufferStride = BoneMatrixSize }, // BoneMatrices
			.() { Binding = 1, Visibility = .Compute, Type = .StorageBufferReadOnly },                                       // SourceVertices
			.() { Binding = 2, Visibility = .Compute, Type = .StorageBufferReadOnly, StorageBufferStride = SkinningRecord.Stride }, // SkinningRecords
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadWrite }                                       // OutputVertices
		);

		BindGroupLayoutDesc layoutDesc = .() { Label = "Skinning BindGroup Layout", Entries = entries };
		if (device.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		// Push constant range: one uint (RecordIndex) at offset 0 in compute stage.
		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		PushConstantRange[1] pushRanges = .(
			.() { Stages = .Compute, Offset = 0, Size = 4 }
		);
		PipelineLayoutDesc plDesc = .()
		{
			Label = "Skinning Pipeline Layout",
			BindGroupLayouts = Span<IBindGroupLayout>(&layouts[0], 1),
			PushConstantRanges = Span<PushConstantRange>(&pushRanges[0], 1)
		};
		if (device.CreatePipelineLayout(plDesc) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		ComputePipelineDesc pipelineDesc = .()
		{
			Label = "Skinning Compute Pipeline",
			Layout = mPipelineLayout,
			Compute = .(computeModule.Module, "main")
		};

		if (device.CreateComputePipeline(pipelineDesc) case .Ok(let pipe))
			mPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	/// Gets or creates a skinning instance for a mesh.
	/// Call during extraction/setup phase - not during render graph execution.
	public SkinningInstance GetOrCreateInstance(SkinningKey key, IBuffer sourceVertexBuffer,
		uint64 sourceVertexOffset, GPUBoneBufferHandle boneBufferHandle, int32 vertexCount, int32 boneCount)
	{
		if (mInstances.TryGetValue(key, let existing))
		{
			existing.Active = true;
			if (existing.BoneBufferHandle != boneBufferHandle || existing.BoneCount != boneCount)
			{
				existing.BoneBufferHandle = boneBufferHandle;
				existing.BoneCount = boneCount;
			}
			return existing;
		}

		// Reserve a sub-range of the shared output pool. If exhausted, decline
		// to skin this mesh - caller skips it, same as the old path did when
		// CreateBuffer returned Err.
		let requestedSize = (uint64)(vertexCount * OutputVertexStride);
		uint64 outputOffset;
		uint64 alignedSize;
		if (!mOutputPool.Allocate(requestedSize, out outputOffset, out alignedSize))
			return null;

		let instance = new SkinningInstance();
		instance.SourceVertexBuffer = sourceVertexBuffer;
		instance.SourceVertexOffset = sourceVertexOffset;
		instance.BoneBufferHandle = boneBufferHandle;
		instance.VertexCount = vertexCount;
		instance.BoneCount = boneCount;
		instance.Active = true;
		instance.OutputOffset = outputOffset;
		instance.OutputSize = alignedSize;

		mInstances[key] = instance;
		return instance;
	}

	/// Returns the shared output pool buffer and the byte offset of `key`'s
	/// sub-range. Pass both to SetVertexBuffer when drawing the skinned mesh.
	/// Returns false if the instance hasn't been created yet (e.g. the
	/// skinning compute hasn't been dispatched this frame because the bone
	/// or source buffer wasn't ready).
	public bool TryGetSkinnedBinding(SkinningKey key, out IBuffer buffer, out uint64 offset)
	{
		if (mInstances.TryGetValue(key, let instance))
		{
			buffer = mOutputPool.Buffer;
			offset = instance.OutputOffset;
			return buffer != null;
		}
		buffer = null;
		offset = 0;
		return false;
	}

	/// Iterates every skinned mesh in the given view's render data, builds
	/// a per-frame SkinningRecord array, binds one frame-scoped descriptor
	/// set, and emits Dispatch+PushConstants per record.
	public void DispatchAllForView(IComputePassEncoder encoder, ExtractedRenderData data,
		GPUResourceManager gpuResources)
	{
		if (data == null || gpuResources == null) return;
		if (mPipeline == null) return;

		let bonePoolBuffer = gpuResources.BonePoolBuffer;
		let sourcePoolBuffer = gpuResources.SkinnedSourcePoolBuffer;
		if (bonePoolBuffer == null || sourcePoolBuffer == null) return;

		// Reset per-frame timing counters.
		mTBuildRecordsTicks = 0;
		mTWriteRecordsTicks = 0;
		mTSetBindGroupTicks = 0;
		mTPushConstantsTicks = 0;
		mTDispatchTicks = 0;
		mDispatchCount = 0;

		// Build records from this frame's skinned-mesh batch.
		let buildStart = Stopwatch.GetTimestamp();
		mFrameRecords.Clear();
		CollectRecords(data, RenderCategories.Opaque, gpuResources);
		CollectRecords(data, RenderCategories.Masked, gpuResources);
		CollectRecords(data, RenderCategories.Transparent, gpuResources);
		mTBuildRecordsTicks = Stopwatch.GetTimestamp() - buildStart;

		if (mFrameRecords.Count == 0) return;

		// Cap at the records buffer's capacity.
		let maxRecords = (int)(RecordsBufferSize / SkinningRecord.Stride);
		if (mFrameRecords.Count > maxRecords)
		{
			Console.WriteLine("[SkinningSystem] Frame records ({0}) exceed buffer capacity ({1}); dropping overflow.",
				mFrameRecords.Count, maxRecords);
			mFrameRecords.Count = maxRecords;
		}

		// Upload records.
		let writeStart = Stopwatch.GetTimestamp();
		TransferHelper.WriteMappedBuffer(mRecordsBuffer, 0,
			Span<uint8>((uint8*)mFrameRecords.Ptr, mFrameRecords.Count * SkinningRecord.Stride));
		mTWriteRecordsTicks = Stopwatch.GetTimestamp() - writeStart;

		// (Re)build the frame bind group if the pool buffers changed (rare;
		// only on pool growth, which is deferred).
		if (mFrameBindGroup == null || bonePoolBuffer != mLastBonePool || sourcePoolBuffer != mLastSourcePool)
		{
			if (mFrameBindGroup != null)
			{
				mDevice.DestroyBindGroup(ref mFrameBindGroup);
				mFrameBindGroup = null;
			}

			BindGroupEntry[4] bgEntries = .(
				BindGroupEntry.Buffer(bonePoolBuffer, 0, 0),
				BindGroupEntry.Buffer(sourcePoolBuffer, 0, 0),
				BindGroupEntry.Buffer(mRecordsBuffer, 0, 0),
				BindGroupEntry.Buffer(mOutputPool.Buffer, 0, 0)
			);

			BindGroupDesc bgDesc = .() { Label = "Skinning Frame BindGroup", Layout = mBindGroupLayout, Entries = bgEntries };
			if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
				mFrameBindGroup = bg;
			else
				return;

			mLastBonePool = bonePoolBuffer;
			mLastSourcePool = sourcePoolBuffer;
		}

		// Bind once for the whole frame's dispatches.
		encoder.SetPipeline(mPipeline);
		let setBGStart = Stopwatch.GetTimestamp();
		encoder.SetBindGroup(0, mFrameBindGroup, default);
		mTSetBindGroupTicks = Stopwatch.GetTimestamp() - setBGStart;

		// Emit one (PushConstants + Dispatch) per record. PushConstants is ~100ns
		// vs ~2µs for SetBindGroup, so the per-character overhead collapses.
		for (uint32 i = 0; i < mFrameRecords.Count; i++)
		{
			let record = mFrameRecords[(int)i];

			let pcStart = Stopwatch.GetTimestamp();
			uint32 recordIndex = i;
			encoder.SetPushConstants(.Compute, 0, 4, &recordIndex);
			mTPushConstantsTicks += Stopwatch.GetTimestamp() - pcStart;

			let dispStart = Stopwatch.GetTimestamp();
			let workgroups = (uint32)((record.VertexCount + WorkgroupSize - 1) / WorkgroupSize);
			encoder.Dispatch(workgroups, 1, 1);
			mTDispatchTicks += Stopwatch.GetTimestamp() - dispStart;
			mDispatchCount++;
		}

		// Periodic breakdown print. Reading raw Stopwatch ticks adds <100ns
		// per pair so the inner-loop overhead is negligible vs the operations
		// being measured.
		mFrameCounter++;
		if (mFrameCounter >= PrintEveryNFrames && mDispatchCount > 0)
		{
			// Stopwatch.GetTimestamp() returns microseconds on Beef.
			let buildMs   = (double)mTBuildRecordsTicks / 1000.0;
			let writeMs   = (double)mTWriteRecordsTicks / 1000.0;
			let setBGMs   = (double)mTSetBindGroupTicks / 1000.0;
			let pcMs      = (double)mTPushConstantsTicks / 1000.0;
			let dispMs    = (double)mTDispatchTicks / 1000.0;
			let totalMs   = buildMs + writeMs + setBGMs + pcMs + dispMs;
			Console.WriteLine(
				"[Skinning] {0} chars | total {1:F2}ms | build {2:F2} ({3:F1}%)  write {4:F2} ({5:F1}%)  setBG {6:F2} ({7:F1}%)  push {8:F2} ({9:F1}%)  dispatch {10:F2} ({11:F1}%)",
				mDispatchCount, totalMs,
				buildMs,   buildMs   / totalMs * 100.0,
				writeMs,   writeMs   / totalMs * 100.0,
				setBGMs,   setBGMs   / totalMs * 100.0,
				pcMs,      pcMs      / totalMs * 100.0,
				dispMs,    dispMs    / totalMs * 100.0);
			mFrameCounter = 0;
		}
	}

	private void CollectRecords(ExtractedRenderData data, RenderDataCategory category,
		GPUResourceManager gpuResources)
	{
		let batch = data.GetBatch(category);
		if (batch == null) return;

		for (let entry in batch)
		{
			let mesh = entry as MeshRenderData;
			if (mesh == null || !mesh.IsSkinned) continue;

			let boneBuffer = gpuResources.GetBoneBuffer(mesh.BoneBufferHandle);
			if (boneBuffer == null) continue;

			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			// Keyed on EntityIndex so each herd character gets its own
			// SkinningInstance + output sub-range. See A.1 commit for the
			// MaterialKey-collision bug this avoids.
			let key = SkinningKey() { MeshHandle = mesh.MeshHandle, EntityId = mesh.EntityIndex };
			let instance = GetOrCreateInstance(key, gpuMesh.VertexBuffer, gpuMesh.VertexOffset,
				mesh.BoneBufferHandle, (int32)gpuMesh.VertexCount, boneBuffer.BoneCount);
			if (instance == null) continue;

			// Bone offset is in bytes; the shader indexes by matrix - divide
			// once here so the shader can do `BoneMatrices[start + jointIdx]`
			// with a single add.
			let record = SkinningRecord()
			{
				SrcVertexOffset = (uint32)instance.SourceVertexOffset,
				OutVertexOffset = (uint32)instance.OutputOffset,
				BoneMatrixStart = (uint32)(boneBuffer.Offset / BoneMatrixSize),
				VertexCount = (uint32)instance.VertexCount
			};
			mFrameRecords.Add(record);
		}
	}

	/// Marks all instances as inactive. Called at start of frame.
	/// Inactive instances can be cleaned up after N frames.
	public void BeginFrame()
	{
		for (let kv in mInstances)
			kv.value.Active = false;
	}

	public void Dispose()
	{
		for (let kv in mInstances)
		{
			kv.value.Release(mDevice, mOutputPool);
			delete kv.value;
		}
		mInstances.Clear();

		mOutputPool.Dispose();

		if (mFrameBindGroup != null) mDevice.DestroyBindGroup(ref mFrameBindGroup);
		if (mRecordsBuffer != null) mDevice.DestroyBuffer(ref mRecordsBuffer);
		if (mPipeline != null) mDevice.DestroyComputePipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
	}

	[CRepr]
	private struct SkinningRecord
	{
		public uint32 SrcVertexOffset;
		public uint32 OutVertexOffset;
		public uint32 BoneMatrixStart;
		public uint32 VertexCount;
		public const int Stride = 16;
	}
}

/// Key for identifying a unique skinning instance.
/// An entity + mesh handle combination - same mesh on different entities
/// gets different instances (different bone transforms).
struct SkinningKey : IHashable, IEquatable<SkinningKey>
{
	public GPUMeshHandle MeshHandle;
	public uint64 EntityId; // unique identifier from extraction

	public int GetHashCode()
	{
		return MeshHandle.GetHashCode() * 31 + EntityId.GetHashCode();
	}

	public bool Equals(SkinningKey other)
	{
		return MeshHandle == other.MeshHandle && EntityId == other.EntityId;
	}
}
