using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Terrain;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;

namespace Sedulous.Engine.Terrain.Tests;

/// The terrain component's authored state and the GPU height cache behind it.
class TerrainComponentTests
{
	private static Guid cTerrainId = .(42, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0);

	private static TerrainComponent* Sole(Scene scene)
	{
		TerrainComponent* found = null;
		scene.GetSystem<TerrainComponentManager>().ForEach(scope [&] (component, owner) =>
			{
				found = component;
			});
		return found;
	}

	[Test]
	public static void AComponentSurvivesASceneRoundTrip()
	{
		let blob = scope MemoryStream();
		Guid id = default;

		let authored = scope Scene();
		{
			let manager = authored.AddSystem<TerrainComponentManager>();
			let entity = authored.CreateEntity("terrain");
			let component = manager.Add(entity);
			component.Terrain.SetId(cTerrainId);
			component.CastShadows = false;
			component.Visible = false;
			id = authored.GetEntityId(entity);

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, authored);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene();
		let manager = loaded.AddSystem<TerrainComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		let entity = loaded.FindEntity(id);
		Test.Assert(entity.IsAssigned);

		let component = manager.Get(entity);
		Test.Assert(component != null);
		Test.Assert(component.Terrain.Id == cTerrainId);
		Test.Assert(!component.CastShadows);
		Test.Assert(!component.Visible);
		Test.Assert(Sole(loaded) != null);
	}

	[Test]
	public static void TheHeightCacheKeysByHeightfieldAndVersion()
	{
		let fixture = scope NullDeviceFixture();

		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		let other = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);

		let cache = scope TerrainHeightTextureCache();

		// The first request creates and caches.
		let first = cache.GetOrCreate(fixture.Device, grid, 1);
		Test.Assert(first != null);
		Test.Assert(cache.Size == 1);

		// The same grid at the same version hits, with no second entry.
		Test.Assert(cache.GetOrCreate(fixture.Device, grid, 1) === first);
		Test.Assert(cache.Size == 1);

		// A bumped version, which is what a sculpt produces, rebuilds IN PLACE.
		let rebuilt = cache.GetOrCreate(fixture.Device, grid, 2);
		Test.Assert(rebuilt != null);
		Test.Assert(cache.Size == 1);

		// A DIFFERENT grid takes a second texture, so two terrains sharing one grid share one
		// texture and two grids never do.
		Test.Assert(cache.GetOrCreate(fixture.Device, other, 1) != null);
		Test.Assert(cache.Size == 2);

		// An empty grid yields nothing at all.
		let empty = scope Heightfield();
		Test.Assert(cache.GetOrCreate(fixture.Device, empty, 1) == null);

