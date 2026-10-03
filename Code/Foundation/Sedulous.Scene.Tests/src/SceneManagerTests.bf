using System;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// A group of scenes: creation, the active set and the current scene, the assembly hooks,
/// the group time term, and the teardown.
class SceneManagerTests
{
	[Test]
	public static void ScenesAreCreatedActivatedAndDestroyed()
	{
		let manager = scope SceneManager();
		Test.Assert(manager.SceneCount == 0);
		Test.Assert(manager.CurrentScene == null);

		let a = manager.CreateScene("A");
		let b = manager.CreateScene("B");
		Test.Assert(a != null && b != null);
		Test.Assert(manager.SceneCount == 2);
		Test.Assert(manager.ActiveScenes.Length == 2);
		Test.Assert(manager.CurrentScene === a, "the first created becomes current");
		Test.Assert(manager.GetScene("B") === b);

		manager.CurrentScene = b;
		Test.Assert(manager.CurrentScene === b);

		manager.DestroyScene(a);
		Test.Assert(manager.SceneCount == 1);
		Test.Assert(manager.GetScene("A") == null);
		Test.Assert(manager.CurrentScene === b, "destroying another scene leaves current alone");

		manager.DestroyScene(b);
		Test.Assert(manager.SceneCount == 0);
		Test.Assert(manager.CurrentScene == null, "destroying the current one clears it");
	}

	/// The hooks are how a scene gets assembled at all, and the manager itself knows
	/// nothing about what they do: the caller owns whatever they close over.
	[Test]
	public static void TheInstallAndUninstallHooksFireAroundEachScene()
	{
		let manager = scope SceneManager();
		int installed = 0;
		int removed = 0;

		delegate void(Scene) installer = scope [&](scene) => { installed++; };
		delegate void(Scene) uninstaller = scope [&](scene) => { removed++; };
		manager.SetSceneInstaller(installer);
		manager.SetSceneUninstaller(uninstaller);

		let scene = manager.CreateScene("S");
		Test.Assert(installed == 1);
		Test.Assert(removed == 0);

		manager.DestroyScene(scene);
		Test.Assert(removed == 1);
	}

	/// The group term of the time chain. Zero freezes the group and a NEGATIVE scale
	/// clamps to zero: a group pauses, it never runs backwards, and the clamp does not
	/// stick afterwards.
	[Test]
	public static void TheGroupTimeScaleFoldsIntoTheTickAndClampsAtZero()
	{
		let manager = scope SceneManager();
		let scene = manager.CreateScene("S");
		scene.Start();
		scene.SetSimulationEnabled(true);
		Test.Assert(manager.TimeScale == 1.0f);

		manager.BeginFrame(FrameTime(0.016f, 1.0f, 1.0f, 1.0f, 0.0f));
		manager.Update(FrameTime(0.016f, 1.0f, 1.0f, 1.0f, 0.0f));

		manager.TimeScale = 0.0f;
		manager.BeginFrame(FrameTime(0.016f, 1.0f, 1.0f, 1.0f, 0.0f));
		manager.Update(FrameTime(0.016f, 1.0f, 1.0f, 1.0f, 0.0f));
		Test.Assert(manager.TimeScale == 0.0f);

		manager.TimeScale = -2.0f;
		Test.Assert(manager.TimeScale == 0.0f, "a negative scale pauses rather than rewinds");

		manager.TimeScale = 0.5f;
		Test.Assert(manager.TimeScale == 0.5f, "and the clamp does not stick");
	}

	[Test]
	public static void ClearDestroysTheWholeGroupAndNotifies()
	{
		let manager = scope SceneManager();
		int installed = 0;
		int removed = 0;
		delegate void(Scene) installer = scope [&](scene) => { installed++; };
		delegate void(Scene) uninstaller = scope [&](scene) => { removed++; };
		manager.SetSceneInstaller(installer);
		manager.SetSceneUninstaller(uninstaller);

		manager.CreateScene("A");
		manager.CreateScene("B");
		Test.Assert(installed == 2);

		manager.Clear();
		Test.Assert(manager.SceneCount == 0);
		Test.Assert(removed == 2, "every scene was notified, not just the last");
		Test.Assert(manager.CurrentScene == null);
	}

