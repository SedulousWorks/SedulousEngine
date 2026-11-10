using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;

namespace Sedulous.Core;

// Long work off the frame, handed back on the main thread. The JobSystem
// is for the frame's fan-out; a cook, an import read, a decode or an export runs here instead, on
// workers of the pool's own, so it never holds a worker the frame's ParallelFor needs.
//
// A task is a name and work (TaskWork) with an optional completion (TaskDone). Submit returns its
// TaskHandle: its state, its progress, and Cancel(). A task goes to a lane: tasks of one lane run
// one at a time in the order submitted (a lane is a queue over the workers, not a thread), lanes run
// side by side, and the shared lane runs its tasks side by side too.
//
// The owner calls Pump() once a frame on the main thread: it runs the completions of the tasks
// finished since, in finishing order, and hands out their log lines. A cancelled task's completion
// never runs, so an owner that cancels its tasks on its way out is never called back.
//
// Cancelling is cooperative: a queued task is dropped without running; a running one sees
// IsCancelled at its next check and returns ErrorCode.Cancelled. Cancel never waits; Wait does, for
// the main thread that must have a task gone before it goes on.
//
// The work owns what it uses (captured by reference count, never a raw owner). A worker never
// touches what the main thread changes; it writes its result where its completion reads it.
//
// A pool of no workers (the web build, which has no threads) runs its queued tasks in Pump, one at
// a time within a time budget, so the page draws between tasks.
//
// The waits poll a latched WaitEvent with a short timeout, as the JobSystem's workers do: Beef's
// Monitor has no wait, and the latch keeps a wake between a check and its wait from being lost.

/// A task's work, run on a worker: what it returns is the task's result.
typealias TaskWork = delegate Result<void, ErrorCode>(TaskContext context);
/// A task's completion, run in Pump on the main thread with the work's result.
typealias TaskDone = delegate void(Result<void, ErrorCode> result);

/// Where a task runs. Shared runs its tasks side by side; a lane from CreateLane runs one at a time.
enum TaskLane : uint32
{
	case Shared = 0;
}

enum TaskState : uint8
{
	Queued,
	Running,
	/// Its work returned success.
	Done,
	/// Its work returned an error.
	Failed,
	/// Dropped before it ran, or it stopped when told.
	Cancelled
}

/// One submitted task: its state, its progress, and how to cancel it. Reference counted: the pool
/// holds one reference until the Pump that hands it back, and whoever keeps it longer takes one.
class TaskHandle : RefCounted
{
	private String mName = new .() ~ delete _;
	private TaskLane mLane;
	private TaskWork mWork ~ delete _;
	private TaskDone mDone ~ delete _;
	private CancelSource mCancel = new .() ~ delete _;
	private volatile int32 mState = (int32)TaskState.Queued;
	private Result<void, ErrorCode> mResult = .Ok;
	/// Guards the progress and the log, which the worker writes.
	private Monitor mLock = new .() ~ delete _;
	private float mFraction = -1.0f;
	private String mStep = new .() ~ delete _;
	/// Which step of mStepCount (0 based); a count of 0 says none.
	private int mStepIndex = 0;
	private int mStepCount = 0;
	private List<String> mLog = new .() ~ DeleteContainerAndItems!(_);

	public this(StringView name, TaskLane lane, TaskWork work, TaskDone done)
	{
		mName.Set(name);
		mLane = lane;
		mWork = work;
		mDone = done;
	}

	public StringView Name => mName;
	public TaskLane Lane => mLane;
	public TaskState State => (TaskState)mState;
	public bool IsEnded
	{
		get
		{
			let state = State;
			return (state == .Done) || (state == .Failed) || (state == .Cancelled);
		}
	}
	/// What its work returned; meaningful once IsEnded.
	public Result<void, ErrorCode> Result => mResult;

	/// How far it has got, 0 to 1, as its work last said; below 0 when it has not said.
	public float Fraction
	{
		get
		{
			using (mLock.Enter())
				return mFraction;
		}
	}

	/// What it is doing now ("Writing Rider.glb"), appended.
	public void GetStep(String outStep)
	{
		using (mLock.Enter())
			outStep.Append(mStep);
	}

	/// Which step it is on, 0 based, of StepCount ("3 of 12"); a count of 0 says none.
	public int StepIndex
	{
		get
		{
			using (mLock.Enter())
				return mStepIndex;
		}
	}

	public int StepCount
	{
		get
		{
			using (mLock.Enter())
				return mStepCount;
		}
	}

	/// Tells it to stop: dropped if it has not started, told through its token if it has. Its
	/// completion will not run. Never waits (TaskPool.Wait does).
	public void Cancel() => mCancel.Cancel();
	public bool IsCancelled => mCancel.IsCancelled;
	/// Its cancel token, for work it hands on (a cook). BORROWED: valid while this is.
	public CancelToken Token => mCancel.Token;

