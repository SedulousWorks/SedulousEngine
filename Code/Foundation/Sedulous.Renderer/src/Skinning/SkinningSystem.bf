namespace Sedulous.Renderer;

using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Profiler;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;

/// Manages compute skinning for animated meshes.
/// Owned by Renderer (shared infrastructure). Creates output vertex buffers
/// and dispatches compute shaders to transform skinned vertices.
///
/// RenderSubsystem.DispatchSkinning() invokes DispatchAllForView() once per
/// frame BEFORE probe captures and the main pipeline render, so both
/// consumers see the same skinned vertex buffers. Forward/depth passes call
/// TryGetSkinnedBinding() to bind the pre-skinned output (shared pool buffer
/// + per-instance offset).
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

	/// Deferred bind group destruction (double-buffered for MaxFramesInFlight).
	private List<IBindGroup>[2] mStaleBindGroups = .(new .(), new .()) ~ { delete _[0]; delete _[1]; };

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

	// Manual stage timing - accumulated each frame, printed every N frames.
	// Profiler scopes are too coarse (per-call overhead drowns the signal at
	// herd scales). Raw Stopwatch ticks have <100ns overhead per pair.
	private int64 mTLookupTicks;
	private int64 mTWriteParamsTicks;
	private int64 mTSetBindGroupTicks;
	private int64 mTDispatchTicks;
	private int64 mTBindGroupCreateTicks;
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

		if (shaderSystem == null)
			return .Ok; // Deferred init

		let shaderResult = shaderSystem.GetShader("skinning", .Compute);
		if (shaderResult case .Err)
			return .Err;

		let computeModule = shaderResult.Value;

		// Bind group layout:
		//   b0: SkinningParams (uniform)
		//   t0: BoneMatrices (storage, read-only)
		//   t1: SourceVertices (storage, read-only)
		//   u0: OutputVertices (storage, read-write)
		BindGroupLayoutEntry[4] entries = .(
			.UniformBuffer(0, .Compute),
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadOnly, StorageBufferStride = 64 }, // BoneMatrices (4 × float4 = 64 bytes per matrix)
			.() { Binding = 1, Visibility = .Compute, Type = .StorageBufferReadOnly },  // SourceVertices (ByteAddressBuffer, stride=0)
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadWrite }   // OutputVertices (RWByteAddressBuffer, stride=0)
		);

		BindGroupLayoutDesc layoutDesc = .() { Label = "Skinning BindGroup Layout", Entries = entries };
		if (device.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		if (device.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
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
		GPUBoneBufferHandle boneBufferHandle, int32 vertexCount, int32 boneCount)
	{
		if (mInstances.TryGetValue(key, let existing))
		{
			existing.Active = true;
			// Update bone buffer or bone count if changed
			if (existing.BoneBufferHandle != boneBufferHandle || existing.BoneCount != boneCount)
			{
				existing.BoneBufferHandle = boneBufferHandle;
				existing.BoneCount = boneCount;
				existing.BindGroupDirty = true;
			}
			return existing;
		}

		// Reserve a sub-range of the shared output pool BEFORE creating the
		// instance - if we're out of pool space we just decline to skin
		// this mesh this frame (caller skips it, same as the old path did
		// when CreateBuffer returned Err).
		let requestedSize = (uint64)(vertexCount * OutputVertexStride);
		uint64 outputOffset;
		uint64 alignedSize;
		if (!mOutputPool.Allocate(requestedSize, out outputOffset, out alignedSize))
			return null;

		let instance = new SkinningInstance();
		instance.SourceVertexBuffer = sourceVertexBuffer;
		instance.BoneBufferHandle = boneBufferHandle;
		instance.VertexCount = vertexCount;
		instance.BoneCount = boneCount;
		instance.Active = true;
		instance.BindGroupDirty = true;
		instance.OutputOffset = outputOffset;
		instance.OutputSize = alignedSize;

		// Create params buffer
		BufferDesc paramsBufDesc = .()
		{
			Label = "Skinning Params",
			Size = SkinningParams.Size,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(paramsBufDesc) case .Ok(let buf))
			instance.ParamsBuffer = buf;

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

	/// Dispatches compute skinning for an instance.
	/// Called per-instance from DispatchAllForView.
	public void DispatchSkinning(IComputePassEncoder encoder, SkinningInstance instance, IBuffer boneBuffer)
	{
		if (mPipeline == null || instance == null)
			return;

		// Upload params
		let writeStart = Stopwatch.GetTimestamp();
		SkinningParams @params = .()
		{
			VertexCount = (uint32)instance.VertexCount,
			BoneCount = (uint32)instance.BoneCount
		};
		TransferHelper.WriteMappedBuffer(instance.ParamsBuffer, 0,
			Span<uint8>((uint8*)&@params, SkinningParams.Size));
		mTWriteParamsTicks += Stopwatch.GetTimestamp() - writeStart;

		// Build bind group if needed
		if (instance.BindGroupDirty || instance.BindGroup == null)
		{
			let bgcStart = Stopwatch.GetTimestamp();
			if (instance.BindGroup != null)
			{
				mStaleBindGroups[1].Add(instance.BindGroup);
				instance.BindGroup = null;
			}

			let boneBufferSize = (uint64)instance.BoneCount * (uint64)sizeof(Matrix) * 2; // current + prev
			let sourceSize = (uint64)(instance.VertexCount * 72); // SkinnedVertex stride
			let outputVertexBytes = (uint64)(instance.VertexCount * OutputVertexStride);

			// Output points at the shared pool's range for this instance.
			// Shader still sees the same 0-based RWByteAddressBuffer thanks
			// to the bind group offset.
			BindGroupEntry[4] bgEntries = .(
				BindGroupEntry.Buffer(instance.ParamsBuffer, 0, SkinningParams.Size),
				BindGroupEntry.Buffer(boneBuffer, 0, boneBufferSize),
				BindGroupEntry.Buffer(instance.SourceVertexBuffer, 0, sourceSize),
				BindGroupEntry.Buffer(mOutputPool.Buffer, instance.OutputOffset, outputVertexBytes)
			);

			BindGroupDesc bgDesc = .() { Label = "Skinning BindGroup", Layout = mBindGroupLayout, Entries = bgEntries };
			if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
				instance.BindGroup = bg;

			instance.BindGroupDirty = false;
			mTBindGroupCreateTicks += Stopwatch.GetTimestamp() - bgcStart;
		}

		if (instance.BindGroup == null)
			return;

		// Pipeline is hoisted to DispatchAllForView - we only rebind the bind
		// group + dispatch here. Saves N redundant SetPipeline calls on herds
		// of skinned characters (the bottleneck in release builds).
		let setBGStart = Stopwatch.GetTimestamp();
		encoder.SetBindGroup(0, instance.BindGroup, default);
		mTSetBindGroupTicks += Stopwatch.GetTimestamp() - setBGStart;

		let dispStart = Stopwatch.GetTimestamp();
		uint32 vertCount = (uint32)instance.VertexCount;
		encoder.Dispatch((vertCount + WorkgroupSize - 1) / WorkgroupSize, 1, 1);
		mTDispatchTicks += Stopwatch.GetTimestamp() - dispStart;
		mDispatchCount++;
	}

	/// Iterates every skinned mesh in the given view's render data and dispatches
	/// the skinning compute for each. Skips meshes whose source or bone buffer
	/// hasn't resolved yet. Callable from any compute-pass encoder - the result
	/// (per-instance sub-ranges of the shared output pool, keyed on SkinningKey)
	/// is shared by every subsequent consumer that calls TryGetSkinnedBinding.
	///
	/// Centralising the dispatch here lets the engine run skinning once per
	/// frame from RenderSubsystem - before probe captures, shadows, and the
	/// main pipeline render - rather than relying on each pipeline's render
	/// graph to dispatch its own. Probe captures previously couldn't reflect
	/// animated meshes because their `Capture` runs before the main pipeline's
	/// in-graph SkinningPass writes the skinned buffers.
	public void DispatchAllForView(IComputePassEncoder encoder, ExtractedRenderData data,
		GPUResourceManager gpuResources)
	{
		if (data == null || gpuResources == null) return;
		if (mPipeline == null) return;

		// Reset per-frame timing counters.
		mTLookupTicks = 0;
		mTWriteParamsTicks = 0;
		mTSetBindGroupTicks = 0;
		mTDispatchTicks = 0;
		mTBindGroupCreateTicks = 0;
		mDispatchCount = 0;

		// Bind the skinning compute pipeline once for the whole frame's
		// dispatches. Each per-character DispatchSkinning then only rebinds
		// the bind group + dispatches, which the driver short-circuits much
		// faster than redundant SetPipeline calls.
		encoder.SetPipeline(mPipeline);

		DispatchCategory(encoder, data, RenderCategories.Opaque, gpuResources);
		DispatchCategory(encoder, data, RenderCategories.Masked, gpuResources);
		DispatchCategory(encoder, data, RenderCategories.Transparent, gpuResources);

		// Periodic breakdown print. Reading raw Stopwatch ticks adds <100ns
		// per pair so the inner-loop overhead is negligible vs the operations
		// being measured.
		mFrameCounter++;
		if (mFrameCounter >= PrintEveryNFrames && mDispatchCount > 0)
		{
			// Stopwatch.GetTimestamp() returns microseconds on Beef.
			let lookupMs = (double)mTLookupTicks / 1000.0;
			let writeMs = (double)mTWriteParamsTicks / 1000.0;
			let setBGMs = (double)mTSetBindGroupTicks / 1000.0;
			let dispMs = (double)mTDispatchTicks / 1000.0;
			let bgCreateMs = (double)mTBindGroupCreateTicks / 1000.0;
			let totalMs = lookupMs + writeMs + setBGMs + dispMs + bgCreateMs;
			Console.WriteLine(
				"[Skinning] {0} chars | total {1:F2}ms | lookup {2:F2} ({3:F1}%)  write {4:F2} ({5:F1}%)  setBG {6:F2} ({7:F1}%)  dispatch {8:F2} ({9:F1}%)  bgCreate {10:F2}",
				mDispatchCount, totalMs,
				lookupMs, lookupMs / totalMs * 100.0,
				writeMs, writeMs / totalMs * 100.0,
				setBGMs, setBGMs / totalMs * 100.0,
				dispMs, dispMs / totalMs * 100.0,
				bgCreateMs);
			mFrameCounter = 0;
		}
	}

	private void DispatchCategory(IComputePassEncoder encoder, ExtractedRenderData data,
		RenderDataCategory category, GPUResourceManager gpuResources)
	{
		let batch = data.GetBatch(category);
		if (batch == null) return;

		for (let entry in batch)
		{
			let mesh = entry as MeshRenderData;
			if (mesh == null || !mesh.IsSkinned) continue;

			// IMPORTANT: key on EntityIndex, not MaterialKey. MaterialKey is the
			// shared MaterialInstance pointer, so every instance of a herd-spawned
			// character (same mesh + same material) used to collide on one
			// SkinningInstance, churning bind groups + overwriting the output
			// vertex buffer 64+ times per frame.
			let lookupStart = Stopwatch.GetTimestamp();
			let boneBuffer = gpuResources.GetBoneBuffer(mesh.BoneBufferHandle);
			if (boneBuffer == null) { mTLookupTicks += Stopwatch.GetTimestamp() - lookupStart; continue; }

			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) { mTLookupTicks += Stopwatch.GetTimestamp() - lookupStart; continue; }

			let key = SkinningKey() { MeshHandle = mesh.MeshHandle, EntityId = mesh.EntityIndex };
			let instance = GetOrCreateInstance(key, gpuMesh.VertexBuffer, mesh.BoneBufferHandle,
				(int32)gpuMesh.VertexCount, boneBuffer.BoneCount);
			mTLookupTicks += Stopwatch.GetTimestamp() - lookupStart;

			DispatchSkinning(encoder, instance, boneBuffer.Buffer);
		}
	}

	/// Marks all instances as inactive. Called at start of frame.
	/// Inactive instances can be cleaned up after N frames.
	public void BeginFrame()
	{
		// Flush stale bind groups (2+ frames old, safe to destroy)
		for (var bg in mStaleBindGroups[0])
			mDevice.DestroyBindGroup(ref bg);
		mStaleBindGroups[0].Clear();
		let temp = mStaleBindGroups[0];
		mStaleBindGroups[0] = mStaleBindGroups[1];
		mStaleBindGroups[1] = temp;

		for (let kv in mInstances)
			kv.value.Active = false;
	}

	public void Dispose()
	{
		// Flush all deferred bind groups
		for (int s = 0; s < 2; s++)
		{
			for (var bg in mStaleBindGroups[s])
				mDevice.DestroyBindGroup(ref bg);
			mStaleBindGroups[s].Clear();
		}

		for (let kv in mInstances)
		{
			kv.value.Release(mDevice, mOutputPool);
			delete kv.value;
		}
		mInstances.Clear();

		mOutputPool.Dispose();

		if (mPipeline != null) mDevice.DestroyComputePipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
	}

	[CRepr]
	private struct SkinningParams
	{
		public uint32 VertexCount;
		public uint32 BoneCount;
		public uint32 _Pad0;
		public uint32 _Pad1;
		public const uint64 Size = 16;
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
