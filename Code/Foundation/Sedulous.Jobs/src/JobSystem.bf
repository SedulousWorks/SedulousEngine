namespace Sedulous.Jobs;

using System;
using System.Collections;
using System.Threading;
using static System.Platform;

using internal Sedulous.Jobs;

/// Static job system providing immediate dispatch and fork-join parallelism.
///
/// Two execution modes:
///   Run()        - dispatches a job immediately to a worker thread
///   ParallelFor  - splits a range across workers + calling thread, blocks until done
///
/// Workers sleep on WaitEvents and wake instantly when work arrives.
/// Call ProcessCompletions() once per frame to run main-thread callbacks.
static class JobSystem
{
	// Worker threads
	private static WorkerThread[] sWorkers;
	private static int32 sWorkerCount;
	private static volatile bool sInitialized = false;

	// Shared work queue (Monitor-protected)
	private static Monitor sQueueLock = new .() ~ delete _;
	private static Queue<JobBase> sWorkQueue = new .() ~ delete _;

	// Main-thread job queue
	private static Monitor sMainThreadLock = new .() ~ delete _;
	private static Queue<JobBase> sMainThreadQueue = new .() ~ delete _;

	// Completion queue (jobs with callbacks to process on main thread)
	private static Monitor sCompletionLock = new .() ~ delete _;
	private static List<JobBase> sCompletionQueue = new .() ~ delete _;

	/// Whether the job system has been initialized.
	public static bool IsInitialized => sInitialized;

	/// Number of background worker threads.
	public static int32 WorkerCount => sWorkerCount;

	// ==================== Lifecycle ====================

	/// Initializes the job system with the specified number of worker threads.
	/// Pass negative to auto-detect based on CPU core count.
	/// Pass 0 for single-threaded mode (ParallelFor runs on calling thread).
	public static void Initialize(int32 workerCount = -1)
	{
		if (sInitialized)
			return;

		var count = workerCount;
		if (count < 0)
		{
			BfpSystemResult result = .Ok;
			int coreCount = Platform.BfpSystem_GetNumLogicalCPUs(&result);
			if (result == .Ok)
				count = (int32)Math.Max(1, coreCount - 1);
			else
				count = 2;
		}

		sWorkerCount = count;
		sWorkers = new WorkerThread[count];
		for (int32 i = 0; i < count; i++)
		{
			sWorkers[i] = new WorkerThread(scope $"TaskWorker{i}");
			sWorkers[i].Start();
		}

		sInitialized = true;
	}

	/// Shuts down the job system and waits for all workers to finish.
	public static void Shutdown()
	{
		if (!sInitialized)
			return;

		// Stop all workers
		for (int32 i = 0; i < sWorkerCount; i++)
			sWorkers[i].Stop();

		// Clean up workers
		for (int32 i = 0; i < sWorkerCount; i++)
			delete sWorkers[i];
		delete sWorkers;
		sWorkers = null;
		sWorkerCount = 0;

		// Drain remaining queues
		using (sQueueLock.Enter())
		{
			while (sWorkQueue.Count > 0)
			{
				let job = sWorkQueue.PopFront();
				job.Cancel();
				job.ReleaseRef();
			}
		}

		using (sMainThreadLock.Enter())
		{
			while (sMainThreadQueue.Count > 0)
			{
				let job = sMainThreadQueue.PopFront();
				job.Cancel();
				job.ReleaseRef();
			}
		}

		using (sCompletionLock.Enter())
		{
			for (let job in sCompletionQueue)
				job.ReleaseRef();
			sCompletionQueue.Clear();
		}

		sInitialized = false;
	}

	// ==================== Run (immediate dispatch) ====================

	/// Dispatches a job immediately. If the job has unmet dependencies, it will
	/// be re-checked when its prerequisites complete.
	public static void Run(JobBase job)
	{
		Runtime.Assert(sInitialized, "JobSystem not initialized.");

		job.AddRef();

		if (job.Flags.HasFlag(.RunOnMainThread))
		{
			using (sMainThreadLock.Enter())
				sMainThreadQueue.Add(job);
		}
		else
		{
			EnqueueInternal(job, true);
		}
	}

	/// Dispatches a delegate job immediately.
	/// The system takes full ownership via AutoRelease - no manual cleanup needed.
	public static void Run(delegate void() work, bool ownsDelegate,
		StringView name = default, JobFlags flags = .None)
	{
		let job = new DelegateJob(work, ownsDelegate, name, flags | .AutoRelease);
		Run(job);
	}

	/// Dispatches a delegate job with a result and optional completion callback.
	/// The system takes full ownership via AutoRelease - no manual cleanup needed.
	public static void Run<T>(delegate T() work, bool ownsDelegate,
		delegate void(T) onComplete = null, bool ownsOnComplete = true,
		StringView name = default, JobFlags flags = .None)
	{
		let job = new DelegateJob<T>(work, ownsDelegate, name, flags | .AutoRelease, onComplete, ownsOnComplete);
		Run(job);
	}

	// ==================== ParallelFor ====================

