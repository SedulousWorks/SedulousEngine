using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.DefaultApp.Integration.Tests;

/// Where a scene's spawns load their prefabs: the app's resources, whatever databases it holds.
///
/// A game run from its project folder has two: its cooked products and its sources (the scenes
/// and the prefabs, which are never cooked). Spawns once read a database of their own, which in
/// that mode was the cooked one, so game code's Spawn and a replicated spawn found no prefab. Its
/// resources now read the cooked database over the sources, a prefab falling through, and every
/// spawn loads through them.
static class SpawnDatabaseTests
{
	/// Builds a two entity prefab in `fixture` and answers its guid.
	private static Guid StorePrefab(SpawnContentFixture fixture)
	{
		let template = scope Scene("crate");
		let root = template.CreateEntity("Crate");
		let lid = template.CreateEntity("Lid");
		template.SetParent(lid, root);
		let instance = fixture.Database.RootGroup.CreateInstance("crate",
			SpawnContentFixture.PrefabTypeName);
		Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok, "the prefab stored");
		return instance.Id;
	}

	[Test]
	public static void ASceneSpawnsThroughTheAppsResourcesFromTheSourcesBeneathTheCooked()
	{
		let cooked = scope SpawnContentFixture("scratch_spawn_db_cooked");
		let sources = scope SpawnContentFixture("scratch_spawn_db_sources");
		let prefabId = StorePrefab(sources);

		// The project folder's resources: the cooked database over the sources.
		let view = scope LayeredContentDatabase(cooked.Database, sources.Database);
		let resources = scope ResourceManager(view);
		resources.AddFactory(sources.Prefabs);
		view.SetFallthrough(new [=resources] (storedTypeName) => resources.ReadsAuthoredRecord(storedTypeName));
		defer view.SetFallthrough(null);

		let app = scope DefaultApplication();
		app.SetContentDatabase(cooked.Database);
		app.SetSceneDatabase(sources.Database);
		app.SetResourceManager(resources);

		let level = scope Scene("level");
		let spawner = level.AddSystem<PrefabSpawnSystem>();
		app.OnSystemsReady(level);
		Test.Assert(spawner.HasSource);
		let root = spawner.Spawn(prefabId, .(1.0f, 2.0f, 3.0f));
		Test.Assert(root.IsAssigned, "the prefab spawned through the resources");
		Test.Assert(level.GetChildCount(root) == 1, "with its child");
		Test.Assert(level.GetLocalTransform(root).Position.Y == 2.0f, "where it was asked for");
		Test.Assert(resources.FindHandle(prefabId).State == .Ready, "loaded by the manager");
	}

	[Test]
	public static void ADatabaseAloneIsNoSource()
	{
		// The prefabs are there, but nothing loads them: no entity rather than a read from disk.
		let content = scope SpawnContentFixture("scratch_spawn_db_one");
		let prefabId = StorePrefab(content);

		let app = scope DefaultApplication();
		app.SetContentDatabase(content.Database);

		let level = scope Scene("level");
		let spawner = level.AddSystem<PrefabSpawnSystem>();
		app.OnSystemsReady(level);
		Test.Assert(!spawner.HasSource);
		Test.Assert(!spawner.Spawn(prefabId, .(0.0f, 0.0f, 0.0f)).IsAssigned, "nothing spawned");
		Test.Assert(level.EntityCount == 0);
	}
}
