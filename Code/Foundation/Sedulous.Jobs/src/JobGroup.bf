using System;
using System.Collections;

namespace Sedulous.Jobs;

/// A job that groups multiple jobs together and executes them sequentially.
class JobGroup : Job
{
	private List<JobBase> mJobs = new .() ~ delete _;

	public this(StringView name, JobFlags flags = .None) : base(name, flags)
	{
	}

	public override void Cancel()
	{
		if (State == .Running)
		{
			// Do not cancel a job that is already running
			return;
		}

		for (let job in mJobs)
		{
			job.Cancel();
		}
		base.Cancel();
	}

	protected override void OnExecute()
	{
		for (let job in mJobs)
		{
			job.[Friend]Execute();
		}
	}

	/// Adds a job to the group. Jobs are executed in the order they are added.
	public void AddJob(JobBase job)
	{
		if (State != .Pending)
			Runtime.FatalError("Cannot add job to JobGroup unless the State is pending.");

		mJobs.Add(job);
	}
}
