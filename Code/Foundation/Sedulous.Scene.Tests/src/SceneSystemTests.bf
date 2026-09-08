using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Messaging;
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

	/// The scene's bus is BORROWED and the scene never drains it. Only the owning scope
	/// does, at a point where nothing else is in flight, which is what makes a handler safe
	/// to run.
	[Test]
	public static void TheEventBusIsBorrowedAndNeverDrainedByTheScene()
	{
		let scene = scope Scene();
		Test.Assert(scene.Events == null, "unwired: nothing to emit into");

		let bus = scope EventBus();
		scene.SetEventBus(bus);
		Test.Assert(scene.Events === bus);

		int fired = 0;
		delegate void(Variant) handler = scope [&](payload) => { fired++; };
		bus.Subscribe(StringHash("Ping"), handler);
		scene.Events.Publish(StringHash("Ping"), Variant());

		scene.Update(0.016f);
		Test.Assert(fired == 0, "the scene did not drain");
		Test.Assert(bus.PendingCount == 1, "still queued for the owning scope");

		bus.Drain();
		Test.Assert(fired == 1);

		// Tearing the scope down detaches cleanly.
		scene.SetEventBus(null);
		Test.Assert(scene.Events == null);
	}
}
