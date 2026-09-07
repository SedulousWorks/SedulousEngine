namespace Sedulous.Resource;

/// What a loading screen watches.
///
/// Issue a batch of async binds, Snapshot the outstanding count as the total, then report
/// progress as they finalize. Step pumps within a frame budget so the screen keeps
/// animating; WaitComplete blocks to the end, for a non-interactive load or a test.
///
/// Remaining reads the manager's TOTAL pending, so the progress is only accurate while the
/// manager is dedicated to this batch, which is the ordinary scene-load case. Unrelated
/// concurrent loads would skew it.
struct AsyncLoadBatch
{
	private ResourceManager mManager;
	private int mTotal;

	public this(ResourceManager manager)
	{
		mManager = manager;
		mTotal = 0;
	}

	/// Records what is outstanding right now as the denominator.
	public void Snapshot() mut => mTotal = mManager.PendingCount;

	public int Total => mTotal;
	public int Remaining => mManager.PendingCount;
	public bool IsComplete => mManager.PendingCount == 0;

	/// Zero to one.
	///
	/// A batch with nothing in it is complete rather than divided by zero, and so is one
	/// with nothing left. Remaining above the total would be new work arriving mid batch,
	/// which reports no progress rather than negative progress.
	public float Progress
	{
		get
		{
			let remaining = mManager.PendingCount;
			if ((mTotal == 0) || (remaining == 0))
				return 1.0f;
			let done = (remaining >= mTotal) ? 0 : (mTotal - remaining);
			return (float)done / (float)mTotal;
		}
	}

	/// Finalises what it can within the budget. True once the batch is done.
	public bool Step(double budgetSeconds = 0.002)
	{
		mManager.Pump(budgetSeconds);
		return IsComplete;
	}

	/// Blocks until everything outstanding has finalised.
	public void WaitComplete() => mManager.WaitAll();
}
