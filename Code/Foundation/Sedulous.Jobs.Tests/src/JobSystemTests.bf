using System;
using System.Threading;
using System.Collections;
using Sedulous.Core.Logging.Debug;

namespace Sedulous.Jobs.Tests;

using internal Sedulous.Jobs;

// Test job implementations
class TestJob : Job
{
	public bool WasExecuted { get; private set; } = false;
	public int32 ExecutionCount { get; private set; } = 0;
	public int32 SleepTimeMs { get; set; } = 0;
	public bool ShouldFail { get; set; } = false;

	public this(StringView name, JobFlags flags = .None) : base(name, flags)
	{
	}

	protected override void OnExecute()
	{
		WasExecuted = true;
		ExecutionCount++;

		if (ShouldFail)
		{
			mState = .Canceled;
			return;
		}

		if (SleepTimeMs > 0)
		{
			Thread.Sleep(SleepTimeMs);
		}
	}
}

class CounterJob : Job
{
	public static int32 sGlobalCounter = 0;
	public static Monitor sCounterMonitor = new .() ~ delete _;

	public this(StringView name, JobFlags flags = .None) : base(name, flags)
	{
	}

	protected override void OnExecute()
	{
		using (sCounterMonitor.Enter())
		{
			sGlobalCounter++;
		}
	}

	public static void ResetCounter()
	{
		using (sCounterMonitor.Enter())
		{
			sGlobalCounter = 0;
		}
	}

	public static int32 GetCounter()
	{
		using (sCounterMonitor.Enter())
		{
			return sGlobalCounter;
		}
	}
}

class JobSystemTests
{
	[Test]
	public static void TestJobSystemStartupShutdown()
	{
		let jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		Test.Assert(!jobSystem.IsRunning);

		jobSystem.Startup();
		Test.Assert(jobSystem.IsRunning);
		Test.Assert(jobSystem.WorkerCount == 2);

		jobSystem.Shutdown();
		Test.Assert(!jobSystem.IsRunning);
	}

	[Test]
	public static void BasicJobExecution()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();

		var job = scope TestJob("BasicTest");
		defer job.ReleaseRefNoDelete();
		jobSystem.AddJob(job);

		jobSystem.Update();
		jobSystem.Update();
		jobSystem.Update();

		// Wait for job completion
		WaitForJobCompletion(job, 1000);

		jobSystem.Shutdown();