	private void SetState(TaskState state)
	{
		mState = (int32)state;
	}
}

/// What the work is given: its cancel token, and where it says how far it has got. Safe from the
/// worker; nothing here touches the main thread.
class TaskContext
{
	private TaskHandle mTask;

	public this(TaskHandle task)
	{
		mTask = task;
	}

	public bool IsCancelled => mTask.IsCancelled;
	/// BORROWED: valid while the work runs.
	public CancelToken Token => mTask.Token;

	public void SetProgress(float fraction, StringView step = default)
	{
		using (mTask.[Friend]mLock.Enter())
		{
			mTask.[Friend]mFraction = fraction;
			mTask.[Friend]mStep.Set(step);
		}
	}

	/// How far, 0 to 1, keeping the step.
	public void SetFraction(float fraction)
	{
		using (mTask.[Friend]mLock.Enter())
			mTask.[Friend]mFraction = fraction;
	}

	/// What it does now, as step `index` (0 based) of `count` ("Writing Rider.glb", 3 of 12),
	/// keeping the fraction.
	public void SetStep(StringView step, int index = 0, int count = 0)
	{
		using (mTask.[Friend]mLock.Enter())
		{
			mTask.[Friend]mStep.Set(step);
			mTask.[Friend]mStepIndex = index;
			mTask.[Friend]mStepCount = count;
		}
	}

	/// A line for whoever pumps the pool (the editor's Console).
	public void Log(StringView line)
	{
		using (mTask.[Friend]mLock.Enter())
			mTask.[Friend]mLog.Add(new String(line));
	}
}

class TaskPool
{
	private class Lane
	{
		public String Name = new .() ~ delete _;
		/// Behind the one it has runnable or running: one reference each.
		public List<TaskHandle> Queued = new .() ~ delete _;
		/// A task of it runnable or running.
		public bool Busy;
	}

	/// Guards everything below but the workers.
	private Monitor mLock = new .() ~ delete _;
	/// A task became runnable, or the pool stops.
	private WaitEvent mWake = new .() ~ delete _;
	/// A task ended (Wait).
	private WaitEvent mEnded = new .() ~ delete _;
	private List<Lane> mLanes = new .() ~ DeleteContainerAndItems!(_);
	/// Ready for a worker, in order; running; ended, for Pump. One reference each.
	private List<TaskHandle> mRunnable = new .() ~ delete _;
	private List<TaskHandle> mRunning = new .() ~ delete _;
	private List<TaskHandle> mFinished = new .() ~ delete _;
	private volatile bool mStopping = false;
	/// How many workers it runs, started with the first task.
	private int32 mWorkerCount;
	private List<Thread> mWorkers = new .() ~ delete _;

	/// The workers for long work: the logical cores less two (the frame keeps its threads), at least
	/// one and at most four (a big cook should not flood the disk and memory); none on the web
	/// build, which has no threads.
	public static int32 DefaultWorkerCount()
	{
#if BF_PLATFORM_WASM
		return 0;
#else
		let cores = JobSystem.LogicalCoreCount();
		let spare = (cores > 2) ? (cores - 2) : 1;
		return Math.Min(spare, 4);
#endif
	}

	/// `workerCount` 0 runs every task in Pump on the calling thread. The workers start with the first
	/// task, so a pool nothing uses costs no threads.
	public this(int32 workerCount)
	{
		mWorkerCount = Math.Max(workerCount, 0);
		let shared = new Lane(); // TaskLane.Shared, never busy
		shared.Name.Set("Shared");
		mLanes.Add(shared);
	}

	/// Cancels everything: what is queued is dropped, what runs is told, and waited for. No
	/// completion runs.
	public ~this()
	{
		using (mLock.Enter())
		{
			mStopping = true;
			for (let task in mRunning)
				task.Cancel();
			DropQueued(mRunnable);
			for (let lane in mLanes)
				DropQueued(lane.Queued);
		}
		mWake.Set(true); // manual: every worker sees the stop
		for (let worker in mWorkers)
		{
			worker.Join();
			delete worker;
		}
		for (let task in mFinished)
			task.ReleaseRef(); // their completions go unrun
		mFinished.Clear();
	}

	/// A lane whose tasks run one at a time, in the order submitted (the editor's build lane: nothing
	/// it runs races the content databases).
	public TaskLane CreateLane(StringView name)
	{
		using (mLock.Enter())
		{
			let lane = new Lane();
			lane.Name.Set(name);
			mLanes.Add(lane);
			return (TaskLane)(mLanes.Count - 1);
		}
	}

