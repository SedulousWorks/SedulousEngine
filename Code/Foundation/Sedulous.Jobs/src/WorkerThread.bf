namespace Sedulous.Jobs;

using System;
using System.Threading;

using internal Sedulous.Jobs;

/// Background worker thread that pulls jobs from JobSystem's shared queue.
/// Sleeps on a WaitEvent until signaled — no polling, instant wakeup.
internal class WorkerThread
{
	private readonly Thread mThread;
	private readonly WaitEvent mWakeEvent = new .() ~ delete _;
	private readonly String mName = new .() ~ delete _;
	private volatile bool mRunning = false;

	public String Name => mName;

	public this(StringView name)
	{
		mName.Set(name);
		mThread = new Thread(new => ThreadProc);
		mThread.SetName(mName);
	}

	public ~this()
	{
		if (mRunning)
			Stop();
		delete mThread;
	}

	public void Start()
	{
		mRunning = true;
		mThread.Start(false);
	}

	public void Stop()
	{
		mRunning = false;
		mWakeEvent.Set();
		mThread.Join();
	}

	/// Signals this worker to check for available work.
	public void Wake()
	{
		mWakeEvent.Set();
	}

	private void ThreadProc()
	{
		while (mRunning)
		{
			mWakeEvent.WaitFor();

			if (!mRunning)
				return;

			// Drain the shared queue — keep pulling until empty
			JobBase job;
			while (mRunning && JobSystem.TryDequeue(out job))
			{
				if (!job.IsReady())
				{
					// Dependencies not met — drop it. HandleCompletion will
					// re-enqueue when its prerequisites complete.
					job.ReleaseRef();
					continue;
				}

				job.Run();

				if (job.[Friend]mSelfCleanup)
				{
					// Internal work items (ParallelFor chunks) manage their own
					// completion and don't go through HandleCompletion.
					job.DeleteUnchecked();
				}
				else
				{
					// HandleCompletion transfers the ref from Run's AddRef to the
					// completion queue and signals completion. Do NOT access `job`
					// after this call — the waiting thread may delete it.
					JobSystem.HandleCompletion(job);
				}
			}
		}
	}
}
