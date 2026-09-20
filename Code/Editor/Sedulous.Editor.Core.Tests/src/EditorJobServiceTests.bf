using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// A job runs on a worker, reports through its context, and completes on the main thread
/// from Update. The tests pump Update in a bounded spin, the workers being fast.
static class EditorJobServiceTests
{
	/// Pumps until nothing is in flight; bounded so a hang fails instead of spinning.
	private static void PumpUntilIdle(EditorJobService jobs, EditorJobService.LogLine log = null)
	{
		int guard = 0;
		while (jobs.IsBusy && (guard++ < 2000000))
			jobs.Update(log);
		jobs.Update(log);
	}

	private static void PumpUntilLightIdle(EditorJobService jobs)
	{
		int guard = 0;
		while (jobs.IsLightBusy && (guard++ < 2000000))
			jobs.Update();
		jobs.Update();
	}

	[Test]
	public static void ASubmittedJobRunsReportsAndCompletesOnUpdate()
	{
		let jobs = scope EditorJobService();
		bool doneFired = false;
		bool okStatus = false;
		jobs.Submit("Work",
			new (context) =>
			{
				context.SetStep("phase one", 1, 2);
				context.SetFraction(0.5f);
				context.Log("halfway");
				context.SetStep("phase two", 2, 2);
				context.SetFraction(1.0f);
				return Result<void, ErrorCode>.Ok;
			},
			new [&doneFired, &okStatus](result) =>
			{
				doneFired = true;
				okStatus = result case .Ok;
			});
		Test.Assert(jobs.IsBusy, "spawned before Submit returned");
		let logs = scope List<String>();
		defer { ClearAndDeleteItems(logs); }
		PumpUntilIdle(jobs, scope [&](line) => { logs.Add(new String(line)); });
		Test.Assert(doneFired && okStatus);
		Test.Assert(!jobs.IsBusy);
		let progress = scope JobProgress();
		jobs.Progress(progress);
		Test.Assert(!progress.Active, "idle: no active progress");
		bool sawLog = false;
		for (let line in logs)
			if (line == "halfway")
				sawLog = true;
		Test.Assert(sawLog, "the log line survived the completion drain");
	}

	[Test]
	public static void AFailingJobPropagatesItsResultToOnDone()
	{
		let jobs = scope EditorJobService();
		bool failed = false;
		jobs.Submit("Bad", new (context) => { return Result<void, ErrorCode>.Err(.Internal); }, new [&failed](result) => { failed = result case .Err; });
		PumpUntilIdle(jobs);
		Test.Assert(failed);
	}

	[Test]
	public static void SubmissionsRunOneAtATimeInOrder()
	{
		let jobs = scope EditorJobService();
		let order = scope List<int>();
		// The completions run on the main thread from Update, so appending is race free.
		for (int i < 3)
		{
			let index = i;
			jobs.Submit("n", new (context) => { return Result<void, ErrorCode>.Ok; }, new [=index, &order](result) => { order.Add(index); });
		}
		PumpUntilIdle(jobs);
		Test.Assert(order.Count == 3);
		Test.Assert((order[0] == 0) && (order[1] == 1) && (order[2] == 2));
	}

	[Test]
	public static void TheLightLaneRunsConcurrentlyAndNeverTripsIsBusy()
	{
		let jobs = scope EditorJobService();
		int value = 0;
		bool lightDone = false;
		jobs.SubmitLight(new [&value]() => { value = 42; }, new [&lightDone]() => { lightDone = true; });
		Test.Assert(!jobs.IsBusy, "the build lane is not busy");
		Test.Assert(jobs.IsLightBusy);
		PumpUntilLightIdle(jobs);
		Test.Assert(lightDone);
		Test.Assert(value == 42, "the work's writes are published before onDone");
		Test.Assert(!jobs.IsLightBusy && !jobs.IsBusy);
	}

	[Test]
	public static void QueuedLightJobsRunInOrderAndOnDoneMayChainAnother()
	{
		let jobs = scope EditorJobService();
		let order = scope List<int>();
		bool chained = false;
		jobs.SubmitLight(null, new [&order]() => { order.Add(1); });
		jobs.SubmitLight(null, new [&order, &chained, =jobs]() =>
			{
				order.Add(2);
				if (!chained)
				{
					chained = true;
					jobs.SubmitLight(null, new [&order]() => { order.Add(3); });
				}
			});
		PumpUntilLightIdle(jobs);
		Test.Assert(order.Count == 3);
		Test.Assert((order[0] == 1) && (order[1] == 2) && (order[2] == 3));
	}
}
