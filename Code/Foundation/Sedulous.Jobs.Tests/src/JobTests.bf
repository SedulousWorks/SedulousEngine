using System;
using System.Threading;

namespace Sedulous.Jobs.Tests;

class JobTests
{
	[Test]
	public static void TestJobState()
	{
		var job = scope DelegateJob(new () => { }, true, "TestJob");
		defer job.ReleaseRefNoDelete();

		Test.Assert(job.State == .Pending);
		Test.Assert(job.IsPending());
		Test.Assert(job.IsReady());
		Test.Assert(!job.IsCompleted());
	}

	[Test]
	public static void TestJobExecution()
	{
		var executed = false;
		var job = scope DelegateJob(new [&] () => { executed = true; }, true, "TestJob");
		defer job.ReleaseRefNoDelete();

		Test.Assert(!executed);
		let result = job.[Friend]Run();
		Test.Assert(result == .Success);
		Test.Assert(executed);
		Test.Assert(job.State == .Succeeded);
		Test.Assert(job.IsCompleted());
	}

	[Test]
	public static void TestJobWithResult()
	{
		var job = scope DelegateJob<int32>(new () => 42, true, "ResultJob");
		defer job.ReleaseRefNoDelete();

		job.[Friend]Run();
		Test.Assert(job.Result == 42);
	}

	[Test]
	public static void TestJobDependency()
	{
		var job1 = scope DelegateJob(new () => { }, true, "Job1");
		defer job1.ReleaseRefNoDelete();

		var job2 = scope DelegateJob(new () => { }, true, "Job2");
		defer job2.ReleaseRefNoDelete();

		job2.AddDependency(job1);

		// Job2 should not be ready until Job1 succeeds
		Test.Assert(job1.IsReady());
		Test.Assert(!job2.IsReady());

		job1.[Friend]Run();
		Test.Assert(job1.State == .Succeeded);
		Test.Assert(job2.IsReady());
	}

	[Test]
	public static void TestJobCancel()
	{
		var job = scope DelegateJob(new () => { }, true, "CancelJob");
		defer job.ReleaseRefNoDelete();

		Test.Assert(job.State == .Pending);
		job.Cancel();
		Test.Assert(job.State == .Canceled);
		Test.Assert(job.IsCompleted());
	}

	[Test]
	public static void TestDependentCancelOnCancel()
	{
		var job1 = scope DelegateJob(new () => { }, true, "Job1");
		defer job1.ReleaseRefNoDelete();

		var job2 = scope DelegateJob(new () => { }, true, "Job2");
		defer job2.ReleaseRefNoDelete();

		job2.AddDependency(job1);

		// Canceling job1 should cancel job2
		job1.Cancel();
		Test.Assert(job1.State == .Canceled);
		Test.Assert(job2.State == .Canceled);
	}

	[Test]
	public static void TestJobFlags()
	{
		// Note: Don't use AutoRelease here since we're manually managing the job
		var job = scope DelegateJob(new () => { }, true, "FlagsJob", .RunOnMainThread);
		defer job.ReleaseRefNoDelete();

		Test.Assert(job.Flags.HasFlag(.RunOnMainThread));
		Test.Assert(!job.Flags.HasFlag(.AutoRelease));

		// Test that flags can be combined - use heap allocation for AutoRelease test
		var job2 = new DelegateJob(new () => { }, true, "FlagsJob2", .RunOnMainThread | .AutoRelease);
		// Don't delete - job2 has AutoRelease flag and starts with refCount=1
		// Just verify the flags and let ReleaseRef handle cleanup
		Test.Assert(job2.Flags.HasFlag(.RunOnMainThread));
		Test.Assert(job2.Flags.HasFlag(.AutoRelease));
		job2.ReleaseRef(); // This will delete the job since refCount goes to 0
	}
}
