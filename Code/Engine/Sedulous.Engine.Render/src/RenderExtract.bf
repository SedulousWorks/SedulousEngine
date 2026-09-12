using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// Reading a scene's render components into the snapshot the renderer consumes.
///
/// THE one way seam: this layer knows about both the scene and the renderer, and the renderer
/// knows about neither. Everything here runs AFTER the scene's transforms are current.
static class RenderExtract
{
	/// Below this many meshes the parallel path costs more than it saves. The win is at
	/// thousands of renderables, so the threshold is set conservatively.
	public const uint32 ParallelExtractThreshold = 256;

	/// Packs an entity into the opaque id the renderer carries for picking. Opaque to the
	/// renderer, which never takes it apart.
	public static uint64 PackEntity(EntityHandle entity) =>
		((uint64)entity.Generation << 32) | (uint64)entity.Index;

	/// Maps a material's blend preset onto the category that decides dispatch and sort order.
	public static uint16 CategoryForMaterial(Material material)
	{
		if (material == null)
			return RenderCategories.Opaque;

		switch (material.Pipeline.BlendMode)
		{
		case .Opaque: return RenderCategories.Opaque;
		case .Masked: return RenderCategories.Masked;
		default: return RenderCategories.Transparent;
		}
	}

	/// The world space bounding sphere radius of a local box under a transform.
	///
	/// The diagonal half extent scaled by the LARGEST axis scale, read off the basis rows
	/// under the row vector convention. Conservative, and cheap enough to do per renderable.
	public static float WorldBoundsRadius(AABB local, Float4x4 world)
	{
		let sx = Length(Float3(world.M[0][0], world.M[0][1], world.M[0][2]));
		let sy = Length(Float3(world.M[1][0], world.M[1][1], world.M[1][2]));
		let sz = Length(Float3(world.M[2][0], world.M[2][1], world.M[2][2]));
		return Length(local.Extents()) * Max(sx, Max(sy, sz));
	}

	/// Fills one mesh record from a component.
	///
	/// A pure read of transforms already computed and of borrowed pointers, which is what
	/// makes it safe to run across components at once once the transforms are current.
	public static void FillMeshRenderData(Scene scene, MeshComponent* component,
		EntityHandle entity, MeshRenderData data)
	{
		// The raw cache is refreshed from the proxies EVERY frame: a few pointer loads, and a
		// late cook or a hot reload heals live rather than pinning whatever was null at
		// resolve time.
		//
		// BORROWED, where Raptor's cache holds a strong reference per entry. Material is not
		// reference counted here, and the render data beside it already borrows the primary
		// material the same way, so this follows the port rather than introducing a second
		// rule. It IS a weaker guarantee: Raptor keeps each material alive from extract until
		// the snapshot is recorded, and this relies on the material system outliving the
		// frame. Whoever makes materials individually releasable has to revisit it.
		component.MaterialCache.Clear();
		for (int i < component.Materials.Count)
			component.MaterialCache.Add(component.Materials[i].Get);

		let primary = component.MaterialCache.IsEmpty ? null : component.MaterialCache[0];

		data.World = scene.GetWorldMatrix(entity);
		let localBounds = (component.Mesh.Get != null)
			? component.Mesh.Get.Bounds
			: AABB(.(0, 0, 0), .(0, 0, 0));
		data.WorldCenter = TransformPoint(localBounds.Center(), data.World);
		data.WorldRadius = WorldBoundsRadius(localBounds, data.World);
		data.Color = component.Color;
		data.Mesh = component.Mesh.Get;
		data.Material = primary;
		data.EntityId = PackEntity(entity);
		data.Category = CategoryForMaterial(primary);
		// The batch key keeps opaque draws contiguous by mesh and material. The renderer id
		// keeps its default, because the mesh renderer registers first.
		data.SortBatchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(component.Mesh.Get),
			Internal.UnsafeCastToPtr(primary));
		data.BoneMatrices = component.BoneMatrices;
		data.PreviousBoneMatrices = component.PrevBoneMatrices;
		data.BoneCount = component.BoneCount;
		// Per view level selection happens in the renderer: ONE snapshot, many views.
		data.LodBias = component.LodBias;
		data.ForceLod = component.ForceLod;

