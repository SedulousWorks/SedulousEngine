using System;

namespace Sedulous.Jobs;

/// Abstract job class that users should extend for custom jobs.
abstract class Job : JobBase
{
	public this(StringView? name = null, JobFlags flags = .None) : base(name, flags)
	{
	}

	protected override void Execute()
	{
		OnExecute();
	}

	/// Override to implement the job's work.
	protected abstract void OnExecute();
}
