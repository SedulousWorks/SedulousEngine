using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Engine.Navigation;
using Sedulous.Navigation;
using Sedulous.Navigation.Pipeline;

namespace Sedulous.Editor.Navigation;

/// The "Bake Navigation" flow: the scene's static geometry touching a zone's box (what its
/// systems answer through AsStaticGeometrySource, never render meshes) is transformed into
/// zone-local space so the baked navmesh rides the zone entity's transform to any placement
/// without a rebake; the Recast bake runs; the result lands in the zone's NavigationZoneAsset
/// sidecar. Editor-only; the player never links this.
static class NavigationBake
{
	/// Collects the triangles, in the zone entity's local space, for a bake: every scene
	/// system's static geometry touching the zone box (physics: static, non-trigger bodies on
	/// active entities; terrain: its surface, sampled no finer than the cell size, since Recast
	/// re-voxelises to its own cells). What moves (agents, dynamic and kinematic bodies,
	/// characters) and bare render meshes are not level geometry: a car or a walker standing in
	/// the zone would bake a hole under itself. Answers the triangle count.
	public static int CollectNavigationGeometry(Scene scene, EntityHandle zoneEntity, Float3 zoneExtents, float cellSize,
		List<Float3> outVertices, List<uint32> outIndices)
	{
		outVertices.Clear();
		outIndices.Clear();
		// Rigid, no scale: the navmesh is baked in world units, so a zone entity's scale must not
		// warp the geometry Recast sees; a zone sharing a scaled entity with its ground would
		// otherwise un-scale that ground to unit size and erode the navmesh to nothing.
		let zoneInv = Inverse(RigidPart(scene.GetWorldMatrix(zoneEntity)));
		let zoneBox = AABB.FromCenterExtents(scene.GetWorldPosition(zoneEntity), zoneExtents);

		let world = scope List<Float3>();
		for (let system in scene.Systems)
		{
			if (let source = system.AsStaticGeometrySource)
				source.CollectStaticGeometry(scene, zoneBox, cellSize, world);
		}
		for (let point in world)
		{
			outIndices.Add((uint32)outVertices.Count);
			outVertices.Add(TransformPoint(point, zoneInv)); // zone local
		}
		return outIndices.Count / 3;
	}

	private static NavigationBakeParams ParamsFor(NavMeshZoneComponent* zone, bool parallelBake)
	{
		var parameters = NavigationBakeParams();
		parameters.CellSize = zone.CellSize;
		parameters.CellHeight = zone.CellHeight;
		parameters.AgentRadius = zone.AgentRadius;
		parameters.AgentHeight = zone.AgentHeight;
		parameters.AgentMaxClimb = zone.AgentMaxClimb;
		parameters.AgentMaxSlopeDegrees = zone.AgentMaxSlopeDegrees;
		parameters.ParallelBake = parallelBake; // the domain-contributed editor setting
		// The bake covers the zone's box (zone local, where the geometry is), so a ground as
		// wide as the level does not widen the grid past the zone.
		parameters.Bounds = .(-zone.Extents, zone.Extents);
		return parameters;
	}

	/// Bakes the zone owned by the entity and writes the result into the zone's
	/// NavigationZoneAsset instance. The bake params come from the zone component. An empty
	/// collection or a degenerate bake writes an empty asset, a valid "no navmesh yet" state.
	public static BakeResult BakeNavigationZone(Scene scene, EntityHandle zoneEntity, Instance targetAsset, bool parallelBake = true)
	{
		var result = BakeResult();
		let zones = scene.GetSystem<NavMeshZoneComponentManager>();
		if (zones == null)
			return result;
		let zone = zones.Get(zoneEntity);
		if (zone == null)
			return result;

		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		result.TriangleCount = CollectNavigationGeometry(scene, zoneEntity, zone.Extents, zone.CellSize, verts, indices);

		let asset = scope NavigationZoneAsset();
		if (result.TriangleCount > 0)
		{
			let parameters = ParamsFor(zone, parallelBake);
			// Tiled: small zones come out as one tile, large ones split, and the per-tile
			// primitive can regenerate a single tile later. The stages are captured every editor
			// bake and parked on the scene system for the bake-stages overlay.
			let blob = scope List<uint8>();
			let stages = scope NavigationBakeStages();
			let baked = NavigationMeshBuilder.BuildTiled(verts, indices, parameters, blob, stages);
			if (let system = scene.GetSystem<NavigationSceneSystem>())
				system.BakeStages.Set(zoneEntity, stages.ContourLines, stages.WalkableSamples);
			if ((baked case .Ok) && !blob.IsEmpty)
			{
				asset.NavMeshBlob.AddRange(blob);
				result.Baked = true;
			}
		}

		if (NavigationZoneStorage.Write(targetAsset, asset) case .Err)
		{
			GlobalLog(.Error, "Editor: navigation bake: writing the zone asset failed");
			result.Baked = false;
		}
		return result;
	}

