using System;
using Sedulous.Core;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Tests;

/// The frontend instrumentation calls, and the mechanism that lets an uninstrumented
/// build pay nothing for it.
class GlobalProfilerTests
{
	[Test]
	public static void WithNoProfilerInstalledTheFrontendIsHarmless()
	{
		ShutdownGlobalProfiler();
		Test.Assert(!HasGlobalProfiler());

		// The whole point: a unit test or a headless tool never installs one, and the
		// instrumentation scattered through the engine still has to be callable.
		ProfileFrameBegin();
		using (ProfileScope("Nowhere"))
		{
		}
		ProfileFrameEnd();
	}

	/// A token closes its scope under defer too, for a region that is not a block.
	[Test]
	public static void TheFrontendRecordsIntoTheInstalledProfiler()
	{
		let profiler = scope Profiler();
		profiler.Arm();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();

		Test.Assert(HasGlobalProfiler());
		Test.Assert(GlobalProfiler() == profiler);

		ProfileFrameBegin();
		{
			var outer = ProfileScope("Outer");
			defer outer.Dispose();

			using (ProfileScope("Inner"))
			{
			}
		}
		ProfileFrameEnd();

		let frame = profiler.LatestFrame;
		Test.Assert(ScopeCount(frame) == 2, scope $"got {ScopeCount(frame)}");
		Test.Assert(DepthOf(profiler, frame, "Outer") == 0);
		Test.Assert(DepthOf(profiler, frame, "Inner") == 1, "defer closed the outer scope after the inner one");
	}

	/// A scope opened while unarmed is not closed by arming inside it: the token closes only
	/// what it opened, so the thread's nesting stays right.
	[Test]
	public static void AScopeOpenedWhileUnarmedIsNotClosedByArmingInsideIt()
	{
		let profiler = scope Profiler();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();

		ProfileFrameBegin();
		using (ProfileScope("Unrecorded"))
		{
			profiler.Arm();
			using (ProfileScope("Recorded"))
			{
			}
		}
		ProfileFrameEnd();

		let frame = profiler.LatestFrame;
		Test.Assert(frame != null);
		Test.Assert(DepthOf(profiler, frame, "Unrecorded") == -1);
		Test.Assert(DepthOf(profiler, frame, "Recorded") == 0);
		Test.Assert(ScopeCount(frame) == 1);

		// Where it would hurt: inside a recorded scope, the unrecorded one's close must not end
		// the parent, or what follows would land at the parent's depth, outside it.
		ProfileFrameBegin();
		using (ProfileScope("Parent"))
		{
			profiler.Disarm();
			using (ProfileScope("Skipped"))
				profiler.Arm();
			using (ProfileScope("Child"))
			{
			}
		}
		ProfileFrameEnd();
		let second = profiler.LatestFrame;
		Test.Assert(DepthOf(profiler, second, "Child") == 1, "the child is still inside its parent");
		Test.Assert(DepthOf(profiler, second, "Parent") == 0);
	}

	/// Every job a job system runs shows as a "Job" scope on the lane of the thread that ran
	/// it, a worker's or the waiting caller's, with its own scopes nested inside.
	[Test]
	public static void AJobSystemsJobsShowOnTheirThreadsLanesWithTheirScopesInside()
	{
		let profiler = scope Profiler();
		profiler.Arm();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();

		ProfileFrameBegin();
		{
			let jobs = scope JobSystem(2);
			for (int i < 40)
			{
				jobs.Submit(new () =>
					{
						using (ProfileScope("Inside a job"))
							Spin();
					});
			}
			jobs.WaitForAll();
		}
		ProfileFrameEnd();

		let frame = profiler.LatestFrame;
		Test.Assert(frame != null);
		var jobScopes = 0;
		var insideScopes = 0;
		for (let thread in frame.Threads)
		{
			let lane = profiler.Threads[thread.Thread].Name;
			for (let recorded in thread.Scopes)
			{
				if (profiler.NameOf(recorded.Name) == "Job")
				{
					jobScopes++;
					Test.Assert(recorded.Depth == 0);
					Test.Assert(lane.StartsWith("Worker ") || lane.StartsWith("Thread ") || (lane == ThreadNames.Current), lane);
				}
				if (profiler.NameOf(recorded.Name) == "Inside a job")
				{
					insideScopes++;
					Test.Assert(recorded.Depth == 1);
				}
			}
		}
		Test.Assert(jobScopes == 40, scope $"{jobScopes} job scopes");
		Test.Assert(insideScopes == 40, scope $"{insideScopes} scopes inside jobs");

		// Shutting the profiler down takes the hooks with it.
		ShutdownGlobalProfiler();
		Test.Assert(JobHooks.Current == null);
	}

