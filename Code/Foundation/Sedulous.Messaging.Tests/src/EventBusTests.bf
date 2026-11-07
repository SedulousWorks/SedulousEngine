using System;
using Sedulous.Core;
using Sedulous.Messaging;

namespace Sedulous.Messaging.Tests;

/// The bus's whole contract: delivery is deferred (or, sent, at once), order is subscription
/// order, a cascade is bounded, a post waits for the next drain, and a subscription may end
/// mid delivery.
class EventBusTests
{
	/// Publishing does NOT deliver. That is the point: a handler runs at the top of a
	/// scope's tick with nothing else in flight, never inside whatever emitted.
	[Test]
	public static void PublishIsDeferredAndDrainDelivers()
	{
		let bus = scope EventBus();

		double got = 0.0;
		int calls = 0;
		delegate void(Variant) handler = scope [&](payload) =>
		{
			calls++;
			got = payload.Get<double>();
		};
		bus.Subscribe(StringHash("score"), handler);

		bus.Publish(StringHash("score"), Variant.Create<double>(7.0));
		Test.Assert(calls == 0, "nothing fires until the drain");
		Test.Assert(bus.PendingCount == 1);

		bus.Drain();
		Test.Assert(calls == 1);
		Test.Assert(got == 7.0);
		Test.Assert(bus.PendingCount == 0);
	}

	/// A subscriber hears only its own event, subscribers fire in the order they
	/// subscribed, and unsubscribing actually stops delivery.
	[Test]
	public static void NamesFilterAndOrderIsSubscriptionOrder()
	{
		let bus = scope EventBus();
		let order = scope String();

		delegate void(Variant) first = scope [&](payload) => { order.Append("1"); };
		delegate void(Variant) second = scope [&](payload) => { order.Append("2"); };
		delegate void(Variant) other = scope [&](payload) => { order.Append("B"); };
		bus.Subscribe(StringHash("A"), first);
		bus.Subscribe(StringHash("A"), second);
		let handleB = bus.Subscribe(StringHash("B"), other);

		bus.Publish(StringHash("A"), Variant());
		bus.Drain();
		Test.Assert(order == "12", "both A subscribers in order, and never B");

		bus.Unsubscribe(handleB);
		bus.Publish(StringHash("B"), Variant());
		bus.Drain();
		Test.Assert(order == "12", "an unsubscribed handler is not delivered to");
	}

	/// A handler's own publish lands in the SAME drain rather than waiting a frame: a
	/// chain of events settles within the tick that started it.
	[Test]
	public static void AHandlersEmitCascadesInTheSameDrain()
	{
		let bus = scope EventBus();
		int aCalls = 0;
		int bCalls = 0;

		delegate void(Variant) onA = scope [&](payload) =>
		{
			aCalls++;
			bus.Publish(StringHash("B"), Variant());
		};
		delegate void(Variant) onB = scope [&](payload) => { bCalls++; };
		bus.Subscribe(StringHash("A"), onA);
		bus.Subscribe(StringHash("B"), onB);

		bus.Publish(StringHash("A"), Variant());
		bus.Drain();
		Test.Assert(aCalls == 1);
		Test.Assert(bCalls == 1, "delivered in this drain, not the next frame's");
	}

	/// A handler that re-emits its own event forever must not hang the tick. The drain
	/// stops at the pass cap and says so, which is recoverable; spinning is not.
	[Test]
	public static void ARunawayEmitIsBounded()
	{
		let bus = scope EventBus();
		int calls = 0;

		delegate void(Variant) onLoop = scope [&](payload) =>
		{
			calls++;
			bus.Publish(StringHash("loop"), Variant());
		};
		bus.Subscribe(StringHash("loop"), onLoop);

		bus.Publish(StringHash("loop"), Variant());
		bus.Drain();

		Test.Assert(calls >= 1);
		Test.Assert(calls <= (int)EventBus.cMaxDrainPasses, "capped, not infinite");
	}

