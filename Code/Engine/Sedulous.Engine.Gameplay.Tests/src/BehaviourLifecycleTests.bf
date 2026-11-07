using System;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// The lifecycle the scene's BehaviourSystem runs: the edges, then the updates type by type in
/// registration order and pool order, the fixed and late ticks, simulation gating, the
/// inactive freeze, and what a callback may do to the pools mid pass.
class BehaviourLifecycleTests
{
	private const float cDt = 1.0f / 60.0f;
	private const float cFixedDt = 0.02f;

	/// Each type's edges, then each type's updates, then the late ticks: types in the order
	/// their managers registered, instances in pool order (the order added), and OnStart once.
	[Test]
	public static void TheEdgesThenTheUpdatesTypeByTypeInPoolOrder()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let runners = scene.AddSystem<BehaviourManager<Runner>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		walkers.Add(b);
		walkers.Add(a);
		runners.Add(a);
		Test.Assert(LifecycleLog.Text.IsEmpty, "nothing runs before the first tick");

		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:b.Enable W:b.Start W:a.Enable W:a.Start R:a.Enable R:a.Start W:b.Update W:a.Update R:a.Update W:b.Late W:a.Late ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:b.Update W:a.Update R:a.Update W:b.Late W:a.Late ", LifecycleLog.Text);
		Test.Assert(Math.Abs(walkers.Get(a).UpdateTime - 2.0f * cDt) < 1e-6f, "the scene's own delta, each tick");
	}

	/// A class joins only the tick lists it overrides; every registered class still gets its
	/// edges. Managers added before the system are found by it, those after find it, and
	/// either may be torn down first.
	[Test]
	public static void OnlyAnOverriddenTickPutsATypeOnItsList()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let markers = scene.AddSystem<BehaviourManager<Marker>>();
		let system = scene.AddSystem<BehaviourSystem>();
		let runners = scene.AddSystem<BehaviourManager<Runner>>();

		Test.Assert(system.ManagerCount == 3);
		Test.Assert(system.UpdateCount == 2, "the walker and the runner");
		Test.Assert(system.FixedUpdateCount == 1, "the walker alone");
		Test.Assert(system.LateUpdateCount == 1, "the walker alone");
		Test.Assert(walkers.TicksUpdate && walkers.TicksFixedUpdate && walkers.TicksLateUpdate);
		Test.Assert(runners.TicksUpdate && !runners.TicksFixedUpdate && !runners.TicksLateUpdate);
		Test.Assert(!markers.TicksUpdate && !markers.TicksFixedUpdate && !markers.TicksLateUpdate);

		let e = scene.CreateEntity("e");
		walkers.Add(e);
		let marker = markers.Add(e);
		runners.Add(e);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:e.Enable W:e.Start R:e.Enable R:e.Start W:e.Update R:e.Update W:e.Late ", LifecycleLog.Text);
		Test.Assert(marker.mStarted && marker.mEnabledDelivered, "a type with no tick still starts");
	}

	/// While the scene does not simulate (edit mode) nothing is called, not even the edges;
	/// simulating again starts what is there.
	[Test]
	public static void ASceneThatDoesNotSimulateRunsNothing()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let e = scene.CreateEntity("e");
		let walker = walkers.Add(e);

		scene.SetSimulationEnabled(false);
		scene.Update(cDt);
		scene.FixedUpdate(cFixedDt);
		Test.Assert(LifecycleLog.Text.IsEmpty, LifecycleLog.Text);
		Test.Assert(!walker.mStarted && !walker.mEnabledDelivered);

		scene.SetSimulationEnabled(true);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:e.Enable W:e.Start W:e.Update W:e.Late ", LifecycleLog.Text);
	}

	/// An inactive entity's behaviour waits to start until it is active; one deactivated (its
	/// own flag or an ancestor's) gets OnDisable on the edge and then nothing, fixed step
	/// included, until it is active again, without a second start.
	[Test]
	public static void AnInactiveEntityFreezesItsBehaviour()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let parent = scene.CreateEntity("parent");
		let e = scene.CreateEntity("e");
		scene.SetParent(e, parent);
		let walker = walkers.Add(e);

		scene.SetActive(e, false);
		scene.Update(cDt);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text.IsEmpty, "inactive from the start: not started");
		Test.Assert(!walker.mStarted);

		scene.SetActive(e, true);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:e.Enable W:e.Start W:e.Update W:e.Late ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		scene.SetActive(parent, false);
		scene.Update(cDt);
		scene.FixedUpdate(cFixedDt);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:e.Disable ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		scene.SetActive(parent, true);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:e.Enable W:e.Update W:e.Late ", LifecycleLog.Text);
	}

	/// Enabled written directly takes effect at the next tick, with its edge; re-enabling is
	/// not a restart.
	[Test]
	public static void DisablingAndEnablingDeliverTheEdges()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let e = scene.CreateEntity("e");
		let walker = walkers.Add(e);
		scene.Update(cDt);

		LifecycleLog.Text.Clear();
		walker.Enabled = false;
		scene.Update(cDt);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:e.Disable ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		walker.Enabled = true;
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:e.Enable W:e.Update W:e.Late ", LifecycleLog.Text);
	}

	/// Removal runs OnDisable when the enable was delivered, then OnDestroy when it started:
	/// one disabled since gets OnDestroy alone, one that never ticked nothing. The scene's
	/// teardown does the same.
	[Test]
	public static void RemovalDisablesThenDestroys()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let c = scene.CreateEntity("c");
		walkers.Add(a);
		walkers.Add(b);
		scene.Update(cDt);
		walkers.Get(b).Enabled = false;
		scene.Update(cDt);
		walkers.Add(c);

		LifecycleLog.Text.Clear();
		walkers.RemoveComponent(a);
		Test.Assert(LifecycleLog.Text == "W:a.Disable W:a.Destroy ", LifecycleLog.Text);
		LifecycleLog.Text.Clear();
		walkers.RemoveComponent(b);
		Test.Assert(LifecycleLog.Text == "W:b.Destroy ", LifecycleLog.Text);
		LifecycleLog.Text.Clear();
		walkers.RemoveComponent(c);
		Test.Assert(LifecycleLog.Text.IsEmpty, LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		{
			let torn = scope Scene();
			torn.AddSystem<BehaviourSystem>();
			torn.AddSystem<BehaviourManager<Walker>>().Add(torn.CreateEntity("t"));
			torn.Update(cDt);
			LifecycleLog.Text.Clear();
		}
		Test.Assert(LifecycleLog.Text == "W:t.Disable W:t.Destroy ", LifecycleLog.Text);
	}

	/// An entity destroyed during Update goes at the end of the frame: the rest of the frame
	/// still runs on it, and its behaviour is disabled and destroyed once.
	[Test]
	public static void ADestroyDuringUpdateWaitsForTheFrameEnd()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		walkers.Add(a);
		walkers.Add(b);

		bool fired = false;
		delegate void(Walker walker) hook = scope [&] (walker) =>
		{
			if (fired || (walker.Entity != a))
				return;
			fired = true;
			scene.DestroyEntity(b);
			scene.DestroyEntity(a);
			Test.Assert(walker.Scene == scene, "deferred: still attached in its own callback");
		};
		Walker.UpdateHook = hook;
		defer { Walker.UpdateHook = null; }

		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:a.Enable W:a.Start W:b.Enable W:b.Start W:a.Update W:b.Update W:a.Late W:b.Late W:b.Disable W:b.Destroy W:a.Disable W:a.Destroy ", LifecycleLog.Text);
		Test.Assert(walkers.Count == 0);

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text.IsEmpty, LifecycleLog.Text);
	}

	/// A behaviour added during a tick, from an OnStart (another type, whose edges come later
	/// in the same pass) or an OnUpdate, is not visited by it: it starts with the next frame's
	/// edges.
	[Test]
	public static void AnAddDuringATickStartsOnTheNext()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let runners = scene.AddSystem<BehaviourManager<Runner>>();
		let a = scene.CreateEntity("a");
		let c = scene.CreateEntity("c");
		let d = scene.CreateEntity("d");
		walkers.Add(a);

		bool started = false;
		bool updated = false;
		delegate void(Walker walker) onStart = scope [&] (walker) =>
		{
			if (started)
				return;
			started = true;
			runners.Add(d);
		};
		delegate void(Walker walker) onUpdate = scope [&] (walker) =>
		{
			if (updated)
				return;
			updated = true;
			walkers.Add(c);
			runners.Add(c);
		};
		Walker.StartHook = onStart;
		Walker.UpdateHook = onUpdate;
		defer { Walker.StartHook = null; Walker.UpdateHook = null; }

		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:a.Enable W:a.Start W:a.Update W:a.Late ", LifecycleLog.Text);
		Test.Assert((walkers.Count == 2) && (runners.Count == 2));

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:c.Enable W:c.Start R:d.Enable R:d.Start R:c.Enable R:c.Start W:a.Update W:c.Update R:d.Update R:c.Update W:a.Late W:c.Late ", LifecycleLog.Text);
	}

	/// Removals during a tick, of one already visited (whose slot the last fills), of one not
	/// yet visited, and of the very behaviour whose callback it is: each of the rest is visited
	/// once, the removed one not again, and the remover lives on until its callback returns.
	[Test]
	public static void ARemovalDuringATickNeitherSkipsNorRevisits()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let c = scene.CreateEntity("c");
		let d = scene.CreateEntity("d");
		walkers.Add(a);
		walkers.Add(b);
		walkers.Add(c);
		walkers.Add(d);
		scene.Update(cDt);

		bool fired = false;
		float timeAfter = 0.0f;
		bool detachedAfter = false;
		delegate void(Walker walker) hook = scope [&] (walker) =>
		{
			if (fired || (walker.Entity != b))
				return;
			fired = true;
			walkers.RemoveComponent(a);
			walkers.RemoveComponent(c);
			walkers.RemoveComponent(b);
			// The remover's own state, read after its removal: still alive.
			timeAfter = walker.UpdateTime;
			detachedAfter = walker.Scene == null;
		};
		Walker.UpdateHook = hook;
		defer { Walker.UpdateHook = null; }

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:a.Update W:b.Update W:a.Disable W:a.Destroy W:c.Disable W:c.Destroy W:b.Disable W:b.Destroy W:d.Update W:d.Late ", LifecycleLog.Text);
		Test.Assert(Math.Abs(timeAfter - 2.0f * cDt) < 1e-6f, "the remover's fields, read after its removal");
		Test.Assert(detachedAfter, "and it is detached");
		Test.Assert(walkers.Count == 1);
		Test.Assert(walkers.Get(d) != null);

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:d.Update W:d.Late ", LifecycleLog.Text);
	}

	/// The fixed step reaches a started behaviour with the step's delta, and the late tick
	/// follows every update of the frame; neither reaches one that has not started.
	[Test]
	public static void TheFixedAndLateTicksAreReached()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let walker = walkers.Add(scene.CreateEntity("e"));

		scene.FixedUpdate(cFixedDt);
		Test.Assert(walker.FixedCount == 0, "not started yet");

		scene.Update(cDt);
		Test.Assert(walker.LateCount == 1);
		scene.FixedUpdate(cFixedDt);
		scene.FixedUpdate(cFixedDt);
		Test.Assert(walker.FixedCount == 2);
		Test.Assert(Math.Abs(walker.FixedTime - 2.0f * cFixedDt) < 1e-6f, "the step's delta");

		// The scene's own drive: one fixed step per whole step of the scaled time.
		scene.AdvanceTime(scene.FixedTimeStep);
		Test.Assert(walker.FixedCount == 3);
	}

	/// An entity destroyed during the fixed step goes at once (the scene defers only during
	/// Update): its behaviour is disabled and destroyed there, outlives its own callback, and
	/// the rest of the step still runs.
	[Test]
	public static void ADestroyDuringTheFixedStepIsSafe()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let a = scene.CreateEntity("a");
		walkers.Add(a);
		walkers.Add(scene.CreateEntity("b"));
		scene.Update(cDt);

		bool fired = false;
		int countAfter = 0;
		delegate void(Walker walker) hook = scope [&] (walker) =>
		{
			if (fired || (walker.Entity != a))
				return;
			fired = true;
			scene.DestroyEntity(a);
			countAfter = walker.FixedCount;
		};
		Walker.FixedHook = hook;
		defer { Walker.FixedHook = null; }

		LifecycleLog.Text.Clear();
		scene.FixedUpdate(cFixedDt);
		Test.Assert(LifecycleLog.Text == "W:a.Fixed W:a.Disable W:a.Destroy W:b.Fixed ", LifecycleLog.Text);
		Test.Assert(countAfter == 1);
		Test.Assert(walkers.Count == 1);

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:b.Update W:b.Late ", LifecycleLog.Text);
	}
}
