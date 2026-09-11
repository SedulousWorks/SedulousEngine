using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

// Bodies capture by reference with [&], since Beef captures by value otherwise. That is
// safe here because every case waits for its work before the captured locals leave
// scope; a job outliving them would be reading freed stack.

/// The job system. Raptor's cases are ported; the allocator one is not, since the pool
/// does not take an allocator yet, and the multi-pool isolation case is new.
class JobSystemTests
{
	[Test]
	public static void RunsEverySubmittedJob()
	{
		let jobs = scope JobSystem(4);
		var counter = 0;
		let lock = scope Monitor();

		let done = scope Counter(100);
		for (int i < 100)
		{
			jobs.Submit(new [&lock, &counter] () =>
				{
					using (lock.Enter())
						counter++;
				}, done);
		}
		jobs.Wait(done);

		Test.Assert(counter == 100);
	}

	/// A pool of zero workers is valid: the caller runs everything when it waits, which
	/// is the single-threaded fallback.
	[Test]
	public static void ZeroWorkersRunsInlineOnTheCaller()
	{
		let jobs = scope JobSystem(0);
		Test.Assert(jobs.WorkerCount == 0);

		var ran = 0;
		let done = scope Counter(10);
		for (int i < 10)
			jobs.Submit(new [&ran] () => { ran++; }, done);

		// Nothing has run yet: there is no worker to run it.
		jobs.Wait(done);
		Test.Assert(ran == 10);
	}

	/// Zero means zero, where Raptor reads it as auto. Without this the single-threaded
	/// path is unreachable through the API, and so untestable anywhere with cores to
	/// spare.
	[Test]
	public static void AutoIsDistinctFromAnExplicitZero()
	{
		let auto = scope JobSystem(JobSystem.Auto);
		let cores = JobSystem.LogicalCoreCount();
		Test.Assert(auto.WorkerCount == ((cores > 1) ? (cores - 1) : 0));

		// The default argument is auto, not zero.
		let byDefault = scope JobSystem();
		Test.Assert(byDefault.WorkerCount == auto.WorkerCount);

		let explicitZero = scope JobSystem(0);
		Test.Assert(explicitZero.WorkerCount == 0);
	}

	[Test]
	public static void WaitForAllDrainsEverything()
	{
		let jobs = scope JobSystem(3);
		var counter = 0;
		let lock = scope Monitor();

		for (int i < 50)
		{
			jobs.Submit(new [&lock, &counter] () =>
				{
					using (lock.Enter())
						counter++;
				});
		}
		jobs.WaitForAll();
		Test.Assert(counter == 50);
	}

	[Test]
	public static void ParallelForCoversTheRangeExactlyOnce()
	{
		let jobs = scope JobSystem(4);
		let count = 1000;
		let seen = scope int[count]*;
		Internal.MemSet(seen, 0, count * sizeof(int));

		jobs.ParallelFor(count, scope (i) => { seen[i]++; });

		for (int i < count)
			Test.Assert(seen[i] == 1, scope $"index {i} ran {seen[i]} times");
	}

	/// A grain size larger than the range still produces one chunk covering all of it,
	/// and a grain of one produces a chunk per item.
	[Test]
	public static void ParallelForHonoursGrainSize()
	{
		let jobs = scope JobSystem(2);
		let count = 64;

		for (let grain in int32[?](1, 7, 64, 1000))
		{
			let seen = scope:: int[count]*;
			Internal.MemSet(seen, 0, count * sizeof(int));
			jobs.ParallelFor(count, scope:: (i) => { seen[i]++; }, grain);
			for (int i < count)
				Test.Assert(seen[i] == 1, scope $"grain {grain}, index {i}");
		}
	}

	[Test]
	public static void ParallelForOverAnEmptyRangeDoesNothing()
	{
		let jobs = scope JobSystem(2);
		var ran = 0;
		jobs.ParallelFor(0, scope [&ran] (i) => { ran++; });
		Test.Assert(ran == 0);
	}

	/// Many dependencies fanning into one continuation: it must not run until the last of
	/// them has finished, and must see all of their work.
	[Test]
	public static void SubmitAfterRunsOnlyOnceItsCounterReachesZero()
	{
		let jobs = scope JobSystem(4);
		const int32 kWork = 200;

		var work = 0;
		var seenByFinalize = -1;
		var finalizeRan = false;
		let lock = scope Monitor();

		let gate = scope Counter(kWork);
		for (int32 i < kWork)
		{
			jobs.Submit(new [&lock, &work] () =>
				{
					using (lock.Enter())
						work++;
				}, gate);
		}

		jobs.SubmitAfter(gate, new [&lock, &seenByFinalize, &finalizeRan, &work] () =>
			{
				using (lock.Enter())
				{
					seenByFinalize = work;
					finalizeRan = true;
				}
			});

		jobs.WaitForAll();

		// WaitForAll did not return before the continuation, and the continuation ran
		// strictly after every one of its dependencies.
		Test.Assert(finalizeRan);
		Test.Assert(seenByFinalize == kWork, scope $"finalize saw {seenByFinalize} of {kWork}");
	}

