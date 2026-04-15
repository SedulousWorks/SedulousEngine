namespace Sedulous.Jobs;

using System.Collections;
using System;

/// A job that groups multiple jobs together and executes them sequentially.
class JobGroup : Job
{
	private List<JobBase> mJobs = new .() ~ { for (let j in _) j.ReleaseRef(); delete _; };

	public this(StringView name = default, JobFlags flags = .None) : base(name, flags)
	{
	}

	public override void Cancel()
	{
		if (State == .Running)
			return;

		for (let job in mJobs)
			job.Cancel();
		base.Cancel();
	}

	protected override void OnExecute()
	{
		for (let job in mJobs)
			job.[Friend]Run();
	}

	/// Adds a job to the group. Jobs are executed in the order they are added.
	public void AddJob(JobBase job)
	{
		if (State != .Pending)
			Runtime.FatalError("Cannot add job to JobGroup unless the State is pending.");

		mJobs.Add(job);
	}
}
