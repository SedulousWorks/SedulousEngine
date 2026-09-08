using System;
using Sedulous.Core;
using Sedulous.Messaging;

namespace Sedulous.Messaging.Tests;

/// The bus's whole contract: delivery is deferred, order is subscription order, and a
/// cascade is bounded.
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
}
