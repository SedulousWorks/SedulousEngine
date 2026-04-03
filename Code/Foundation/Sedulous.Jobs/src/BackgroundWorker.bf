using System;
using System.Threading;

namespace Sedulous.Jobs;

using internal Sedulous.Jobs;

/// Worker that processes jobs on a background thread.
internal class BackgroundWorker : Worker
{
	private readonly Thread mThread;
	private WaitEvent mWakeEvent = new .() ~ delete _;

	public this(JobSystem jobSystem, StringView name, WorkerFlags flags = .None)
		: base(jobSystem, name, flags)
	{
		mThread = new Thread(new => ProcessJobsAsync);
		mThread.SetName(mName);
	}

	public ~this()
	{
		delete mThread;
	}

	protected override void OnStarting()
	{
		mThread.Start(false);
	}

	protected override void OnStopping()
	{
		mWakeEvent.Set();
		mThread.Join();
	}

	/// Wakes the worker thread to process jobs.
	public void Wake()
	{
		mWakeEvent.Set();
	}

	private void ProcessJobsAsync()
	{
		while (IsRunning)
		{
			// Wait for jobs or wake signal
			mWakeEvent.WaitFor(100);

			if (!IsRunning)
				return;

			ProcessJobs();
		}
	}

	public override void Update()
	{
		if (!IsRunning && mThread.ThreadState == .Stopped)
		{
			// the worker needs to be stopped
			// Set the worker thread state to dead
			mState = .Dead;
		}

		if (!IsRunning)
		{
			// Return any pending jobs to the job system if the worker dies
			using (mJobsMonitor.Enter())
			{
				while (mJobs.Count > 0)
				{
					var job = mJobs.PopFront();
					defer job.ReleaseRef();
					mJobSystem.RequeueJob(job);
				}
			}
		}
	}
}