	/// The partial rebake: only the tiles whose bounds intersect the world region, an edited
	/// region such as a moved obstacle or a terrain sculpt, regenerate and patch into the
	/// zone's existing tiled blob. Everything outside keeps its exact bytes, and a patched blob
	/// equals a full rebake of the same scene byte for byte, the grid anchored by the original
	/// bake. Falls back to a full bake when the asset has no tiled blob yet.
	public static RegionRebakeResult RebakeNavigationZoneRegion(Scene scene, EntityHandle zoneEntity, Instance targetAsset,
		Float3 worldMin, Float3 worldMax, bool parallelBake = true)
	{
		var result = RegionRebakeResult();
		let zones = scene.GetSystem<NavMeshZoneComponentManager>();
		let zone = (zones != null) ? zones.Get(zoneEntity) : null;
		if (zone == null)
			return result;

		// The existing blob's grid anchors the patch; no tiled blob means the full-bake fallback,
		// also the migration path for single-tile assets.
		let asset = scope NavigationZoneAsset();
		var grid = NavigationTileGridDesc();
		let haveTiled = (NavigationZoneStorage.EnsureNavMeshLoaded(targetAsset, asset) case .Ok)
			&& !asset.NavMeshBlob.IsEmpty && NavigationBlob.ReadGrid(asset.NavMeshBlob, out grid);
		if (!haveTiled)
		{
			let full = BakeNavigationZone(scene, zoneEntity, targetAsset, parallelBake);
			result.Rebaked = full.Baked;
			result.FullBake = true;
			return result;
		}

		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		if (CollectNavigationGeometry(scene, zoneEntity, zone.Extents, zone.CellSize, verts, indices) == 0)
			return result; // nothing to bake against: the asset stays

		let parameters = ParamsFor(zone, parallelBake);

		// The edited region in zone-local space, the grid's frame, padded by the bake's border
		// apron so tiles whose border overlapped the edit also refresh.
		let zoneInv = Inverse(RigidPart(scene.GetWorldMatrix(zoneEntity)));
		var region = AABB.Empty();
		for (int i < 8)
		{
			let corner = Float3(((i & 1) != 0) ? worldMax.X : worldMin.X,
				((i & 2) != 0) ? worldMax.Y : worldMin.Y,
				((i & 4) != 0) ? worldMax.Z : worldMin.Z);
			region.Expand(TransformPoint(corner, zoneInv));
		}
		let apron = (Math.Ceiling(parameters.AgentRadius / parameters.CellSize) + 3.0f) * parameters.CellSize;

		let tx0 = Math.Clamp((int32)Math.Floor((region.Min.X - apron - grid.Origin.X) / grid.TileWorldSize), 0, grid.CountX - 1);
		let tx1 = Math.Clamp((int32)Math.Floor((region.Max.X + apron - grid.Origin.X) / grid.TileWorldSize), 0, grid.CountX - 1);
		let ty0 = Math.Clamp((int32)Math.Floor((region.Min.Z - apron - grid.Origin.Z) / grid.TileWorldSize), 0, grid.CountY - 1);
		let ty1 = Math.Clamp((int32)Math.Floor((region.Max.Z + apron - grid.Origin.Z) / grid.TileWorldSize), 0, grid.CountY - 1);

		let blob = scope List<uint8>();
		blob.AddRange(asset.NavMeshBlob);
		for (int32 ty = ty0; ty <= ty1; ty++)
		{
			for (int32 tx = tx0; tx <= tx1; tx++)
			{
				let tileData = scope List<uint8>();
				if (NavigationMeshBuilder.BuildTileInGrid(verts, indices, parameters, grid, tx, ty, tileData) case .Err(let error))
				{
					if (error != .NotFound)
						return result; // a hard bake failure leaves the asset untouched
				}
				// NotFound means the tile is now empty: the patch removes its record.
				if (!NavigationBlob.Patch(blob, tx, ty, tileData))
					return result;
				result.TilesRebuilt++;
			}
		}

		asset.NavMeshBlob.Clear();
		asset.NavMeshBlob.AddRange(blob);
		if (NavigationZoneStorage.Write(targetAsset, asset) case .Err)
			return result;
		result.Rebaked = true;
		return result;
	}
}