		cache.Clear(fixture.Device);
		Test.Assert(cache.Size == 0);
	}

	[Test]
	public static void TheCacheKeysByUidRatherThanAddress()
	{
		// The failure an address keyed cache cannot survive: grid A dies, a FRESH grid B lands
		// on the same address at an equal version, and the cache serves A's dead texture for
		// B. Keying on the UID always passes; keying on the address passes only by luck.
		let fixture = scope NullDeviceFixture();
		let cache = scope TerrainHeightTextureCache();

		uint64 uidA = 0;
		{
			let a = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
			uidA = a.Uid;
			Test.Assert(cache.GetOrCreate(fixture.Device, a, a.Version) != null);
			Test.Assert(cache.Size == 1);
		}

		let b = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		Test.Assert(b.Uid != uidA);

		Test.Assert(cache.GetOrCreate(fixture.Device, b, b.Version) != null);
		Test.Assert(cache.Size == 2);

		cache.Clear(fixture.Device);
	}

	[Test]
	public static void AVersionBumpRetiresTheOldTexture()
	{
		// The old view sits in a submitted frame's bindings, so the rebuild has to route it
		// through the frame aged queue rather than destroying it where it stands.
		let fixture = scope NullDeviceFixture();

		let retire = scope GpuRetireQueue();
		retire.Initialize(fixture.Device, 2);

		let cache = scope TerrainHeightTextureCache();
		cache.SetRetireQueue(retire);

		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		Test.Assert(cache.GetOrCreate(fixture.Device, grid, grid.Version) != null);
		Test.Assert(retire.PendingCount == 0);

		grid.BumpVersion();
		Test.Assert(cache.GetOrCreate(fixture.Device, grid, grid.Version) != null);
		// The old view AND its texture aged, rather than being destroyed in place.
		Test.Assert(retire.PendingCount == 2);
		Test.Assert(cache.Size == 1);

		// They free only once every frame that could still hold them has cycled.
		retire.Tick();
		retire.Tick();
		Test.Assert(retire.PendingCount == 2);
		retire.Tick();
		Test.Assert(retire.PendingCount == 0);

		// Clear with the queue wired RETIRES the live pair too, a scene destroy mid frame
		// being the same in flight hazard as the rebuild; the drain frees everything.
		cache.Clear(fixture.Device);
		Test.Assert(retire.PendingCount == 2);
		retire.Flush();
	}

	/// Stopping play in the editor destroys the run's scenes from a toolbar click, mid frame
	/// loop: the terrain's height texture is still bound by a submitted frame's descriptor
	/// set, and ClearGpu destroyed it in place, which validation reported on every stop. Clear
	/// now routes through the frame aged queue like the version bump rebuild; without a queue
	/// it stays direct.
	[Test]
	public static void ClearRetiresLiveEntriesWhenAQueueIsWired()
	{
		let fixture = scope NullDeviceFixture();
		let retire = scope GpuRetireQueue();
		retire.Initialize(fixture.Device, 2);
		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		{
			let cache = scope TerrainHeightTextureCache();
			cache.SetRetireQueue(retire);
			Test.Assert(cache.GetOrCreate(fixture.Device, grid, grid.Version) != null);
			Test.Assert(retire.PendingCount == 0);
			cache.Clear(fixture.Device);
			Test.Assert(cache.Size == 0);
			Test.Assert(retire.PendingCount == 2, "the view and the texture aged, NOT destroyed in place");
			retire.Tick();
			retire.Tick();
			Test.Assert(retire.PendingCount == 2);
			retire.Tick();
			Test.Assert(retire.PendingCount == 0, "freed once every in flight frame cycled");
		}
		{
			let cache = scope TerrainHeightTextureCache(); // no queue: direct destroy
			Test.Assert(cache.GetOrCreate(fixture.Device, grid, grid.Version) != null);
			cache.Clear(fixture.Device);
			Test.Assert(cache.Size == 0);
			Test.Assert(retire.PendingCount == 0);
		}
	}

	[Test]
	public static void ClearGpuFreesWhileTheDeviceIsStillAlive()
	{
		// The manager's cache would otherwise hold a live texture across the device's own
		// destruction. The subsystem calls this on scene destroy and at shutdown; this pins
		// the manager side of that contract headless.
		let fixture = scope NullDeviceFixture();

		let scene = scope Scene();
		TerrainScene.AddTerrainSceneManagers(scene);

		let manager = scene.GetSystem<TerrainComponentManager>();
		Test.Assert(manager != null);
		manager.SetRenderContext(fixture.Device, 7);

		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		let resource = scope TerrainResource();
		resource.Heightfield.SetDirect(grid);

		let entity = scene.CreateEntity("terrain");
		manager.Add(entity).Terrain.SetDirect(resource);
		scene.Start();

		let snapshot = scope ExtractedScene();
		manager.ExtractRenderData(snapshot);
		// The extract built and cached the texture.
		Test.Assert(manager.HeightTextureCount == 1);

		manager.ClearGpu();
		Test.Assert(manager.HeightTextureCount == 0);

		// Idempotent, and a later extract finds no device and does nothing.
		manager.ClearGpu();
		manager.ExtractRenderData(snapshot);
		Test.Assert(manager.HeightTextureCount == 0);
	}

	[Test]
	public static void TheSnapshotOutlivesTheSceneItCameFrom()
	{
		// The snapshot has to be SELF CONTAINED: readable at record time even once the scene,
		// its manager and every cache the extract read from are gone. A borrowed quadtree
		// pointer is a use after free the moment a mid frame mutation rebuilds the cache.
		let snapshot = scope ExtractedScene();
		{
			let fixture = scope NullDeviceFixture();

			let scene = scope Scene();
			TerrainScene.AddTerrainSceneManagers(scene);

			let manager = scene.GetSystem<TerrainComponentManager>();
			Test.Assert(manager != null);
			manager.SetRenderContext(fixture.Device, 7);

			let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
			let resource = scope TerrainResource();
			resource.Heightfield.SetDirect(grid);

			let entity = scene.CreateEntity("terrain");
			manager.Add(entity).Terrain.SetDirect(resource);
			scene.Start();

			manager.ExtractRenderData(snapshot);
			manager.ClearGpu();
		}

		Test.Assert(snapshot.Size == 1);

		let data = snapshot.Items[0] as TerrainRenderData;
		Test.Assert(data != null);
		Test.Assert(data.Chunks != null);
		Test.Assert(data.Nodes != null);
		Test.Assert(data.NodeCount > 0);

		// The cull and the level selection run straight off the snapshot, with no living
		// producer anywhere: the whole grid is visible from above.
		let view = Float4x4.LookAtRH(.(32.0f, 100.0f, 32.0f), .(32.0f, 0.0f, 32.1f),
			.(0.0f, 0.0f, 1.0f));
		let projection = Float4x4.PerspectiveFovRH(1.2f, 1.0f, 0.1f, 1000.0f);
		let frustum = BoundingFrustum(data.ChunkToWorld * (view * projection));

		let draws = scope System.Collections.List<ChunkDraw>();
		TerrainChunks.ExtractVisibleChunkDraws(.(data.Nodes, (int)data.NodeCount),
			.(data.Chunks, (int)data.ChunkCount), data.ChunkToWorld, view, projection, frustum,
			.(&data.Thresholds[0], (int)data.ThresholdCount), 0.0f, draws);
		Test.Assert(!draws.IsEmpty);
	}
}
