using System;
using System.Collections;
using System.Threading;

namespace Sedulous.Core;

/// A stackless work-stealing job system: a fixed worker pool with per-worker deques,
/// ParallelFor fan-out, and counter-based dependencies.
///
/// No fibers. The parallelism this serves is broad data-parallel fan-out plus a few
/// dependent stages, and fibers do not translate to WASM.
///
/// The load-bearing property is CALLER PARTICIPATION: a thread that waits runs jobs
/// itself rather than blocking. That keeps the calling thread busy, keeps the main thread
/// from blocking indefinitely under WASM, and gives a correct single-threaded fallback
/// for free when the worker count is zero, since the caller then runs everything.
///
/// The pool is ordinarily constructible and passed like any other dependency. A managed
/// process-wide instance also exists, in GlobalJobSystem, for the call sites that
/// threading a pool through would cost more than it buys.
///
/// Raptor uses a condition variable for the sleep and wake path. Beef's Monitor has no
/// wait, so this uses a WaitEvent, which latches: a Set that arrives between a worker's
/// last check and its wait is not lost, so the idle mutex Raptor needs to close that
/// window is not needed here.
class JobSystem
{
	private class Deque
	{
		public Monitor Lock = new .() ~ delete _;
		public List<JobItem> Items = new .() ~ delete _;
	}

	/// The slot of the calling thread, and which pool it belongs to.
	///
	/// Raptor keys this on a bare thread-local index, which is wrong once two pools
	/// exist: a worker of a four-worker pool submitting to a two-worker pool would index
	/// a deque that is not there. The owning pool is identified by a never-reused id
	/// rather than by pointer, because a freed pool's address can be handed to the next
	/// one and the identity check would then wrongly succeed.
	[ThreadStatic] private static int sSlotOwnerId;
	[ThreadStatic] private static int32 sSlot;

	private static int sNextId;
	private readonly int mId = Interlocked.Increment(ref sNextId);

	private int32 mWorkerCount;
	private List<Deque> mDeques = new .() ~ DeleteContainerAndItems!(_);
	private Monitor mExternalLock = new .() ~ delete _;
	private List<JobItem> mExternal = new .() ~ delete _;
	private List<Thread> mWorkers = new .() ~ delete _;
	private WaitEvent mJobAvailable = new .() ~ delete _;
	private volatile int32 mPending;
	private volatile int32 mNextExternal;
	private volatile bool mStop;

	/// Passed as the worker count to pick logical cores minus one. This is the default.
	///
	/// Raptor spells auto as zero, which leaves a caller no way to ask for a pool with no
	/// workers at all. That configuration is not a curiosity: it is single-threaded WASM,
	/// and it is the one path where caller participation is load bearing rather than
	/// merely efficient. It is worth being able to name, and worth being able to test on a
	/// desktop with cores to spare, so zero means zero here.
	public const int32 Auto = -1;

	/// A negative worker count picks logical cores minus one. Zero is a pool with no
	/// workers, which is valid: every wait then runs inline on the calling thread.
	public this(int32 workerCount = Auto)
	{
		var count = workerCount;
		if (count < 0)
		{
			count = (LogicalCoreCount() > 1) ? (LogicalCoreCount() - 1) : 0;
		}
		mWorkerCount = count;

		for (int32 i < count)
			mDeques.Add(new Deque());

		for (int32 i < count)
		{
			let index = i;
			let thread = new Thread(new () => WorkerLoop(index));
			mWorkers.Add(thread);
			thread.Start(false);
		}
	}

	public ~this()
	{
		mStop = true;
		// Manual reset, so every worker sees the stop rather than one consuming it.
		mJobAvailable.Set(true);
		for (let worker in mWorkers)
		{
			worker.Join();
			delete worker;
		}

		// Anything still queued was never run, so its delegate is still ours to free.
		for (let deque in mDeques)
			for (let item in deque.Items)
				delete item.Work;
		for (let item in mExternal)
			delete item.Work;
	}

