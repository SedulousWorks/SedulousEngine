using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Integration.Tests;

/// The storage entry points, across the content boundary they exist to cross.
///
/// The unit tests drive the serializer over a memory stream, which proves the format. What
/// they cannot prove is the rest of the trip: an instance materialising with the right
/// primary, a document type resolving out of the registry by its stored name, and the
/// world coming back out of a sidecar stream written on a previous run.
class SceneStorageTests
{
	[Test]
	public static void ASavedSceneReloadsThroughTheDatabase()
	{
		let fixture = scope SceneContentFixture("scratch_scene_storage");

		var sceneId = Guid();
		var heroId = Guid();
		var foeId = Guid();
		{
			let scene = scope Scene("arena");
			let tags = scene.AddSystem<TagManager>();
			let hero = scene.CreateEntity("hero");
			let foe = scene.CreateEntity("foe");
			scene.SetParent(foe, hero);
			tags.Add(hero).Team = 1;
			tags.Add(foe).Team = 2;
			heroId = scene.GetEntityId(hero);
			foeId = scene.GetEntityId(foe);

			let instance = fixture.Database.RootGroup.CreateInstance("level",
				SceneContentFixture.SceneTypeName);
			sceneId = instance.Id;
			Test.Assert(SceneStorage.SaveScene(scene, instance) case .Ok);
		}

		// A new database over the same files: everything below came off disk.
		let reopened = fixture.Reopen();
		let instance = reopened.GetInstance(sceneId);
		Test.Assert(instance != null, "the envelope was written and scanned back");

		let document = instance.ReadObject();
		defer delete document;
		let scene = document as SceneDocument;
		Test.Assert(scene != null, "the primary resolved through the registry");
		Test.Assert(scene.Name == "arena", "the name a browser lists it by");

		// The managers are injected FIRST, as a subsystem would: load deserializes into
		// them rather than creating them.
		let loaded = scope Scene();
		let tags = loaded.AddSystem<TagManager>();
		Test.Assert(SceneStorage.LoadScene(instance, loaded) case .Ok);

		Test.Assert(loaded.Name == "arena");
		Test.Assert(loaded.EntityCount == 2);
		let hero = loaded.FindEntity(heroId);
		let foe = loaded.FindEntity(foeId);
		Test.Assert(hero.IsAssigned && foe.IsAssigned, "both entities kept their ids");
		Test.Assert(loaded.GetParent(foe) == hero, "and the hierarchy between them");
		Test.Assert(tags.Has(hero) && tags.Has(foe));
		Test.Assert(tags.Get(hero).Team == 1);
		Test.Assert(tags.Get(foe).Team == 2);
	}

	/// The prefab twin, and the reference that outlives the session: a scene stores an
	/// instance as a record, and resolving it re-reads the template's stream from the
	/// database.
	[Test]
	public static void ASavedPrefabRespawnsIntoAReloadedScene()
	{
		let fixture = scope SceneContentFixture("scratch_prefab_storage");

		var prefabId = Guid();
		var sceneId = Guid();
		{
			let template = scope Scene("turret");
			let tags = template.AddSystem<TagManager>();
			let root = template.CreateEntity("Turret");
			let barrel = template.CreateEntity("Barrel");
			template.SetParent(barrel, root);
			tags.Add(root).Team = 7;

			let instance = fixture.Database.RootGroup.CreateInstance("turret",
				SceneContentFixture.PrefabTypeName);
			prefabId = instance.Id;
			Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok);
		}
		{
			// A level that spawns one, saved with the instance as a REFERENCE.
			let level = scope Scene("level");
			level.AddSystem<TagManager>();
			let payload = fixture.Database.GetInstance(prefabId).ReadData("scene");
			Test.Assert(payload != null, "the prefab stream was written");
			defer delete payload;
			Test.Assert(PrefabSpawn.Spawn(level, payload, prefabId).IsAssigned, "it spawned");

			let instance = fixture.Database.RootGroup.CreateInstance("level",
				SceneContentFixture.SceneTypeName);
			sceneId = instance.Id;
			Test.Assert(SceneStorage.SaveScene(level, instance) case .Ok);
		}

