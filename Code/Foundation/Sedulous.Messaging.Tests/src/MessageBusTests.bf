namespace Sedulous.Messaging.Tests;

using System;
using System.Collections;
using Sedulous.Messaging;

// ==================== Test message types ====================

struct TestMessage : IMessage
{
	public int32 Value;
	public void Dispose() mut { }
}

struct OtherMessage : IMessage
{
	public float X;
	public float Y;
	public void Dispose() mut { }
}

struct OwnedStringMessage : IMessage
{
	public String Text;
	public void Dispose() mut
	{
		delete Text;
		Text = null;
	}
}

// ==================== Tests ====================

class MessageBusTests
{
	[Test]
	public static void Publish_DeliversToSubscriber()
	{
		let bus = scope DefaultMessageBus();
		int32 received = 0;

		var handle = bus.Subscribe<TestMessage>(new [&received](msg) =>
			{
				received = msg.Value;
			});

		TestMessage msg = .() { Value = 42 };
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(received == 42);

		bus.Unsubscribe(handle);
	}

	[Test]
	public static void Publish_DeliversToMultipleSubscribers()
	{
		let bus = scope DefaultMessageBus();
		int32 count = 0;

		var h1 = bus.Subscribe<TestMessage>(new [&count](msg) => { count++; });
		var h2 = bus.Subscribe<TestMessage>(new [&count](msg) => { count++; });

		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(count == 2);

		bus.Unsubscribe(h1);
		bus.Unsubscribe(h2);
	}

