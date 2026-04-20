namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Materials.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Jobs;

/// Manages mesh components: resolves resource refs, uploads to GPU, extracts render data.
/// Injected into scenes by RenderSubsystem via ISceneAware.
///
/// Per-frame resolution (PostUpdate):
///   1. For each component, resolve MeshRef -> StaticMeshResource -> GPU upload
///   2. Resolve MaterialRefs -> MaterialResource -> MaterialInstance + bind group
///
/// Extraction emits one MeshRenderData per submesh.
class MeshComponentManager : ComponentManager<MeshComponent>, IRenderDataProvider
{
	/// Reference to GPU resource manager (set by RenderSubsystem).
	public GPUResourceManager GPUResources { get; set; }

	/// Shared resource resolver (set by RenderSubsystem).
	public RenderResourceResolver Resolver { get; set; }

	/// Per-component resolve state, keyed by entity handle.
	private Dictionary<EntityHandle, MeshResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
			kv.value.Release();
		DeleteDictionaryAndValues!(_);
	};


	public override StringView SerializationTypeId => "Sedulous.MeshComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostUpdate, new => ResolveResources);
	}

	/// Per-frame resource resolution. Loads resources, uploads to GPU, creates materials.
	private void ResolveResources(float deltaTime)
	{
		if (Resolver == null)
			return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive)
				continue;

			let entityHandle = comp.Owner;
			MeshResolveState state = null;

			if (!mResolveStates.TryGetValue(entityHandle, var existingState))
			{
				let newState = new MeshResolveState();
				mResolveStates[entityHandle] = newState;
				state = newState;
			}
			else
			{
				state = existingState;
			}

			// Resolve mesh
			let meshRef = comp.MeshRef;
			GPUMeshHandle meshHandle;
			BoundingBox bounds;
			if (Resolver.ResolveMesh(ref state.Mesh, meshRef, out meshHandle, out bounds))
			{
				comp.MeshHandle = meshHandle;
				comp.LocalBounds = bounds;
			}

			// Resolve materials from refs
			for (int32 slot = 0; slot < comp.MaterialRefCount; slot++)
			{
				let matRef = comp.GetMaterialRef(slot);
				if (!matRef.IsValid)
					continue;

				// Grow resolve state material list if needed
				while (state.Materials.Count <= slot)
					state.Materials.Add(.());

				MaterialInstance instance;
				if (Resolver.ResolveMaterial(ref state.Materials[slot], matRef, out instance))
				{
					comp.SetMaterial(slot, instance);
					instance.ReleaseRef(); // SetMaterial AddRef'd - resolver doesn't own it
				}
			}

			// Prepare any dirty material instances (handles both resolved and manually-set materials)
			for (int32 slot = 0; slot < comp.Materials.Count; slot++)
			{
				let material = comp.Materials[slot];
				if (material != null && (material.IsBindGroupDirty || material.IsUniformDirty))
					Resolver.PrepareMaterial(material);
			}
		}
	}

	/// Extracts MeshRenderData for all active, visible mesh components.
	/// Emits one entry per submesh, each with its own material.
	/// Uses ParallelFor with per-thread allocators and output lists - zero
	/// contention during extraction, one cheap merge pass after.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null || GPUResources == null)
			return;

		let slotCount = SlotCount;
		if (slotCount == 0)
			return;

		let workerCount = Jobs.JobSystem.IsInitialized ? Jobs.JobSystem.WorkerCount : 0;

		// For small counts or no job system, extract sequentially
		if (slotCount < 256 || workerCount == 0)
		{
			ExtractRange(0, slotCount, context.RenderContext.FrameAllocator, context.RenderData);
			return;
		}

		// Parallel extraction - per-thread allocators + per-thread output lists
		let chunkCount = Math.Min((int32)slotCount, workerCount + 1);
		let catCount = RenderCategories.Count;

		// Per-chunk output lists: chunkCount × catCount flat array
		let threadLists = scope List<RenderData>[chunkCount * catCount];
		for (int i = 0; i < threadLists.Count; i++)
			threadLists[i] = scope:: List<RenderData>();

		int32 nextAllocIdx = 0;

		Jobs.JobSystem.ParallelFor(0, slotCount, scope [&](begin, end) => {
			let chunkIdx = System.Threading.Interlocked.Increment(ref nextAllocIdx) - 1;
			let alloc = context.RenderContext.GetWorkerAllocator(chunkIdx);

			// Build per-category output for this chunk
			let baseIdx = chunkIdx * (int32)catCount;
			ExtractRangeToLists(begin, end, alloc, context, threadLists, baseIdx);
		});

		// Merge per-thread lists into the shared ExtractedRenderData (single-threaded)
		for (int32 c = 0; c < catCount; c++)
		{
			let category = RenderDataCategory((uint16)c);
			for (int32 t = 0; t < chunkCount; t++)
			{
				let list = threadLists[t * catCount + c];
				for (let entry in list)
					context.RenderData.Add(category, entry);
			}
		}
	}

	/// Sequential extraction into ExtractedRenderData directly.
	private void ExtractRange(int32 begin, int32 end,
		Sedulous.Core.Memory.FrameAllocator alloc,
		ExtractedRenderData renderData)
	{
		let scene = Scene;
		let gpuResources = GPUResources;

		for (int32 i = begin; i < end; i++)
			ExtractSlot(i, scene, gpuResources, alloc, renderData, null, 0);
	}

	/// Parallel extraction into per-thread lists (no shared state).
	private void ExtractRangeToLists(int32 begin, int32 end,
		Sedulous.Core.Memory.FrameAllocator alloc,
		in RenderExtractionContext context,
		List<RenderData>[] threadLists, int32 baseIdx)
	{
		let scene = Scene;
		let gpuResources = GPUResources;

		for (int32 i = begin; i < end; i++)
			ExtractSlot(i, scene, gpuResources, alloc, null, threadLists, baseIdx);
	}

	/// Extracts a single slot. Writes to either renderData (sequential) or
	/// threadLists (parallel). Exactly one of renderData/threadLists is non-null.
	private void ExtractSlot(int32 slotIdx, Scene scene, GPUResourceManager gpuResources,
		Sedulous.Core.Memory.FrameAllocator alloc,
		ExtractedRenderData renderData,
		List<RenderData>[] threadLists, int32 threadListBase)
	{
		let mesh = GetAtSlot(slotIdx);
		if (mesh == null || !mesh.IsActive || !mesh.IsVisible)
			return;

		if (!mesh.MeshHandle.IsValid)
			return;

		let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
		if (gpuMesh == null)
			return;

		let worldMatrix = scene.GetWorldMatrix(mesh.Owner);
		let prevWorldMatrix = scene.GetPrevWorldMatrix(mesh.Owner);
		let center = Vector3.Transform(mesh.LocalBounds.Center, worldMatrix);

		var flags = RenderDataFlags.None;
		if (mesh.CastsShadows)
			flags |= .CastShadows;

		for (int32 subIdx = 0; subIdx < gpuMesh.SubMeshes.Count; subIdx++)
		{
			let subMesh = gpuMesh.SubMeshes[subIdx];
			let materialSlot = (int32)subMesh.MaterialSlot;
			let material = mesh.GetMaterial(materialSlot);

			var category = RenderCategories.Opaque;
			if (material != null)
			{
				switch (material.BlendMode)
				{
				case .Masked:
					category = RenderCategories.Masked;
				case .AlphaBlend, .Additive, .Multiply, .PremultipliedAlpha:
					category = RenderCategories.Transparent;
				default:
				}
			}

			let materialKey = (material != null) ? (uint32)(int)Internal.UnsafeCastToPtr(material) : 0;

			let data = new:alloc MeshRenderData();
			data.Position = center;
			data.Bounds = mesh.LocalBounds;
			data.MaterialSortKey = materialKey;
			data.SortOrder = 0;
			data.Flags = flags;
			data.WorldMatrix = worldMatrix;
			data.PrevWorldMatrix = prevWorldMatrix;
			data.MeshHandle = mesh.MeshHandle;
			data.SubMeshIndex = (uint32)subIdx;
			data.MaterialBindGroup = material?.BindGroup;
			data.MaterialKey = materialKey;

			if (renderData != null)
				renderData.Add(category, data);
			else
				threadLists[threadListBase + category.Value].Add(data);
		}
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		// Release material refs on this component.
		// GPU resources (bind group, uniform buffer) are cleaned up by
		// MaterialInstance's destructor when the last ref is released.
		if (let comp = GetForEntity(entity))
		{
			for (let material in comp.Materials)
				material?.ReleaseRef();
			comp.Materials.Clear();
		}

		if (mResolveStates.TryGetValue(entity, let state))
		{
			state.Release();
			delete state;
			mResolveStates.Remove(entity);
		}

		base.OnEntityDestroyed(entity);
	}
}

/// Per-component resource resolution tracking.
/// Stored in MeshComponentManager, not on the component.
class MeshResolveState
{
	public ResolvedResource<StaticMeshResource> Mesh;
	public List<ResolvedResource<MaterialResource>> Materials = new .() ~ delete _;

	public void Release()
	{
		Mesh.Release();
		for (var mat in ref Materials)
			mat.Release();
	}
}
