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
}
