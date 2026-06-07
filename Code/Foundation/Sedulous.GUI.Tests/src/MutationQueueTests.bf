namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class MutationQueueTests
{
	[Test]
	public static void Empty_HasNoPending()
	{
		let queue = scope MutationQueue();
		Test.Assert(!queue.HasPending);
	}

	[Test]
	public static void QueueAction_HasPending()
	{
		let queue = scope MutationQueue();
		queue.QueueAction(new () => { });
		Test.Assert(queue.HasPending);
	}

	[Test]
	public static void Drain_ExecutesActions()
	{
		let queue = scope MutationQueue();
		int counter = 0;
		queue.QueueAction(new [&counter] () => { counter++; });
		queue.QueueAction(new [&counter] () => { counter++; });

		queue.Drain();
		Test.Assert(counter == 2);
		Test.Assert(!queue.HasPending);
	}

	[Test]
	public static void Drain_ExecutesInOrder()
	{
		let queue = scope MutationQueue();
		int order = 0;
		int first = -1, second = -1;
		queue.QueueAction(new [&] () => { first = order++; });
		queue.QueueAction(new [&] () => { second = order++; });

		queue.Drain();
		Test.Assert(first == 0);
		Test.Assert(second == 1);
	}

	[Test]
	public static void Drain_HandlesReentrantEnqueue()
	{
		let queue = scope MutationQueue();
		int counter = 0;
		queue.QueueAction(new [&] () =>
		{
			counter++;
			// Enqueue another action during drain
			queue.QueueAction(new [&counter] () => { counter++; });
		});

		queue.Drain();
		Test.Assert(counter == 2); // Both original and re-entrant executed
		Test.Assert(!queue.HasPending);
	}

	[Test]
	public static void Drain_IntegratedWithBeginFrame()
	{
		let ctx = scope UIContext();
		int counter = 0;
		ctx.MutationQueue.QueueAction(new [&counter] () => { counter++; });
		ctx.BeginFrame(0.016f);
		Test.Assert(counter == 1);
	}

	[Test]
	public static void QueueDelete_PreventsDoubleDelete()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		ctx.MutationQueue.QueueDelete(view);
		Test.Assert(view.IsPendingDeletion);

		// Second queue should be no-op
		ctx.MutationQueue.QueueDelete(view);
		// Drain should only delete once
		ctx.MutationQueue.Drain();
	}
}
