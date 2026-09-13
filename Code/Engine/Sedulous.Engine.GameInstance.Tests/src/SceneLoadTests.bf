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

	[Test]
	public static void TheSyncPathReturnsAnActiveResolvedScene()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_sync");
		let level = AuthorLevel(fixture, "level");

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		let scene = instance.LoadScene(level, resources, null);
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

		var handle = instance.LoadSceneAsync(level, resources, null);
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

		var handle = instance.LoadSceneAsync(empty, resources, null);
		Test.Assert(handle.Failed);
		Test.Assert(handle.IsComplete);
		Test.Assert(handle.Scene == null);

		Test.Assert(instance.LoadScene(empty, resources, null) == null);
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

		let handle = instance.LoadSceneAsync(level, resources, null);
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
	public static void AFailedLoadReadsTerminalByTicket()
	{
		let fixture = scope SceneContentFixture("scratch_gi_load_failed");
		let empty = fixture.Database.RootGroup.CreateInstance("empty",
			SceneContentFixture.SceneTypeName);

		let resources = scope ResourceManager(fixture.Database);
		let instance = scope GameInstance();

		let ticket = instance.TrackLoad(instance.LoadSceneAsync(empty, resources, null));
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

		let handle = instance.LoadSceneAsync(level, resources, null);
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

		let live = instance.LoadScene(level, resources, null);
		Test.Assert(live != null);
		instance.SetScene(live);
		Test.Assert(instance.SceneReady);

		let ticket = instance.TrackLoad(instance.LoadSceneAsync(level, resources, null));
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

		let ticket = instance.TrackLoad(instance.LoadSceneAsync(level, resources, null));
		instance.PumpLoads();
		Test.Assert(instance.SceneReady);

		let live = instance.GetScene();
		Test.Assert(instance.LoadComplete(ticket));

		instance.DestroyScene(live);
		instance.PumpLoads();
		Test.Assert(instance.LoadComplete(ticket));
	}
}