	/// corlib's Platform.ProcessorCount is a compile-time constant of 8 regardless of the
	/// machine, so the real count comes from the platform call. One is the floor, which
	/// gives the inline fallback rather than a negative worker count.
	public static int32 LogicalCoreCount()
	{
		Platform.BfpSystemResult result = .Ok;
		let cores = Platform.BfpSystem_GetNumLogicalCPUs(&result);
		return ((result == .Ok) && (cores > 0)) ? cores : 1;
	}

	public int32 WorkerCount => mWorkerCount;

	/// The number of distinct slots a body may run on: one per worker plus one for any
	/// non-worker thread. Size per-worker scratch by this and index it with CurrentSlot.
	public int32 SlotCount => mWorkerCount + 1;

	/// The calling thread's slot: its worker index, or WorkerCount for any non-worker.
	/// Stable for the duration of a job, so it can index per-worker scratch without
	/// locking.
	public int32 CurrentSlot
	{
		get
		{
			let self = SelfSlot();
			return (self >= 0) ? self : mWorkerCount;
		}
	}

	/// This thread's worker index within THIS pool, or -1 if it is not one of its
	/// workers.
	private int32 SelfSlot() => (sSlotOwnerId == mId) ? sSlot : -1;

	// ---- submission ----

	/// Runs work sometime on the pool, optionally signalling a counter on completion.
	/// The pool takes ownership of the delegate and deletes it once it has run.
	///
	/// The counter is CALLER SEEDED: this does not add to it. Seed it with the number of
	/// jobs about to be submitted against it. Adding here would read better at the call
	/// site, but it would make a pre-seeded gate impossible to express, and it would
	/// silently double count every site ported from Raptor, which spells it this way.
	public void Submit(delegate void() work, Counter signal = null)
	{
		Schedule(JobItem(work, signal));
	}

	/// Runs work only once dep reaches zero. If dep is already zero it is scheduled
	/// immediately. dep must outlive the call until it reaches zero.
	///
	/// signal is caller seeded, as in Submit.
	public void SubmitAfter(Counter dep, delegate void() work, Counter signal = null)
	{
		let job = JobItem(work, signal);
		var runNow = false;
		using (dep.[Friend]mLock.Enter())
		{
			if (dep.Value == 0)
				runNow = true;
			else
				dep.[Friend]mContinuations.Add(job);
		}
		if (runNow)
			Schedule(job);
	}

	/// Runs body(i) for i in [0, count) across the pool, blocking with caller
	/// participation until all are done. A grain size of zero picks one automatically.
	///
	/// The body belongs to the caller and is not deleted here; the per-chunk delegates
	/// that wrap it are created and deleted by the pool.
	public void ParallelFor(int32 count, delegate void(int32) body, int32 grainSize = 0)
	{
		if (count == 0)
			return;

		let workers = (mWorkerCount > 0) ? mWorkerCount : 1;
		var grain = grainSize;
		if (grain == 0)
		{
			// Roughly four chunks per worker, for load balancing, and never zero.
			grain = (count + (4 * workers) - 1) / (4 * workers);
			if (grain == 0)
				grain = 1;
		}
		let chunks = (count + grain - 1) / grain;

		let done = scope Counter(chunks);
		for (int32 c < chunks)
		{
			let begin = c * grain;
			let end = (begin + grain < count) ? (begin + grain) : count;
			Submit(new () =>
				{
					for (int32 i = begin; i < end; i++)
						body(i);
				}, done);
		}
		Wait(done);
	}

	// ---- waiting; the caller participates ----

	/// Runs jobs until the counter reaches zero. The calling thread is a worker for the
	/// duration.
	public void Wait(Counter counter)
	{
		while (counter.Value != 0)
		{
			if (!RunOneJob())
				Thread.Yield();
		}

		// Lifetime fence. The thread that drove the count to zero did so while holding
		// the counter's lock and may still be inside that critical section. Taking the
		// lock here blocks until it has left, so a caller that destroys the counter
		// immediately after Wait returns cannot free it underneath that thread.
		using (counter.[Friend]mLock.Enter()) { }
	}