	/// Clearing a scope drops its subscribers AND whatever was still queued, so a torn
	/// down scope delivers nothing afterwards.
	[Test]
	public static void ClearDropsSubscribersAndPendingEvents()
	{
		let bus = scope EventBus();
		int calls = 0;
		delegate void(Variant) handler = scope [&](payload) => { calls++; };
		bus.Subscribe(StringHash("A"), handler);
		bus.Publish(StringHash("A"), Variant());

		Test.Assert(bus.SubscriberCount == 1);
		Test.Assert(bus.PendingCount == 1);

		bus.Clear();
		Test.Assert(bus.SubscriberCount == 0);
		Test.Assert(bus.PendingCount == 0);

		bus.Drain();
		Test.Assert(calls == 0);
	}

	/// A handler that unsubscribes itself, handing its callback to the bus, stays alive for its
	/// call, and the subscriber after it still hears the event.
	[Test]
	public static void AHandlerThatUnsubscribesItselfStaysAliveForItsCallAndTheNextStillHears()
	{
		let bus = scope EventBus();
		let order = scope String();
		uint32 self = 0;
		let tag = new String("1");
		delegate void(Variant) first = new [=bus, &self, =order, =tag] (payload) =>
			{
				bus.Unsubscribe(self, true); // deleted by the bus once it has returned
				order.Append(tag); // its captures are still there after the unsubscribe
			} ~ delete tag;
		self = bus.Subscribe(StringHash("A"), first);
		bus.Subscribe(StringHash("A"), scope [&] (payload) => { order.Append("2"); });
		bus.Publish(StringHash("A"), Variant());
		bus.Publish(StringHash("A"), Variant());
		bus.Drain();
		Test.Assert(order == "122", order); // the second event no longer reaches the first
		Test.Assert(bus.SubscriberCount == 1);
	}

	/// A subscription made by a handler joins after that event; many at once move nothing that
	/// runs.
	[Test]
	public static void ASubscriptionMadeByAHandlerJoinsAfterThatEvent()
	{
		let bus = scope EventBus();
		int late = 0;
		let order = scope String();
		delegate void(Variant) lateHandler = scope [&] (payload) => { late++; };
		bus.Subscribe(StringHash("A"), scope [&] (payload) =>
			{
				for (int i < 64) // enough to grow the list many times over
					bus.Subscribe(StringHash("A"), lateHandler);
				order.Append("a");
			});
		bus.Publish(StringHash("A"), Variant());
		bus.Publish(StringHash("A"), Variant());
		bus.Drain();
		Test.Assert(order == "aa", order);
		Test.Assert(late == 64, "the first event's 64 hear the second; none hears the event it was made in");
		Test.Assert(bus.SubscriberCount == 129);
	}

	/// Clear from a handler stops every delivery; a Drain from a handler leaves the events to
	/// the one running.
	[Test]
	public static void ClearFromAHandlerStopsEveryDeliveryANestedDrainDoesNothing()
	{
		let bus = scope EventBus();
		let order = scope String();
		bus.Subscribe(StringHash("A"), scope [&] (payload) =>
			{
				bus.Publish(StringHash("B"), Variant());
				bus.Drain(); // nested: does nothing; B goes in the next pass
				order.Append("A");
			});
		bus.Subscribe(StringHash("B"), scope [&] (payload) => { order.Append("B"); });
		bus.Publish(StringHash("A"), Variant());
		bus.Drain();
		Test.Assert(order == "AB", order);

		let closing = scope EventBus();
		int after = 0;
		closing.Subscribe(StringHash("A"), scope [&] (payload) => { closing.Clear(); });
		closing.Subscribe(StringHash("A"), scope [&] (payload) => { after++; });
		closing.Publish(StringHash("A"), Variant());
		closing.Drain();
		Test.Assert(after == 0);
		Test.Assert(closing.SubscriberCount == 0);
	}