	/// Creating INACTIVE is what an asynchronous level load needs: the scene is owned and
	/// can be populated, but it does not tick, does not render and is not a spawn target
	/// until its resources have finalised.
	[Test]
	public static void AnInactiveSceneIsOwnedButNotTickedUntilActivated()
	{
		let manager = scope SceneManager();
		let scene = manager.CreateScene("loading", false);
		Test.Assert(scene != null);
		Test.Assert(manager.SceneCount == 1);
		Test.Assert(manager.ActiveScenes.Length == 0);
		Test.Assert(!manager.IsActive(scene));
		Test.Assert(manager.CurrentScene == null);

		manager.ActivateScene(scene);
		Test.Assert(manager.ActiveScenes.Length == 1);
		Test.Assert(manager.IsActive(scene));
		Test.Assert(manager.CurrentScene === scene);

		// Idempotent: a second activate does not add it twice, which would tick it twice.
		manager.ActivateScene(scene);
		Test.Assert(manager.ActiveScenes.Length == 1);

		// Deactivating stops the ticking and clears current WITHOUT destroying anything.
		manager.DeactivateScene(scene);
		Test.Assert(manager.ActiveScenes.Length == 0);
		Test.Assert(!manager.IsActive(scene));
		Test.Assert(manager.CurrentScene == null);
		Test.Assert(manager.SceneCount == 1, "still owned");

		manager.ActivateScene(scene);
		Test.Assert(manager.IsActive(scene));

		// The default is still to activate.
		let normal = manager.CreateScene("default");
		Test.Assert(manager.IsActive(normal));
		Test.Assert(manager.ActiveScenes.Length == 2);

		// A scene this manager does not own cannot be activated into its set: it would
		// then tick something it has no claim on and does not free.
		let foreign = scope Scene("foreign");
		manager.ActivateScene(foreign);
		Test.Assert(!manager.IsActive(foreign));
		Test.Assert(manager.ActiveScenes.Length == 2);
	}

	/// Counts stops into a count that outlives the scene (the system goes with it).
	private class StopWitness : SceneSystem
	{
		public int* Stops = null;
		public override void OnSceneStopped() { (*Stops)++; }
	}

	/// A scene system unhooks itself from what outlives the scene in its stop hook (a script
	/// system's handlers on a run's event bus). A running scene destroyed without a stop (a run
	/// loading the scene it is already in) left those handlers pointing at freed memory.
	[Test]
	public static void ARunningSceneIsStoppedBeforeItIsDestroyed()
	{
		let manager = scope SceneManager();
		int stops = 0;
		let running = manager.CreateScene("running");
		running.AddSystem<StopWitness>().Stops = &stops;
		running.Start();
		manager.DestroyScene(running);
		Test.Assert(stops == 1, "stopped on the way out");

		// A scene that never started is not stopped (its systems never began).
		let idle = manager.CreateScene("idle");
		idle.AddSystem<StopWitness>().Stops = &stops;
		manager.DestroyScene(idle);
		Test.Assert(stops == 1);

		// A scene already stopped is not stopped twice.
		let stopped = manager.CreateScene("stopped");
		stopped.AddSystem<StopWitness>().Stops = &stops;
		stopped.Start();
		stopped.Stop();
		Test.Assert(stops == 2);
		manager.DestroyScene(stopped);
		Test.Assert(stops == 2);

		// The group's teardown stops what still runs, too.
		let last = manager.CreateScene("last");
		last.AddSystem<StopWitness>().Stops = &stops;
		last.Start();
		manager.Clear();
		Test.Assert(stops == 3, "a clear stops the running scenes it destroys");
	}
}
