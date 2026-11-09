using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Engine.GameInstance;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.GameInstance.Tests;

/// The scene load orchestration the instance owns: the synchronous path, the streaming one,
/// and the ticket registry that sits over it.
///
/// The app still owns POLICY, which is what to load and what to do to a scene once it is
/// live; what is tested here is the bookkeeping both an editor and a player would otherwise
/// hand roll identically.
class SceneLoadTests
{
	/// A tiny entities only scene, saved through the database, and the instance it lives in.
	private static Instance AuthorLevel(SceneContentFixture fixture, StringView name)
	{
		let instance = fixture.Database.RootGroup.CreateInstance(name,
			SceneContentFixture.SceneTypeName);

		let authored = scope Scene("level");
		authored.CreateEntity("a");
		authored.CreateEntity("b");
		Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);

		return instance;
	}

	public const String PrefabTypeName = "Sedulous.Scene.Resource.PrefabDocument";

	/// A crate prefab (the crate and its lid) and a level placing it three times, as stored.
	private static Instance AuthorPlacements(SceneContentFixture fixture, out Guid prefabId)
	{
		let template = scope Scene("crate");
		let crate = template.CreateEntity("Crate");
		template.SetParent(template.CreateEntity("Lid"), crate);
		let prefab = fixture.Database.RootGroup.CreateInstance("crate", PrefabTypeName);
		Test.Assert(SceneStorage.SavePrefab(template, prefab) case .Ok);
		prefabId = prefab.Id;

		let authored = scope Scene("level");
		for (int i < 3)
		{
			let payload = prefab.ReadData("scene");
			Test.Assert(payload != null);
			defer delete payload;
			Test.Assert(PrefabSpawn.Spawn(authored, payload, prefabId).IsAssigned);
		}
		let level = fixture.Database.RootGroup.CreateInstance("level", SceneContentFixture.SceneTypeName);
		Test.Assert(SceneStorage.SaveScene(authored, level) case .Ok);
		return level;
	}

	/// The crate made a single entity on disk, as an edit the game has not reloaded.
	private static void FlattenPrefab(SceneContentFixture fixture, Guid prefabId)
	{
		let template = scope Scene("crate");
		template.CreateEntity("Flat");
		Test.Assert(SceneStorage.SavePrefab(template, fixture.Database.GetInstance(prefabId)) case .Ok);
	}

	[Test]
	public static void ALoadPlacesItsPrefabsFromThePrefabTheResourcesLoaded()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_prefabs");
		let level = AuthorPlacements(fixture, let prefabId);

		let resources = scope ResourceManager(fixture.Database);
		let prefabs = scope PrefabFactory();
		resources.AddFactory(prefabs);
		let instance = scope GameInstance();

		// Never bound before: the load binds it for its three placements.
		let first = instance.LoadScene(level, resources);
		Test.Assert(first != null);
		Test.Assert(first.EntityCount == 6, "three crates, each with its lid");
		Test.Assert(resources.FindHandle(prefabId).State == .Ready, "loaded by the manager");

		// Changed on disk, not reloaded: both loads place the prefab the game has.
		FlattenPrefab(fixture, prefabId);
		let second = instance.LoadScene(level, resources);
		Test.Assert(second.EntityCount == 6, "the loaded crate, not the file");
		var handle = instance.LoadSceneAsync(level, resources);
		Test.Assert(!handle.Failed);
		Test.Assert(handle.Scene.EntityCount == 6, "the streaming load places it too");

		// Reloaded, the next load places it as it now is.
		resources.Reload(prefabId);
		let third = instance.LoadScene(level, resources);
		Test.Assert(third.EntityCount == 3, "three flat crates");
	}

	[Test]
	public static void ALoadWithoutThePrefabPlacesNothingOfIt()
	{
		// No factory makes a prefab: its placements are skipped, the rest of the level loads.
		let fixture = scope SceneContentFixture("scratch_gi_load_no_prefabs");
		let level = AuthorPlacements(fixture, let prefabId);
		Test.Assert(prefabId != Guid());

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();
		let scene = instance.LoadScene(level, resources);
		Test.Assert(scene != null);
		Test.Assert(scene.EntityCount == 0);
	}

	[Test]
	public static void ALevelLoadsByTheSceneAFieldNames()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_scene_ref");
		let level = AuthorLevel(fixture, "level");
		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();
		instance.SetSceneLoader(new [=fixture, =resources, =instance] (sceneId) =>
			{
				let sceneInstance = fixture.Database.GetInstance(sceneId);
				if (sceneInstance == null)
				{
					var failed = SceneLoadHandle();
					failed.Failed = true;
					return failed;
				}
				return instance.LoadSceneAsync(sceneInstance, resources);
			});

		Test.Assert(!instance.LoadScene(SceneRef()), "a field naming none loads nothing");
		Test.Assert(instance.LoadSceneAsync(SceneRef()) == 0);
		Test.Assert(instance.LoadScene(SceneRef(level.Id)));
		Test.Assert((instance.GetScene() != null) && (instance.GetScene().EntityCount == 2));
	}

	[Test]
	public static void TheSyncPathReturnsAnActiveResolvedScene()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_sync");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		let scene = instance.LoadScene(level, resources);
		Test.Assert(scene != null);
		Test.Assert(scene.EntityCount == 2);
		// The synchronous path activates at once.
		Test.Assert(instance.Scenes.IsActive(scene));
	}

	[Test]
	public static void TheAsyncPathStaysInactiveUntilActivated()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_async");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		var handle = instance.LoadSceneAsync(level, resources);
		Test.Assert(handle.Scene != null);
		Test.Assert(!handle.Failed);
		// Inactive while it loads: it must not tick or draw half built.
		Test.Assert(!instance.Scenes.IsActive(handle.Scene));
		// Nothing here binds anything asynchronously, so it is already whole.
		Test.Assert(handle.IsComplete);
		Test.Assert(handle.Progress == 1.0f);

		let activated = instance.ActivateLoadedScene(ref handle);
		Test.Assert(activated === handle.Scene);
		Test.Assert(instance.Scenes.IsActive(activated));
		Test.Assert(activated.EntityCount == 2);
	}

	[Test]
	public static void ALoadWithNoSceneStreamFailsCleanly()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_empty");
		let empty = fixture.Database.RootGroup.CreateInstance("empty",
			SceneContentFixture.SceneTypeName);

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		var handle = instance.LoadSceneAsync(empty, resources);
		Test.Assert(handle.Failed);
		Test.Assert(handle.IsComplete);
		Test.Assert(handle.Scene == null);

		Test.Assert(instance.LoadScene(empty, resources) == null);
	}

	[Test]
	public static void ATicketPollsToCompletionAndRunsTheAppsPolicy()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_ticket");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();
		// No current scene at launch, which is what an orchestrator first boot looks like.
		Test.Assert(!instance.SceneReady);

		Scene policyRanOn = null;
		instance.SetSceneActivationPolicy(new [&] (scene) => { policyRanOn = scene; });

		let handle = instance.LoadSceneAsync(level, resources);
		Test.Assert(handle.Scene != null);
		let pending = handle.Scene;

		let ticket = instance.TrackLoad(handle);
		// One based, nought being reserved for "did not start".
		Test.Assert(ticket == 1);

		// Registered but not pumped: not complete, still inactive, policy not run.
		Test.Assert(!instance.LoadComplete(ticket));
		Test.Assert(!instance.LoadFailed(ticket));
		Test.Assert(instance.LoadProgress(ticket) == 1.0f);
		Test.Assert(!instance.Scenes.IsActive(pending));
		Test.Assert(policyRanOn == null);

		instance.PumpLoads();
		Test.Assert(instance.LoadComplete(ticket));
		Test.Assert(!instance.LoadFailed(ticket));
		Test.Assert(instance.LoadProgress(ticket) == 1.0f);
		Test.Assert(instance.Scenes.IsActive(pending));
		Test.Assert(policyRanOn === pending);
		Test.Assert(instance.GetScene() === pending);
		Test.Assert(instance.SceneReady);

		// Idempotent: an already activated load is skipped.
		instance.PumpLoads();
		Test.Assert(policyRanOn === pending);

		// And an unknown ticket never hangs a caller polling it in a loop.
		Test.Assert(instance.LoadComplete(999));
		Test.Assert(!instance.LoadFailed(999));
		Test.Assert(instance.LoadProgress(999) == 1.0f);
	}

	[Test]
	public static void ALevelLoadReplacesTheSceneItLandsOver()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_replace");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();
		instance.SetSceneActivationPolicy(new (scene) => { scene.Start(); scene.SetSimulationEnabled(true); });

		instance.TrackLoad(instance.LoadSceneAsync(level, resources));
		instance.PumpLoads();
		let first = instance.GetScene();
		Test.Assert(first != null);
		Test.Assert(instance.Scenes.SceneCount == 1);

		// The same level again, as a restart loads it: the new copy is the run's scene and
		// the scene manager's current, and the old one is gone rather than ticking unseen.
		let handle = instance.LoadSceneAsync(level, resources);
		let second = handle.Scene;
		instance.TrackLoad(handle);
		Test.Assert(instance.Scenes.SceneCount == 2, "both exist while the new one loads");
		instance.PumpLoads();
		Test.Assert(instance.GetScene() === second);
		Test.Assert(instance.Scenes.CurrentScene === second);
		Test.Assert(instance.Scenes.IsActive(second));
		Test.Assert(instance.Scenes.SceneCount == 1, scope $"{instance.Scenes.SceneCount} scenes after the load");
	}

	[Test]
	public static void AFailedLoadReadsTerminalByTicket()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_failed");
		let empty = fixture.Database.RootGroup.CreateInstance("empty",
			SceneContentFixture.SceneTypeName);

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		let ticket = instance.TrackLoad(instance.LoadSceneAsync(empty, resources));
		Test.Assert(ticket == 1);

		// A failed handle is skipped rather than activated, and stays terminal.
		instance.PumpLoads();
		Test.Assert(instance.LoadComplete(ticket));
		Test.Assert(instance.LoadFailed(ticket));
		Test.Assert(!instance.SceneReady);
	}

	[Test]
	public static void DestroyingAPendingSceneSweepsItsTrackedLoad()
	{
		// The tracked handle BORROWS its scene. Destroying a pending one before it activates
		// has to drop the tracked load, or the next pump would activate freed memory.
		let fixture = scope SceneContentFixture("scratch_gi_load_sweep");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		let handle = instance.LoadSceneAsync(level, resources);
		Test.Assert(handle.Scene != null);
		let pending = handle.Scene;

		let ticket = instance.TrackLoad(handle);
		Test.Assert(!instance.LoadComplete(ticket));

		instance.DestroyScene(pending);
		// Nothing left to activate.
		instance.PumpLoads();
		Test.Assert(instance.LoadComplete(ticket));
		Test.Assert(!instance.LoadFailed(ticket));
		Test.Assert(!instance.SceneReady);
	}

	[Test]
	public static void ClearScenesDropsLoadsStillInFlight()
	{
		// A stop that keeps the instance tears the scenes down while a load may still be in
		// flight, and that load borrows a scene from the group. Dropping the tracked entries
		// FIRST is what stops the next pump, which still runs every frame, from activating
		// and starting a scene that had just been freed.
		let fixture = scope SceneContentFixture("scratch_gi_load_clear");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		let live = instance.LoadScene(level, resources);
		Test.Assert(live != null);
		instance.SetScene(live);
		Test.Assert(instance.SceneReady);

		let ticket = instance.TrackLoad(instance.LoadSceneAsync(level, resources));
		Test.Assert(!instance.LoadComplete(ticket));
		// The live scene, and the pending inactive one.
		Test.Assert(instance.Scenes.SceneCount == 2);

		var policyRan = false;
		instance.SetSceneActivationPolicy(new [&] (scene) => { policyRan = true; });

		instance.ClearScenes();
		Test.Assert(instance.Scenes.SceneCount == 0);
		Test.Assert(instance.GetScene() == null);
		Test.Assert(!instance.SceneReady);

		instance.PumpLoads();
		Test.Assert(!policyRan);
		Test.Assert(instance.LoadComplete(ticket));
		Test.Assert(instance.GetScene() == null);
	}

	[Test]
	public static void ASuccessfulLoadIsRetiredOnActivation()
	{
		// The registry must not grow without bound. After activation the entry is dropped, so
		// re-destroying the now live scene is a safe no op and the ticket still reads terminal
		// safe: what a caller can observe is unchanged.
		let fixture = scope SceneContentFixture("scratch_gi_load_retire");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		let ticket = instance.TrackLoad(instance.LoadSceneAsync(level, resources));
		instance.PumpLoads();
		Test.Assert(instance.SceneReady);

		let live = instance.GetScene();
		Test.Assert(instance.LoadComplete(ticket));

		instance.DestroyScene(live);
		instance.PumpLoads();
		Test.Assert(instance.LoadComplete(ticket));
	}
}
