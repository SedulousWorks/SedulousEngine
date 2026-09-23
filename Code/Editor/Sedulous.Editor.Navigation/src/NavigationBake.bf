using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Heightfield;
using Sedulous.Terrain.Resource;
using Sedulous.Engine.Render;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.Navigation;
using Sedulous.Navigation;
using Sedulous.Navigation.Pipeline;

namespace Sedulous.Editor.Navigation;

/// The "Bake Navigation" flow: every static mesh whose world bounds intersect a zone's box
/// contributes its triangles, transformed into zone-local space so the baked navmesh rides the
/// zone entity's transform to any placement without a rebake; the Recast bake runs; the result
/// lands in the zone's NavigationZoneAsset sidecar. Editor-only; the player never links this.
static class NavigationBake
{
	/// The world-space bounds of local bounds under a transform, all eight corners.
	private static AABB WorldBounds(AABB local, Float4x4 world)
	{
		var result = AABB.Empty();
		for (int i < 8)
		{
			let corner = Float3(((i & 1) != 0) ? local.Max.X : local.Min.X,
				((i & 2) != 0) ? local.Max.Y : local.Min.Y,
				((i & 4) != 0) ? local.Max.Z : local.Min.Z);
			result.Expand(TransformPoint(corner, world));
		}
		return result;
	}

	/// Collects the triangle soup, in the zone entity's local space, for a bake: every mesh
	/// component whose world bounds intersect the zone box contributes its triangles, and every
	/// terrain's heightfield surface inside the box triangulates in, sampled no finer than the
	/// cell size since Recast re-voxelises to its own cells. Answers the triangle count.
	public static int CollectNavigationGeometry(Scene scene, EntityHandle zoneEntity, Float3 zoneExtents, float cellSize,
		List<Float3> outVertices, List<uint32> outIndices)
	{
		outVertices.Clear();
		outIndices.Clear();
		// Rigid, no scale: the navmesh is baked in world units, so a zone entity's scale must not
		// warp the geometry Recast sees; a zone sharing a scaled entity with its ground would
		// otherwise un-scale that ground to unit size and erode the navmesh to nothing.
		let zoneWorld = RigidPart(scene.GetWorldMatrix(zoneEntity));
		let zoneInv = Inverse(zoneWorld);
		let zoneBox = AABB.FromCenterExtents(scene.GetWorldPosition(zoneEntity), zoneExtents);

		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			meshes.ForEach(scope [&](c, entity) =>
				{
					let mesh = c.Mesh.Get;
					if ((mesh == null) || (mesh.VertexCount == 0) || (mesh.IndexCount == 0))
						return;
					let meshWorld = scene.GetWorldMatrix(entity);
					if (!WorldBounds(mesh.Bounds, meshWorld).Intersects(zoneBox))
						return;
					let firstVertex = (uint32)outVertices.Count;
					for (let v in mesh.Vertices)
					{
						let world = TransformPoint(v.Position, meshWorld);
						outVertices.Add(TransformPoint(world, zoneInv)); // zone-local
					}
					for (uint32 i < mesh.IndexCount)
						outIndices.Add(firstVertex + mesh.Indices.Get(i));
				});
		}

		// Terrain: the shared heightfield surface, the same grid physics collides against,
		// triangulates inside the zone box so agents can walk on terrain.
		if (let terrains = scene.GetSystem<TerrainComponentManager>())
		{
			terrains.ForEach(scope [&](c, entity) =>
				{
					let terrain = c.Terrain.Get;
					let field = (terrain != null) ? terrain.Heightfield.Get : null;
					if ((field == null) || (field.Size < 2))
						return;
					let terrainWorld = scene.GetWorldMatrix(entity);
					let footprint = field.WorldSize;
					let localBox = AABB(.(-footprint.X * 0.5f, field.MinY, -footprint.Y * 0.5f),
						.(footprint.X * 0.5f, field.MaxY, footprint.Y * 0.5f));
					if (!WorldBounds(localBox, terrainWorld).Intersects(zoneBox))
						return;

					// The zone box in terrain-local space bounds the grid range to triangulate.
					let zoneLocal = WorldBounds(zoneBox, Inverse(terrainWorld));
					let last = field.Size - 1;
					let g0 = field.WorldToGrid(zoneLocal.Min.X, zoneLocal.Min.Z);
					let g1 = field.WorldToGrid(zoneLocal.Max.X, zoneLocal.Max.Z);
					let x0 = Math.Clamp((int32)Math.Floor(g0.X), 0, last);
					let z0 = Math.Clamp((int32)Math.Floor(g0.Y), 0, last);
					let x1 = Math.Clamp((int32)Math.Ceiling(g1.X), 0, last);
					let z1 = Math.Clamp((int32)Math.Ceiling(g1.Y), 0, last);
					if ((x1 <= x0) || (z1 <= z0))
						return;

					let spacing = footprint.X / (float)last;
					let stride = Math.Max(1, (int32)(cellSize / Math.Max(spacing, 0.0001f)));

					// The sample coordinates along each axis: stride steps, the last row and
					// column always included so the surface reaches the zone edge.
					let xs = scope List<int32>();
					let zs = scope List<int32>();
					for (int32 gx = x0; gx < x1; gx += stride)
						xs.Add(gx);
					xs.Add(x1);
					for (int32 gz = z0; gz < z1; gz += stride)
						zs.Add(gz);
					zs.Add(z1);

					let firstVertex = (uint32)outVertices.Count;
					for (let gz in zs)
					{
						for (let gx in xs)
						{
							let xz = field.GridToWorld((float)gx, (float)gz);
							let local = Float3(xz.X, field.GetHeightAtGrid(gx, gz), xz.Y);
							let world = TransformPoint(local, terrainWorld);
							outVertices.Add(TransformPoint(world, zoneInv));
						}
					}
					let columns = (uint32)xs.Count;
					for (uint32 row = 0; row + 1 < (uint32)zs.Count; row++)
					{
						for (uint32 col = 0; col + 1 < columns; col++)
						{
							// A hole anywhere in this BLOCK, which is the stride square with
							// its interior, is no walkable surface: the block's two triangles
							// are left out, so the navmesh opens there and agents route round.
							if (field.BlockHasHole(xs[(int)col], zs[(int)row],
								xs[(int)col + 1], zs[(int)row + 1]))
							{
								continue;
							}

							let v00 = firstVertex + row * columns + col;
							let v10 = v00 + 1;
							let v01 = v00 + columns;
							let v11 = v01 + 1;
							// +Y face normals; Recast's walkable filter keys on them.
							outIndices.Add(v00);
							outIndices.Add(v01);
							outIndices.Add(v11);
							outIndices.Add(v00);
							outIndices.Add(v11);
							outIndices.Add(v10);
						}
					}
				});
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
