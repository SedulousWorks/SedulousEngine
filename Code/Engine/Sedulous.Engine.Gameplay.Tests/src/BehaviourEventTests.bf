using System;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// Typed run events, direct (Emit) and queued (Post), the listeners a behaviour holds, and
/// queued calls on the scene's BehaviourSystem.
class BehaviourEventTests
{
	private const float cDt = 1.0f / 60.0f;

	// ---- GameEvents over a run ----

	/// Emit delivers inside the caller, to every listener of the type in subscription order,
	/// queueing nothing; a disposed subscription hears nothing more.
	[Test]
	public static void EmitDeliversNowInSubscriptionOrder()
	{
		let run = scope RunBase("events");
		let log = scope String();
		var first = GameEvents.Listen<DoorOpened>(run, new [=log] (evt) => { log.AppendF("1:{} ", evt.Door); });
		var second = GameEvents.Listen<DoorOpened>(run, new [=log] (evt) => { log.AppendF("2:{} ", evt.Door); });
		defer { first.Dispose(); second.Dispose(); }
		Test.Assert(first.IsSubscribed && second.IsSubscribed);

		GameEvents.Emit(run, DoorOpened(7));
		Test.Assert(log == "1:7 2:7 ", log);
		Test.Assert(run.Events.PendingCount == 0, "nothing queued");

		first.Dispose();
		GameEvents.Emit(run, DoorOpened(8));
		Test.Assert(log == "1:7 2:7 2:8 ", log);
	}

	/// Post queues for the run's drain, a small payload and one larger than a Variant holds
	/// both arriving whole.
	[Test]
	public static void PostDeliversAtTheDrainNotBefore()
	{
		let run = scope RunBase("events");
		let scene = scope Scene();
		let coinBy = scene.CreateEntity("coin");
		let log = scope String();
		var coins = GameEvents.Listen<CoinTaken>(run, new [=log, =coinBy] (evt) =>
			{
				log.AppendF("coin:{}:{}:{} ", evt.Points, (evt.By == coinBy) ? "by" : "?", (int)evt.At.Y);
			});
		var doors = GameEvents.Listen<DoorOpened>(run, new [=log] (evt) => { log.AppendF("door:{} ", evt.Door); });
		defer { coins.Dispose(); doors.Dispose(); }

		GameEvents.Post(run, CoinTaken(5, coinBy, .(1.0f, 2.0f, 3.0f)));
		GameEvents.Post(run, DoorOpened(2));
		Test.Assert(log.IsEmpty, "a post waits for the drain");
		Test.Assert(run.Events.PendingCount == 2);

		run.Events.Drain();
		Test.Assert(log == "coin:5:by:2 door:2 ", log);
		Test.Assert(run.Events.PendingCount == 0);
	}

	/// What a listener posts during the drain waits for the next one, so a listener that
	/// posts its own event cannot keep a drain going.
	[Test]
	public static void APostDuringTheDrainWaitsForTheNext()
	{
		let run = scope RunBase("events");
		int heard = 0;
		var subscription = GameEvents.Listen<DoorOpened>(run, new [&] (evt) =>
			{
				heard++;
				GameEvents.Post(run, DoorOpened(evt.Door + 1));
			});
		defer subscription.Dispose();

		GameEvents.Post(run, DoorOpened(1));
		run.Events.Drain();
		Test.Assert(heard == 1, "one per drain");
		run.Events.Drain();
		Test.Assert(heard == 2);
		Test.Assert(run.Events.PendingCount == 1, "the next one waits");
	}

	/// Two event types do not cross, and a payload of another type under the same key is not
	/// misread.
	[Test]
	public static void TwoEventTypesDoNotCross()
	{
		let run = scope RunBase("events");
		let log = scope String();
		var doors = GameEvents.Listen<DoorOpened>(run, new [=log] (evt) => { log.Append("door "); });
		var coins = GameEvents.Listen<CoinTaken>(run, new [=log] (evt) => { log.Append("coin "); });
		defer { doors.Dispose(); coins.Dispose(); }
		Test.Assert(!(GameEvents.KeyOf<DoorOpened>() == GameEvents.KeyOf<CoinTaken>()));

		GameEvents.Emit(run, DoorOpened(1));
		Test.Assert(log == "door ", log);
		GameEvents.Post(run, CoinTaken(1, .Invalid, .(0.0f, 0.0f, 0.0f)));
		run.Events.Drain();
		Test.Assert(log == "door coin ", log);

		run.Events.Send(GameEvents.KeyOf<DoorOpened>(), Variant.Create<float>(1.5f));
		Test.Assert(log == "door coin ", "another type under the key is not read");
	}