	/// Runs jobs until every submitted job has completed.
	public void WaitForAll()
	{
		while (mPending != 0)
		{
			if (!RunOneJob())
				Thread.Yield();
		}
	}

	// ---- internals ----

	private void Schedule(JobItem job)
	{
		Interlocked.Increment(ref mPending);

		if (mWorkerCount == 0)
		{
			// No workers: park on the external list, which a waiting caller drains.
			using (mExternalLock.Enter())
				mExternal.Add(job);
			return;
		}

		let self = SelfSlot();
		int32 target;
		if (self >= 0)
			target = self;
		else
			target = (int32)((uint32)Interlocked.Increment(ref mNextExternal) % (uint32)mWorkerCount);

		using (mDeques[target].Lock.Enter())
			mDeques[target].Items.Add(job);

		mJobAvailable.Set();
	}

	/// Runs one job if there is one: own deque last-in-first-out, else steal oldest-first
	/// from the others, else the external list.
	private bool RunOneJob()
	{
		JobItem job = ?;
		if (!TryGetJob(out job))
			return false;
		RunJob(job);
		return true;
	}

	private bool TryGetJob(out JobItem outJob)
	{
		outJob = default;
		let self = SelfSlot();

		// Own deque, last in first out, which is the cache-friendly end.
		if (self >= 0)
		{
			let d = mDeques[self];
			using (d.Lock.Enter())
			{
				if (!d.Items.IsEmpty)
				{
					outJob = d.Items.PopBack();
					return true;
				}
			}
		}

		// Steal from the others, oldest first: the least contended end.
		for (int32 k < mWorkerCount)
		{
			if ((self >= 0) && (k == self))
				continue;
			let d = mDeques[k];
			using (d.Lock.Enter())
			{
				if (!d.Items.IsEmpty)
				{
					outJob = d.Items[0];
					d.Items.RemoveAt(0);
					return true;
				}
			}
		}

		// Non-worker submissions, and the zero-worker fallback.
		using (mExternalLock.Enter())
		{
			if (!mExternal.IsEmpty)
			{
				outJob = mExternal[0];
				mExternal.RemoveAt(0);
				return true;
			}
		}
		return false;
	}

	private void RunJob(JobItem job)
	{
		job.Work();
		delete job.Work;

		// The completion signal is handled BEFORE this job leaves mPending, because a
		// continuation joins mPending before its predecessor leaves it. Otherwise
		// mPending could momentarily read zero while a dependent is still to come, and
		// WaitForAll would return early.
		if (job.Signal != null)
		{
			var last = false;
			let ready = scope List<JobItem>();

			// Decrement INSIDE the lock. Holding it across the one-to-zero transition,
			// paired with the fence in Wait, stops a released waiter from destroying the
			// counter while this thread is still touching it. Once this scope is left
			// with the count at zero, the counter may already be freed.
			using (job.Signal.[Friend]mLock.Enter())
			{
				if (Interlocked.Decrement(ref job.Signal.[Friend]mCount) == 0)
				{
					last = true;
					for (let cont in job.Signal.[Friend]mContinuations)
						ready.Add(cont);
					job.Signal.[Friend]mContinuations.Clear();
				}
			}

			if (last)
			{
				for (let cont in ready)
					Schedule(cont);
			}
		}

		Interlocked.Decrement(ref mPending);
	}

	private void WorkerLoop(int32 index)
	{
		sSlotOwnerId = mId;
		sSlot = index;

		for (;;)
		{
			if (RunOneJob())
				continue;

			if (mStop)
				return;

			// The event latches, so a Set between the failed run above and this wait is
			// not lost. A timeout keeps a worker from sleeping through a stop that was
			// consumed by another waiter.
			mJobAvailable.WaitFor(1);

			if (mStop && !HasAnyWork())
				return;
		}
	}

	private bool HasAnyWork()
	{
		for (int32 k < mWorkerCount)
		{
			using (mDeques[k].Lock.Enter())
			{
				if (!mDeques[k].Items.IsEmpty)
					return true;
			}
		}
		using (mExternalLock.Enter())
			return !mExternal.IsEmpty;
	}
}