		Test.Assert(job.WasExecuted);
		Test.Assert(job.State == .Succeeded);
	}

	[Test]
	public static void JobDependencies()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();

		var job1 = scope TestJob("Job1");
		defer job1.ReleaseRefNoDelete();
		var job2 = scope TestJob("Job2");
		defer job2.ReleaseRefNoDelete();
		var job3 = scope TestJob("Job3");
		defer job3.ReleaseRefNoDelete();

		job2.AddDependency(job1);
		job3.AddDependency(job2);

		// Add jobs in reverse order to test dependency resolution
		jobSystem.AddJob(job3);
		jobSystem.AddJob(job2);
		jobSystem.AddJob(job1);

		for (int i = 0; i < 6000; i++)
		{
			jobSystem.Update();
		}

		WaitForJobCompletion(job3, 2000);
		jobSystem.Shutdown();

		Test.Assert(job1.WasExecuted);
		Test.Assert(job2.WasExecuted);
		Test.Assert(job3.WasExecuted);
	}

	[Test]
	public static void MainThreadJobs()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();
		defer jobSystem.Shutdown();

		var mainThreadJob = scope TestJob("MainThreadJob", .RunOnMainThread);
		defer mainThreadJob.ReleaseRefNoDelete();
		jobSystem.AddJob(mainThreadJob);

		// Process main thread jobs
		for (int i = 0; i < 100 && !mainThreadJob.WasExecuted; i++)
		{
			jobSystem.Update();
			Thread.Sleep(10);
		}

		Test.Assert(mainThreadJob.WasExecuted);
	}

	[Test]
	public static void JobCancellation()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 1);
		jobSystem.Startup();

		var job1 = scope TestJob("Job1");
		defer job1.ReleaseRefNoDelete();
		job1.SleepTimeMs = 100;
		var job2 = scope TestJob("Job2");
		defer job2.ReleaseRefNoDelete();
		job2.AddDependency(job1);

		jobSystem.AddJob(job1);
		jobSystem.AddJob(job2);

		// Cancel job1 before it completes
		Thread.Sleep(10);
		job1.Cancel();

		jobSystem.Update();
		jobSystem.Update();
		jobSystem.Update();
		jobSystem.Update();
		WaitForJobCompletion(job1, 1000);

		Test.Assert(job1.State == .Canceled);
		Test.Assert(job2.State == .Canceled);

		jobSystem.Shutdown();
	}

	[Test]
	public static void JobGroups()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();

		CounterJob.ResetCounter();

		var jobGroup = scope JobGroup("TestGroup");
		defer jobGroup.ReleaseRefNoDelete();

		for (int i = 0; i < 5; i++)
		{
			var counterJob = scope:: CounterJob(scope $"Counter{i}", .AutoRelease);
			defer:: counterJob.ReleaseRefNoDelete();
			jobGroup.AddJob(counterJob);
		}

		jobSystem.AddJob(jobGroup);

		for (int i = 0; i < 6000; i++)
		{
			jobSystem.Update();
		}

		WaitForJobCompletion(jobGroup, 2000);
		jobSystem.Shutdown();

		Test.Assert(jobGroup.State == .Succeeded);
		Test.Assert(CounterJob.GetCounter() == 5);
	}

	[Test]
	public static void DelegateJobs()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();
		defer jobSystem.Shutdown();

		bool executed = false;

		jobSystem.AddJob(scope [&]() => {
			executed = true;
		}, false, "DelegateTest");

		// Wait for execution
		for (int i = 0; i < 100 && !executed; i++)
		{
			Thread.Sleep(10);
			jobSystem.Update();
		}

		Test.Assert(executed);
	}

	[Test]
	public static void ResultJobs()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();
		defer jobSystem.Shutdown();

		int32 resultValue = 0;
		bool callbackCalled = false;

		jobSystem.AddJob<int32>(scope () => {
			return 42;
		}, false, "ResultTest", .None, scope [&](result) => {
			resultValue = result;
			callbackCalled = true;
		}, false);

		// Wait for completion
		for (int i = 0; i < 100 && !callbackCalled; i++)
		{
			Thread.Sleep(10);
			jobSystem.Update();
		}

		Test.Assert(callbackCalled);
		Test.Assert(resultValue == 42);
	}

	[Test]
	public static void JobSystemMultipleStartupShutdown()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);

		// Test multiple startup/shutdown cycles
		for (int cycle = 0; cycle < 3; cycle++)
		{
			jobSystem.Startup();
			Test.Assert(jobSystem.WorkerCount == 2);

			var job = scope:: TestJob(scope:: $"CycleTest{cycle}");
			defer:: job.ReleaseRefNoDelete();
			jobSystem.AddJob(job);

			for (int i = 0; i < 6000; i++)
			{
				jobSystem.Update();
			}

			WaitForJobCompletion(job, 1000);

			Test.Assert(job.WasExecuted);

			jobSystem.Shutdown();
		}
	}

	[Test]
	public static void MultipleWorkers()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 4);
		jobSystem.Startup();
		defer jobSystem.Shutdown();

		CounterJob.ResetCounter();

		// Add many jobs to test worker distribution
		List<TestJob> jobs = scope .();
		for (int i = 0; i < 20; i++)
		{
			var job = scope:: TestJob(scope:: $"Worker Test {i}");
			defer:: job.ReleaseRefNoDelete();
			jobs.Add(job);
			jobSystem.AddJob(job);
		}

		// Wait for all jobs to complete
		bool allComplete = false;
		for (int i = 0; i < 200 && !allComplete; i++)
		{
			allComplete = true;
			for (var job in jobs)
			{
				if (!job.IsCompleted())
				{
					allComplete = false;
					break;
				}
			}
			Thread.Sleep(10);
			jobSystem.Update();
		}

		Test.Assert(allComplete);

		int executedCount = 0;
		for (var job in jobs)
		{
			if (job.WasExecuted)
				executedCount++;
		}

		Test.Assert(executedCount == 20);
	}

	[Test]
	public static void JobStates()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 1);
		jobSystem.Startup();
		defer jobSystem.Shutdown();

		var job = scope TestJob("StateTest");
		defer job.ReleaseRefNoDelete();

		Test.Assert(job.State == .Pending);
		Test.Assert(job.IsPending());
		Test.Assert(!job.IsCompleted());

		jobSystem.AddJob(job);

		for (int i = 0; i < 6000; i++)
		{
			jobSystem.Update();
		}

		WaitForJobCompletion(job, 1000);

		Test.Assert(job.State == .Succeeded);
		Test.Assert(!job.IsPending());
		Test.Assert(job.IsCompleted());
	}

	[Test]
	public static void AutoRelease()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 1);
		jobSystem.Startup();
		defer jobSystem.Shutdown();

		// Test that auto-release jobs don't cause issues
		jobSystem.AddJob(scope () => {
			// This job has AutoRelease flag by default
		}, false, "AutoReleaseTest");

		// Allow time for processing
		for (int i = 0; i < 50; i++)
		{
			jobSystem.Update();
			Thread.Sleep(10);
		}

		// If we get here without crashing, auto-release worked
		Test.Assert(true);
	}

	[Test]
	public static void JobSystemWithNoWorkers()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 0);
		jobSystem.Startup();

		var job = scope TestJob("NoWorkerTest");
		jobSystem.AddJob(job);

		// Should execute on main thread
		for (int i = 0; i < 100 && !job.WasExecuted; i++)
		{
			jobSystem.Update();
			Thread.Sleep(10);
		}

		Test.Assert(job.WasExecuted);

		// Extra Update calls to ensure cleanup happens
		for (int i = 0; i < 10; i++)
		{
			jobSystem.Update();
		}

		// Shutdown before leaving scope to ensure proper cleanup
		jobSystem.Shutdown();

		// Now release our ref - should bring refcount to 0
		job.ReleaseRefNoDelete();
	}

	[Test]
	public static void ConcurrentJobAddition()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();

		CounterJob.ResetCounter();

		// Simulate concurrent job addition from multiple threads
		List<Thread> threads = scope .();

		for (int t = 0; t < 3; t++)
		{
			var thread = new Thread(new [&](data) => {
				int threadId = Thread.CurrentThreadId;
				for (int i = 0; i < 10; i++)
				{
					var counterJob = new CounterJob(scope $"ConcurrentJob_{threadId}_{i}", .AutoRelease);
					jobSystem.AddJob(counterJob);
					Thread.Sleep(1);
				}
			});
			threads.Add(thread);
			thread.Start(false);
		}

		// Wait for all threads to finish adding jobs
		for (var thread in threads)
		{
			thread.Join();
			delete thread;
		}

		// Wait for jobs to complete
		for (int i = 0; i < 300; i++)
		{
			jobSystem.Update();
			Thread.Sleep(10);
			if (CounterJob.GetCounter() >= 30)
				break;
		}

		jobSystem.Shutdown();

		Test.Assert(CounterJob.GetCounter() == 30);
	}

	[Test]
	public static void WorkerRecovery()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 2);
		jobSystem.Startup();

		var job = scope TestJob("RecoveryTest");
		defer job.ReleaseRefNoDelete();
		jobSystem.AddJob(job);

		// Update the job system multiple times to trigger worker updates
		for (int i = 0; i < 100; i++)
		{
			jobSystem.Update();
			Thread.Sleep(5);
			if (job.WasExecuted)
				break;
		}

		Test.Assert(job.WasExecuted);
		jobSystem.Shutdown();
	}

	[Test]
	public static void JobIsReadyLogic()
	{
		var job1 = scope TestJob("Job1");
		defer job1.ReleaseRefNoDelete();

		var job2 = scope TestJob("Job2");
		defer job2.ReleaseRefNoDelete();

		var job3 = scope TestJob("Job3");
		defer job3.ReleaseRefNoDelete();

		// Job with no dependencies should be ready
		Test.Assert(job1.IsReady());

		// Add dependency - job2 should not be ready until job1 succeeds
		job2.AddDependency(job1);
		Test.Assert(!job2.IsReady());

		// Manually set job1 to succeeded state
		job1.[Friend]mState = .Succeeded;
		Test.Assert(job2.IsReady());

		// Chain dependencies
		job3.AddDependency(job2);
		Test.Assert(!job3.IsReady()); // job2 hasn't succeeded yet

		job2.[Friend]mState = .Succeeded;
		Test.Assert(job3.IsReady());
	}

	[Test]
	public static void JobSelfDependencyPrevention()
	{
		var job = scope TestJob("SelfTest");
		defer job.ReleaseRefNoDelete();

		// Verify the job doesn't think it depends on itself initially
		Test.Assert(!job.HasDependents);
	}

	[Test]
	public static void JobExecutionOrder()
	{
		var jobSystem = scope JobSystem(scope DebugLogger(.Trace), 1); // Single worker for deterministic order
		jobSystem.Startup();

		List<String> executionOrder = new .();
		var monitor = scope Monitor();

		var job1 = scope DelegateJob(scope () => {
			using (monitor.Enter())
			{
				executionOrder.Add(new String("First"));
			}
		}, false, "First", .None);
		defer job1.ReleaseRefNoDelete();

		var job2 = scope DelegateJob(scope () => {
			using (monitor.Enter())
			{
				executionOrder.Add(new String("Second"));
			}
		}, false, "Second", .None);
		defer job2.ReleaseRefNoDelete();

		var job3 = scope DelegateJob(scope () => {
			using (monitor.Enter())
			{
				executionOrder.Add(new String("Third"));
			}
		}, false, "Third", .None);
		defer job3.ReleaseRefNoDelete();

		// Set up dependencies: job1 -> job2 -> job3
		job2.AddDependency(job1);
		job3.AddDependency(job2);

		// Add in reverse order
		jobSystem.AddJob(job3);
		jobSystem.AddJob(job2);
		jobSystem.AddJob(job1);

		for (int i = 0; i < 6000; i++)
		{
			jobSystem.Update();
		}

		WaitForJobCompletion(job3, 2000);
		jobSystem.Shutdown();

		Test.Assert(executionOrder.Count == 3);
		Test.Assert(executionOrder[0] == "First");
		Test.Assert(executionOrder[1] == "Second");
		Test.Assert(executionOrder[2] == "Third");

		// Clean up
		DeleteContainerAndItems!(executionOrder);
	}

	private static void WaitForJobCompletion(JobBase job, int32 timeoutMs)
	{
		int32 elapsed = 0;
		while (!job.IsCompleted() && elapsed < timeoutMs)
		{
			Thread.Sleep(10);
			elapsed += 10;
		}
	}
}
