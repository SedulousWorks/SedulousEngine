namespace Sedulous.Jobs;

using System;
using System.Collections;
using System.Threading;

using internal Sedulous.Jobs;

/// Base class for all jobs. Provides dependency tracking, state management,
/// and ref-counted lifecycle.
abstract class JobBase : RefCounted
{
	private readonly String mName = new .() ~ delete _;
	private readonly JobFlags mFlags;
	protected volatile JobState mState = .Pending;
	private JobPriority mPriority = .Normal;

	private List<JobBase> mDependencies = new .() ~ delete _;
	private List<JobBase> mDependents = new .() ~ delete _;

	/// Event signaled when the job completes (succeeds or is canceled).
	/// Used by Wait() for efficient blocking instead of spin-polling.
	private WaitEvent mCompletionEvent = new .() ~ delete _;

	/// If true, the worker deletes this job after execution instead of
	/// going through HandleCompletion. Used by ParallelFor chunks.
	internal bool mSelfCleanup = false;

	/// Gets whether this job has dependents waiting on it.
	public bool HasDependents => mDependents.Count > 0;

	/// Gets the dependents list (jobs waiting on this one).
	internal List<JobBase> Dependents => mDependents;

	/// Gets the job name.
	public String Name => mName;

	/// Gets the job flags.
	public JobFlags Flags => mFlags;

	/// Gets the current job state.
	public JobState State => mState;

	/// Gets the job priority.
	public JobPriority Priority => mPriority;

	public this(StringView name = default, JobFlags flags = .None)
	{
		if (name.Length > 0)
			mName.Set(name);
		mFlags = flags;
	}

	public ~this()
	{
		for (let dependency in mDependencies)
			dependency.ReleaseRef();
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
			SignalCompletion();
			for (let dependent in mDependents)
				dependent.Cancel();
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
		if (IsCompleted())
			return;
		mCompletionEvent.WaitFor();
	}

	/// Override to implement job execution logic.
	protected virtual void Execute()
	{
	}

	/// Called after the job completes successfully.
	protected virtual void OnCompleted()
	{
	}

	/// Signals the completion event. Called by JobSystem after all post-completion
	/// processing (dependency resolution, completion queue) is done, so Wait()
	/// callers don't resume while the system still holds refs on the job.
	internal void SignalCompletion()
	{
		mCompletionEvent.Set(true);
	}

	/// Runs the job. Called by worker threads. Does NOT signal the completion
	/// event - that's done by JobSystem.HandleCompletion after post-processing.
	internal void Run()
	{
		mState = .Running;
		Execute();

		if (mState == .Canceled)
			return;

		mState = .Succeeded;
		OnCompleted();
	}
}
