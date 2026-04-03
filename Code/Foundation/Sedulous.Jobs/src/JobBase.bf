using System;
using System.Collections;
using System.Threading;

namespace Sedulous.Jobs;

/// Base class for all jobs. Provides dependency tracking and lifecycle management.
abstract class JobBase : RefCounted
{
	private readonly String mName = new .() ~ delete _;
	private readonly JobFlags mFlags;
	protected JobState mState = .Pending;
	private JobPriority mPriority = .Normal;

	private List<JobBase> mDependencies = new .() ~ delete _;
	private List<JobBase> mDependents = new .() ~ delete _;

	/// Gets whether this job has dependents waiting on it.
	public bool HasDependents => mDependents.Count > 0;

	/// Gets the job name.
	public String Name => mName;

	/// Gets the job flags.
	public JobFlags Flags => mFlags;

	/// Gets the current job state.
	public JobState State => mState;

	/// Gets the job priority.
	public JobPriority Priority => mPriority;

	public this(StringView? name, JobFlags flags = .None)
	{
		if (name != null)
			mName.Set(name.Value);
		mFlags = flags;
	}

	public ~this()
	{
		for (JobBase dependency in mDependencies)
		{
			dependency.ReleaseRef();
		}
	}

	/// Adds a dependency. This job will not run until the dependency completes.
	public void AddDependency(JobBase dependency)
	{
		if (dependency == this)
			Runtime.FatalError("Job cannot depend on itself.");

		if (dependency.mDependencies.Contains(this))
			Runtime.FatalError("Circular dependency detected.");

		mDependencies.Add(dependency);
		dependency.AddRef();
		dependency.mDependents.Add(this);
	}

	/// Returns true if the job is pending.
	public bool IsPending()
	{
		return mState == .Pending;
	}

	/// Returns true if the job is ready to run (all dependencies succeeded).
	public bool IsReady()
	{
		for (let dependency in mDependencies)
		{
			if (dependency.mState != .Succeeded)
				return false;
		}
		return IsPending();
	}

	/// Cancels this job and all dependents.
	public virtual void Cancel()
	{
		if (mState != .Succeeded && mState != .Canceled)
		{
			mState = .Canceled;
			for (let dependent in mDependents)
			{
				dependent.Cancel();
			}
		}
	}

	/// Returns true if the job is completed (succeeded or canceled).
	public virtual bool IsCompleted()
	{
		return mState == .Canceled || mState == .Succeeded;
	}

	/// Blocks until the job completes (succeeds or is canceled).
	public void Wait()
	{
		while (!IsCompleted())
		{
			Thread.Sleep(1);
		}
	}

	/// Override to implement job execution logic.
	protected virtual void Execute()
	{
	}

	/// Called after the job completes successfully.
	protected virtual void OnCompleted()
	{
	}

	/// Runs the job. Returns the result of the run attempt.
	internal JobRunResult Run()
	{
		if (!IsReady())
			return .NotReady;

		mState = .Running;
		Execute();

		if (mState == .Canceled)
			return .Cancelled;

		mState = .Succeeded;
		OnCompleted();
		return .Success;
	}
}