	[Test]
	public static void Publish_NoSubscribers_NoError()
	{
		let bus = scope DefaultMessageBus();
		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);
	}

	[Test]
	public static void Unsubscribe_StopsDelivery()
	{
		let bus = scope DefaultMessageBus();
		int32 count = 0;

		var handle = bus.Subscribe<TestMessage>(new [&count](msg) => { count++; });

		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(count == 1);

		bus.Unsubscribe(handle);

		bus.Publish<TestMessage>(ref msg);
		Test.Assert(count == 1);
	}

	[Test]
	public static void Unsubscribe_DuringDispatch_Safe()
	{
		let bus = scope DefaultMessageBus();
		int32 count = 0;
		SubscriptionHandle selfHandle = default;

		selfHandle = bus.Subscribe<TestMessage>(new [&count, &selfHandle, =bus](msg) =>
			{
				count++;
				bus.Unsubscribe(selfHandle);
			});

		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(count == 1);

		// Second publish should NOT reach the handler
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(count == 1);
	}

	[Test]
	public static void Subscribe_DuringDispatch_NotCalledForCurrentMessage()
	{
		let bus = scope DefaultMessageBus();
		int32 lateCount = 0;
		SubscriptionHandle lateHandle = default;

		var h1 = bus.Subscribe<TestMessage>(new [&lateCount, &lateHandle, =bus](msg) =>
			{
				lateHandle = bus.Subscribe<TestMessage>(new [&lateCount](msg2) =>
					{
						lateCount++;
					});
			});

		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(lateCount == 0); // late subscriber not called for this publish

		bus.Publish<TestMessage>(ref msg);
		Test.Assert(lateCount == 1); // now it's called

		bus.Unsubscribe(h1);
		bus.Unsubscribe(lateHandle);
	}

	[Test]
	public static void Queue_And_Drain()
	{
		let bus = scope DefaultMessageBus();
		int32 received = 0;

		var handle = bus.Subscribe<TestMessage>(new [&received](msg) =>
			{
				received = msg.Value;
			});

		TestMessage msg = .() { Value = 99 };
		bus.Queue<TestMessage>(msg);
		Test.Assert(received == 0);

		bus.Drain();
		Test.Assert(received == 99);

		bus.Unsubscribe(handle);
	}

	[Test]
	public static void Drain_Empty_IsNoOp()
	{
		let bus = scope DefaultMessageBus();
		bus.Drain();
		bus.Drain();
	}

	[Test]
	public static void Drain_QueueDuringDrain_DeferredToNextDrain()
	{
		let bus = scope DefaultMessageBus();
		List<int32> order = scope .();

		var handle = bus.Subscribe<TestMessage>(new [&order, =bus](msg) =>
			{
				order.Add(msg.Value);
				if (msg.Value == 1)
				{
					TestMessage followUp = .() { Value = 2 };
					bus.Queue<TestMessage>(followUp);
				}
			});

		TestMessage msg = .() { Value = 1 };
		bus.Queue<TestMessage>(msg);

		bus.Drain();
		Test.Assert(order.Count == 1);
		Test.Assert(order[0] == 1);

		bus.Drain();
		Test.Assert(order.Count == 2);
		Test.Assert(order[1] == 2);

		bus.Unsubscribe(handle);
	}

	[Test]
	public static void DifferentMessageTypes_Independent()
	{
		let bus = scope DefaultMessageBus();
		int32 testCount = 0;
		float otherX = 0;

		var h1 = bus.Subscribe<TestMessage>(new [&testCount](msg) => { testCount++; });
		var h2 = bus.Subscribe<OtherMessage>(new [&otherX](msg) => { otherX = msg.X; });

		TestMessage tm = .() { Value = 1 };
		bus.Publish<TestMessage>(ref tm);
		Test.Assert(testCount == 1);
		Test.Assert(otherX == 0);

		OtherMessage om = .() { X = 3.14f, Y = 2.71f };
		bus.Publish<OtherMessage>(ref om);
		Test.Assert(testCount == 1);
		Test.Assert(otherX == 3.14f);

		bus.Unsubscribe(h1);
		bus.Unsubscribe(h2);
	}

	[Test]
	public static void SubscriptionHandle_Dispose_AutoUnsubscribes()
	{
		let bus = scope DefaultMessageBus();
		int32 count = 0;

		var handle = bus.Subscribe<TestMessage>(new [&count](msg) => { count++; });

		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(count == 1);

		handle.Dispose();

		TestMessage msg2 = .() { Value = 2 };
		bus.Publish<TestMessage>(ref msg2);
		Test.Assert(count == 1);
	}

	[Test]
	public static void Publish_Reentrant_SameType()
	{
		let bus = scope DefaultMessageBus();
		List<int32> order = scope .();

		var handle = bus.Subscribe<TestMessage>(new [&order, =bus](msg) =>
			{
				order.Add(msg.Value);
				if (msg.Value == 1)
				{
					TestMessage inner = .() { Value = 2 };
					bus.Publish<TestMessage>(ref inner);
				}
			});

		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);

		// Outer dispatch calls handler(1), which re-entrantly publishes(2),
		// inner dispatch calls handler(2). Result: [1, 2].
		Test.Assert(order.Count == 2);
		Test.Assert(order[0] == 1);
		Test.Assert(order[1] == 2);

		bus.Unsubscribe(handle);
	}

	[Test]
	public static void DoubleUnsubscribe_Safe()
	{
		let bus = scope DefaultMessageBus();
		var handle = bus.Subscribe<TestMessage>(new (msg) => { });
		bus.Unsubscribe(handle);
		bus.Unsubscribe(handle); // second call is no-op
	}

	[Test]
	public static void Queue_MultipleMessages_AllDispatched()
	{
		let bus = scope DefaultMessageBus();
		List<int32> received = scope .();

		var handle = bus.Subscribe<TestMessage>(new [&received](msg) =>
			{
				received.Add(msg.Value);
			});

		bus.Queue<TestMessage>(.() { Value = 10 });
		bus.Queue<TestMessage>(.() { Value = 20 });
		bus.Queue<TestMessage>(.() { Value = 30 });

		bus.Drain();

		Test.Assert(received.Count == 3);
		Test.Assert(received[0] == 10);
		Test.Assert(received[1] == 20);
		Test.Assert(received[2] == 30);

		bus.Unsubscribe(handle);
	}

	[Test]
	public static void Unsubscribe_OtherHandler_DuringDispatch_Safe()
	{
		let bus = scope DefaultMessageBus();
		List<int32> order = scope .();
		SubscriptionHandle h2 = default;

		var h1 = bus.Subscribe<TestMessage>(new [&order, &h2, =bus](msg) =>
			{
				order.Add(1);
				bus.Unsubscribe(h2); // remove the second handler mid-dispatch
			});

		h2 = bus.Subscribe<TestMessage>(new [&order](msg) =>
			{
				order.Add(2);
			});

		TestMessage msg = .() { Value = 1 };
		bus.Publish<TestMessage>(ref msg);

		// h2 was nulled during dispatch so it should not fire
		Test.Assert(order.Count == 1);
		Test.Assert(order[0] == 1);

		// Confirm h2 stays removed on next publish
		order.Clear();
		bus.Publish<TestMessage>(ref msg);
		Test.Assert(order.Count == 1);
		Test.Assert(order[0] == 1);

		bus.Unsubscribe(h1);
	}

	[Test]
	public static void Queue_NoSubscribers_DoesNotCrash()
	{
		let bus = scope DefaultMessageBus();

		bus.Queue<TestMessage>(.() { Value = 42 });
		bus.Drain(); // no subscribers - should not crash
	}

	[Test]
	public static void Queue_OwnedStringMessage_DisposedAfterDrain()
	{
		let bus = scope DefaultMessageBus();
		bool handlerCalled = false;

		var handle = bus.Subscribe<OwnedStringMessage>(new [&handlerCalled](msg) =>
			{
				// Verify we can read the message data during dispatch
				Test.Assert(msg.Text != null);
				Test.Assert(msg.Text.Length > 0);
				handlerCalled = true;
			});

		bus.Queue<OwnedStringMessage>(.() { Text = new String("hello") });

		bus.Drain();
		Test.Assert(handlerCalled);

		// After drain, the String owned by the message has been deleted
		// via IMessage.Dispose(). No leak, no crash.

		bus.Unsubscribe(handle);
	}

	[Test]
	public static void Publish_CrossType_DuringDispatch()
	{
		let bus = scope DefaultMessageBus();
		int32 testReceived = 0;
		float otherReceived = 0;

		var h1 = bus.Subscribe<TestMessage>(new [&testReceived, =bus](msg) =>
			{
				testReceived = msg.Value;
				// Cross-type publish from inside a handler
				OtherMessage om = .() { X = 7.5f, Y = 0 };
				bus.Publish<OtherMessage>(ref om);
			});

		var h2 = bus.Subscribe<OtherMessage>(new [&otherReceived](msg) =>
			{
				otherReceived = msg.X;
			});

		TestMessage tm = .() { Value = 10 };
		bus.Publish<TestMessage>(ref tm);

		Test.Assert(testReceived == 10);
		Test.Assert(otherReceived == 7.5f);

		bus.Unsubscribe(h1);
		bus.Unsubscribe(h2);
	}

	[Test]
	public static void Publish_RefSemantics_MutationVisibleToLaterHandlers()
	{
		let bus = scope DefaultMessageBus();
		int32 finalValue = 0;

		var h1 = bus.Subscribe<TestMessage>(new (msg) =>
			{
				msg.Value = msg.Value * 10; // mutate via ref
			});

		var h2 = bus.Subscribe<TestMessage>(new [&finalValue](msg) =>
			{
				finalValue = msg.Value; // should see mutated value
			});

		TestMessage msg = .() { Value = 5 };
		bus.Publish<TestMessage>(ref msg);

		Test.Assert(finalValue == 50);

		bus.Unsubscribe(h1);
		bus.Unsubscribe(h2);
	}

	[Test]
	public static void Subscribe_HandlersFireInSubscriptionOrder()
	{
		let bus = scope DefaultMessageBus();
		List<int32> order = scope .();

		var h1 = bus.Subscribe<TestMessage>(new [&order](msg) => { order.Add(1); });
		var h2 = bus.Subscribe<TestMessage>(new [&order](msg) => { order.Add(2); });
		var h3 = bus.Subscribe<TestMessage>(new [&order](msg) => { order.Add(3); });

		TestMessage msg = .() { Value = 0 };
		bus.Publish<TestMessage>(ref msg);

		Test.Assert(order.Count == 3);
		Test.Assert(order[0] == 1);
		Test.Assert(order[1] == 2);
		Test.Assert(order[2] == 3);

		bus.Unsubscribe(h1);
		bus.Unsubscribe(h2);
		bus.Unsubscribe(h3);
	}
}
