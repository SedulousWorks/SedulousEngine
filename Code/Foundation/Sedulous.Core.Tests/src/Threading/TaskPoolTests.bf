using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

// Bodies capture by reference with [&]: every case waits for (or pumps) its tasks before the
// captured locals leave scope.

/// The task pool: long work off the frame, its completions on the pumping thread; lanes one at a
/// time, the shared lane side by side; cancelling, waiting, progress and log; going away.
class TaskPoolTests
{
	/// Spins (yielding) until `ready` holds or about two seconds pass; false on the timeout, so a
	/// broken pool fails a check instead of hanging the suite.
	private static bool Eventually(delegate bool() ready)
	{
		let clock = scope Stopwatch(true);
		while (!ready())
		{
			if (clock.ElapsedMilliseconds > 2000)
				return false;
			Thread.Yield();
		}
		return true;
	}

	[Test]
	public static void WithNoWorkersTasksRunInPumpInOrderAndWaitRunsTheQueueUntilItsTaskEnds()
	{
		let pool = scope TaskPool(0);
		let order = scope List<int>();
		let completed = scope List<int>();
		let first = pool.Submit("first", new [&] (context) => { order.Add(1); return Result<void, ErrorCode>.Ok; }, new [&] (result) => { completed.Add(1); });
		first.AddRef();
		defer first.ReleaseRef();
		let second = pool.Submit("second", new [&] (context) => { order.Add(2); return Result<void, ErrorCode>.Ok; });
		second.AddRef();
		defer second.ReleaseRef();
		Test.Assert(first.State == .Queued, "nothing runs until the owner pumps");
		Test.Assert(order.IsEmpty);

		pool.Wait(second); // runs the queue here until `second` has ended
		Test.Assert(order.Count == 2);
		Test.Assert(order[0] == 1);
		Test.Assert(second.State == .Done);
		Test.Assert(completed.IsEmpty, "completions wait for Pump");

		pool.Pump();
		Test.Assert((completed.Count == 1) && (completed[0] == 1));

		let third = pool.Submit("third", new (context) => Result<void, ErrorCode>.Err(.NotFound));
		third.AddRef();
		defer third.ReleaseRef();
		pool.Pump(); // runs it within the budget
		Test.Assert(third.State == .Failed);
		Test.Assert(third.Result case .Err(.NotFound));
	}

	[Test]
	public static void ATaskCancelledBeforeItStartsIsDroppedUnrunAndItsCompletionNeverRuns()
	{
		let pool = scope TaskPool(0);
		bool ran = false;
		bool completed = false;
		let task = pool.Submit("dropped", new [&] (context) => { ran = true; return Result<void, ErrorCode>.Ok; }, new [&] (result) => { completed = true; });
		task.AddRef();
		defer task.ReleaseRef();
		task.Cancel();
		pool.Wait(task);
		Test.Assert(task.State == .Cancelled);
		pool.Pump();
		Test.Assert(!ran);
		Test.Assert(!completed);
	}

	[Test]
	public static void ProgressAndLogLinesFromTheWorkReachThePumpingThread()
	{
		let pool = scope TaskPool(0);
		let reporting = pool.Submit("reporting", new (context) =>
			{
				context.SetProgress(0.5f, "Halfway");
				context.Log("half done");
				return Result<void, ErrorCode>.Ok;
			});
		reporting.AddRef();
		defer reporting.ReleaseRef();
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		pool.Pump(scope [&] (task, line) => { lines.Add(new String()..AppendF("{}: {}", task.Name, line)); });
		Test.Assert(Math.Abs(reporting.Fraction - 0.5f) < 1e-6f);
		Test.Assert(reporting.GetStep(.. scope .()) == "Halfway");
		Test.Assert((lines.Count == 1) && (lines[0] == "reporting: half done"));
	}

	[Test]
	public static void ACompletionMaySubmitMore()
	{
		let pool = scope TaskPool(0);
		int stage = 0;
		pool.Submit("one", new (context) => Result<void, ErrorCode>.Ok, new [&] (result) =>
			{
				stage = 1;
				pool.Submit("two", new (context) => Result<void, ErrorCode>.Ok, new [&] (next) => { stage = 2; });
			});
		pool.Pump();
		Test.Assert(stage == 1);
		pool.Pump();
		Test.Assert(stage == 2);
	}

	[Test]
	public static void WorkRunsOnAWorkerNeverThePumpingThreadItsCompletionRunsOnThePumpingThread()
	{
		let pool = scope TaskPool(2);
		Test.Assert(pool.WorkerCount == 2);
		let main = Thread.CurrentThreadId;
		int ranOn = 0;
		int completedOn = 0;
		let task = pool.Submit("off", new [&] (context) => { Volatile.Write(ref ranOn, Thread.CurrentThreadId); return Result<void, ErrorCode>.Ok; },
			new [&] (result) => { completedOn = Thread.CurrentThreadId; });
		task.AddRef();
		defer task.ReleaseRef();
		pool.Wait(task);
		Test.Assert(task.State == .Done);
		Test.Assert(Volatile.Read(ref ranOn) != main);
		Test.Assert(completedOn == 0, "not before Pump");
		pool.Pump();
		Test.Assert(completedOn == main);
	}

