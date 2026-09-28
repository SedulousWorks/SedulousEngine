using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Editor.Core;

/// The editor's background job runner with progress and step reporting: submit a unit of
/// work, it runs on a worker so the UI stays live, reports through its JobContext, and its
/// completion fires on the MAIN thread from Update. Build lane jobs run ONE AT A TIME, a
/// submit while busy queues: the editor's build lock, so a cook, an export and an import
/// never race the databases. The app pumps Update each frame and reads Progress for the
/// status bar.
///
/// The light lane is short CPU only side work, editor preview bakes, on its OWN worker,
/// concurrent with the build lane and deliberately outside IsBusy: that flag gates cook
/// mutations, and a preview must never lock the build. No progress, no cancellation.
class EditorJobService
{
	public typealias Work = delegate Result<void, ErrorCode>(JobContext context);
	public typealias Done = delegate void(Result<void, ErrorCode> result);
	public typealias LightWork = delegate void();
	public typealias LogLine = delegate void(StringView line);

	private class Pending
	{
		public String Title = new .() ~ delete _;
		public Work Work ~ delete _;
		public Done OnDone ~ delete _;
	}

	private class PendingLight
	{
		public LightWork Work ~ delete _;
		public LightWork OnDone ~ delete _;
	}

	// The build lane.
	private Thread mWorker = null;
	private JobContext mContext = null;
	private Work mWork = null;
	private Done mOnDone = null;
	private String mTitle = new .() ~ delete _;
	private int32 mRunning = 0;
	private int32 mFinished = 0;
	/// Worker written, main read after mFinished.
	private Result<void, ErrorCode> mResult = .Ok;
	private List<Pending> mQueue = new .() ~ DeleteContainerAndItems!(_);

	// The light lane.
	private Thread mLightWorker = null;
	private LightWork mLightWork = null;
	private LightWork mLightOnDone = null;
	private int32 mLightRunning = 0;
	private int32 mLightFinished = 0;
	private List<PendingLight> mLightQueue = new .() ~ DeleteContainerAndItems!(_);

	public ~this()
	{
		Shutdown();
		delete mWork;
		delete mOnDone;
		delete mContext;
		delete mLightWork;
		delete mLightOnDone;
	}

	/// Submits a job, TAKING OWNERSHIP of both delegates. `work` runs on a worker and
	/// reports through its context; `onDone` fires on the main thread from Update with its
	/// result. Immediately when idle, else queued behind the running job.
	public void Submit(StringView title, Work work, Done onDone = null)
	{
		let pending = new Pending();
		pending.Title.Set(title);
		pending.Work = work;
		pending.OnDone = onDone;
		mQueue.Add(pending);
		if (Interlocked.Load(ref mRunning) == 0)
			StartNext();
	}

	public bool IsBusy => (Interlocked.Load(ref mRunning) != 0) || !mQueue.IsEmpty;

	/// TAKES OWNERSHIP. `work` runs on the light worker; `onDone` on the main thread from
	/// Update. Results travel through state both closures capture: the work writes before
	/// the completion flag publishes them to onDone.
	public void SubmitLight(LightWork work, LightWork onDone = null)
	{
		let pending = new PendingLight();
		pending.Work = work;
		pending.OnDone = onDone;
		mLightQueue.Add(pending);
		StartNextLight();
	}

	public bool IsLightBusy => (Interlocked.Load(ref mLightRunning) != 0) || !mLightQueue.IsEmpty;

	/// Asks the running job to stop; cooperative, the worker polls CancelRequested.
	public void CancelActive()
	{
		if (mContext != null)
			mContext.RequestCancel();
	}

	/// The main thread pump, once per frame: drains the active job's log to `log`, and on a
	/// completion fires its onDone and starts the next queued job.
	public void Update(LogLine log = null)
	{
		if (mContext != null)
			Drain(log);

		if (Interlocked.Exchange(ref mLightFinished, 0) != 0)
		{
			JoinLightWorker();
			let onDone = mLightOnDone;
			mLightOnDone = null;
			delete mLightWork;
			mLightWork = null;
			Interlocked.Exchange(ref mLightRunning, 0);
			if (onDone != null)
			{
				onDone();
				delete onDone;
			}
			StartNextLight();
		}

		if (Interlocked.Exchange(ref mFinished, 0) != 0)
		{
			JoinWorker();
			// The final drain, the worker joined so nothing appends any more: the lines it
			// wrote after the drain above and before it finished. Without it a fast job's
			// last lines are lost with the context.
			Drain(log);
			let onDone = mOnDone;
			mOnDone = null;
			delete mWork;
			mWork = null;
			let result = mResult;
			delete mContext;
			mContext = null;
			Interlocked.Exchange(ref mRunning, 0);
			if (onDone != null)
			{
				onDone(result);
				delete onDone;
			}
			StartNext();
		}
	}

	/// Fills `outView` with the running job's state; Active false when idle.
	public void Progress(JobProgress outView)
	{
		outView.Active = false;
		if ((Interlocked.Load(ref mRunning) == 0) || (mContext == null))
			return;
		outView.Active = true;
		outView.Title.Set(mTitle);
		mContext.Snapshot(outView);
	}

	public void Shutdown()
	{
		CancelActive();
		JoinWorker();
		JoinLightWorker();
	}

	private void Drain(LogLine log)
	{
		let drained = scope List<String>();
		defer { ClearAndDeleteItems(drained); }
		mContext.DrainLog(drained);
		if (log != null)
			for (let line in drained)
				log(line);
	}

	private void JoinWorker()
	{
		if (mWorker != null)
		{
			mWorker.Join();
			delete mWorker;
			mWorker = null;
		}
	}

	private void JoinLightWorker()
	{
		if (mLightWorker != null)
		{
			mLightWorker.Join();
			delete mLightWorker;
			mLightWorker = null;
		}
	}

	/// Main thread: dequeues and launches the next job; nothing when busy or empty.
	private void StartNext()
	{
		if ((Interlocked.Load(ref mRunning) != 0) || mQueue.IsEmpty)
			return;
		let job = mQueue.PopFront();
		mTitle.Set(job.Title);
		mWork = job.Work;
		mOnDone = job.OnDone;
		job.Work = null;
		job.OnDone = null;
		delete job;
		mContext = new JobContext();
		mResult = .Ok;
		Interlocked.Exchange(ref mRunning, 1);
		Interlocked.Exchange(ref mFinished, 0);
		mWorker = new Thread(new () =>
			{
				mResult = (mWork != null) ? mWork(mContext) : .Ok;
				Interlocked.Exchange(ref mFinished, 1);
			});
		mWorker.Start(false);
	}

	private void StartNextLight()
	{
		if ((Interlocked.Load(ref mLightRunning) != 0) || mLightQueue.IsEmpty)
			return;
		let job = mLightQueue.PopFront();
		mLightWork = job.Work;
		mLightOnDone = job.OnDone;
		job.Work = null;
		job.OnDone = null;
		delete job;
		Interlocked.Exchange(ref mLightRunning, 1);
		Interlocked.Exchange(ref mLightFinished, 0);
		mLightWorker = new Thread(new () =>
			{
				if (mLightWork != null)
					mLightWork();
				Interlocked.Exchange(ref mLightFinished, 1);
			});
		mLightWorker.Start(false);
	}
}