	/// Without a run nothing is subscribed, the handler is deleted (ASan checks), and Emit and
	/// Post do nothing.
	[Test]
	public static void WithoutARunNothingIsSubscribed()
	{
		int heard = 0;
		var subscription = GameEvents.Listen<DoorOpened>(null, new [&] (evt) => { heard++; });
		Test.Assert(!subscription.IsSubscribed);
		subscription.Dispose();
		GameEvents.Emit<DoorOpened>(null, DoorOpened(1));
		GameEvents.Post<DoorOpened>(null, DoorOpened(1));
		Test.Assert(heard == 0);
	}

	// ---- a behaviour's listeners ----

	/// Every listening behaviour hears an emit at once, the emitter itself included; one on an
	/// inactive entity hears nothing until it is active again.
	[Test]
	public static void EveryTickingListenerHearsAnEmit()
	{
		LifecycleLog.Text.Clear();
		let run = scope RunBase("events");
		let scene = scope Scene();
		scene.SetRun(run);
		scene.AddSystem<BehaviourSystem>();
		let collectors = scene.AddSystem<BehaviourManager<Collector>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let emitter = collectors.Add(a);
		collectors.Add(b);
		scene.Update(cDt);
		Test.Assert(emitter.Listening);
		Test.Assert(run.Events.SubscriberCount == 4, "two types for each");

		emitter.Emit(CoinTaken(3, a, .(0.0f, 0.0f, 0.0f)));
		Test.Assert(LifecycleLog.Text == "C:a.Coin3 C:b.Coin3 ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		scene.SetActive(b, false);
		emitter.Emit(CoinTaken(3, a, .(0.0f, 0.0f, 0.0f)));
		scene.Update(cDt);
		emitter.Post(DoorOpened(4));
		run.Events.Drain();
		Test.Assert(LifecycleLog.Text == "C:a.Coin3 C:a.Door4 ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		scene.SetActive(b, true);
		scene.Update(cDt);
		emitter.Emit(CoinTaken(1, a, .(0.0f, 0.0f, 0.0f)));
		Test.Assert(LifecycleLog.Text == "C:a.Coin1 C:b.Coin1 ", LifecycleLog.Text);
		Test.Assert((emitter.Score == 7) && (collectors.Get(b).Score == 4));
	}

	/// A behaviour's subscriptions end as it is removed, as its entity is destroyed and as its
	/// scene is torn down: nothing reaches it after, and nothing is left on the run's bus.
	[Test]
	public static void ListenersEndWithTheirBehaviour()
	{
		LifecycleLog.Text.Clear();
		let run = scope RunBase("events");
		{
			let scene = scope Scene();
			scene.SetRun(run);
			scene.AddSystem<BehaviourSystem>();
			let collectors = scene.AddSystem<BehaviourManager<Collector>>();
			let a = scene.CreateEntity("a");
			let b = scene.CreateEntity("b");
			let c = scene.CreateEntity("c");
			collectors.Add(a);
			collectors.Add(b);
			collectors.Add(c);
			scene.Update(cDt);
			Test.Assert(run.Events.SubscriberCount == 6);

			collectors.RemoveComponent(a);
			Test.Assert(run.Events.SubscriberCount == 4, "removed");
			// Outside Update a destroy is at once.
			scene.DestroyEntity(b);
			Test.Assert(run.Events.SubscriberCount == 2, "destroyed");

			GameEvents.Emit(run, CoinTaken(1, .Invalid, .(0.0f, 0.0f, 0.0f)));
			Test.Assert(LifecycleLog.Text == "C:c.Coin1 ", LifecycleLog.Text);
		}
		Test.Assert(run.Events.SubscriberCount == 0, "torn down");

		LifecycleLog.Text.Clear();
		GameEvents.Emit(run, CoinTaken(1, .Invalid, .(0.0f, 0.0f, 0.0f)));
		Test.Assert(LifecycleLog.Text.IsEmpty, LifecycleLog.Text);
	}

	/// A handler that destroys its own entity, outside any pass, returns into a live instance
	/// (deleted once it is done), and the listeners after it still hear the event: emitted,
	/// and posted to the run's drain.
	[Test]
	public static void AHandlerMayDestroyItsOwnEntity()
	{
		LifecycleLog.Text.Clear();
		let run = scope RunBase("events");
		let scene = scope Scene();
		scene.SetRun(run);
		scene.AddSystem<BehaviourSystem>();
		let collectors = scene.AddSystem<BehaviourManager<Collector>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let c = scene.CreateEntity("c");
		collectors.Add(a);
		collectors.Add(b);
		collectors.Add(c);
		scene.Update(cDt);

		int32 scoreAfter = 0;
		bool detachedAfter = false;
		delegate void(Collector collector, CoinTaken evt) hook = scope [&] (collector, evt) =>
		{
			if (collector.Entity != evt.By)
				return;
			scene.DestroyEntity(collector.Entity);
			// Its own state, read after its destruction: still alive.
			scoreAfter = collector.Score;
			detachedAfter = collector.Scene == null;
		};
		Collector.CoinHook = hook;
		defer { Collector.CoinHook = null; }

		GameEvents.Emit(run, CoinTaken(2, a, .(0.0f, 0.0f, 0.0f)));
		Test.Assert(LifecycleLog.Text == "C:a.Coin2 C:b.Coin2 C:c.Coin2 ", LifecycleLog.Text);
		Test.Assert((scoreAfter == 2) && detachedAfter);
		Test.Assert((collectors.Count == 2) && (run.Events.SubscriberCount == 4));

		LifecycleLog.Text.Clear();
		GameEvents.Post(run, CoinTaken(5, b, .(0.0f, 0.0f, 0.0f)));
		run.Events.Drain();
		Test.Assert(LifecycleLog.Text == "C:b.Coin5 C:c.Coin5 ", LifecycleLog.Text);
		Test.Assert((scoreAfter == 7) && (collectors.Count == 1) && (run.Events.SubscriberCount == 2));
	}

	/// Outside a run a behaviour's Listen answers false and deletes its handler (ASan checks).
	[Test]
	public static void ABehaviourOutsideARunListensToNothing()
	{
		let scene = scope Scene();
		scene.AddSystem<BehaviourSystem>();
		let collector = scene.AddSystem<BehaviourManager<Collector>>().Add(scene.CreateEntity("a"));
		scene.Update(cDt);
		Test.Assert(!collector.Listening);
	}

	// ---- queued calls ----

	/// Queued calls run at the end of the tick, after the updates and before the late tick, in
	/// the order queued; one bound to a behaviour released since does not run.
	[Test]
	public static void AQueuedCallRunsAtTheDrainUnlessItsBehaviourWent()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		walkers.Add(a);
		walkers.Add(b);
		scene.Update(cDt);

		Test.Assert(walkers.Get(a).Post(new () => { LifecycleLog.Text.Append("call:a "); }));
		system.Post(new () => { LifecycleLog.Text.Append("call:unbound "); });
		Test.Assert(walkers.Get(b).Post(new () => { LifecycleLog.Text.Append("call:b "); }));
		Test.Assert(system.PendingCallCount == 3);

		LifecycleLog.Text.Clear();
		walkers.RemoveComponent(b);
		Test.Assert(LifecycleLog.Text == "W:b.Disable W:b.Destroy ", "not run by the release");

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:a.Update call:a call:unbound W:a.Late ", LifecycleLog.Text);
		Test.Assert(system.PendingCallCount == 0);
	}

	/// A call queued by a call waits for the next drain; a call that releases its own
	/// behaviour finishes, and the behaviour's later calls in the same drain do not run. A
	/// stopped scene drops what is queued (ASan checks the delete).
	[Test]
	public static void ACallQueuedDuringTheDrainWaitsForTheNext()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let walkers = scene.AddSystem<BehaviourManager<Walker>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		walkers.Add(a);
		walkers.Add(b);
		scene.Update(cDt);

		walkers.Get(a).Post(new [=system] () =>
			{
				LifecycleLog.Text.Append("first ");
				system.Post(new () => { LifecycleLog.Text.Append("second "); });
			});
		walkers.Get(b).Post(new [=walkers, =b] () =>
			{
				walkers.RemoveComponent(b);
				LifecycleLog.Text.Append("gone ");
			});
		walkers.Get(b).Post(new () => { LifecycleLog.Text.Append("never "); });

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:a.Update W:b.Update first W:b.Disable W:b.Destroy gone W:a.Late ", LifecycleLog.Text);
		Test.Assert(system.PendingCallCount == 1);

		LifecycleLog.Text.Clear();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "W:a.Update second W:a.Late ", LifecycleLog.Text);

		scene.Start();
		walkers.Get(a).Post(new () => { LifecycleLog.Text.Append("stopped "); });
		scene.Stop();
		Test.Assert(system.PendingCallCount == 0);
		Test.Assert(walkers.Get(a).mQueuedCalls == 0);
	}
}
