namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;

/// Manages compute skinning for animated meshes.
/// Owned by Renderer (shared infrastructure). Creates output vertex buffers
/// and dispatches compute shaders to transform skinned vertices.
///
/// The SkinningPass (PipelinePass) calls DispatchSkinning() during render graph execution.
/// Forward/depth passes call GetSkinnedVertexBuffer() to bind the pre-skinned output.
class SkinningSystem : IDisposable
{
	private IDevice mDevice;
	private IComputePipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;

	/// Active skinning instances keyed by mesh handle.
	/// Multiple entities sharing the same mesh get separate instances
	/// (different bone transforms → different output).
	private Dictionary<SkinningKey, SkinningInstance> mInstances = new .() ~ delete _;

	/// Output vertex stride (standard Mesh layout: 48 bytes).
	private const uint32 OutputVertexStride = 48;

	/// Compute workgroup size (must match shader).
	private const uint32 WorkgroupSize = 64;

	// ==================== Lifecycle ====================

	public Result<void> Initialize(IDevice device, ShaderSystem shaderSystem)
	{
		mDevice = device;

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
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadOnly },
			.() { Binding = 1, Visibility = .Compute, Type = .StorageBufferReadOnly },
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadWrite }
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
	/// Call during extraction/setup phase — not during render graph execution.
	public SkinningInstance GetOrCreateInstance(SkinningKey key, IBuffer sourceVertexBuffer,
		GPUBoneBufferHandle boneBufferHandle, int32 vertexCount, int32 boneCount)
	{
		if (mInstances.TryGetValue(key, let existing))
		{
			existing.Active = true;
			// Update bone buffer if changed
			if (existing.BoneBufferHandle != boneBufferHandle)
			{
				existing.BoneBufferHandle = boneBufferHandle;
				existing.BindGroupDirty = true;
			}
			return existing;
		}

		let instance = new SkinningInstance();
		instance.SourceVertexBuffer = sourceVertexBuffer;
		instance.BoneBufferHandle = boneBufferHandle;
		instance.VertexCount = vertexCount;
		instance.BoneCount = boneCount;
		instance.Active = true;
		instance.BindGroupDirty = true;

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

		// Create output vertex buffer (48 bytes per vertex, Storage + Vertex)
		let outputSize = (uint64)(vertexCount * OutputVertexStride);
		BufferDesc outputBufDesc = .()
		{
			Label = "Skinned Vertices",
			Size = outputSize,
			Usage = .Storage | .Vertex,
			Memory = .GpuOnly
		};
		if (mDevice.CreateBuffer(outputBufDesc) case .Ok(let outBuf))
			instance.SkinnedVertexBuffer = outBuf;

		mInstances[key] = instance;
		return instance;
	}

	/// Gets the skinned vertex buffer for a mesh. Returns null if not skinned.
	public IBuffer GetSkinnedVertexBuffer(SkinningKey key)
	{
		if (mInstances.TryGetValue(key, let instance))
			return instance.SkinnedVertexBuffer;
		return null;
	}

	/// Dispatches compute skinning for an instance.
	/// Called from SkinningPass during render graph execution.
	public void DispatchSkinning(IComputePassEncoder encoder, SkinningInstance instance, IBuffer boneBuffer)
	{
		if (mPipeline == null || instance == null)
			return;

		// Upload params
		SkinningParams @params = .()
		{
			VertexCount = (uint32)instance.VertexCount,
			BoneCount = (uint32)instance.BoneCount
		};
		TransferHelper.WriteMappedBuffer(instance.ParamsBuffer, 0,
			Span<uint8>((uint8*)&@params, SkinningParams.Size));

		// Build bind group if needed
		if (instance.BindGroupDirty || instance.BindGroup == null)
		{
			if (instance.BindGroup != null)
				mDevice.DestroyBindGroup(ref instance.BindGroup);

			let boneBufferSize = (uint64)instance.BoneCount * (uint64)sizeof(Matrix) * 2; // current + prev
			let sourceSize = (uint64)(instance.VertexCount * 72); // SkinnedVertex stride
			let outputSize = (uint64)(instance.VertexCount * OutputVertexStride);

			BindGroupEntry[4] bgEntries = .(
				BindGroupEntry.Buffer(instance.ParamsBuffer, 0, SkinningParams.Size),
				BindGroupEntry.Buffer(boneBuffer, 0, boneBufferSize),
				BindGroupEntry.Buffer(instance.SourceVertexBuffer, 0, sourceSize),
				BindGroupEntry.Buffer(instance.SkinnedVertexBuffer, 0, outputSize)
			);

			BindGroupDesc bgDesc = .() { Label = "Skinning BindGroup", Layout = mBindGroupLayout, Entries = bgEntries };
			if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
				instance.BindGroup = bg;

			instance.BindGroupDirty = false;
		}

		if (instance.BindGroup == null)
			return;

		encoder.SetPipeline(mPipeline);
		encoder.SetBindGroup(0, instance.BindGroup, default);

		uint32 vertCount = (uint32)instance.VertexCount;
		encoder.Dispatch((vertCount + WorkgroupSize - 1) / WorkgroupSize, 1, 1);
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
			kv.value.Release(mDevice);
			delete kv.value;
		}
		mInstances.Clear();

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
/// An entity + mesh handle combination — same mesh on different entities
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
