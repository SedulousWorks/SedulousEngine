using System;
namespace Sedulous.Jobs;


/// A job that executes a delegate and returns a result.
class DelegateJob<T> : Job<T>
{
	private delegate T() mJob = null ~ { if (mOwnsJobDelegate) delete _; };
	private bool mOwnsJobDelegate = false;
	private delegate void(T) mOnCompleted ~ { if (mOwnsCompletedDelegate) delete _; };
	private bool mOwnsCompletedDelegate;

	public this(delegate T() job,
		bool ownsJobDelegate,
		StringView? name = null,
		JobFlags flags = .None,
		delegate void(T) onCompleted = null,
		bool ownsCompletedDelegate = true)
		: base(name, flags)
	{
		mJob = job;
		mOwnsJobDelegate = ownsJobDelegate;
		mOnCompleted = onCompleted;
		mOwnsCompletedDelegate = ownsCompletedDelegate;
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