using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.Run;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// Systems wired into a scene: ownership and lookup, the phase ordered update, deferred
/// destruction, component freeing, the notifications, UpdateOrder and simulation gating.
class SceneSystemTests
{
	[Test]
	public static void SystemsAreAddedFoundByTypeAndOwnedByTheScene()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		Test.Assert(manager != null);
		Test.Assert(scene.GetSystem<HealthManager>() === manager);
		Test.Assert(scene.HasSystem<HealthManager>());
		Test.Assert(scene.GetSystem<RecordingSystem>() == null);
	}

	/// The phase ORDER is the contract systems depend on, so it is pinned exactly. The
	/// transform recompute sits between PostUpdate and PostTransform, which is what makes
	/// final matrices available to extraction.
	[Test]
	public static void UpdateRunsTheGameplayPhasesInOrder()
	{
		let scene = scope Scene();
		let recorder = scene.AddSystem<RecordingSystem>();

		scene.Update(0.016f);

		Test.Assert(recorder.Phases.Count == 5);
		Test.Assert(recorder.Phases[0] == .PreUpdate);
		Test.Assert(recorder.Phases[1] == .Update);
		Test.Assert(recorder.Phases[2] == .AsyncUpdate);
		Test.Assert(recorder.Phases[3] == .PostUpdate);
		Test.Assert(recorder.Phases[4] == .PostTransform);
	}

	[Test]
	public static void ComponentInitialisationHappensInTheScenesInitializePhase()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity();
		manager.Add(entity).Value = 50.0f;
		Test.Assert(manager.Initialized == 0);

		scene.Update(0.016f);
		Test.Assert(manager.Initialized == 1);
	}

	[Test]
	public static void DestroyingAnEntityFreesItsComponentThroughTheManager()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity();
		manager.Add(entity);
		Test.Assert(manager.Has(entity));

		// Outside an update, so it happens at once.
		scene.DestroyEntity(entity);
		Test.Assert(!manager.Has(entity));
		Test.Assert(manager.Destroyed == 1);
	}

	/// A destroy asked for DURING an update is deferred to the frame's cleanup, so the
	/// entity is still there for the rest of the frame and whatever is iterating does not
	/// have the ground move under it.
	[Test]
	public static void ADestroyDuringUpdateIsDeferredToCleanup()
	{
		let scene = scope Scene();
		let target = scene.CreateEntity();

		let destroyer = scene.AddSystem<DestroyerSystem>();
		destroyer.Target = target;

		scene.Update(0.016f);

		Test.Assert(destroyer.TargetWasValidDuringUpdate, "still alive mid frame");
		Test.Assert(!scene.IsValid(target), "and gone by the end of it");
	}

	[Test]
	public static void ActiveChangesAndStartStopNotifySystemsAndFixedUpdateTicks()
	{
		let scene = scope Scene();
		let recorder = scene.AddSystem<RecordingSystem>();
		let entity = scene.CreateEntity();

		scene.SetActive(entity, false);
		Test.Assert(recorder.ActiveChanges == 1);

		scene.Start();
		Test.Assert(recorder.Started == 1);
		Test.Assert(scene.IsStarted);

		scene.FixedUpdate(0.02f);
		Test.Assert(recorder.FixedUpdates == 1);

		scene.Stop();
		Test.Assert(recorder.Stopped == 1);
		Test.Assert(!scene.IsStarted);
	}

	/// Edit mode: a simulation only system stops running while the simulation is off, on
	/// both lanes. A system with mixed work does not declare itself this way and asks the
	/// scene instead.
	[Test]
	public static void SimulationOnlySystemsSkipWhileSimulationIsOff()
	{
		let scene = scope Scene();
		let system = scene.AddSystem<SimulationOnlySystem>();

		scene.Update(0.016f);
		Test.Assert(system.Updates == 5, "five phases while simulating");

		scene.SetSimulationEnabled(false);
		scene.Update(0.016f);
		Test.Assert(system.Updates == 5, "skipped on the variable lane");

		scene.FixedUpdate(0.02f);
		Test.Assert(system.Updates == 5, "and on the fixed one");
	}

	/// Within a phase, UpdateOrder decides, not the order systems happened to be added in.
	[Test]
	public static void SystemsRunWithinAPhaseInUpdateOrder()
	{
		let order = scope List<int32>();
		let scene = scope Scene();

		// Added first, but ordered later.
		let late = scene.AddSystem<OrderedSystem>();
		late.Order = 10;
		late.Log = order;

		let early = scene.AddSystem<OrderedSystem>();
		early.Order = -5;
		early.Log = order;

		scene.Update(0.016f);

		Test.Assert(order.Count == 2);
		Test.Assert(order[0] == -5);
		Test.Assert(order[1] == 10);
	}

	/// A scene has no bus of its own: its run's is its bus, null outside every run, and the
	/// scene never drains it. Only the run does, at a point where nothing else is in flight,
	/// which is what makes a handler safe to run.
	[Test]
	public static void TheEventBusIsTheRunsNoneOutsideEveryRunAndNeverDrainedByTheScene()
	{
		let scene = scope Scene();
		Test.Assert(scene.Events == null, "outside every run: nothing to emit into");

		let run = scope RunBase("run");
		scene.SetRun(run);
		Test.Assert(scene.Events === run.Events);

		int fired = 0;
		delegate void(Variant) handler = scope [&](payload) => { fired++; };
		run.Events.Subscribe(StringHash("Ping"), handler);
		scene.Events.Publish(StringHash("Ping"), Variant());

		scene.Update(0.016f);
		Test.Assert(fired == 0, "the scene did not drain");
		Test.Assert(run.Events.PendingCount == 1, "still queued for the run");

		run.Events.Drain();
		Test.Assert(fired == 1);

		// Leaving the run leaves its bus.
		scene.SetRun(null);
		Test.Assert(scene.Events == null);
	}

	/// A system that owns level geometry: one floor quad at height nought, when the box
	/// reaches it.
	private class FloorSource : SceneSystem, IStaticGeometrySource
	{
		public override IStaticGeometrySource AsStaticGeometrySource => this;

		public void CollectStaticGeometry(Scene scene, AABB bounds, float detail, List<Float3> outTriangles)
		{
			if ((bounds.Min.Y > 0.0f) || (bounds.Max.Y < 0.0f))
				return;
			outTriangles.AddRange(scope Float3[](.(-1, 0, -1), .(-1, 0, 1), .(1, 0, 1), .(-1, 0, -1), .(1, 0, 1), .(1, 0, -1)));
		}
	}

	/// Navigation bakes from every system that answers AsStaticGeometrySource; the rest answer
	/// null.
	[Test]
	public static void ASystemWithStaticGeometryAnswersTheQueryAndOthersAnswerNull()
	{
		let scene = scope Scene("geometry");
		scene.AddSystem<HealthManager>();
		scene.AddSystem<FloorSource>();
		let triangles = scope List<Float3>();
		int sources = 0;
		let around = AABB(.(-5, -1, -5), .(5, 1, 5));
		for (let system in scene.Systems)
		{
			if (let source = system.AsStaticGeometrySource)
			{
				sources++;
				source.CollectStaticGeometry(scene, around, 0.3f, triangles);
			}
		}
		Test.Assert(sources == 1);
		Test.Assert(triangles.Count == 6);
	}

	/// On its first fixed step, destroys `Target` and notes whether it was still valid after.
	private class FixedDestroyer : SceneSystem
	{
		public EntityHandle Target = .Invalid;
		public bool ValidAfterAsk = false;

		public override void OnFixedUpdate(float fixedDeltaTime)
		{
			if (!Target.IsAssigned)
				return;
			Scene.DestroyEntity(Target);
			ValidAfterAsk = Scene.IsValid(Target);
			Target = .Invalid;
		}
	}

	/// The fixed step walks the scene as Update does, so what it destroys waits for the end of
	/// the steps.
	[Test]
	public static void ADestroyAskedInTheFixedStepWaitsForTheEndOfTheSteps()
	{
		let scene = scope Scene("fixed");
		let destroyer = scene.AddSystem<FixedDestroyer>();
		let entity = scene.CreateEntity("e");
		destroyer.Target = entity;
		scene.SetFixedTiming(0.25f, 4);
		Test.Assert(scene.AdvanceTime(0.5f) == 2);
		Test.Assert(destroyer.ValidAfterAsk, "the step still saw it");
		Test.Assert(!scene.IsValid(entity), "gone once the steps ended");
	}

	/// Destroying `Trigger` destroys `Also` from its hook, as a behaviour's onDestroy might, and
	/// notes whether `Trigger` was still alive when `Also`'s hooks ran.
	private class ChainDestroyer : SceneSystem
	{
		public EntityHandle Trigger = .Invalid;
		public EntityHandle Also = .Invalid;
		public int Seen = 0;
		public bool TriggerAliveAtAlso = false;

		public override void OnEntityDestroyed(EntityHandle entity)
		{
			Seen++;
			if (entity == Also)
				TriggerAliveAtAlso = Scene.IsValid(Trigger);
			if ((entity == Trigger) && Scene.IsValid(Also))
				Scene.DestroyEntity(Also);
		}
	}

	/// A destroy hook that destroys a sibling destroys it after the first is gone, never inside
	/// the first's destroy, and in the same call.
	[Test]
	public static void ADestroyHookThatDestroysASiblingDestroysItAfterTheFirst()
	{
		let scene = scope Scene("hooks");
		let chain = scene.AddSystem<ChainDestroyer>();
		let parent = scene.CreateEntity("parent");
		let first = scene.CreateEntity("first");
		let second = scene.CreateEntity("second");
		scene.SetParent(first, parent);
		scene.SetParent(second, parent);
		chain.Trigger = first;
		chain.Also = second;
		scene.DestroyEntity(first);
		Test.Assert(!scene.IsValid(first));
		Test.Assert(!scene.IsValid(second), "destroyed in the same call");
		Test.Assert(!chain.TriggerAliveAtAlso, "after the first was gone, not inside it");
		Test.Assert(scene.IsValid(parent));
		Test.Assert(chain.Seen == 2);
		let next = scene.CreateEntity("next"); // the free list is sound
		Test.Assert(scene.IsValid(next));
		Test.Assert(scene.EntityCount == 2);
	}

	/// While the scene's run defers its mutations, a destroy waits for the run's flush; a scene
	/// gone before the flush takes its queued destroy with it.
	[Test]
	public static void WhileTheRunDefersADestroyWaitsForItsFlushAndASceneGoneCancelsIt()
	{
		let run = scope RunBase("run");
		{
			let scene = scope Scene("deferred");
			scene.SetRun(run);
			let entity = scene.CreateEntity("e");
			run.Mutations.Enter();
			scene.DestroyEntity(entity);
			Test.Assert(scene.IsValid(entity), "waits while the run defers");
			run.Mutations.Leave();
			Test.Assert(scene.IsValid(entity), "and until the flush");
			run.Mutations.Flush();
			Test.Assert(!scene.IsValid(entity));
		}
		{
			let scene = new Scene("gone");
			scene.SetRun(run);
			let entity = scene.CreateEntity("e");
			run.Mutations.Enter();
			scene.DestroyEntity(entity);
			run.Mutations.Leave();
			Test.Assert(run.Mutations.PendingCount == 1);
			delete scene; // the scene goes before the flush
			Test.Assert(run.Mutations.PendingCount == 0);
			run.Mutations.Flush(); // nothing reaches the freed scene
		}
	}

	/// When `Trigger` is destroyed, moves `Away` to the roots and `Into` under `Parent`, as a
	/// behaviour's onDestroy might.
	private class Reparenter : SceneSystem
	{
		public EntityHandle Trigger = .Invalid;
		public EntityHandle Away = .Invalid;
		public EntityHandle Into = .Invalid;
		public EntityHandle Parent = .Invalid;

		public override void OnEntityDestroyed(EntityHandle entity)
		{
			if (!(entity == Trigger))
				return;
			Scene.SetParent(Away, .Invalid);
			Scene.SetParent(Into, Parent);
		}
	}

	/// A subtree's destroy follows the parent's children as its hooks move them: a sibling moved
	/// away stays, an entity moved in goes with the parent, and no link is left to a freed slot.
	[Test]
	public static void ASubtreesDestroyFollowsItsChildrenAsHooksMoveThem()
	{
		let scene = scope Scene("subtree");
		let hooks = scene.AddSystem<Reparenter>();
		let parent = scene.CreateEntity("parent");
		let first = scene.CreateEntity("first");
		let second = scene.CreateEntity("second");
		let outsider = scene.CreateEntity("outsider");
		scene.SetParent(first, parent);
		scene.SetParent(second, parent);
		hooks.Trigger = first;
		hooks.Away = second; // the sibling read before the first went, moved out
		hooks.Into = outsider; // moved in while the parent goes
		hooks.Parent = parent;
		scene.DestroyEntity(parent);
		Test.Assert(!scene.IsValid(parent));
		Test.Assert(!scene.IsValid(first));
		Test.Assert(scene.IsValid(second), "no longer a child when its turn would have come");
		Test.Assert(!scene.GetParent(second).IsAssigned);
		Test.Assert(!scene.IsValid(outsider), "a child by then: it went with the parent");
		Test.Assert(scene.EntityCount == 1);
		let next = scene.CreateEntity("next"); // the free list is sound
		let more = scene.CreateEntity("more");
		Test.Assert(!(next == more));
		Test.Assert(scene.EntityCount == 3);
	}

	/// During its update, removes `Target`'s Health and records what the pool shows after.
	private class Remover : SceneSystem
	{
		private Scene mScene = null;
		public HealthManager Health = null;
		public EntityHandle Target = .Invalid;
		public bool GiveBack = false;
		public bool Had = false;
		public bool HasAfter = true;
		public bool GetAfter = true;
		public int WalkedAfter = -1;
		public int DestroyedDuring = -1;

		public override void OnSceneCreate(Scene scene) => mScene = scene;

		public override void OnUpdate(ScenePhase phase, float deltaTime)
		{
			if ((phase != .Update) || !Target.IsAssigned)
				return;
			Had = mScene.RemoveComponent(Health, Target);
			HasAfter = Health.Has(Target);
			GetAfter = Health.Get(Target) != null;
			WalkedAfter = 0;
			Health.ForEach(scope [&] (component, owner) => { WalkedAfter++; });
			DestroyedDuring = Health.Destroyed;
			if (GiveBack)
				Health.Add(Target); // given back before it left
			Target = .Invalid;
		}
	}

	/// A component removed during a step is gone to every lookup at once, and leaves the pool,
	/// its hook told, at the step's end: swap-removed at once, it moved under whatever walked
	/// the pool.
	[Test]
	public static void AComponentRemovedDuringAStepLeavesThePoolAtTheStepsEnd()
	{
		let scene = scope Scene("leaving");
		let health = scene.AddSystem<HealthManager>();
		let remover = scene.AddSystem<Remover>();
		remover.Health = health;
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		health.Add(a).Value = 1.0f;
		health.Add(b).Value = 2.0f;
		remover.Target = a;
		scene.Update(1.0f / 60.0f);
		Test.Assert(remover.Had);
		Test.Assert(!remover.HasAfter);
		Test.Assert(!remover.GetAfter);
		Test.Assert(remover.WalkedAfter == 1, "the walk passes it by");
		Test.Assert(remover.DestroyedDuring == 0, "its hook waits for the step's end");
		Test.Assert(health.Destroyed == 1);
		Test.Assert(health.Count == 1);
		Test.Assert((health.Get(b) != null) && (health.Get(b).Value == 2.0f));

		// Outside a step it leaves at once.
		Test.Assert(scene.RemoveComponent(health, b));
		Test.Assert(health.Count == 0);
		Test.Assert(health.Destroyed == 2);
		Test.Assert(!scene.RemoveComponent(health, b), "none to take");
	}

	/// While its run defers (a physics contact handler, the network pump), a component removed
	/// is gone to every lookup at once and leaves the pool at the run's flush.
	[Test]
	public static void WhileItsRunDefersAComponentRemovedLeavesAtTheRunsFlush()
	{
		let run = scope RunBase("run");
		let scene = scope Scene("deferred");
		scene.SetRun(run);
		let health = scene.AddSystem<HealthManager>();
		let a = scene.CreateEntity("a");
		health.Add(a).Value = 1.0f;
		run.Mutations.Enter();
		Test.Assert(scene.RemoveComponent(health, a));
		Test.Assert(!health.HasComponent(a), "gone to every lookup at once");
		Test.Assert(health.Destroyed == 0, "its hook waits for the flush");
		run.Mutations.Leave();
		Test.Assert(health.Destroyed == 0, "and until the flush");
		run.Mutations.Flush();
		Test.Assert(health.Destroyed == 1);
		Test.Assert(health.Count == 0);
	}

	/// A component removed and given back within a step was never removed: its values kept, its
	/// hook never told.
	[Test]
	public static void AComponentRemovedAndGivenBackWithinAStepWasNeverRemoved()
	{
		let scene = scope Scene("given back");
		let health = scene.AddSystem<HealthManager>();
		let remover = scene.AddSystem<Remover>();
		remover.Health = health;
		let a = scene.CreateEntity("a");
		health.Add(a).Value = 7.0f;
		remover.Target = a;
		remover.GiveBack = true;
		scene.Update(1.0f / 60.0f);
		Test.Assert(health.Get(a) != null);
		Test.Assert(health.Get(a).Value == 7.0f, "its values kept");
		Test.Assert(health.Destroyed == 0, "never destroyed");
		Test.Assert(health.Count == 1);
	}

	/// Records what each fixed step says it is.
	private class StepRecorder : SceneSystem
	{
		public List<FixedStepFrame> Seen = new .() ~ delete _;

		public override void OnFixedUpdate(float fixedDeltaTime)
		{
			let step = FixedStepFrames.Current;
			Seen.Add((step != null) ? *step : FixedStepFrame(99, 99));
		}
	}

	[Test]
	public static void EachFixedStepSaysWhichOfItsFramesStepsItIsAndTheFramesSinceTheLast()
	{
		let scene = scope Scene("steps");
		let recorder = scene.AddSystem<StepRecorder>();
		scene.SetFixedTiming(1.0f / 60.0f, 4);
		scene.AdvanceTime(1.0f / 30.0f + 0.001f); // two steps
		scene.AdvanceTime(0.0f); // none
		scene.AdvanceTime(1.0f / 60.0f); // one, two frames after the last
		Test.Assert(recorder.Seen.Count == 3, scope $"{recorder.Seen.Count} steps");
		Test.Assert((recorder.Seen[0].Index == 0) && (recorder.Seen[0].FramesSinceLastStep == 1));
		Test.Assert(recorder.Seen[1].Index == 1);
		Test.Assert((recorder.Seen[2].Index == 0) && (recorder.Seen[2].FramesSinceLastStep == 2));
		Test.Assert(FixedStepFrames.Current == null, "only while a step runs");
	}
}
