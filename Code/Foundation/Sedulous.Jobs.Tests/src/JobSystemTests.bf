using System;
using System.Threading;
using System.Collections;

namespace Sedulous.Jobs.Tests;

class TestJob : Job
{
	public bool WasExecuted { get; private set; } = false;
	public int32 SleepTimeMs { get; set; } = 0;

	public this(StringView name = default, JobFlags flags = .None) : base(name, flags) { }

	protected override void OnExecute()
	{
		WasExecuted = true;
		if (SleepTimeMs > 0)
			Thread.Sleep(SleepTimeMs);
	}
}

class CounterJob : Job
{
	private static int32 sCounter = 0;
	public this(StringView name = default, JobFlags flags = .None) : base(name, flags) { }
	protected override void OnExecute() { Interlocked.Increment(ref sCounter); }
	public static void Reset() { sCounter = 0; }
	public static int32 Value => Interlocked.Load(ref sCounter);
}

class JobSystemTests
{
	[Test]
	public static void TestInitializeShutdown()
	{
		Test.Assert(!JobSystem.IsInitialized);
		JobSystem.Initialize(2);
		Test.Assert(JobSystem.IsInitialized);
		Test.Assert(JobSystem.WorkerCount == 2);
		JobSystem.Shutdown();
		Test.Assert(!JobSystem.IsInitialized);
	}

	[Test]
	public static void TestBasicJobExecution()
	{
		JobSystem.Initialize(2);

		let job = new TestJob("Basic", .AutoRelease);
		job.AddRef(); // observation ref — survives AutoRelease
		JobSystem.Run(job);
		job.Wait();

		Test.Assert(job.WasExecuted);
		Test.Assert(job.State == .Succeeded);

		JobSystem.ProcessCompletions();
		job.ReleaseRef(); // observation ref → rc=0 → delete

		JobSystem.Shutdown();
	}

	[Test]
	public static void TestDelegateJob()
	{
		JobSystem.Initialize(2);

		bool executed = false;
		WaitEvent done = scope .();

		JobSystem.Run(new [&]() => {
			executed = true;
			done.Set();
		}, true, "Delegate");

		done.WaitFor(1000);
		JobSystem.ProcessCompletions();
		Test.Assert(executed);

		JobSystem.Shutdown();
	}

	[Test]
	public static void TestResultJob()
	{
		JobSystem.Initialize(2);

		int32 resultValue = 0;
		WaitEvent done = scope .();

		JobSystem.Run<int32>(new () => { return 42; }, true,
			new [&](result) => { resultValue = result; done.Set(); }, true, "Result");

		done.WaitFor(1000);
		JobSystem.ProcessCompletions();
		Test.Assert(resultValue == 42);

		JobSystem.Shutdown();
	}

	[Test]
	public static void TestJobDependencies()
	{
		JobSystem.Initialize(1); // single worker for deterministic ordering

		let job1 = new TestJob("Job1");
		let job2 = new TestJob("Job2");
		let job3 = new TestJob("Job3");

		job2.AddDependency(job1);
		job3.AddDependency(job2);

		JobSystem.Run(job3);
		JobSystem.Run(job2);
		JobSystem.Run(job1);

		job3.Wait();
		Thread.Sleep(10); // ensure all HandleCompletion calls have completed
		JobSystem.ProcessCompletions();

		Test.Assert(job1.WasExecuted);
		Test.Assert(job2.WasExecuted);
		Test.Assert(job3.WasExecuted);

		// Release in reverse dependency order so destructors chain correctly
		job3.ReleaseRef(); // creation ref → triggers destructor → job2 dependency ReleaseRef
		job2.ReleaseRef(); // creation ref → triggers destructor → job1 dependency ReleaseRef
		job1.ReleaseRef(); // creation ref

		JobSystem.Shutdown();
	}

