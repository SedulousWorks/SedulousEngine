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
			queue.QueueAction(new [&counter] () => { counter++; });
		});

		queue.Drain();
		Test.Assert(counter == 2);
		Test.Assert(!queue.HasPending);
	}
}
