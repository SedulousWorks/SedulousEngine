namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Materials.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Jobs;
using Sedulous.Core.Memory;
using Sedulous.Profiler;

/// Manages mesh components: resolves resource refs, uploads to GPU, extracts render data.
/// Injected into scenes by RenderSubsystem via ISceneAware.
///
/// Per-frame resolution (PostUpdate):
///   1. For each component, resolve MeshRef -> StaticMeshResource -> GPU upload
///   2. Resolve MaterialRefs -> MaterialResource -> MaterialInstance + bind group
///
/// Extraction emits one MeshRenderData per submesh.
class MeshComponentManager : ComponentManager<MeshComponent>, IRenderDataProvider, IResourceChangeListener
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

	/// Entity indices whose LocalBounds was written this frame (mesh ref
	/// resolved or cleared). Drained in RefreshWorldBounds. Set semantics
	/// are not required - duplicates are deduped by the BoundsDirty gate
	/// inside the drain loop.
	private List<int32> mBoundsDirtyEntities = new .() ~ delete _;

	/// Entity indices that need (re)resolving this frame. Drained in
	/// ResolveResources. Filled by:
	///   - OnComponentCreated (first resolve)
	///   - MeshChanged / MaterialChanged events on components (ref edits)
	///   - OnResourceReloaded (hot-reload, coarse: marks all components)
	private List<int32> mResolveDirtyEntities = new .() ~ delete _;

	/// Tracks whether we've registered as a resource change listener so
	/// OnSceneDestroy can cleanly unregister.
	private bool mListenerRegistered;


	public override StringView SerializationTypeId => "Sedulous.MeshComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostUpdate, new => ResolveResources);
		RegisterUpdate(.PostTransform, new => RefreshWorldBounds);
	}

	public override void OnSceneCreate(Scene scene)
	{
		base.OnSceneCreate(scene);
		// Resolver is injected by RenderSubsystem before AddModule, so
		// the resource system is available here. Listener catches
		// hot-reloads (rare event) and marks every component dirty so
		// the next ResolveResources picks up fresh resources.
		if (Resolver?.ResourceSystem != null)
		{
			Resolver.ResourceSystem.AddChangeListener(this);
			mListenerRegistered = true;
		}
	}

	public override void OnSceneDestroy()
	{
		if (mListenerRegistered && Resolver?.ResourceSystem != null)
		{
			Resolver.ResourceSystem.RemoveChangeListener(this);
			mListenerRegistered = false;
		}
		base.OnSceneDestroy();
	}

	protected override void OnComponentCreated(MeshComponent comp)
	{
		// Subscribe to ref-change events. Closures are owned by the
		// component's Event<T> and disposed when the component dies.
		comp.MeshChanged.Add(new (c) => MarkResolveDirty(c));
		comp.MaterialChanged.Add(new (c, slot) => MarkResolveDirty(c));

		// First-frame resolve. Even if SetMeshRef hasn't been called
		// yet, the empty-ref path through ResolveResources is correct.
		MarkResolveDirty(comp);
	}

	/// Marks a component for re-resolution on the next ResolveResources
	/// pass. Guarded so we only enqueue once per dirty cycle.
	public void MarkResolveDirty(MeshComponent comp)
	{
		if (comp.ResolveDirty)
			return;
		comp.ResolveDirty = true;
		mResolveDirtyEntities.Add((int32)comp.Owner.Index);
	}

	// IResourceChangeListener - any reload marks every component dirty.
	// Coarse but correct: hot-reloads happen rarely (editor save), and a
	// one-time O(N) sweep on the reload frame amortizes to zero. If
	// reload frequency ever becomes hot, swap for a per-resource reverse
	// index.
	public void OnResourceReloaded(StringView uri, Type resourceType, IResource resource)
	{
		for (let comp in ActiveComponents)
			MarkResolveDirty(comp);
	}

	/// Per-frame resource resolution. Two passes:
	///   1. Drain the resolve-dirty queue (mesh + material ref resolution
	///      for components whose refs changed or hot-reload fired).
	///   2. Per-frame material-instance prep pass over ALL active
	///      components - catches live-edit of MaterialInstance uniforms
	///      / bind groups that didn't go through a ref change. Cheap
	///      bool reads in the common case (no work to do).
	private void ResolveResources(float deltaTime)
	{
		using (Profiler.Begin("Mesh.ResolveResources"))
		{
		if (Resolver == null)
			return;

		// Pass 1: drain dirty queue.
		for (let entityIdx in mResolveDirtyEntities)
		{
			let comp = GetByEntityIndex(entityIdx);
			if (comp == null || !comp.IsActive || !comp.ResolveDirty)
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
				MarkBoundsDirty(comp);
			}
			else if (!meshRef.IsValid && comp.MeshHandle.IsValid)
			{
				// Ref was cleared - reset GPU handle
				comp.MeshHandle = .Invalid;
				comp.LocalBounds = .(.Zero, .Zero);
				MarkBoundsDirty(comp);
			}

			// Resolve materials from refs
			for (int32 slot = 0; slot < comp.MaterialRefCount; slot++)
			{
				let matRef = comp.GetMaterialRef(slot);

				if (!matRef.IsValid)
				{
					// Ref cleared - remove material instance if present
					if (slot < comp.Materials.Count && comp.Materials[slot] != null)
						comp.SetMaterial(slot, null);
					continue;
				}

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

			comp.ResolveDirty = false;
		}
		mResolveDirtyEntities.Clear();

		// Pass 2: prep dirty MaterialInstances on EVERY active component.
		// MaterialInstance dirty (uniform/bind-group edits from editor or
		// runtime mutation) is decoupled from ref changes - a component's
		// material may need PrepareMaterial even though its refs are
		// unchanged. Residual O(N) work; consider moving to a global
		// per-frame Resolver-side dirty pass when this shows up in
		// profiling.
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;
			for (int32 slot = 0; slot < comp.Materials.Count; slot++)
			{
				let material = comp.Materials[slot];
				if (material != null && (material.IsBindGroupDirty || material.IsUniformDirty))
					Resolver.PrepareMaterial(material);
			}
		}
		}
	}

	/// Marks a component for WorldBounds refresh on the next PostTransform
	/// pass. Guarded so we only enqueue once per dirty cycle.
	private void MarkBoundsDirty(MeshComponent comp)
	{
		if (comp.BoundsDirty)
			return;
		comp.BoundsDirty = true;
		mBoundsDirtyEntities.Add((int32)comp.Owner.Index);
	}

	/// PostTransform-phase refresh of cached world bounds. Walks the
	/// per-frame "what moved" list from Scene and the per-manager dirty
	/// queue. Total work is proportional to "entities that moved" +
	/// "LocalBounds changes", not to total component count - a fully
	/// static scene does zero work after initial resolution.
	private void RefreshWorldBounds(float deltaTime)
	{
		using (Profiler.Begin("Mesh.RefreshWorldBounds"))
		{
		let scene = Scene;
		if (scene == null)
			return;

		// 1. Entities whose transform changed this frame.
		for (let entityIdx in scene.TransformsUpdatedThisFrame)
		{
			let comp = GetByEntityIndex(entityIdx);
			if (comp == null) continue;
			comp.WorldBounds = BoundingBox.Transform(comp.LocalBounds, scene.GetWorldMatrix(comp.Owner));
			comp.BoundsDirty = false;
		}

		// 2. LocalBounds-only changes (mesh ref swaps, etc.). Skip entries
		// step 1 already refreshed (BoundsDirty == false then).
		for (let entityIdx in mBoundsDirtyEntities)
		{
			let comp = GetByEntityIndex(entityIdx);
			if (comp == null || !comp.BoundsDirty) continue;
			comp.WorldBounds = BoundingBox.Transform(comp.LocalBounds, scene.GetWorldMatrix(comp.Owner));
			comp.BoundsDirty = false;
		}
		mBoundsDirtyEntities.Clear();
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
		FrameAllocator alloc,
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
		FrameAllocator alloc,
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

		let (prevWorldMatrix, worldMatrix) = scene.GetWorldMatrices(mesh.Owner);

		// Cached world-space bounds (refreshed in PostTransform). Used
		// for both the sort-key center and the world-space data.Bounds.
		let center = mesh.WorldBounds.Center;

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
			data.Bounds = mesh.WorldBounds;
			data.MaterialSortKey = materialKey;
			data.SortOrder = 0;
			data.Flags = flags;
			data.WorldMatrix = worldMatrix;
			data.PrevWorldMatrix = prevWorldMatrix;
			data.InstanceColor = mesh.Color;
			data.MeshHandle = mesh.MeshHandle;
			data.SubMeshIndex = (uint32)subIdx;
			data.MaterialBindGroup = material?.BindGroup;
			data.MaterialBindGroupLayout = material?.BindGroupLayout;
			data.MaterialPipelineConfig = material?.Material?.PipelineConfig ?? .();
			data.MaterialKey = materialKey;
			data.EntityIndex = mesh.Owner.Index;

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
