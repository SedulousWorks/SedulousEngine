using System;
using System.Threading;
using System.Collections;

namespace Sedulous.Jobs;

using internal Sedulous.Jobs;

/// Base class for job workers.
internal abstract class Worker
{
	protected readonly JobSystem mJobSystem;
	protected readonly String mName = new .() ~ delete _;
	private bool mIsRunning = false;
	protected WorkerState mState = .Paused;
	private readonly WorkerFlags mFlags;

	protected Monitor mJobsMonitor = new .() ~ delete _;
	protected Queue<JobBase> mJobs = new .() ~ delete _;

	/// Gets whether this worker is running.
	public bool IsRunning => mIsRunning;

	/// Gets the worker name.
	public String Name => mName;

	/// Gets the current worker state.
	public WorkerState State => mState;

	/// Gets the worker flags.
	public WorkerFlags Flags => mFlags;

	public this(JobSystem jobSystem, StringView name, WorkerFlags flags)
	{
		mJobSystem = jobSystem;
		mName.Set(name);
		mFlags = flags;
	}

	protected virtual void OnStarting() { }

	/// Starts the worker.
	public void Start()
	{
		if (mIsRunning)
		{
			mJobSystem.Logger?.LogError("Start called on a worker '{}' that is already running.", mName);
			return;
		}

		OnStarting();

		mIsRunning = true;
		mState = .Idle;
	}

	protected virtual void OnStopping() { }

	/// Stops the worker.
	public void Stop()
	{
		if (!mIsRunning)
		{
			mJobSystem.Logger?.LogError("Stop called on a worker '{}' that is not running.", mName);
			return;
		}

		mIsRunning = false;

		// Ensure the last task is completed
		WaitForIdle();

		OnStopping();

		// Return remaining jobs to the system
		using (mJobsMonitor.Enter())
		{
			while (mJobs.Count > 0)
			{
				let job = mJobs.PopFront();
				defer job.ReleaseRef();
				mJobSystem.AddJob(job);
			}
		}

		mState = .Dead;
	}

	/// Waits until the worker is idle.
	public void WaitForIdle()
	{
		while (mState == .Busy)
		{
			Update();
		}
	}

	protected virtual void OnPausing() { }

	/// Pauses the worker.
	public void Pause()
	{
		using (mJobsMonitor.Enter())
		{
			if (mState == .Idle && mJobs.Count == 0)
			{
				OnPausing();
				mState = .Paused;
			} else
			{
				mJobSystem.Logger?.LogWarning("Pause called on worker that is not idle. The worker will not be paused.");
			}
		}
	}

	protected virtual void OnResuming() { }

	/// Resumes the worker.
	public void Resume()
	{
		if (mState == .Paused)
		{
			OnResuming();
			mState = .Idle;
		} else
		{
			mJobSystem.Logger?.LogWarning("Resume called on worker that is not paused.");
		}
	}

	public Result<void> QueueJobs(Span<JobBase> jobs)
	{
		if (mState == .Dead)
		{
			return .Err;
		}

		if (mState == .Paused)
			Resume();

		using (mJobsMonitor.Enter())
		{
			for (JobBase job in jobs)
			{
				mJobs.Add(job);
				job.AddRef();
			}
		}
		return .Ok;
	}

	/// Queues a job on this worker.
	public Result<void> QueueJob(JobBase job)
	{
		if (mState == .Dead)
		{
			return .Err;
		}

		if (mState == .Paused)
			Resume();

		using (mJobsMonitor.Enter())
		{
			mJobs.Add(job);
			job.AddRef();
		}

		return .Ok;
	}

	/// Called each frame to update the worker.
	public virtual void Update()
	{
	}

	/// Processes all queued jobs.
	protected void ProcessJobs()
	{
		while (mJobs.Count > 0)
		{
			if (!mIsRunning)
			{
				break;
			}

			mState = .Busy;

			JobBase currentJob = null;
			using (mJobsMonitor.Enter())
			{
				if (mJobs.Count > 0)
					currentJob = mJobs.PopFront();
			}

			if (currentJob == null)
				break;

			defer currentJob.ReleaseRef();

			if (!currentJob.IsReady())
			{
				mJobSystem.AddJob(currentJob);
				continue;
			}

			mJobSystem.Logger?.LogInformation("Worker: {} - Running job: {}.", mName, currentJob.Name);
			let result = currentJob.[Friend]Run();
			if (result == .NotReady)
			{
				mJobSystem.AddJob(currentJob);
				continue;
			}

			mJobSystem.[Friend]HandleProcessedJob(currentJob, this);
		}

		mState = .Idle;
	}
}
