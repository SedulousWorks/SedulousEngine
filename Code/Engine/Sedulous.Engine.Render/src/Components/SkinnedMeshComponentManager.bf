namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Engine.Animation;
using Sedulous.Geometry.Resources;
using Sedulous.Materials.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Jobs;
using Sedulous.Profiler;

#define REFRESH_WORLD_BOUNDS_THREADED
#define FRUSTUM_CULL_MAIN_VIEW

/// Manages skinned mesh components: resolves resource refs, reads bone matrices
/// from SkeletalAnimationComponent, uploads to GPU, and extracts render data.
///
/// Each frame:
///   1. PostUpdate: resolve mesh/material refs via RenderResourceResolver
///   2. PostUpdate: read bone matrices from animation component -> upload to bone buffer
///   3. Extraction: emit MeshRenderData with IsSkinned + BoneBufferHandle
class SkinnedMeshComponentManager : ComponentManager<SkinnedMeshComponent>, IRenderDataProvider, IResourceChangeListener
{
	/// Reference to GPU resource manager (set by RenderSubsystem).
	public GPUResourceManager GPUResources { get; set; }

	/// Shared resource resolver (set by RenderSubsystem).
	public RenderResourceResolver Resolver { get; set; }

	/// Frame counter for deferred bone buffer deletion.
	private uint64 mFrameCounter;

