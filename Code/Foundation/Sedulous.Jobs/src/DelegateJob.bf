using System;
namespace Sedulous.Jobs;

/// A job that executes a delegate.
class DelegateJob : Job
{
	private delegate void() mJob = null ~ { if (mOwnsDelegate) delete _; };
	private bool mOwnsDelegate = false;

	public this(delegate void() job, bool ownsDelegate,
		StringView name = default, JobFlags flags = .None)
		: base(name, flags)
	{
		mJob = job;
		mOwnsDelegate = ownsDelegate;
	}

	protected override void OnExecute()
	{
		mJob?.Invoke();
	}
}