	/// Queues `work` on `lane`; `done` runs in Pump on the main thread once it has ended, unless it
	/// was cancelled. Called on the main thread (or from a completion). TAKES OWNERSHIP of `work`
	/// and `done`. The handle is BORROWED: valid until the Pump that hands it back; take a reference
	/// to keep it longer.
	public TaskHandle Submit(StringView name, TaskWork work, TaskDone done = null, TaskLane lane = .Shared)
	{
		let task = new TaskHandle(name, lane, work, done); // the pool's reference
		while (mWorkers.Count < mWorkerCount)
		{
			let thread = new Thread(new () => { WorkerLoop(); });
			mWorkers.Add(thread);
			thread.Start(false);
		}
		using (mLock.Enter())
		{
			Debug.Assert((int)lane < mLanes.Count);
			let queue = mLanes[(int)lane];
			if ((lane == .Shared) || !queue.Busy)
			{
				queue.Busy = lane != .Shared;
				mRunnable.Add(task);
			}
			else
				queue.Queued.Add(task); // after the one it runs now
		}
		mWake.Set();
		return task;
	}

	/// The main thread's once-a-frame call: the log lines written since (to `log`, null: dropped),
	/// then the completions of the tasks ended since, in the order they ended. A pool of no workers
	/// first runs its queued tasks here, one at a time, for as long as `budgetMs` allows (at least
	/// one).
	public void Pump(delegate void(TaskHandle task, StringView line) log = null, int budgetMs = 8)
	{
		if (mWorkerCount == 0)
		{
			let clock = scope Stopwatch(true);
			repeat
			{
				if (!RunOneInline())
					break;
			}
			while (clock.ElapsedMilliseconds < budgetMs);
		}

		let running = scope List<TaskHandle>();
		let finished = scope List<TaskHandle>();
		using (mLock.Enter())
		{
			for (let task in mRunning)
			{
				task.AddRef(); // ours, while its lines go out
				running.Add(task);
			}
			finished.AddRange(mFinished); // their references come with them
			mFinished.Clear();
		}
		for (let task in running)
		{
			HandOutLog(task, log);
			task.ReleaseRef();
		}
		for (let task in finished)
		{
			HandOutLog(task, log);
			if (!task.IsCancelled && (task.[Friend]mDone != null))
				task.[Friend]mDone(task.[Friend]mResult); // may Submit more
			DeleteAndNullify!(task.[Friend]mDone); // what it captured goes now, on the main thread
			task.ReleaseRef();
		}
	}

	/// Waits on the calling thread for `task` to end. A task cancelled before it started ends at
	/// once; a running one ends at its next check. A pool of no workers runs the queue until it has.
	/// Its completion still runs in the next Pump (unless it was cancelled).
	public void Wait(TaskHandle task)
	{
		for (;;)
		{
			using (mLock.Enter())
			{
				if (task.IsEnded)
					return;
				if ((task.State == .Queued) && task.IsCancelled && DropIfQueued(task))
					return;
			}
			if (mWorkerCount != 0)
			{
				mEnded.WaitFor(1);
				continue;
			}
			if (!RunOneInline())
				return; // nothing left to run: it was never this pool's
		}
	}

	/// Waits for every task to end, then pumps: the completions run here (tests; a host that must
	/// have its work done before it goes on). A pool of no workers runs them all here.
	public void Finish(delegate void(TaskHandle task, StringView line) log = null)
	{
		if (mWorkerCount == 0)
		{
			while (RunOneInline())
			{
			}
		}
		else
		{
			for (;;)
			{
				using (mLock.Enter())
				{
					if (mRunnable.IsEmpty && mRunning.IsEmpty && !AnyLaneQueued())
						break;
				}
				mEnded.WaitFor(1);
			}
		}
		Pump(log);
	}

	/// Cancels every task, queued and running: what has not started is dropped, what runs is told.
	/// Never waits; Finish then waits for those running, and runs no cancelled completion (an owner
	/// closing what the tasks use: a project, a session).
	public void CancelAll()
	{
		using (mLock.Enter())
		{
			for (let task in mRunning)
				task.Cancel();
			for (let task in mRunnable)
				task.Cancel();
			for (let lane in mLanes)
			{
				for (let task in lane.Queued)
					task.Cancel();
			}
		}
	}

	/// Tasks submitted and not yet handed back by Pump.
	public int InFlight
	{
		get
		{
			using (mLock.Enter())
			{
				var count = mRunnable.Count + mRunning.Count + mFinished.Count;
				for (let lane in mLanes)
					count += lane.Queued.Count;
				return count;
			}
		}
	}

	/// Whether `lane` has a task queued or running (the editor gates project changes on its build
	/// lane).
	public bool IsLaneBusy(TaskLane lane)
	{
		using (mLock.Enter())
			return ((int)lane < mLanes.Count) && mLanes[(int)lane].Busy;
	}