	/// Per-component resolve state, keyed by entity handle.
	private Dictionary<EntityHandle, SkinnedMeshResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
			kv.value.Release();
		DeleteDictionaryAndValues!(_);
	};

	/// Entity indices whose LocalBounds was written this frame. Drained in
	/// RefreshWorldBounds. See MeshComponentManager for the same pattern.
	private List<int32> mBoundsDirtyEntities = new .() ~ delete _;

	/// Entity indices that need (re)resolving this frame. See
	/// MeshComponentManager for the same pattern.
	private List<int32> mResolveDirtyEntities = new .() ~ delete _;

	private bool mListenerRegistered;


	public override StringView SerializationTypeId => "Sedulous.SkinnedMeshComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		// Resource resolution always runs (presentation).
		RegisterUpdate(.PostUpdate, new => ResolveSkinnedMeshResources);

		// Bone matrix upload only runs during simulation - animation must have evaluated first.
		// Bind-pose matrices are uploaded once during resource resolution so skinned meshes
		// are visible even without simulation (editor mode).
		RegisterUpdate(.PostUpdate, new => UploadBoneMatrices, simulationOnly: true);

		// World-space bounds refresh runs after transforms are final.
		RegisterUpdate(.PostTransform, new => RefreshWorldBounds);
	}

	public override void OnSceneCreate(Scene scene)
	{
		base.OnSceneCreate(scene);
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

	protected override void OnComponentCreated(SkinnedMeshComponent comp)
	{
		comp.MeshChanged.Add(new (c) => MarkResolveDirty(c));
		comp.MaterialChanged.Add(new (c, slot) => MarkResolveDirty(c));
		// Manually-created MaterialInstances - see MeshComponentManager.
		comp.MaterialInstanceAttached.Add(new (mat) => OnMaterialInstanceAttached(mat));
		MarkResolveDirty(comp);
	}

	private void OnMaterialInstanceAttached(MaterialInstance material)
	{
		if (material == null || Resolver == null)
			return;
		Resolver.MaterialSystem.PrepareInstance(material);
	}

	public void MarkResolveDirty(SkinnedMeshComponent comp)
	{
		if (comp.ResolveDirty)
			return;
		comp.ResolveDirty = true;
		mResolveDirtyEntities.Add((int32)comp.Owner.Index);
	}

	public void OnResourceReloaded(StringView uri, Type resourceType, IResource resource)
	{
		for (let comp in ActiveComponents)
			MarkResolveDirty(comp);
	}

	/// Resolves mesh and material resources. Two passes:
	///   1. Drain the resolve-dirty queue.
	///   2. Per-frame material-instance prep over all active components.
	private void ResolveSkinnedMeshResources(float deltaTime)
	{
		if (Resolver == null) return;

		// Pass 1: drain dirty queue.
		for (let entityIdx in mResolveDirtyEntities)
		{
			let comp = GetByEntityIndex(entityIdx);
			if (comp == null || !comp.IsActive || !comp.ResolveDirty)
				continue;
			ResolveComponentResources(comp);
			comp.ResolveDirty = false;
		}
		mResolveDirtyEntities.Clear();

		// Pass 2: drain the global MaterialSystem dirty list. See
		// MeshComponentManager.ResolveResources for the same pattern.
		Resolver.MaterialSystem.PrepareDirtyInstances();
	}

	/// Reads bone matrices from animation components and uploads to GPU.
	/// Simulation only - requires animation evaluation to have run first.
	/// Bind-pose is uploaded once during resource resolution for editor visibility.
	private void UploadBoneMatrices(float deltaTime)
	{
		mFrameCounter++;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive)
				continue;

			if (comp.BoneBufferHandle.IsValid && GPUResources != null && Scene != null)
			{
				Span<Matrix> currentMatrices = default;
				Span<Matrix> prevMatrices = default;

				// Check for animation graph first (overrides simple clip)
				// Priority: AnimationGraphComponent > SkeletalAnimationComponent
				let graphMgr = Scene.GetModule<AnimationGraphComponentManager>();
				let graphComp = (graphMgr != null) ? graphMgr.GetForEntity(comp.Owner) : null;
				if (graphComp != null && graphComp.IsReady)
				{
					currentMatrices = graphComp.GetSkinningMatrices();
					prevMatrices = graphComp.GetPrevSkinningMatrices();
				}
				else
				{
					// Fall back to simple skeletal animation
					let animMgr = Scene.GetModule<SkeletalAnimationComponentManager>();
					let animComp = (animMgr != null) ? animMgr.GetForEntity(comp.Owner) : null;
					if (animComp != null && animComp.IsReady)
					{
						currentMatrices = animComp.GetSkinningMatrices();
						prevMatrices = animComp.GetPrevSkinningMatrices();
					}
				}

				if (currentMatrices.Length > 0)
				{
					let poolBuf = GPUResources.BonePoolBuffer;
					let boneBuffer = GPUResources.GetBoneBuffer(comp.BoneBufferHandle);
					if (boneBuffer != null && poolBuf != null)
					{
						// If the bone count changed (e.g., skeleton assigned in editor),
						// the existing pool slot is too small. Reallocate.
						if (currentMatrices.Length > boneBuffer.BoneCount)
						{
							GPUResources.ReleaseBoneBuffer(comp.BoneBufferHandle, mFrameCounter);
							if (GPUResources.CreateBoneBuffer((uint16)currentMatrices.Length) case .Ok(let newHandle))
							{
								comp.BoneBufferHandle = newHandle;
								// Invalidate the skinning instance so it picks up the new bone offset
								comp.ResolveDirty = true;
							}
							else
								continue;

							let newBoneBuffer = GPUResources.GetBoneBuffer(comp.BoneBufferHandle);
							if (newBoneBuffer == null)
								continue;

							let matrixSize = (uint64)(currentMatrices.Length * sizeof(Matrix));
							let baseOff = newBoneBuffer.Offset;
							TransferHelper.WriteMappedBuffer(poolBuf, baseOff,
								Span<uint8>((uint8*)currentMatrices.Ptr, (int)matrixSize));
							if (prevMatrices.Length > 0)
								TransferHelper.WriteMappedBuffer(poolBuf, baseOff + matrixSize,
									Span<uint8>((uint8*)prevMatrices.Ptr, (int)matrixSize));
						}
						else
						{
							let matrixSize = (uint64)(currentMatrices.Length * sizeof(Matrix));
							let baseOff = boneBuffer.Offset;
							TransferHelper.WriteMappedBuffer(poolBuf, baseOff,
								Span<uint8>((uint8*)currentMatrices.Ptr, (int)matrixSize));
							if (prevMatrices.Length > 0)
								TransferHelper.WriteMappedBuffer(poolBuf, baseOff + matrixSize,
									Span<uint8>((uint8*)prevMatrices.Ptr, (int)matrixSize));
						}
					}
				}
			}
		}
	}

	/// Resolves mesh and material resource refs for a component.
	private void ResolveComponentResources(SkinnedMeshComponent comp)
	{
		let entityHandle = comp.Owner;
		SkinnedMeshResolveState state = null;

		if (!mResolveStates.TryGetValue(entityHandle, var existingState))
		{
			let newState = new SkinnedMeshResolveState();
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
		if (Resolver.ResolveSkinnedMesh(ref state.Mesh, meshRef, out meshHandle, out bounds))
		{
			comp.MeshHandle = meshHandle;
			comp.LocalBounds = bounds;
			MarkBoundsDirty(comp);

			// Create bone buffer - prefer skeleton from animation component,
			// fall back to mesh's RequiredBoneCount for T-pose rendering.
			if (!comp.BoneBufferHandle.IsValid && GPUResources != null)
			{
				uint16 boneCount = 0;

				// Try to get bone count from animation component's skeleton
				if (Scene != null)
				{
					Skeleton skeleton = null;

					let graphMgr = Scene.GetModule<AnimationGraphComponentManager>();
					let graphComp = (graphMgr != null) ? graphMgr.GetForEntity(comp.Owner) : null;
					if (graphComp != null)
						skeleton = graphComp.Skeleton;

					if (skeleton == null)
					{
						let animMgr = Scene.GetModule<SkeletalAnimationComponentManager>();
						let animComp = (animMgr != null) ? animMgr.GetForEntity(comp.Owner) : null;
						if (animComp != null)
							skeleton = animComp.Skeleton;
					}

					if (skeleton != null)
						boneCount = (uint16)skeleton.BoneCount;
				}

				// Fall back to mesh's required bone count (from vertex joint indices)
				if (boneCount == 0)
				{
					let gpuMesh = GPUResources.GetMesh(comp.MeshHandle);
					if (gpuMesh != null && gpuMesh.IsSkinned)
						boneCount = gpuMesh.RequiredBoneCount;
				}

				if (boneCount > 0)
				{
					if (GPUResources.CreateBoneBuffer(boneCount) case .Ok(let boneHandle))
					{
						comp.BoneBufferHandle = boneHandle;

						// Upload identity matrices so the mesh renders in bind pose
						// (T-pose) until animation overwrites them.
						let poolBuf = GPUResources.BonePoolBuffer;
						let boneBuffer = GPUResources.GetBoneBuffer(boneHandle);
						if (boneBuffer != null && poolBuf != null)
						{
							let bindPose = scope Matrix[boneCount];
							for (int i = 0; i < boneCount; i++)
								bindPose[i] = .Identity;

							let matrixSize = (uint64)(boneCount * sizeof(Matrix));
							let baseOff = boneBuffer.Offset;
							TransferHelper.WriteMappedBuffer(poolBuf, baseOff,
								Span<uint8>((uint8*)&bindPose[0], (int)matrixSize));
							// Previous frame = same bind pose
							TransferHelper.WriteMappedBuffer(poolBuf, baseOff + matrixSize,
								Span<uint8>((uint8*)&bindPose[0], (int)matrixSize));
						}
					}
				}
			}
		}
		else if (!meshRef.IsValid && comp.MeshHandle.IsValid)
		{
			comp.MeshHandle = .Invalid;
			comp.LocalBounds = .(.Zero, .Zero);
			MarkBoundsDirty(comp);
		}

		// Resolve materials
		for (int32 slot = 0; slot < comp.MaterialRefCount; slot++)
		{
			let matRef = comp.GetMaterialRef(slot);

			if (!matRef.IsValid)
			{
				if (slot < comp.Materials.Count && comp.Materials[slot] != null)
					comp.SetMaterial(slot, null);
				continue;
			}

			while (state.Materials.Count <= slot)
				state.Materials.Add(.());

			MaterialInstance instance;
			if (Resolver.ResolveMaterial(ref state.Materials[slot], matRef, out instance))
			{
				comp.SetMaterial(slot, instance);
				instance.ReleaseRef(); // SetMaterial AddRef'd - resolver doesn't own it
			}
		}

		// NOTE: material-instance dirty prep moved out to the caller's
		// Pass 2 loop so it covers all active components (uniform / bind
		// group edits don't trip ref-change dirty tracking).
	}

	/// Marks a component for WorldBounds refresh on the next PostTransform.
	private void MarkBoundsDirty(SkinnedMeshComponent comp)
	{
		if (comp.BoundsDirty)
			return;
		comp.BoundsDirty = true;
		mBoundsDirtyEntities.Add((int32)comp.Owner.Index);
	}

	/// PostTransform-phase refresh of cached world bounds. See
	/// MeshComponentManager.RefreshWorldBounds for the same pattern and
	/// thread-safety reasoning - total work is "entities moved" +
	/// "LocalBounds changes", not total component count.
#if !REFRESH_WORLD_BOUNDS_THREADED
	private void RefreshWorldBounds(float deltaTime)
	{
		using (Profiler.Begin("SkinnedMesh.RefreshWorldBounds"))
		{
		let scene = Scene;
		if (scene == null)
			return;

		for (let entityIdx in scene.TransformsUpdatedThisFrame)
		{
			let comp = GetByEntityIndex(entityIdx);
			if (comp == null) continue;
			comp.WorldBounds = BoundingBox.Transform(comp.LocalBounds, scene.GetWorldMatrix(comp.Owner));
			comp.BoundsDirty = false;
		}

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
#else
	private void RefreshWorldBounds(float deltaTime)
	{
		using (Profiler.Begin("SkinnedMesh.RefreshWorldBounds"))
		{
		let scene = Scene;
		if (scene == null)
			return;

		let workerCount = JobSystem.IsInitialized ? JobSystem.WorkerCount : 0;
		let updatedList = scene.TransformsUpdatedThisFrame;
		let updatedCount = (int32)updatedList.Count;

		// Pass 1: entities whose transform changed this frame.
		if (updatedCount >= 256 && workerCount > 0)
		{
			JobSystem.ParallelFor(0, updatedCount, scope [&](begin, end) => {
				for (int32 i = begin; i < end; i++)
				{
					let entityIdx = updatedList[i];
					let comp = GetByEntityIndex(entityIdx);
					if (comp == null) continue;
					comp.WorldBounds = BoundingBox.Transform(comp.LocalBounds, scene.GetWorldMatrix(comp.Owner));
					comp.BoundsDirty = false;
				}
			});
		}
		else
		{
			for (let entityIdx in updatedList)
			{
				let comp = GetByEntityIndex(entityIdx);
				if (comp == null) continue;
				comp.WorldBounds = BoundingBox.Transform(comp.LocalBounds, scene.GetWorldMatrix(comp.Owner));
				comp.BoundsDirty = false;
			}
		}

		// Pass 2: LocalBounds-only changes.
		let dirtyCount = (int32)mBoundsDirtyEntities.Count;
		if (dirtyCount >= 256 && workerCount > 0)
		{
			JobSystem.ParallelFor(0, dirtyCount, scope [&](begin, end) => {
				for (int32 i = begin; i < end; i++)
				{
					let entityIdx = mBoundsDirtyEntities[i];
					let comp = GetByEntityIndex(entityIdx);
					if (comp == null || !comp.BoundsDirty) continue;
					comp.WorldBounds = BoundingBox.Transform(comp.LocalBounds, scene.GetWorldMatrix(comp.Owner));
					comp.BoundsDirty = false;
				}
			});
		}
		else
		{
			for (let entityIdx in mBoundsDirtyEntities)
			{
				let comp = GetByEntityIndex(entityIdx);
				if (comp == null || !comp.BoundsDirty) continue;
				comp.WorldBounds = BoundingBox.Transform(comp.LocalBounds, scene.GetWorldMatrix(comp.Owner));
				comp.BoundsDirty = false;
			}
		}
		mBoundsDirtyEntities.Clear();
		}
	}
#endif

	/// Extracts MeshRenderData for all active skinned mesh components.
	///
	/// With FRUSTUM_CULL_MAIN_VIEW defined, each skinned mesh's WorldBounds
	/// (rest-pose AABB transformed by world matrix - conservative for
	/// animated poses, see SkinnedMeshComponent.WorldBounds comment) is
	/// tested against the view frustum before per-submesh emission.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		using (Profiler.Begin("SkinnedMesh.Extract"))
		{
		let scene = Scene;
		if (scene == null || GPUResources == null)
			return;

		let frameAlloc = context.RenderContext.FrameAllocator;
		let mainFrustum = BoundingFrustum(context.ViewProjectionMatrix);
		let viewMatrix = context.ViewMatrix;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsVisible)
				continue;

			if (!comp.MeshHandle.IsValid || !comp.BoneBufferHandle.IsValid)
				continue;

#if FRUSTUM_CULL_MAIN_VIEW
			if (!mainFrustum.Intersects(comp.WorldBounds))
				continue;
#endif

			let gpuMesh = GPUResources.GetMesh(comp.MeshHandle);
			if (gpuMesh == null)
				continue;

			let worldMatrix = scene.GetWorldMatrix(comp.Owner);
			let prevWorldMatrix = scene.GetPrevWorldMatrix(comp.Owner);
			let center = comp.WorldBounds.Center;

			// View-space depth shared across all submeshes of this entity.
			let viewPos = Vector3.Transform(center, viewMatrix);
			let depth = Math.Max(viewPos.Z, 0);
			let depthBits = (uint32)(depth * 1000.0f);

			var flags = RenderDataFlags.None;
			if (comp.CastsShadows)
				flags |= .CastShadows;

			// Emit one MeshRenderData per submesh
			for (int32 subIdx = 0; subIdx < gpuMesh.SubMeshes.Count; subIdx++)
			{
				let subMesh = gpuMesh.SubMeshes[subIdx];
				let materialSlot = (int32)subMesh.MaterialSlot;
				let material = comp.GetMaterial(materialSlot);

				// Determine category from material blend mode
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

				// Inline sort key: same shape as MeshComponentManager.ExtractSlot.
				uint64 sortKey;
				if (category == RenderCategories.Transparent)
					sortKey = (uint64)(uint32.MaxValue - depthBits);
				else
					sortKey = ((uint64)materialKey << 32) | (uint64)depthBits;

				let data = new:frameAlloc MeshRenderData();
				data.Position = center;
				data.Bounds = comp.WorldBounds;
				data.MaterialSortKey = materialKey;
				data.SortOrder = 0;
				data.Flags = flags;
				data.SortKey = sortKey;
				data.WorldMatrix = worldMatrix;
				data.PrevWorldMatrix = prevWorldMatrix;
				data.InstanceColor = comp.Color;
				data.MeshHandle = comp.MeshHandle;
				data.SubMeshIndex = (uint32)subIdx;
				data.MaterialBindGroup = material?.BindGroup;
				data.MaterialBindGroupLayout = material?.BindGroupLayout;
				data.MaterialPipelineConfig = material?.Material?.PipelineConfig ?? .();
				data.MaterialKey = materialKey;
				data.BoneBufferHandle = comp.BoneBufferHandle;
				data.IsSkinned = true;
				data.EntityIndex = comp.Owner.Index;
				context.RenderData.Add(category, data);
			}
		}
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

/// Per-component resource resolution tracking for skinned meshes.
class SkinnedMeshResolveState
{
	public ResolvedResource<SkinnedMeshResource> Mesh;
	public List<ResolvedResource<MaterialResource>> Materials = new .() ~ delete _;

	public void Release()
	{
		Mesh.Release();
		for (var mat in ref Materials)
			mat.Release();
	}
}