	[Test]
	public static void TestJobCancellation()
	{
		let job1 = new TestJob("Job1");
		let job2 = new TestJob("Job2");

		job2.AddDependency(job1);
		job1.Cancel();

		Test.Assert(job1.State == .Canceled);
		Test.Assert(job2.State == .Canceled);

		job2.ReleaseRef();
		job1.ReleaseRef();
	}

	[Test]
	public static void TestJobGroup()
	{
		JobSystem.Initialize(2);

		CounterJob.Reset();

		let group = new JobGroup("Group", .AutoRelease);
		group.AddRef(); // observation ref
		for (int i = 0; i < 5; i++)
			group.AddJob(new CounterJob(scope $"C{i}"));

		JobSystem.Run(group);
		group.Wait();
		JobSystem.ProcessCompletions();

		Test.Assert(group.State == .Succeeded);
		Test.Assert(CounterJob.Value == 5);

		group.ReleaseRef(); // observation ref
		JobSystem.Shutdown();
	}

	[Test]
	public static void TestMainThreadJob()
	{
		JobSystem.Initialize(2);

		let job = new TestJob("MainThread", .RunOnMainThread | .AutoRelease);
		job.AddRef(); // observation ref
		JobSystem.Run(job);

		Thread.Sleep(50);
		Test.Assert(!job.WasExecuted);

		JobSystem.ProcessCompletions();
		Test.Assert(job.WasExecuted);
		Test.Assert(job.State == .Succeeded);

		job.ReleaseRef(); // observation ref
		JobSystem.Shutdown();
	}

	[Test]
	public static void TestJobWait()
	{
		JobSystem.Initialize(2);

		let job = new TestJob("Wait", .AutoRelease);
		job.AddRef(); // observation ref
		job.SleepTimeMs = 50;
		JobSystem.Run(job);

		job.Wait();
		Test.Assert(job.IsCompleted());
		Test.Assert(job.WasExecuted);

		JobSystem.ProcessCompletions();
		job.ReleaseRef(); // observation ref
		JobSystem.Shutdown();
	}

	[Test]
	public static void TestJobStates()
	{
		let job = new TestJob("States");

		Test.Assert(job.State == .Pending);
		Test.Assert(job.IsPending());
		Test.Assert(!job.IsCompleted());

		job.ReleaseRef();
	}

	[Test]
	public static void TestMultipleInitShutdownCycles()
	{
		for (int cycle = 0; cycle < 3; cycle++)
		{
			JobSystem.Initialize(2);

			let job = new TestJob(scope $"Cycle{cycle}", .AutoRelease);
			job.AddRef(); // observation ref
			JobSystem.Run(job);
			job.Wait();
			Test.Assert(job.WasExecuted);

			JobSystem.ProcessCompletions();
			job.ReleaseRef(); // observation ref
			JobSystem.Shutdown();
		}
	}

	[Test]
	public static void TestConcurrentSubmission()
	{
		JobSystem.Initialize(2);

		CounterJob.Reset();

		Thread[3] threads = ?;
		for (int t = 0; t < 3; t++)
		{
			threads[t] = new Thread(new () => {
				for (int i = 0; i < 10; i++)
				{
					let job = new CounterJob("C", .AutoRelease);
					JobSystem.Run(job);
				}
			});
			threads[t].Start(false);
		}

		for (int t = 0; t < 3; t++)
		{
			threads[t].Join();
			delete threads[t];
		}

		Thread.Sleep(200);
		JobSystem.ProcessCompletions();
		Test.Assert(CounterJob.Value == 30);

		JobSystem.Shutdown();
	}

	[Test]
	public static void TestNoWorkersRunsOnCallingThread()
	{
		JobSystem.Initialize(0);

		int32 sum = 0;
		JobSystem.ParallelFor(0, 100, scope [&](begin, end) => {
			for (int32 i = begin; i < end; i++)
				sum += i;
		});

		Test.Assert(sum == 4950);
		JobSystem.Shutdown();
	}
}