	/// The task `lane` runs now (null when none): what a progress view shows. BORROWED: valid until
	/// the next Pump.
	public TaskHandle RunningIn(TaskLane lane)
	{
		using (mLock.Enter())
		{
			for (let task in mRunning)
			{
				if (task.Lane == lane)
					return task;
			}
			return null;
		}
	}

	public int32 WorkerCount => mWorkerCount;

	/// Whether a lane has a task waiting behind the one it runs (mLock held).
	private bool AnyLaneQueued()
	{
		for (let lane in mLanes)
		{
			if (!lane.Queued.IsEmpty)
				return true;
		}
		return false;
	}

	/// Drops every task in `queue` unrun, its result Cancelled (mLock held).
	private static void DropQueued(List<TaskHandle> queue)
	{
		for (let task in queue)
		{
			task.Cancel();
			task.[Friend]mResult = .Err(.Cancelled);
			task.[Friend]SetState(.Cancelled);
			task.ReleaseRef();
		}
		queue.Clear();
	}

	/// The next runnable task (mLock held): one cancelled before it started ends here, unrun, and the
	/// next is taken. Null when none is runnable.
	private TaskHandle TakeRunnable()
	{
		while (!mRunnable.IsEmpty)
		{
			let task = mRunnable.PopFront();
			if (task.IsCancelled)
			{
				mRunning.Add(task); // End takes it from there
				End(task, .Err(.Cancelled));
				continue;
			}
			task.[Friend]SetState(.Running);
			mRunning.Add(task);
			return task;
		}
		return null;
	}

	/// Runs `task`'s work on this thread, with the profiler's hooks around it.
	private static Result<void, ErrorCode> Run(TaskHandle task)
	{
		let hooks = JobHooks.Current;
		let began = (hooks != null) && (hooks.Begin != null) && hooks.Begin();
		let context = scope TaskContext(task);
		let result = task.[Friend]mWork(context);
		DeleteAndNullify!(task.[Friend]mWork); // what it captured goes here, on the thread that ran it
		if (began && (hooks.End != null))
			hooks.End();
		return result;
	}

	/// Records how `task` ended and lets its lane run its next (mLock held).
	private void End(TaskHandle task, Result<void, ErrorCode> result)
	{
		task.[Friend]mResult = result;
		TaskState state = .Done;
		if (result case .Err(let error))
			state = (error == .Cancelled) ? .Cancelled : .Failed;
		task.[Friend]SetState(state);
		mRunning.Remove(task);
		mFinished.Add(task); // the reference moves with it
		if (task.Lane != .Shared)
		{
			let lane = mLanes[(int)task.Lane];
			if (lane.Queued.IsEmpty)
				lane.Busy = false;
			else
			{
				mRunnable.Add(lane.Queued.PopFront());
				mWake.Set();
			}
		}
		mEnded.Set();
	}

	/// Ends a cancelled `task` that has not started, wherever it waits (mLock held).
	private bool DropIfQueued(TaskHandle task)
	{
		let at = mRunnable.IndexOf(task);
		if (at >= 0)
		{
			mRunnable.RemoveAt(at);
			mRunning.Add(task); // End takes it from there, and its lane's next becomes runnable
			End(task, .Err(.Cancelled));
			return true;
		}
		for (let lane in mLanes)
		{
			let queued = lane.Queued.IndexOf(task);
			if (queued < 0)
				continue;
			lane.Queued.RemoveAt(queued);
			task.[Friend]mResult = .Err(.Cancelled);
			task.[Friend]SetState(.Cancelled);
			mFinished.Add(task);
			mEnded.Set();
			return true;
		}
		return false;
	}

	/// A pool of no workers: runs the next runnable task here. False when none was.
	private bool RunOneInline()
	{
		TaskHandle task;
		using (mLock.Enter())
			task = TakeRunnable();
		if (task == null)
			return false;
		let result = Run(task);
		using (mLock.Enter())
			End(task, result);
		return true;
	}

	private void WorkerLoop()
	{
		ThreadNames.SetCurrent("Task worker");
		for (;;)
		{
			TaskHandle task;
			using (mLock.Enter())
				task = TakeRunnable();
			if (task == null)
			{
				if (mStopping)
					return;
				mWake.WaitFor(5);
				continue;
			}
			let result = Run(task);
			using (mLock.Enter())
				End(task, result);
		}
	}

	/// `task`'s log lines written since, to `log` (null: dropped).
	private static void HandOutLog(TaskHandle task, delegate void(TaskHandle task, StringView line) log)
	{
		let lines = scope List<String>();
		using (task.[Friend]mLock.Enter())
		{
			if (task.[Friend]mLog.IsEmpty)
				return;
			lines.AddRange(task.[Friend]mLog);
			task.[Friend]mLog.Clear();
		}
		if (log != null)
		{
			for (let line in lines)
				log(task, line);
		}
		ClearAndDeleteItems!(lines);
	}
}
