using System;
using System.Threading;
using System.Collections;
using Sedulous.Core.Logging.Abstractions;
using static System.Platform;

namespace Sedulous.Jobs;

using internal Sedulous.Jobs;

/// Manages job execution across worker threads.
class JobSystem
{
	private readonly int32 mWorkerCount;
	private readonly List<BackgroundWorker> mWorkers = new .() ~ delete _;
	private MainThreadWorker mMainThreadWorker = null;

	private readonly Monitor mJobsToRunMonitor = new .() ~ delete _;
	private readonly Queue<JobBase> mJobsToRun = new .() ~ delete _;

	private readonly Monitor mCompletedJobsMonitor = new .() ~ delete _;
	private readonly List<JobBase> mCompletedJobs = new .() ~ delete _;

	private readonly Monitor mCancelledJobsMonitor = new .() ~ delete _;
	private readonly List<JobBase> mCancelledJobs = new .() ~ delete _;

	private bool mIsRunning = false;

	/// Gets the number of background workers.
	public int WorkerCount => mWorkers?.Count ?? 0;

	private readonly ILogger mLogger;
	public ILogger Logger => mLogger;
	
	/// Gets whether the job system is running.
	public bool IsRunning => mIsRunning;

	public this(ILogger logger, int32 workerCount = 0)
	{
		mLogger = logger;
		var count = workerCount;

		// Auto-detect worker count based on CPU cores
		if (count <= 0)
		{
			BfpSystemResult result = .Ok;
			int coreCount = Platform.BfpSystem_GetNumLogicalCPUs(&result);
			if (result == .Ok)
				count = (int32)Math.Max(1, coreCount - 1);
			else
				count = 2;
		}

		mWorkerCount = count;
	}

	public ~this()
	{
		if (mIsRunning)
			Shutdown();

		for (let worker in mWorkers)
			delete worker;

		delete mMainThreadWorker;
	}

	private void CreateWorkers()
	{
		mMainThreadWorker = new .(this, "Main Thread Worker");

		for (int32 i = 0; i < mWorkerCount; i++)
		{
			let worker = new BackgroundWorker(this, scope $"Worker{i}", .Persistent);
			mWorkers.Add(worker);
		}
	}

	private void DestroyWorkers()
	{
		if (mMainThreadWorker != null)
		{
			delete mMainThreadWorker;
			mMainThreadWorker = null;
		}

		for (let worker in mWorkers)
			delete worker;
		mWorkers.Clear();
	}

	private void HandleProcessedJob(JobBase job, Worker worker)
	{
		if (job.State == .Succeeded)
			OnJobCompleted(job, worker);
		else if (job.State == .Canceled)
			OnJobCancelled(job, worker);
	}

	private void OnJobCompleted(JobBase job, Worker worker)
	{
		using (mCompletedJobsMonitor.Enter())
		{
			job.AddRef();
			mCompletedJobs.Add(job);
		}
	}

	private void OnJobCancelled(JobBase job, Worker worker)
	{
		using (mCancelledJobsMonitor.Enter())
		{
			job.AddRef();
			mCancelledJobs.Add(job);
		}
	}

	/// Starts the job system.
	public void Startup()
	{
		if (mIsRunning)
		{
			Logger?.LogError("Startup called on JobSystem that is already running.");
			return;
		}

		CreateWorkers();

		mMainThreadWorker.Start();

		for (let worker in mWorkers)
			worker.Start();

		mIsRunning = true;
	}

	/// Shuts down the job system.
	public void Shutdown()
	{
		if (!mIsRunning)
		{
			Logger?.LogError("Shutdown called on JobSystem that is not running.");
			return;
		}

		// Stop all workers
		for (let worker in mWorkers)
		{
			if (worker.State == .Paused)
				worker.Resume();
			worker.Stop();
		}

		mMainThreadWorker.Stop();

		// Cancel remaining jobs
		while (mJobsToRun.Count > 0)
		{
			let job = mJobsToRun.PopFront();
			defer job.ReleaseRef();
			job.Cancel();
			OnJobCancelled(job, null);
		}

		ClearCompletedJobs();
		ClearCancelledJobs();

		mIsRunning = false;
		DestroyWorkers();
	}