	/// Busy until the tick counter moves, so a scope has a duration it can see.
	private static void Spin()
	{
		let start = ProfileClock.Now();
		while (ProfileClock.Now() == start)
		{
		}
	}

	/// The form instrumentation should actually use. Leaving the block closes the scope,
	/// so the nesting follows the braces rather than a defer that has to be remembered.
	[Test]
	public static void UsingBracketsAScopeWithItsBlock()
	{
		let profiler = scope Profiler();
		profiler.Arm();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();

		ProfileFrameBegin();
		using (ProfileScope("Outer"))
		{
			using (ProfileScope("Inner"))
			{
			}

			// Closed with the inner block, so this is a sibling and not a child.
			using (ProfileScope("Sibling"))
			{
			}
		}
		ProfileFrameEnd();

		let frame = profiler.LatestFrame;
		Test.Assert(ScopeCount(frame) == 3, scope $"got {ScopeCount(frame)}");
		Test.Assert(DepthOf(profiler, frame, "Outer") == 0);
		Test.Assert(DepthOf(profiler, frame, "Inner") == 1);
		Test.Assert(DepthOf(profiler, frame, "Sibling") == 1, "a sibling of Inner, not nested in it");
	}

	/// An early return still closes the scope, which is the reason to prefer using over a
	/// matched pair of calls.
	[Test]
	public static void UsingClosesTheScopeOnAnEarlyReturn()
	{
		let profiler = scope Profiler();
		profiler.Arm();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();

		ProfileFrameBegin();
		ReturnsEarly();
		using (ProfileScope("After"))
		{
		}
		ProfileFrameEnd();

		let frame = profiler.LatestFrame;
		Test.Assert(ScopeCount(frame) == 2);
		Test.Assert(DepthOf(profiler, frame, "After") == 0, "the abandoned scope was closed, not left open");
	}

	private static void ReturnsEarly()
	{
		using (ProfileScope("Abandoned"))
		{
			return;
		}
	}

	/// Installing replaces, and owning deletes. Not owning leaves the caller's profiler
	/// alone, which is what the scope allocated ones above depend on.
	[Test]
	public static void InstallingReplacesAndOwnershipDecidesTheDelete()
	{
		let borrowed = scope Profiler();
		InitGlobalProfiler(borrowed);

		// Owned, and installed over the borrowed one: the borrowed one is not touched.
		InitGlobalProfiler(new Profiler(), true);
		Test.Assert(GlobalProfiler() != borrowed);

		// Deletes the owned one rather than leaking it.
		ShutdownGlobalProfiler();
		Test.Assert(!HasGlobalProfiler());
		Test.Assert(GlobalProfiler() == null);

		// The borrowed one survived, since it was never owned.
		borrowed.BeginFrame();
		borrowed.EndFrame();
	}

	private static int ScopeCount(FrameRecord frame)
	{
		var count = 0;
		for (let thread in frame.Threads)
			count += thread.Scopes.Count;
		return count;
	}

	private static int32 DepthOf(Profiler profiler, FrameRecord frame, StringView name)
	{
		for (let thread in frame.Threads)
		{
			for (let recorded in thread.Scopes)
			{
				if (profiler.NameOf(recorded.Name) == name)
					return (int32)recorded.Depth;
			}
		}
		return -1;
	}
}
