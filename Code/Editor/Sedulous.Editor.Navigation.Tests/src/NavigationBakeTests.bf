using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using Sedulous.Engine.Navigation;
using Sedulous.Navigation;
using Sedulous.Navigation.Resource;
using Sedulous.Navigation.Pipeline;
using Sedulous.Physics;
using Sedulous.Engine.Physics;

namespace Sedulous.Editor.Navigation.Tests;

/// The editor navigation bake: a scene with a static ground body and a zone, the in-zone geometry in
/// zone-local space, the Recast bake, the NavigationZoneAsset sidecar. The written blob loads
/// back into a navmesh and paths, proving the author-side chain end to end, headless.
static class NavigationBakeTests
{
	[Test]
	public static void BakeCollectsSceneGeometryAndWritesALoadableZoneAsset()
	{
		NavigationResources.RegisterAll();
		NavigationPipeline.RegisterAll();
		let dir = BakeFixtures.ScratchDir("scratch_navbake_db", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let mount = scope NativeFileSystem(dir);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let db = scope ContentDatabase(mount, serializers, "rasset");
		let assetInstance = db.RootGroup.CreateInstance("zone", BakeFixtures.cZoneAssetType);
		Test.Assert(assetInstance != null);

		// The scene: a static ground slab at the origin, its top at y nought, and a zone entity
		// that covers it.
		let scene = scope Scene("bake");
		NavigationScene.AddNavigationSceneManagers(scene);
		scene.AddSystem<RigidBodyComponentManager>();
		BakeFixtures.AddBody(scene, "ground", .(0, -0.5f, 0), .(10, 0.5f, 10), .Static);

		let zoneEntity = scene.CreateEntity("zone");
		let z = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
		z.Extents = .(15, 10, 15);
		scene.UpdateTransforms();

		// The bake collects the slab's triangles (a box: twelve) and writes the navmesh into the
		// sidecar.
		let result = NavigationBake.BakeNavigationZone(scene, zoneEntity, assetInstance);
		Test.Assert(result.TriangleCount == 12, scope $"{result.TriangleCount}");
		Test.Assert(result.Baked);

		// The written asset carries a navmesh that loads and paths.
		let readBack = scope List<uint8>();
		{
			let object = assetInstance.ReadObject();
			defer delete object;
			let asset = object as NavigationZoneAsset;
			Test.Assert(asset != null);
			Test.Assert(NavigationZoneStorage.EnsureNavMeshLoaded(assetInstance, asset) case .Ok);
			Test.Assert(!asset.NavMeshBlob.IsEmpty);
			readBack.AddRange(asset.NavMeshBlob);
		}
		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(readBack) case .Ok);
		Test.Assert(mesh.IsValid);
		let query = scope NavigationMeshQuery(mesh);
		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(-8, 0, 0), .(8, 0, 0), path) case .Ok);
		Test.Assert(path.Complete);
	}

	/// Authoring a zone directly on a ground entity scaled up 20x: the bake frame must be
	/// rigid. A primitive body keeps its world size, as physics builds it, and an inverse
	/// carrying the scale would shrink it 20x, which the agent-radius erosion wipes.
	[Test]
	public static void BakeSucceedsWhenTheZoneSharesAScaledEntityWithItsGround()
	{
		NavigationPipeline.RegisterAll();
		let dir = BakeFixtures.ScratchDir("scratch_navbake_scaled_db", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let mount = scope NativeFileSystem(dir);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let db = scope ContentDatabase(mount, serializers, "rasset");
		let assetInstance = db.RootGroup.CreateInstance("zone", BakeFixtures.cZoneAssetType);
		Test.Assert(assetInstance != null);

		let scene = scope Scene("bake_scaled");
		NavigationScene.AddNavigationSceneManagers(scene);
		scene.AddSystem<RigidBodyComponentManager>();

		// One entity carries both the ground slab and the zone, scaled 20x in X and Z.
		let entity = BakeFixtures.AddBody(scene, "ground_zone", .(0, 0, 0), .(10, 0.5f, 10), .Static);
		let z = scene.GetSystem<NavMeshZoneComponentManager>().Add(entity);
		z.Extents = .(15, 10, 15);

		var t = scene.GetLocalTransform(entity);
		t.Scale = .(20, 1, 20);
		scene.SetLocalTransform(entity, t);
		scene.UpdateTransforms();

		let result = NavigationBake.BakeNavigationZone(scene, entity, assetInstance);
		Test.Assert(result.TriangleCount == 12, "the slab's box");
		Test.Assert(result.Baked, "without the rigid frame the geometry shrinks 20x and erodes away");
	}

	/// A level's ground is often far wider than a zone (a static plane 2000 units across). Its triangles reach
	/// past the zone, and the bake sized the navmesh grid from them: a grid of over a hundred
	/// tiles a side, whose navmesh did not load at runtime. The zone's box bounds the bake.
	[Test]
	public static void AGroundWiderThanTheZoneBakesToTheZonesBox()
	{
		NavigationPipeline.RegisterAll();
		let dir = BakeFixtures.ScratchDir("scratch_navbake_plane_db", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let mount = scope NativeFileSystem(dir);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let db = scope ContentDatabase(mount, serializers, "rasset");
		let assetInstance = db.RootGroup.CreateInstance("zone", BakeFixtures.cZoneAssetType);
		Test.Assert(assetInstance != null);

		let scene = scope Scene("bake_plane");
		NavigationScene.AddNavigationSceneManagers(scene);
		scene.AddSystem<RigidBodyComponentManager>();
		let groundEntity = scene.CreateEntity("ground");
		let plane = scene.GetSystem<RigidBodyComponentManager>().Add(groundEntity);
		plane.Motion = .Static;
		plane.Shape = .Plane;
		plane.PlaneHalfExtent = 1000.0f;
		let zoneEntity = scene.CreateEntity("zone");
		scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity).Extents = .(20, 6, 20);
		scene.UpdateTransforms();

		let result = NavigationBake.BakeNavigationZone(scene, zoneEntity, assetInstance);
		Test.Assert(result.Baked);
		let blob = scope List<uint8>();
		{
			let object = assetInstance.ReadObject();
			defer delete object;
			let asset = object as NavigationZoneAsset;
			Test.Assert(NavigationZoneStorage.EnsureNavMeshLoaded(assetInstance, asset) case .Ok);
			blob.AddRange(asset.NavMeshBlob);
		}
		Test.Assert(NavigationBlob.ReadGrid(blob, let grid));
		// The zone's 40 units, not the ground's 2000.
		Test.Assert((grid.CountX == 3) && (grid.CountY == 3), scope $"{grid.CountX} x {grid.CountY}");
		Test.Assert(BakeFixtures.PathAcross(blob, .(-15, 0, -15), .(15, 0, 15)));
	}

	/// Collects the zone's static geometry and bakes it with the zone's parameters; empty when
	/// there was nothing to bake or no walkable surface.
	private static void BakeCollected(Scene scene, EntityHandle zoneEntity, out int outTriangles, List<uint8> outBlob)
	{
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Get(zoneEntity);
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		outTriangles = NavigationBake.CollectNavigationGeometry(scene, zoneEntity, zone.Extents, zone.CellSize, verts, indices);
		outBlob.Clear();
		if (outTriangles == 0)
			return;
		var parameters = NavigationBakeParams();
		parameters.CellSize = zone.CellSize;
		parameters.CellHeight = zone.CellHeight;
		parameters.AgentRadius = zone.AgentRadius;
		parameters.AgentHeight = zone.AgentHeight;
		parameters.AgentMaxClimb = zone.AgentMaxClimb;
		parameters.AgentMaxSlopeDegrees = zone.AgentMaxSlopeDegrees;
		NavigationMeshBuilder.BuildTiled(verts, indices, parameters, outBlob);
	}

	/// The regression the source rule exists for: the bake read every render mesh, so a car or a
	/// walker standing in a zone baked a hole in the road under itself. Only static, solid
	/// bodies are level geometry: dynamic and kinematic bodies, triggers and a bare render mesh
	/// across the floor leave the path open; a static wall in the same place cuts it.
	[Test]
	public static void OnlyStaticSolidBodiesAreBakedWhatMovesAndBareMeshesAreNot()
	{
		void Bake(bool staticWall, out int triangles, List<uint8> blob)
		{
			let scene = scope Scene("bake_movers");
			NavigationScene.AddNavigationSceneManagers(scene);
			scene.AddSystem<RigidBodyComponentManager>();
			let meshes = scene.AddSystem<MeshComponentManager>();
			BakeFixtures.AddBody(scene, "ground", .(0, -0.5f, 0), .(10, 0.5f, 10), .Static);
			// Across the middle, at x nought: a car, a lift, a trigger, and a wall that is only a mesh.
			BakeFixtures.AddBody(scene, "car", .(0, 1, -5), .(1, 1, 2), .Dynamic);
			BakeFixtures.AddBody(scene, "lift", .(0, 1, 0), .(1, 1, 2), .Kinematic);
			BakeFixtures.AddBody(scene, "porch", .(0, 1, 5), .(1, 1, 2), .Static, true);
			let wall = BakeFixtures.WallMesh();
			defer delete wall;
			meshes.Add(scene.CreateEntity("mesh wall")).Mesh.SetDirect(wall);
			if (staticWall)
				BakeFixtures.AddBody(scene, "wall", .(0, 1.5f, 0), .(0.5f, 1.5f, 15), .Static);
			let zoneEntity = scene.CreateEntity("zone");
			scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity).Extents = .(15, 10, 15);
			scene.UpdateTransforms();
			BakeCollected(scene, zoneEntity, out triangles, blob);
		}

		let open = scope List<uint8>();
		Bake(false, var triangles, open);
		Test.Assert(triangles == 12, scope $"{triangles}"); // the ground's box, nothing else
		Test.Assert(!open.IsEmpty);
		Test.Assert(BakeFixtures.PathAcross(open, .(-8, 0, 0), .(8, 0, 0)));
		Test.Assert(BakeFixtures.PathAcross(open, .(-8, 0, -5), .(8, 0, -5)));

		let walled = scope List<uint8>();
		Bake(true, out triangles, walled);
		Test.Assert(triangles == 24, scope $"{triangles}"); // the ground and the wall
		Test.Assert(!walled.IsEmpty);
		Test.Assert(!BakeFixtures.PathAcross(walled, .(-8, 0, 0), .(8, 0, 0)));
	}

	[Test]
	public static void TerrainContributesWalkableSurfaceToTheBake()
	{
		let blob = scope List<uint8>();
		BakeFixtures.BakeTerrainZone(BakeFixtures.MakeTerrain(0.0f, 10.0f, 32.0f, scope (gx, gz) => 2.0f), .(14, 8, 14), let triangles, blob);
		Test.Assert(triangles > 0);
		Test.Assert(!blob.IsEmpty);
		Test.Assert(BakeFixtures.PathAcross(blob, .(-10, 2, 0), .(10, 2, 0)));
	}

	[Test]
	public static void AnAgentPathsAcrossSlopedTerrain()
	{
		// A gentle ramp: ~4 units of rise over the 32-unit footprint, ~7 degrees.
		let blob = scope List<uint8>();
		BakeFixtures.BakeTerrainZone(BakeFixtures.MakeTerrain(0.0f, 10.0f, 32.0f, scope (gx, gz) => (float)gx * (4.0f / 64.0f)), .(14, 8, 14), let triangles, blob);
		Test.Assert(!blob.IsEmpty);
		Test.Assert(BakeFixtures.PathAcross(blob, .(-10, 1, 0), .(10, 3, 0)));
	}

	[Test]
	public static void ATooSteepTerrainWallSplitsTheNavmesh()
	{
		// A cliff across the middle: ~24 units of rise over one cell, far past the walkable
		// slope filter, so the two plateaus must not connect.
		let blob = scope List<uint8>();
		BakeFixtures.BakeTerrainZone(BakeFixtures.MakeTerrain(0.0f, 30.0f, 32.0f, scope (gx, gz) => (gx < 32) ? 1.0f : 25.0f), .(14, 28, 14), let triangles, blob);
		Test.Assert(!blob.IsEmpty);
		Test.Assert(!BakeFixtures.PathAcross(blob, .(-10, 1, 0), .(10, 25, 0)));
		// Each plateau itself remains walkable.
		Test.Assert(BakeFixtures.PathAcross(blob, .(-10, 1, 0), .(-3, 1, 6)));
	}
}