		let reopened = fixture.Reopen();
		let loaded = scope Scene();
		loaded.AddSystem<TagManager>();
		let sceneInstance = reopened.GetInstance(sceneId);
		Test.Assert(sceneInstance != null, "the level scanned back");
		Test.Assert(SceneStorage.LoadScene(sceneInstance, loaded) case .Ok, "the level loaded");

		// Referenced: the members are NOT in the stream, so before resolving there is a
		// record and no subtree.
		Test.Assert(loaded.PendingPrefabInstanceCount == 1, "one record");
		Test.Assert(loaded.EntityCount == 0, "the members respawn, they are not stored");

		// The resolve pass takes ownership of each stream it is handed.
		ScenePrefabs.PayloadResolver resolver = scope [&](id) =>
		{
			let instance = reopened.GetInstance(id);
			return (instance != null) ? instance.ReadData("scene") : null;
		};
		ScenePrefabs.ResolveScenePrefabs(loaded, resolver);

		Test.Assert(loaded.PrefabInstanceCount == 1, "the record became a live instance");
		Test.Assert(loaded.EntityCount == 2, "root and barrel, back from the template");
		Test.Assert(loaded.FindEntityByName("Turret").IsAssigned);
		Test.Assert(loaded.FindEntityByName("Barrel").IsAssigned);
	}

	/// A prefab is a SINGLE ROOTED subtree, and the gate runs before any write: a refused
	/// save leaves nothing behind for the next scan to find.
	[Test]
	public static void SavePrefabRefusesAMultiRootSceneAndWritesNothing()
	{
		let fixture = scope SceneContentFixture("scratch_prefab_multiroot");

		let scene = scope Scene("prefab");
		scene.CreateEntity("A");
		scene.CreateEntity("B");

		let instance = fixture.Database.RootGroup.CreateInstance("broken",
			SceneContentFixture.PrefabTypeName);
		let id = instance.Id;
		Test.Assert(SceneStorage.SavePrefab(scene, instance) case .Err(.InvalidArgument));

		let envelope = instance.OpenEnvelope();
		Test.Assert(envelope == null, "refused before the primary was written");
		Test.Assert(fixture.Reopen().GetInstance(id) == null, "and nothing to scan back");
	}

	/// A prefab whose edit scene contains an instance of ITSELF would reference itself
	/// forever, so that save is refused too.
	[Test]
	public static void SavePrefabRefusesASceneHoldingAnInstanceOfItself()
	{
		let fixture = scope SceneContentFixture("scratch_prefab_selfref");

		let instance = fixture.Database.RootGroup.CreateInstance("lamp",
			SceneContentFixture.PrefabTypeName);

		let template = scope Scene("lamp");
		template.CreateEntity("Lamp");
		Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok);

		// Reopen the same prefab for editing and drop a copy of itself inside it.
		let editing = scope Scene("lamp");
		let payload = instance.ReadData("scene");
		Test.Assert(payload != null);
		defer delete payload;
		Test.Assert(PrefabSpawn.Spawn(editing, payload, instance.Id).IsAssigned);

		Test.Assert(SceneStorage.SavePrefab(editing, instance) case .Err(.InvalidArgument));
	}

	/// An instance whose primary exists but whose scene stream does not. A missing world
	/// is NotFound rather than an empty scene, so a caller can tell the two apart.
	[Test]
	public static void LoadingAnInstanceWithNoSceneStreamIsNotFound()
	{
		let fixture = scope SceneContentFixture("scratch_scene_nostream");

		let instance = fixture.Database.RootGroup.CreateInstance("empty",
			SceneContentFixture.SceneTypeName);
		let document = scope SceneDocument();
		document.Name.Set("empty");
		Test.Assert(instance.WriteObject(document) case .Ok);

		let scene = scope Scene();
		Test.Assert(SceneStorage.LoadScene(instance, scene) case .Err(.NotFound));
	}
}