		// Submesh routing ONLY when the mesh is genuinely multi material. A single entry is
		// the whole mesh path, where slot zero is the material above, and taking it keeps the
		// batching intact.
		let multiMaterial = component.MaterialCache.Count > 1;
		data.SubmeshMaterials = multiMaterial ? component.MaterialCache.Ptr : null;
		data.SubmeshMaterialCount = multiMaterial ? (uint32)component.MaterialCache.Count : 0;
	}

	// ---- scene extractors ------------------------------------------------------------------

	/// Fills the snapshot with one record per VISIBLE mesh, serially.
	///
	/// Assumes the transforms are current, and that the snapshot was reset beforehand.
	public static void ExtractSceneInto(Scene scene, ExtractedScene outScene)
	{
		let meshes = scene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		meshes.ForEach(scope (component, entity) =>
			{
				// An entity that is not effectively active renders nothing.
				if (!scene.IsEffectivelyActive(entity) || !component.Visible
					|| (component.Mesh.Get == null))
					return;

				if (let data = outScene.Add<MeshRenderData>())
					FillMeshRenderData(scene, component, entity, data);
			});
	}

	/// The same, spread across the job system when there is one and the scene is big enough.
	///
	/// Each worker fills its OWN arena and item list, so nothing contends, and a single
	/// threaded merge gathers them afterwards. Falls back to the serial path through slot
	/// zero when there is no job system or too little to gain.
	///
	/// The snapshot is reset here; the context's arenas accumulate across the frame, which
	/// is why the caller begins it once per frame rather than per extract.
	public static void ExtractSceneInto(Scene scene, ExtractedScene outScene, RenderContext context)
	{
		outScene.Reset();

		let meshes = scene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		let count = meshes.Count;
		if (count == 0)
			return;

		context.ResetItems();
		let components = meshes.Dense;
		let owners = meshes.Owners;

		if (HasGlobalJobSystem() && (count >= ParallelExtractThreshold))
		{
			let jobs = GlobalJobs();
			jobs.ParallelFor((int32)count, scope (i) =>
				{
					// The fill REFRESHES the component's per frame material cache, so this
					// writes. Safe here because each component is touched by exactly one job.
					let component = &components[i];
					if (!scene.IsEffectivelyActive(owners[i]) || !component.Visible
						|| (component.Mesh.Get == null))
						return;

					let slot = (uint32)jobs.CurrentSlot;
					let arena = context.Arena(slot);
					let data = new:arena MeshRenderData();
					if (data == null)
						return;

					FillMeshRenderData(scene, component, owners[i], data);
					context.Items(slot).Add(data);
				});
		}
		else
		{
			let arena = context.Arena(0);
			let items = context.Items(0);
			for (int32 i < (int32)count)
			{
				let component = &components[i];
				if (!scene.IsEffectivelyActive(owners[i]) || !component.Visible
					|| (component.Mesh.Get == null))
					continue;

				let data = new:arena MeshRenderData();
				if (data == null)
					continue;

				FillMeshRenderData(scene, component, owners[i], data);
				items.Add(data);
			}
		}

		context.MergeInto(outScene);
	}

	/// Fills the snapshot with ONE record per visible instanced set: the set, not its
	/// instances.
	///
	/// Per frame cost is constant in the instance count, because the renderer holds the
	/// transforms in a persistent buffer keyed by the entity and the whole set culls against
	/// one merged bounds.
	public static void ExtractInstancedMeshesInto(Scene scene, ExtractedScene outScene)
	{
		let sets = scene.GetSystem<InstancedMeshComponentManager>();
		if (sets == null)
			return;

		sets.ForEach(scope (component, entity) =>
			{
				// Gated BEFORE the caches below: an inactive set is simply absent from the
				// snapshot. The renderer draws from the snapshot, and its buffer is only a
				// cache that revalidates by version when the set comes back.
				if (!scene.IsEffectivelyActive(entity) || !component.Visible
					|| (component.Mesh.Get == null) || (component.Count == 0))
					return;

				// The entity relative instances are composed into world space and CACHED,
				// rebuilt only when the authored set changed or the entity moved. The
				// renderer keys its upload on the composed version, so either kind of change
				// re uploads.
				let entityWorld = scene.GetWorldMatrix(entity);
				if ((component.ComposedFromVersion != component.Version)
					|| !(component.ComposedEntityWorld == entityWorld))
				{
					component.WorldTransforms.Clear();
					for (int i < component.Instances.Count)
						component.WorldTransforms.Add(component.Instances[i] * entityWorld);

					component.ComposedEntityWorld = entityWorld;
					component.ComposedFromVersion = component.Version;
					component.ComposedVersion++;
				}

				// The merged bounds are the union of the mesh's local box under every composed
				// instance, cached the same way and rebuilt only when that set changed.
				if (component.BoundsVersion != component.ComposedVersion)
				{
					let localBounds = component.Mesh.Get.Bounds;
					var merged = AABB.Empty();
					for (let transform in component.WorldTransforms)
					{
						let center = TransformPoint(localBounds.Center(), transform);
						let radius = WorldBoundsRadius(localBounds, transform);
						merged.Expand(center - Float3(radius, radius, radius));
						merged.Expand(center + Float3(radius, radius, radius));
					}
					component.CachedCenter = merged.Center();
					component.CachedRadius = Length(merged.Extents());
					component.BoundsVersion = component.ComposedVersion;
				}

				let data = outScene.Add<MultiMeshRenderData>();
				if (data == null)
					return;

				data.MultiMesh = true;
				data.Key = PackEntity(entity);
				// BORROWED for the frame, which the snapshot being immutable is what makes safe.
				data.Transforms = component.WorldTransforms.Ptr;
				let tintsMatch = !component.Tints.IsEmpty
					&& (component.Tints.Count == component.Instances.Count);
				data.Tints = tintsMatch ? component.Tints.Ptr : null;
				data.InstanceCount = component.Count;
				data.Version = component.ComposedVersion;
				data.Mesh = component.Mesh.Get;
				data.Material = component.Material.Get;
				data.SubmeshMaterials = component.SubmeshMaterials.IsEmpty
					? null : component.SubmeshMaterials.Ptr;
				data.SubmeshMaterialCount = (uint32)component.SubmeshMaterials.Count;
				data.Color = component.Color;
				// The merged bounds are what let the whole set cull and depth sort as one.
				data.WorldCenter = component.CachedCenter;
				data.WorldRadius = component.CachedRadius;
				data.EntityId = PackEntity(entity);
				data.Category = CategoryForMaterial(component.Material.Get);
				data.SortBatchKey = SortKeys.BatchKey(
					Internal.UnsafeCastToPtr(component.Mesh.Get),
					Internal.UnsafeCastToPtr(component.Material.Get));

				data.PosePool = component.PosePool;
				data.PreviousPosePool = component.PrevPosePool;
				data.PoseCount = component.PoseCount;
				data.PoseBoneCount = component.BoneCount;
				data.PoseAssignment = component.PoseAssignment;
				// The explicit indices are borrowed ONLY when the policy asks for them and the
				// list is the right length; otherwise null leaves the renderer on its hashed
				// default rather than reading a mismatched array.
				let explicitPoses = (component.PoseAssignment == .Explicit)
					&& (component.PoseIndices.Count == component.Instances.Count);
				data.PoseIndices = explicitPoses ? component.PoseIndices.Ptr : null;

				// The renderer id stays nought, since the mesh renderer draws these too, and
				// the world matrix stays identity: the per instance transforms ride above.
			});
	}
}
