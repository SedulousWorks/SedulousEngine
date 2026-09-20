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

namespace Sedulous.Editor.Navigation.Tests;

/// The editor navigation bake: a scene with a ground mesh and a zone, the in-zone geometry in
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

		// The scene: a ground mesh at the origin and a zone entity that covers it.
		let scene = scope Scene("bake");
		NavigationScene.AddNavigationSceneManagers(scene);
		let meshes = scene.AddSystem<MeshComponentManager>();
		let ground = BakeFixtures.GroundMesh();
		defer delete ground;
		let groundEntity = scene.CreateEntity("ground");
		let mc = meshes.Add(groundEntity);
		mc.Mesh.SetDirect(ground);

		let zoneEntity = scene.CreateEntity("zone");
		let z = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
		z.Extents = .(15, 10, 15);
		scene.UpdateTransforms();

		// The bake collects the two ground triangles and writes the navmesh into the sidecar.
		let result = NavigationBake.BakeNavigationZone(scene, zoneEntity, assetInstance);
		Test.Assert(result.TriangleCount == 2);
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

	/// Authoring a zone directly on a ground entity scaled up, a unit plane at 20x20: the bake
	/// frame must be rigid, since an inverse carrying the scale would hand Recast a unit plane
	/// that the agent-radius erosion wipes.
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
		let meshes = scene.AddSystem<MeshComponentManager>();

		// One entity carries both the unit ground mesh and the zone, scaled 20x in X and Z.
		let ground = BakeFixtures.UnitGroundMesh();
		defer delete ground;
		let entity = scene.CreateEntity("ground_zone");
		let mc = meshes.Add(entity);
		mc.Mesh.SetDirect(ground);
		let z = scene.GetSystem<NavMeshZoneComponentManager>().Add(entity);
		z.Extents = .(15, 10, 15);

		var t = scene.GetLocalTransform(entity);
		t.Scale = .(20, 1, 20);
		scene.SetLocalTransform(entity, t);
		scene.UpdateTransforms();

		let result = NavigationBake.BakeNavigationZone(scene, entity, assetInstance);
		Test.Assert(result.TriangleCount == 2, "the unit plane's world bounds intersect the zone");
		Test.Assert(result.Baked, "without the rigid frame the unit-size plane erodes away");
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
