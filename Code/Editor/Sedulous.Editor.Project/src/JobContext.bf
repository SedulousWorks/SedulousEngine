using System;
using System.Collections;
using System.Threading;

namespace Sedulous.Editor.Core;

/// Handed to a job's worker; thread safe progress reporting back to the UI. One monitor
/// guards the whole snapshot, fraction, step and log; cancellation is a flag.
class JobContext
{
	private Monitor mLock = new .() ~ delete _;
	private float mFraction = 0.0f;
	private String mStep = new .() ~ delete _;
	private int mStepIndex = 0;
	private int mStepCount = 0;
	private List<String> mLog = new .() ~ DeleteContainerAndItems!(_);
	private int32 mCancel = 0;

	/// Overall progress, clamped to 0..1.
	public void SetFraction(float fraction)
	{
		using (mLock.Enter())
			mFraction = Math.Clamp(fraction, 0.0f, 1.0f);
	}

	/// A named step, "index/count: label", index 1 based for display; 0/0 is no breakdown.
	public void SetStep(StringView label, int index = 0, int count = 0)
	{
		using (mLock.Enter())
		{
			mStep.Set(label);
			mStepIndex = index;
			mStepCount = count;
		}
	}

	/// Queues a line for the app's console, drained on the main thread by Update.
	public void Log(StringView message)
	{
		using (mLock.Enter())
			mLog.Add(new String(message));
	}

	/// Cooperative cancellation: a long worker polls this and bails early.
	public bool CancelRequested => Interlocked.Load(ref mCancel) != 0;

	// ---- the service's side; a worker never calls these ----

	public void RequestCancel() => Interlocked.Exchange(ref mCancel, 1);

	/// Moves every queued log line to `outLines`.
	public void DrainLog(List<String> outLines)
	{
		using (mLock.Enter())
		{
			outLines.AddRange(mLog);
			mLog.Clear();
		}
	}

	public void Snapshot(JobProgress outView)
	{
		using (mLock.Enter())
		{
			outView.Fraction = mFraction;
			outView.Step.Set(mStep);
			outView.StepIndex = mStepIndex;
			outView.StepCount = mStepCount;
		}
	}
}
