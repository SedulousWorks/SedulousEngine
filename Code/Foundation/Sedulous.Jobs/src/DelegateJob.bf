using System;

namespace Sedulous.Jobs;

/// A job that executes a delegate.
class DelegateJob : Job
{
	private delegate void() mJob = null~ { if (mOwnsJobDelegate) delete _; };
	private bool mOwnsJobDelegate = false;

	public this(delegate void() job,
		bool ownsJobDelegate, 
		StringView? name = null, 
		JobFlags flags = .None)
		: base(name, flags)
	{
		mJob = job;
		mOwnsJobDelegate = ownsJobDelegate;
	}

	protected override void OnExecute()
	{
		mJob?.Invoke();
	}
}