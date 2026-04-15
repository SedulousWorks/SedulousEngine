using System;
namespace Sedulous.Jobs;

/// A job that executes a delegate and returns a result.
class DelegateJob<T> : Job<T>
{
	private delegate T() mJob = null ~ { if (mOwnsDelegate) delete _; };
	private bool mOwnsDelegate = false;
	private delegate void(T) mOnCompleted ~ { if (mOwnsOnCompleted) delete _; };
	private bool mOwnsOnCompleted;

	public this(delegate T() job, bool ownsDelegate,
		StringView name = default, JobFlags flags = .None,
		delegate void(T) onCompleted = null, bool ownsOnCompleted = true)
		: base(name, flags)
	{
		mJob = job;
		mOwnsDelegate = ownsDelegate;
		mOnCompleted = onCompleted;
		mOwnsOnCompleted = ownsOnCompleted;
	}

	protected override T OnExecute()
	{
		if (mJob != null)
			return mJob();
		return default;
	}

	protected override void OnCompleted()
	{
		mOnCompleted?.Invoke(mResult);
	}
}