	[Test]
	public static void ALaneRunsItsTasksOneAtATimeInOrderTheSharedLaneRunsThemSideBySide()
	{
		let pool = scope TaskPool(3);
		let lane = pool.CreateLane("build");
		let guard = scope Monitor();
		int inside = 0;
		int most = 0;
		let order = scope List<int>();
		TaskHandle last = null;
		for (int i < 6)
		{
			last = pool.Submit("serial", new [=i, &guard, &inside, &most, &order] (context) =>
				{
					using (guard.Enter())
					{
						inside++;
						most = Math.Max(most, inside);
						order.Add(i);
					}
					for (int spin < 200)
						Thread.Yield();
					using (guard.Enter())
						inside--;
					return Result<void, ErrorCode>.Ok;
				}, null, lane);
		}
		last.AddRef();
		Test.Assert(pool.IsLaneBusy(lane));
		pool.Wait(last);
		last.ReleaseRef();
		Test.Assert(most == 1);
		Test.Assert(order.Count == 6);
		for (int i < 6)
			Test.Assert(order[i] == i);
		pool.Pump();
		Test.Assert(!pool.IsLaneBusy(lane));

		// Two shared tasks that each wait to see the other running: they finish only side by side.
		int arrived = 0;
		let a = pool.Submit("a", new [&] (context) =>
			{
				Interlocked.Increment(ref arrived);
				return Eventually(scope [&] () => Volatile.Read(ref arrived) >= 2) ? Result<void, ErrorCode>.Ok : Result<void, ErrorCode>.Err(.Unknown);
			});
		a.AddRef();
		defer a.ReleaseRef();
		let b = pool.Submit("b", new [&] (context) =>
			{
				Interlocked.Increment(ref arrived);
				return Eventually(scope [&] () => Volatile.Read(ref arrived) >= 2) ? Result<void, ErrorCode>.Ok : Result<void, ErrorCode>.Err(.Unknown);
			});
		b.AddRef();
		defer b.ReleaseRef();
		pool.Wait(a);
		pool.Wait(b);
		Test.Assert(a.State == .Done);
		Test.Assert(b.State == .Done);
	}

	[Test]
	public static void ARunningTaskStopsWhenCancelledOneQueuedBehindItInItsLaneIsDroppedAtOnceByWait()
	{
		let pool = scope TaskPool(1);
		let lane = pool.CreateLane("build");
		bool started = false;
		bool completed = false;
		let running = pool.Submit("long", new [&] (context) =>
			{
				Volatile.Write(ref started, true);
				while (!context.IsCancelled)
					Thread.Yield();
				return Result<void, ErrorCode>.Err(.Cancelled);
			}, new [&] (result) => { completed = true; }, lane);
		running.AddRef();
		defer running.ReleaseRef();
		bool queuedRan = false;
		let queued = pool.Submit("behind", new [&] (context) => { queuedRan = true; return Result<void, ErrorCode>.Ok; }, null, lane);
		queued.AddRef();
		defer queued.ReleaseRef();
		Test.Assert(Eventually(scope [&] () => Volatile.Read(ref started)));

		queued.Cancel();
		pool.Wait(queued); // dropped from its lane without waiting for the one running
		Test.Assert(queued.State == .Cancelled);
		Test.Assert(running.State == .Running);

		running.Cancel();
		pool.Wait(running);
		Test.Assert(running.State == .Cancelled);
		pool.Pump();
		Test.Assert(!completed);
		Test.Assert(!queuedRan);
		Test.Assert(!pool.IsLaneBusy(lane));
	}

	[Test]
	public static void GoingAwayCancelsWhatRunsDropsWhatWaitsAndCallsNoCompletion()
	{
		bool started = false;
		bool sawCancel = false;
		bool completed = false;
		bool queuedRan = false;
		{
			let pool = scope TaskPool(1);
			pool.Submit("long", new [&] (context) =>
				{
					Volatile.Write(ref started, true);
					while (!context.IsCancelled)
						Thread.Yield();
					Volatile.Write(ref sawCancel, true);
					return Result<void, ErrorCode>.Err(.Cancelled);
				}, new [&] (result) => { completed = true; });
			pool.Submit("waiting", new [&] (context) => { queuedRan = true; return Result<void, ErrorCode>.Ok; });
			Test.Assert(Eventually(scope [&] () => Volatile.Read(ref started)));
		}
		Test.Assert(Volatile.Read(ref sawCancel));
		Test.Assert(!queuedRan);
		Test.Assert(!completed);
	}

	/// Finish waits for every task, then hands them back; InFlight counts what is not handed back
	/// yet. The workers start with the first task.
	[Test]
	public static void FinishWaitsForEveryTaskThenHandsThemBackInFlightCountsWhatIsNotHandedBackYet()
	{
		int32[2] counts = .(0, 2); // no workers, then two
		for (let workers in counts)
		{
			let pool = scope TaskPool(workers); // gone with each round, its workers joined
			Test.Assert(pool.WorkerCount == workers);
			Test.Assert(pool.[Friend]mWorkers.IsEmpty, "no threads before the first task");
			let lane = pool.CreateLane("serial");
			int ran = 0;
			int completed = 0;
			for (int i < 3)
				pool.Submit("shared", new [&ran] (context) => { Interlocked.Increment(ref ran); return Result<void, ErrorCode>.Ok; }, new [&completed] (result) => { completed++; });
			for (int i < 3)
				pool.Submit("lane", new [&ran] (context) => { Interlocked.Increment(ref ran); return Result<void, ErrorCode>.Ok; }, new [&completed] (result) => { completed++; }, lane);
			Test.Assert(pool.InFlight == 6);
			Test.Assert(pool.[Friend]mWorkers.Count == workers);
			pool.Finish();
			Test.Assert(Volatile.Read(ref ran) == 6);
			Test.Assert(completed == 6);
			Test.Assert(pool.InFlight == 0);
		}
	}

	[Test]
	public static void TheDefaultWorkerCountLeavesTheFrameItsThreads()
	{
		let count = TaskPool.DefaultWorkerCount();
		Test.Assert((count >= 1) && (count <= 4));
	}
}