	/// Splits [begin, end) into chunks across worker threads + the calling thread.
	/// Blocks until all chunks complete. The calling thread processes one chunk itself
	/// to avoid wasting it while waiting.
	public static void ParallelFor(int32 begin, int32 end,
		delegate void(int32 chunkBegin, int32 chunkEnd) body)
	{
		let range = end - begin;
		if (range <= 0) return;

		// If not initialized or no workers, run everything on calling thread
		if (!sInitialized || sWorkerCount == 0)
		{
			body(begin, end);
			return;
		}

		let chunkCount = Math.Min(range, sWorkerCount + 1);
		let chunkSize = (range + chunkCount - 1) / chunkCount;

		if (chunkCount == 1)
		{
			body(begin, end);
			return;
		}

		// Shared completion state
		int32 remaining = chunkCount;
		WaitEvent completionEvent = scope .();

		// Submit chunks 1..N-1 to workers via the shared queue
		for (int32 i = 1; i < chunkCount; i++)
		{
			let chunkBegin = begin + i * chunkSize;
			let chunkEnd = Math.Min(chunkBegin + chunkSize, end);

			let chunk = new ParallelChunk(body, chunkBegin, chunkEnd, &remaining, completionEvent);
			using (sQueueLock.Enter())
				sWorkQueue.Add(chunk);
		}

		// Wake workers
		let wakeable = Math.Min(chunkCount - 1, sWorkerCount);
		for (int32 i = 0; i < wakeable; i++)
			sWorkers[i].Wake();

		// Calling thread processes chunk 0
		body(begin, Math.Min(begin + chunkSize, end));

		// Check if we were the last to finish
		if (Interlocked.Decrement(ref remaining) != 0)
			completionEvent.WaitFor(); // wait for workers to finish
	}

	// ==================== Main thread ====================

	/// Processes main-thread jobs and completion callbacks.
	/// Call once per frame from the main thread.
	public static void ProcessCompletions()
	{
		if (!sInitialized)
			return;

		// Process main-thread-only jobs
		while (true)
		{
			JobBase job = null;
			using (sMainThreadLock.Enter())
			{
				if (sMainThreadQueue.Count > 0)
					job = sMainThreadQueue.PopFront();
			}
			if (job == null) break;

			if (job.IsReady())
			{
				job.Run();
				// HandleCompletion releases the queue ref and adds a completion ref.
				// Do NOT access `job` after this for AutoRelease jobs.
				HandleCompletion(job);
			}
			else
			{
				// Not ready yet - put it back
				using (sMainThreadLock.Enter())
					sMainThreadQueue.Add(job);
				break; // avoid infinite loop on unresolvable dependency
			}
		}

		// Process completion callbacks (auto-release etc.)
		List<JobBase> completions = scope .();
		using (sCompletionLock.Enter())
		{
			completions.AddRange(sCompletionQueue);
			sCompletionQueue.Clear();
		}

		for (let job in completions)
		{
			if (job.Flags.HasFlag(.AutoRelease))
				job.ReleaseRef();
			job.ReleaseRef();
		}
	}

	// ==================== Internal ====================

	/// Adds a job to the shared work queue and optionally wakes a worker.
	internal static void EnqueueInternal(JobBase job, bool wake)
	{
		using (sQueueLock.Enter())
			sWorkQueue.Add(job);

		if (wake && sWorkers != null && sWorkerCount > 0)
			sWorkers[0].Wake();
	}

	/// Attempts to dequeue a job from the shared queue.
	internal static bool TryDequeue(out JobBase job)
	{
		using (sQueueLock.Enter())
		{
			if (sWorkQueue.Count > 0)
			{
				job = sWorkQueue.PopFront();
				return true;
			}
		}
		job = null;
		return false;
	}

	/// Called by workers after a job finishes. Resolves dependencies,
	/// queues for main-thread cleanup, then signals completion.
	///
	/// Ref ownership transfer: AddRef for the completion queue first, then
	/// ReleaseRef the worker/queue ownership, then signal. The AddRef ensures
	/// rc > 0 during the ReleaseRef. After SignalCompletion, the worker must
	/// NOT access `job` - the waiting thread may delete it.
	internal static void HandleCompletion(JobBase job)
	{
		// Resolve dependents - if a dependent is now ready, dispatch it
		for (let dependent in job.Dependents)
		{
			if (dependent.IsReady())
			{
				dependent.AddRef();
				EnqueueInternal(dependent, true);
			}
		}

		// Transfer ownership: add completion ref BEFORE releasing the worker ref.
		// This ensures rc never hits 0 during the transfer.
		using (sCompletionLock.Enter())
		{
			job.AddRef(); // completion queue ref
			sCompletionQueue.Add(job);
		}
		job.ReleaseRefNoDelete(); // release the worker/queue ref (won't delete - completion ref keeps it alive)

		// Signal LAST - after this, the waiting thread may delete the job.
		job.SignalCompletion();
	}

	// ==================== ParallelFor internals ====================

	/// A lightweight work item for ParallelFor chunks. Not a full Job - no ref
	/// counting, no dependencies, no completion callbacks. Just a delegate + range.
	private class ParallelChunk : JobBase
	{
		private delegate void(int32, int32) mBody;
		private int32 mBegin;
		private int32 mEnd;
		private int32* mRemaining;
		private WaitEvent mCompletionEvent;

		public this(delegate void(int32, int32) body, int32 begin, int32 end,
			int32* remaining, WaitEvent completionEvent)
		{
			mBody = body;
			mBegin = begin;
			mEnd = end;
			mRemaining = remaining;
			mCompletionEvent = completionEvent;
			mSelfCleanup = true; // worker deletes after execution, no HandleCompletion
		}

		protected override void Execute()
		{
			mBody(mBegin, mEnd);

			if (Interlocked.Decrement(ref *mRemaining) == 0)
				mCompletionEvent.Set();
		}
	}
}
