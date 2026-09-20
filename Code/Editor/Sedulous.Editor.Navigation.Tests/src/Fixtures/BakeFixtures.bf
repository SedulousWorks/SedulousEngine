using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Heightfield;
using Sedulous.Terrain.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.Navigation;
using Sedulous.Navigation;

namespace Sedulous.Editor.Navigation.Tests;

/// The ground meshes, in-memory terrains and bake helpers the cases share.
static class BakeFixtures
{
	public const String cZoneAssetType = "Sedulous.Navigation.Pipeline.NavigationZoneAsset";

	private static StaticMesh Quad(float half)
	{
		let mesh = new StaticMesh();
		for (let p in scope Float3[](.(-half, 0, -half), .(half, 0, -half), .(half, 0, half), .(-half, 0, half)))
		{
			var v = StaticMeshVertex();
			v.Position = p;
			v.Normal = .(0, 1, 0);
			mesh.Vertices.Add(v);
		}
		let tris = scope uint32[](0, 3, 2, 0, 2, 1); // +Y winding
		mesh.Indices.Resize((uint32)tris.Count); // Add writes into a sized buffer
		for (let i in tris)
			mesh.Indices.Add(i);
		mesh.CalculateBounds();
		return mesh;
	}

	/// A 20x20 ground quad at the origin.
	public static StaticMesh GroundMesh() => Quad(10.0f);
	/// A unit ground quad, meant to be scaled up by its entity: the case where the zone shares
	/// that scaled entity and the bake frame must strip the scale.
	public static StaticMesh UnitGroundMesh() => Quad(0.5f);

	/// An in-memory terrain over a 65x65 heightfield, the smallest legal grid: heights come
	/// from the delegate in world Y, quantised onto [minY, maxY].
	public static TerrainResource MakeTerrain(float minY, float maxY, float worldSide, delegate float(int32 gx, int32 gz) heightAt)
	{
		const int32 cSide = 65;
		let field = new Heightfield(cSide, .(worldSide, worldSide), minY, maxY);
		for (int32 gz < cSide)
		{
			for (int32 gx < cSide)
				field.SetSample(gx, gz, field.WorldYToSample(heightAt(gx, gz)));
		}
		let terrain = new TerrainResource();
		terrain.Heightfield.SetDirect(field);
		return terrain;
	}

	/// A scene, a zone and one terrain entity; answers the baked navmesh blob, empty on failure.
	/// Takes ownership of the terrain.
	public static void BakeTerrainZone(TerrainResource terrain, Float3 zoneExtents, out int outTriangles, List<uint8> outBlob)
	{
		outBlob.Clear();
		let field = terrain.Heightfield.Get;
		defer { delete terrain; delete field; }
		let scene = scope Scene("bake_terrain");
		NavigationScene.AddNavigationSceneManagers(scene);
		let terrains = scene.AddSystem<TerrainComponentManager>();

		let terrainEntity = scene.CreateEntity("terrain");
		let tc = terrains.Add(terrainEntity);
		tc.Terrain.SetDirect(terrain);

		let zoneEntity = scene.CreateEntity("zone");
		let z = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
		z.Extents = zoneExtents;
		scene.UpdateTransforms();

		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		outTriangles = NavigationBake.CollectNavigationGeometry(scene, zoneEntity, z.Extents, z.CellSize, verts, indices);
		if (outTriangles > 0)
		{
			var parameters = NavigationBakeParams();
			parameters.CellSize = z.CellSize;
			parameters.CellHeight = z.CellHeight;
			parameters.AgentRadius = z.AgentRadius;
			parameters.AgentHeight = z.AgentHeight;
			parameters.AgentMaxClimb = z.AgentMaxClimb;
			parameters.AgentMaxSlopeDegrees = z.AgentMaxSlopeDegrees;
			NavigationMeshBuilder.Build(verts, indices, parameters, outBlob).IgnoreError();
		}
	}

	public static bool PathAcross(Span<uint8> blob, Float3 from, Float3 to)
	{
		let mesh = scope NavigationMesh();
		if ((mesh.Load(blob) case .Err) || !mesh.IsValid)
			return false;
		let query = scope NavigationMeshQuery(mesh);
		let path = scope NavigationPath();
		return (query.FindPath(from, to, path) case .Ok) && path.Complete;
	}

	/// A scratch directory under the working directory, emptied.
	public static void ScratchDir(StringView name, String outDir)
	{
		GetCurrentDirectory(outDir);
		PathJoin(outDir, name, outDir);
		RemoveDirectoryRecursive(outDir);
		CreateDirectory(outDir);
	}
}
