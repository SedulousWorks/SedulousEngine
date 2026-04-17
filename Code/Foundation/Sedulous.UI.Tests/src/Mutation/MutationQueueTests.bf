namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;

class MutationQueueTests
{
	[Test]
	public static void Drain_ExecutesActions()
	{
		let queue = scope MutationQueue();
		int counter = 0;
		queue.QueueAction(new [&counter]() => { counter++; });
		queue.QueueAction(new [&counter]() => { counter += 10; });

		Test.Assert(counter == 0);
		queue.Drain();
		Test.Assert(counter == 11);
	}

	[Test]
	public static void Drain_ClearsQueue()
	{
		let queue = scope MutationQueue();
		queue.QueueAction(new () => { });
		Test.Assert(queue.HasPending);

		queue.Drain();
		Test.Assert(!queue.HasPending);
	}

	[Test]
	public static void Drain_HandlesRecursiveEnqueue()
	{
		let queue = scope MutationQueue();
		int counter = 0;
		queue.QueueAction(new [&] () => {
			counter++;
			// Enqueue another action during drain.
			queue.QueueAction(new [&] () => { counter += 100; });
		});

		queue.Drain();
		// Both actions should have run: 1 + 100 = 101.
		Test.Assert(counter == 101);
	}

	[Test]
	public static void QueueRemove_DuringTreeWalk_Safe()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);
		let id = child.Id;

		// Simulate an event handler queuing removal.
		ctx.MutationQueue.QueueAction(new [&] () => {
			ctx.Root.RemoveView(child, true);
		});

		// Drain should execute the removal without crash.
		ctx.BeginFrame(0);

		// Child should be gone.
		Test.Assert(ctx.GetElementById(id) == null);
	}
}