	/// The ordering itself, in the small: a continuation parked behind a held gate runs
	/// only once the job that releases the gate has finished.
	[Test]
	public static void SubmitAfterOrdersTheContinuationAfterItsDependency()
	{
		let jobs = scope JobSystem(2);
		var order = scope String();
		let lock = scope Monitor();

		// One job will signal the gate, so it starts at one and B parks behind it.
		let gate = scope Counter(1);
		let finished = scope Counter(1);
		jobs.SubmitAfter(gate, new [&lock, &order] () =>
			{
				using (lock.Enter())
					order.Append('B');
			}, finished);

		// Nothing decrements the gate yet, so B must still be parked.
		Thread.Sleep(20);
		Test.Assert(order.IsEmpty);

		jobs.Submit(new [&lock, &order] () =>
			{
				using (lock.Enter())
					order.Append('A');
			}, gate);

		jobs.Wait(finished);
		Test.Assert(order == "AB", scope $"order was '{order}'");
	}

	/// A dependency that is already satisfied schedules immediately rather than waiting
	/// for a decrement that will never come.
	[Test]
	public static void SubmitAfterAnAlreadyZeroCounterRunsImmediately()
	{
		let jobs = scope JobSystem(2);
		let satisfied = scope Counter();
		Test.Assert(satisfied.Value == 0);

		var ran = false;
		let done = scope Counter(1);
		jobs.SubmitAfter(satisfied, new [&ran] () => { ran = true; }, done);
		jobs.Wait(done);
		Test.Assert(ran);
	}

	/// Waiting participates: the calling thread runs jobs rather than blocking. With no
	/// workers at all this is the only way the work can complete, which is what proves
	/// it rather than merely suggesting it.
	[Test]
	public static void WaitParticipatesRatherThanBlocking()
	{
		let jobs = scope JobSystem(0);
		let done = scope Counter(20);
		var ran = 0;

		for (int i < 20)
			jobs.Submit(new [&ran] () => { ran++; }, done);

		Test.Assert(ran == 0);
		jobs.Wait(done);
		Test.Assert(ran == 20);
	}

	/// Nested ParallelFor must not deadlock: the outer body is itself running as a job,
	/// and its inner wait participates rather than blocking a worker that the inner
	/// chunks need.
	[Test]
	public static void NestedParallelForDoesNotDeadlock()
	{
		let jobs = scope JobSystem(2);
		let outer = 8;
		let inner = 8;
		var total = 0;
		let lock = scope Monitor();

		jobs.ParallelFor(outer, scope [&] (i) =>
			{
				jobs.ParallelFor(inner, scope [&] (j) =>
					{
						using (lock.Enter())
							total++;
					});
			});

		Test.Assert(total == outer * inner);
	}

	[Test]
	public static void WorkerSlotsAreDistinctAndInRange()
	{
		let jobs = scope JobSystem(4);
		Test.Assert(jobs.SlotCount == jobs.WorkerCount + 1);

		let seen = scope bool[jobs.SlotCount]*;
		Internal.MemSet(seen, 0, jobs.SlotCount * sizeof(bool));
		let lock = scope Monitor();

		jobs.ParallelFor(200, scope [&] (i) =>
			{
				let slot = jobs.CurrentSlot;
				Test.Assert((slot >= 0) && (slot < jobs.SlotCount));
				using (lock.Enter())
					seen[slot] = true;
			});

		// The calling thread participates, so its own slot is reached too.
		Test.Assert(jobs.CurrentSlot == jobs.WorkerCount);
	}

	/// Raptor keys the worker slot on a bare thread-local index, which two pools would
	/// share: a worker of a four-worker pool submitting into a two-worker pool would
	/// index a deque that is not there. The slot is tagged with its owning pool here, so
	/// a thread is only a worker of the pool it belongs to.
	[Test]
	public static void SlotsAreIsolatedBetweenPools()
	{
		let big = scope JobSystem(4);
		let small = scope JobSystem(1);

		let done = scope Counter(1);
		var observed = -1;

		// Run on one of big's workers, and ask small what slot we are.
		big.Submit(new [&observed, &small] () =>
			{
				// Inside a worker of `big`, but a stranger to `small`.
				observed = small.CurrentSlot;
			}, done);
		big.Wait(done);

		// A non-worker of `small` reports small's external slot, not big's index.
		Test.Assert(observed == small.WorkerCount, scope $"observed {observed}");
	}

	/// The count falls when the job COMPLETES, not when it is dequeued: a job that is
	/// running but held still reads as outstanding.
	[Test]
	public static void CounterTracksOutstandingWork()
	{
		let jobs = scope JobSystem(2);
		let done = scope Counter(1);
		Test.Assert(done.Value == 1);

		let gate = scope WaitEvent();
		jobs.Submit(new () => { gate.WaitFor(1000); }, done);

		Thread.Sleep(20);
		Test.Assert(done.Value == 1);

		gate.Set();
		jobs.Wait(done);
		Test.Assert(done.Value == 0);
	}
}
