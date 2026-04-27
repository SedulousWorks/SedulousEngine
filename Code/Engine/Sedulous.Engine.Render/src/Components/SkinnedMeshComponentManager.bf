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

/// Manages skinned mesh components: resolves resource refs, reads bone matrices
/// from SkeletalAnimationComponent, uploads to GPU, and extracts render data.
///
/// Each frame:
///   1. PostUpdate: resolve mesh/material refs via RenderResourceResolver
///   2. PostUpdate: read bone matrices from animation component -> upload to bone buffer
///   3. Extraction: emit MeshRenderData with IsSkinned + BoneBufferHandle
class SkinnedMeshComponentManager : ComponentManager<SkinnedMeshComponent>, IRenderDataProvider
{
	/// Reference to GPU resource manager (set by RenderSubsystem).
	public GPUResourceManager GPUResources { get; set; }

	/// Shared resource resolver (set by RenderSubsystem).
	public RenderResourceResolver Resolver { get; set; }

	/// Per-component resolve state, keyed by entity handle.
	private Dictionary<EntityHandle, SkinnedMeshResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
			kv.value.Release();
		DeleteDictionaryAndValues!(_);
	};


	public override StringView SerializationTypeId => "Sedulous.SkinnedMeshComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostUpdate, new => UpdateSkinnedMeshes);
	}

	/// Per-frame: resolve resources, evaluate animation, upload bone matrices.
	private void UpdateSkinnedMeshes(float deltaTime)
	{
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive)
				continue;

			// Resolve resources if resolver is available
			if (Resolver != null)
				ResolveComponentResources(comp);

			// Read bone matrices from animation component on the same entity
			// and upload to the GPU bone buffer.
			// Priority: AnimationGraphComponent > SkeletalAnimationComponent
			if (comp.BoneBufferHandle.IsValid && GPUResources != null && Scene != null)
			{
				Span<Matrix> currentMatrices = default;
				Span<Matrix> prevMatrices = default;

				// Check for animation graph first (overrides simple clip)
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
					let boneBuffer = GPUResources.GetBoneBuffer(comp.BoneBufferHandle);
					if (boneBuffer != null && boneBuffer.Buffer != null)
					{
						let matrixSize = (uint64)(currentMatrices.Length * sizeof(Matrix));

						// Current frame matrices at offset 0
						TransferHelper.WriteMappedBuffer(boneBuffer.Buffer, 0,
							Span<uint8>((uint8*)currentMatrices.Ptr, (int)matrixSize));

						// Previous frame matrices at offset matrixSize
						if (prevMatrices.Length > 0)
							TransferHelper.WriteMappedBuffer(boneBuffer.Buffer, matrixSize,
								Span<uint8>((uint8*)prevMatrices.Ptr, (int)matrixSize));
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

			// Create bone buffer from animation component's skeleton
			if (!comp.BoneBufferHandle.IsValid && Scene != null)
			{
				Skeleton skeleton = null;

				// Check graph component first
				let graphMgr = Scene.GetModule<AnimationGraphComponentManager>();
				let graphComp = (graphMgr != null) ? graphMgr.GetForEntity(comp.Owner) : null;
				if (graphComp != null)
					skeleton = graphComp.Skeleton;

				// Fall back to skeletal animation component
				if (skeleton == null)
				{
					let animMgr = Scene.GetModule<SkeletalAnimationComponentManager>();
					let animComp = (animMgr != null) ? animMgr.GetForEntity(comp.Owner) : null;
					if (animComp != null)
						skeleton = animComp.Skeleton;
				}

				if (skeleton != null)
				{
					let boneCount = (uint16)skeleton.BoneCount;
					if (boneCount > 0)
					{
						if (GPUResources.CreateBoneBuffer(boneCount) case .Ok(let boneHandle))
							comp.BoneBufferHandle = boneHandle;
					}
				}
			}
		}
		else if (!meshRef.IsValid && comp.MeshHandle.IsValid)
		{
			comp.MeshHandle = .Invalid;
			comp.LocalBounds = .(.Zero, .Zero);
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

		// Prepare any dirty material instances (handles both resolved and manually-set materials)
		for (int32 slot = 0; slot < comp.Materials.Count; slot++)
		{
			let material = comp.Materials[slot];
			if (material != null && (material.IsBindGroupDirty || material.IsUniformDirty))
				Resolver.PrepareMaterial(material);
		}
	}

	/// Extracts MeshRenderData for all active skinned mesh components.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null || GPUResources == null)
			return;

		let frameAlloc = context.RenderContext.FrameAllocator;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsVisible)
				continue;

			if (!comp.MeshHandle.IsValid || !comp.BoneBufferHandle.IsValid)
				continue;

			let gpuMesh = GPUResources.GetMesh(comp.MeshHandle);
			if (gpuMesh == null)
				continue;

			let worldMatrix = scene.GetWorldMatrix(comp.Owner);
			let prevWorldMatrix = scene.GetPrevWorldMatrix(comp.Owner);
			let center = Vector3.Transform(comp.LocalBounds.Center, worldMatrix);

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

				let data = new:frameAlloc MeshRenderData();
				data.Position = center;
				data.Bounds = comp.LocalBounds;
				data.MaterialSortKey = materialKey;
				data.SortOrder = 0;
				data.Flags = flags;
				data.WorldMatrix = worldMatrix;
				data.PrevWorldMatrix = prevWorldMatrix;
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
