using System;
using System.Collections;
namespace Sedulous.Jobs;

/// A job that returns a result of type T.
abstract class Job<T> : JobBase
{
	protected T mResult = default;

	/// Gets the result after the job completes.
	public T Result => mResult;

	public this(StringView? name = null,
		JobFlags flags = .None)
		 : base(name, flags)
	{
	}

	/// Blocks until the job completes and returns the result.
	public T WaitForResult()
	{
		Wait();
		return mResult;
	}

	protected override void Execute()
	{
		mResult = OnExecute();
	}

	/// Override to implement the job's work and return a result.
	protected abstract T OnExecute();
}