	/// Send delivers inside the caller, in subscription order, without queueing, and leaves
	/// the payload the caller's: one referencing the caller's own value is fine.
	[Test]
	public static void SendDeliversNowAndBorrowsThePayload()
	{
		let bus = scope EventBus();
		let order = scope String();
		delegate void(Variant) first = scope [&](payload) => { order.AppendF("1:{} ", payload.Get<int64>()); };
		delegate void(Variant) second = scope [&](payload) => { order.AppendF("2:{} ", payload.Get<int64>()); };
		bus.Subscribe(StringHash("A"), first);
		bus.Subscribe(StringHash("A"), second);

		int64 value = 42;
		bus.Send(StringHash("A"), Variant.Create<int64>(ref value));
		Test.Assert(order == "1:42 2:42 ", order);
		Test.Assert(bus.PendingCount == 0, "nothing queued");
	}

	/// What a handler posts during a drain waits for the next drain, where a publish would
	/// cascade into this one.
	[Test]
	public static void APostDuringADrainWaitsForTheNext()
	{
		let bus = scope EventBus();
		int aCalls = 0;
		int bCalls = 0;
		delegate void(Variant) onA = scope [&](payload) =>
		{
			aCalls++;
			bus.Post(StringHash("B"), Variant());
		};
		delegate void(Variant) onB = scope [&](payload) => { bCalls++; };
		bus.Subscribe(StringHash("A"), onA);
		bus.Subscribe(StringHash("B"), onB);

		bus.Post(StringHash("A"), Variant());
		Test.Assert(aCalls == 0, "a post is queued");
		bus.Drain();
		Test.Assert((aCalls == 1) && (bCalls == 0), "the handler's post waits");
		Test.Assert(bus.PendingCount == 1);
		bus.Drain();
		Test.Assert(bCalls == 1, "and is delivered by the next drain");
		Test.Assert(bus.PendingCount == 0);
	}

	/// A handler that ends its own subscription, and an earlier one's, mid delivery: the
	/// subscribers after it are still reached once each, the ended ones not again, and an
	/// owned callback outlives its own call (ASan would see it otherwise).
	[Test]
	public static void ASubscriptionMayEndMidDelivery()
	{
		let bus = scope EventBus();
		let order = scope String();
		uint32 firstHandle = 0;
		uint32 selfHandle = 0;
		delegate void(Variant) first = scope [&](payload) => { order.Append("1"); };
		firstHandle = bus.Subscribe(StringHash("A"), first);
		selfHandle = bus.SubscribeOwned(StringHash("A"), new [&](payload) =>
			{
				order.Append("S");
				bus.Unsubscribe(firstHandle);
				bus.Unsubscribe(selfHandle);
				order.Append("s");
			});
		delegate void(Variant) last = scope [&](payload) => { order.Append("3"); };
		bus.Subscribe(StringHash("A"), last);
		Test.Assert(bus.SubscriberCount == 3);

		int64 value = 1;
		bus.Send(StringHash("A"), Variant.Create<int64>(ref value));
		Test.Assert(order == "1Ss3", order);
		Test.Assert(bus.SubscriberCount == 1);

		order.Clear();
		bus.Publish(StringHash("A"), Variant());
		bus.Drain();
		Test.Assert(order == "3", order);
	}

	/// An owned callback goes with its subscription, with a clear, and with the bus (ASan
	/// checks the leaks).
	[Test]
	public static void AnOwnedCallbackIsDeletedByTheBus()
	{
		let bus = scope EventBus();
		int calls = 0;
		let handle = bus.SubscribeOwned(StringHash("A"), new [&](payload) => { calls++; });
		bus.SubscribeOwned(StringHash("A"), new [&](payload) => { calls++; });
		bus.Publish(StringHash("A"), Variant());
		bus.Drain();
		Test.Assert(calls == 2);

		bus.Unsubscribe(handle);
		Test.Assert(bus.SubscriberCount == 1);
		bus.Clear();
		Test.Assert(bus.SubscriberCount == 0);

		bus.SubscribeOwned(StringHash("A"), new [&](payload) => { calls++; });
	}
}