	/// Updates the job system. Call this once per frame from the main thread.
	public void Update()
	{
		if (!mIsRunning)
		{
			Logger?.LogError("Update called on JobSystem that is not running.");
			return;
		}

		// Collect jobs to dispatch
		List<JobBase> jobsToDispatch = scope .();
		using (mJobsToRunMonitor.Enter())
		{
			jobsToDispatch.AddRange(mJobsToRun);
			mJobsToRun.Clear();
		}

		// Dispatch jobs to workers
		for (let job in jobsToDispatch)
		{
			defer job.ReleaseRef();

			if (!job.IsReady())
			{
				// Requeue job
				AddJob(job);
				continue;
			}
			// Check if job was canceled or succeeded
			if (job.State == .Canceled || job.State == .Succeeded)
			{
				HandleProcessedJob(job, null);
				continue;
			}

			// Queue the job on the main thread worker
			// if it has the RunOnMainThread flag or no background workers exist
			if (job.Flags.HasFlag(.RunOnMainThread) || mWorkers.Count == 0)
			{
				if (mMainThreadWorker.QueueJob(job) case .Err)
					RequeueJob(job);
				continue;
			}

			// Find available background worker
			BackgroundWorker targetWorker = null;
			for (let worker in mWorkers)
			{
				if (worker.State == .Idle || worker.State == .Paused)
				{
					targetWorker = worker;
					break;
				}
			}

			if (targetWorker != null)
			{
				if (targetWorker.QueueJob(job) case .Err)
				{
					Logger?.LogError("Failed to queue job on worker '{}'.", targetWorker.Name);
					RequeueJob(job);
				}else{
					targetWorker.Wake();
				}
			}
			else
			{
				// No available worker, requeue
				RequeueJob(job);
			}
		}

		// Handle dead workers
		List<BackgroundWorker> deadWorkers = scope .();
		for (let worker in mWorkers)
		{

			// Update worker in case thread died
			worker.Update();

			// gather dead workers
			if (worker.State == .Dead)
				deadWorkers.Add(worker);
		}

		// Replace dead persistent workers
		for (let deadWorker in deadWorkers)
		{
			let name = scope String(deadWorker.Name);
			let flags = deadWorker.Flags;
			mWorkers.Remove(deadWorker);

			if (flags.HasFlag(.Persistent))
			{
				let newWorker = new BackgroundWorker(this, name, flags);
				newWorker.Start();
				mWorkers.Add(newWorker);
			}

			delete deadWorker;
		}

		// Process main thread jobs
		mMainThreadWorker.Update();

		// Cleanup completed/cancelled jobs
		ClearCompletedJobs();
		ClearCancelledJobs();
	}

	/// Adds a job to be executed.
	public void AddJob(JobBase job)
	{
		if (!mIsRunning)
		{
			Runtime.FatalError("JobSystem is not running.");
		}
		using (mJobsToRunMonitor.Enter())
		{
			job.AddRef();
			mJobsToRun.Add(job);
		}
	}

	/// Requeues a job to the front of the queue. Used internally by workers.
	internal void RequeueJob(JobBase job)
	{
		using (mJobsToRunMonitor.Enter())
		{
			job.AddRef();
			mJobsToRun.AddFront(job);
		}
	}

	public void AddJobs(Span<JobBase> jobs)
	{
		if (!mIsRunning)
		{
			Runtime.FatalError("JobSystem is not running.");
		}
		using (mJobsToRunMonitor.Enter())
		{
			for (JobBase job in jobs)
			{
				job.AddRef();
				mJobsToRun.Add(job);
			}
		}
	}

	/// Adds a delegate job to be executed.
	public void AddJob(delegate void() jobDelegate, bool ownsJobDelegate, StringView? jobName = null, JobFlags flags = .None)
	{
		let job = new DelegateJob(jobDelegate, ownsJobDelegate, jobName, flags | .AutoRelease);
		AddJob(job);
	}

	/// Adds a delegate job with a result to be executed.
	public void AddJob<T>(delegate T() jobDelegate,
		bool ownsJobDelegate,
		StringView? jobName = null,
		JobFlags flags = .None,
		delegate void(T) onCompleted = null,
		bool ownsOnCompletedDelegate = true)
	{
		let job = new DelegateJob<T>(jobDelegate, ownsJobDelegate, jobName, flags | .AutoRelease, onCompleted, ownsOnCompletedDelegate);
		AddJob(job);
	}

	private void ClearCompletedJobs()
	{
		using (mCompletedJobsMonitor.Enter())
		{
			for (let job in mCompletedJobs)
			{
				if (job.Flags.HasFlag(.AutoRelease))
					job.ReleaseRef();
				job.ReleaseRef();
			}
			mCompletedJobs.Clear();
		}
	}

	private void ClearCancelledJobs()
	{
		using (mCancelledJobsMonitor.Enter())
		{
			for (let job in mCancelledJobs)
			{
				if (job.Flags.HasFlag(.AutoRelease))
					job.ReleaseRef();
				job.ReleaseRef();
			}
			mCancelledJobs.Clear();
		}
	}
}
