using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.DefaultApp.Integration.Tests;

/// Where a scene's spawns read their prefabs: the database the app's scenes load from.
///
/// A game run from its project folder has two: its content database is the cooked one (the
/// resources), and its scene database the sources (the scenes and the prefabs, which are never
/// cooked). Spawns once read the content database, so in that mode a script's Spawn and a
/// replicated spawn found no prefab while the prefabs placed in a scene, which load from the
/// scene database, came through.
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
	public static void ASceneSpawnsFromItsScenesDatabaseNotTheCookedOne()
	{
		let cooked = scope SpawnContentFixture("scratch_spawn_db_cooked");
		let sources = scope SpawnContentFixture("scratch_spawn_db_sources");
		let prefabId = StorePrefab(sources);

		let app = scope DefaultApplication();
		app.SetContentDatabase(cooked.Database);
		app.SetSceneDatabase(sources.Database);

		let level = scope Scene("level");
		let spawner = level.AddSystem<PrefabSpawnSystem>();
		app.OnSystemsReady(level);
		let root = spawner.Spawn(prefabId, .(1.0f, 2.0f, 3.0f));
		Test.Assert(root.IsAssigned, "the prefab spawned from the scene database");
		Test.Assert(level.GetChildCount(root) == 1, "with its child");
		Test.Assert(level.GetLocalTransform(root).Position.Y == 2.0f, "where it was asked for");
	}

	[Test]
	public static void WithOneDatabaseASceneSpawnsFromIt()
	{
		// The editor and an exported game name one database, the content one, which holds the
		// prefabs: the scene database falls back to it.
		let content = scope SpawnContentFixture("scratch_spawn_db_one");
		let prefabId = StorePrefab(content);

		let app = scope DefaultApplication();
		app.SetContentDatabase(content.Database);

		let level = scope Scene("level");
		let spawner = level.AddSystem<PrefabSpawnSystem>();
		app.OnSystemsReady(level);
		Test.Assert(spawner.Spawn(prefabId, .(0.0f, 0.0f, 0.0f)).IsAssigned, "spawned from the one database");
	}
}
