using System;
using System.Collections;
using System.Threading;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Tests;

/// Each case builds its own profiler rather than poking a shared singleton.
class ProfilerTests
{
	[Test]
	public static void ASingleScopeIsRecorded()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		{
			profiler.BeginScope("Alpha");
			profiler.EndScope();
		}
		profiler.EndFrame();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples.Count == 1);
		Test.Assert(frame.Samples[0].Name == "Alpha");
		Test.Assert(frame.Samples[0].Depth == 0);
	}

	[Test]
	public static void NestedScopesGetIncreasingDepth()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		{
			profiler.BeginScope("Outer");
			defer profiler.EndScope();

			profiler.BeginScope("Inner");
			profiler.EndScope();

			profiler.BeginScope("Inner2");
			profiler.EndScope();
		}
		profiler.EndFrame();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples.Count == 3);
		Test.Assert(DepthOf(profiler, "Outer") == 0);
		Test.Assert(DepthOf(profiler, "Inner") == 1);
		Test.Assert(DepthOf(profiler, "Inner2") == 1);
	}

	/// A scope closed on a later frame than it was opened does not carry into it: EndFrame
	/// clears the open stack, so the next frame starts at depth zero rather than drifting
	/// deeper every frame.
	[Test]
	public static void AnUnbalancedScopeDoesNotLeakIntoTheNextFrame()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.BeginScope("NeverClosed");
		profiler.EndFrame();

		Test.Assert(profiler.CompletedFrame.Samples.Count == 0, "it never closed, so it never recorded");

		profiler.BeginFrame();
		profiler.BeginScope("Fresh");
		profiler.EndScope();
		profiler.EndFrame();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples.Count == 1);
		Test.Assert(frame.Samples[0].Depth == 0, "not nested inside the abandoned scope");
	}

	/// An unmatched EndScope is ignored rather than reaching past the bottom of the stack.
	[Test]
	public static void AnUnmatchedEndIsHarmless()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.EndScope();
		profiler.EndScope();
		profiler.BeginScope("Alpha");
		profiler.EndScope();
		profiler.EndFrame();

		Test.Assert(profiler.CompletedFrame.Samples.Count == 1);
	}

	[Test]
	public static void DisabledRecordsNothing()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.EndFrame();
		Test.Assert(profiler.CompletedFrame.Samples.Count == 0);

		profiler.Enabled = false;
		profiler.BeginFrame();
		profiler.BeginScope("Ignored");
		profiler.EndScope();
		profiler.EndFrame();

		Test.Assert(profiler.CompletedFrame.Samples.Count == 0, "unchanged, since disabled did nothing");

		// And it was not merely withheld: re enabling must not spill what was recorded
		// while it was off into the next frame.
		profiler.Enabled = true;
		profiler.BeginFrame();
		profiler.BeginScope("Kept");
		profiler.EndScope();
		profiler.EndFrame();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples.Count == 1, scope $"got {frame.Samples.Count} samples");
		Test.Assert(frame.Samples[0].Name == "Kept", "the scope taken while disabled did not surface later");
	}

	[Test]
	public static void TheFrameNumberAdvances()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.BeginScope("Work");
		profiler.EndScope();
		profiler.EndFrame();
		let first = profiler.CompletedFrame.FrameNumber;

		profiler.BeginFrame();
		profiler.BeginScope("Work");
		profiler.EndScope();
		profiler.EndFrame();

		Test.Assert(profiler.CompletedFrame.FrameNumber == first + 1);
	}

	/// A frame's samples are ITS samples: the snapshot is rebuilt, not appended to.
	[Test]
	public static void EachFrameReplacesTheLastSnapshot()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.BeginScope("First");
		profiler.EndScope();
		profiler.EndFrame();

		profiler.BeginFrame();
		profiler.BeginScope("Second");
		profiler.EndScope();
		profiler.EndFrame();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples.Count == 1, "the first frame's sample did not carry over");
		Test.Assert(frame.Samples[0].Name == "Second");
	}

	/// Scopes closed between frames are drained by the frame that ends after them, rather
	/// than being dropped.
	[Test]
	public static void AverageFrameMsCoversTheFramesSoFar()
	{
		let profiler = scope Profiler();
		Test.Assert(profiler.AverageFrameMs == 0.0, "no frames yet, so no average");

		for (int i < 3)
		{
			profiler.BeginFrame();
			Spin(2);
			profiler.EndFrame();
		}

		Test.Assert(profiler.AverageFrameMs > 0.0);
		Test.Assert(profiler.AverageFrameMs <= profiler.CompletedFrame.FrameMs * 10, "in the region of a frame");
	}

	[Test]
	public static void AScopeMeasuresTheTimeItSpans()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.BeginScope("Slow");
		Spin(5);
		profiler.EndScope();
		profiler.EndFrame();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples[0].DurationTicks > 0, "a measurable span, not zero");
		Test.Assert(frame.Samples[0].DurationMs <= frame.FrameMs, "and within the frame that contains it");
	}

	/// The report exists to be read, so the shape is what is checked: a headline, and a
	/// line per sample indented by depth with the parent above the child.
	[Test]
	public static void TheReportNestsChildrenUnderTheirParent()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.BeginScope("Outer");
		profiler.BeginScope("Inner");
		profiler.EndScope();
		profiler.EndScope();
		profiler.EndFrame();

		let report = scope String();
		profiler.BuildReport(report);

		Test.Assert(report.Contains("=== Profile: frame"));
		let outer = report.IndexOf("  Outer:");
		let inner = report.IndexOf("    Inner:");
		Test.Assert(outer >= 0, scope $"no outer line in:\n{report}");
		Test.Assert(inner >= 0, scope $"no indented inner line in:\n{report}");
		Test.Assert(outer < inner, "the parent precedes its child even when they share a start tick");
	}

	/// The tie itself, which is the case the ordering exists for and the one the test
	/// above cannot force: two scopes that really do share a start tick. The snapshot is
	/// plain data, so the samples are crafted rather than raced for.
	[Test]
	public static void TheReportPutsAParentBeforeAChildThatSharesItsStartTick()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.EndFrame();

		let samples = profiler.CompletedFrame.Samples;
		samples.Clear();
		// Recorded in completion order, so the child is added FIRST: a sort that leans on
		// stability alone would keep it there.
		samples.Add(ProfileSample() { Name = "Child", StartTick = 1000, DurationTicks = 1, Depth = 1 });
		samples.Add(ProfileSample() { Name = "Parent", StartTick = 1000, DurationTicks = 2, Depth = 0 });

		let report = scope String();
		profiler.BuildReport(report);

		let parent = report.IndexOf("  Parent:");
		let child = report.IndexOf("    Child:");
		Test.Assert(parent >= 0 && child >= 0, scope $"missing a line in:\n{report}");
		Test.Assert(parent < child, scope $"the child was printed above its parent:\n{report}");
	}

	/// Siblings print in the order they STARTED, not the order they finished. Samples are
	/// recorded on close, so a long scope that began first lands after a short one that
	/// began later, and the report has to undo that.
	[Test]
	public static void TheReportOrdersSiblingsByWhenTheyStarted()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();
		profiler.EndFrame();

		let samples = profiler.CompletedFrame.Samples;
		samples.Clear();
		samples.Add(ProfileSample() { Name = "Second", StartTick = 2000, DurationTicks = 1, Depth = 0 });
		samples.Add(ProfileSample() { Name = "First", StartTick = 1000, DurationTicks = 9, Depth = 0 });

		let report = scope String();
		profiler.BuildReport(report);

		let first = report.IndexOf("  First:");
		let second = report.IndexOf("  Second:");
		Test.Assert(first >= 0 && second >= 0, scope $"missing a line in:\n{report}");
		Test.Assert(first < second, scope $"printed out of start order:\n{report}");
	}

	/// Every thread gets its own stack, so concurrent scopes neither interleave into one
	/// tree nor lose samples.
	[Test]
	public static void ThreadsRecordIndependently()
	{
		let profiler = scope Profiler();
		profiler.BeginFrame();

		let threads = scope List<Thread>();
		for (int t < 4)
		{
			let thread = new Thread(new () =>
				{
					profiler.BeginScope("Worker");
					profiler.BeginScope("Nested");
					profiler.EndScope();
					profiler.EndScope();
				});
			threads.Add(thread);
			thread.Start(false);
		}
		for (let thread in threads)
		{
			thread.Join();
			delete thread;
		}

		profiler.EndFrame();

		let frame = profiler.CompletedFrame;
		Test.Assert(frame.Samples.Count == 8, scope $"got {frame.Samples.Count} samples");
		Test.Assert(profiler.ThreadCount == 4, scope $"got {profiler.ThreadCount} threads");

		// Each thread nested exactly once, and no thread's depth ran away.
		var nested = 0;
		let seen = scope List<int32>();
		for (let sample in frame.Samples)
		{
			Test.Assert(sample.Depth < 2, "one nesting level, not a shared stack");
			if (sample.Depth == 1)
				nested++;
			if (!seen.Contains(sample.ThreadIndex))
				seen.Add(sample.ThreadIndex);
		}
		Test.Assert(nested == 4);
		Test.Assert(seen.Count == 4, "four distinct thread indices");
	}

	/// Two profilers do not see each other's threads: the cached thread slot is tagged with
	/// its owner so that it does not leak across them, which a singleton could never express.
	[Test]
	public static void TwoProfilersDoNotShareThreadState()
	{
		let first = scope Profiler();
		let second = scope Profiler();

		first.BeginFrame();
		second.BeginFrame();

		first.BeginScope("First");
		second.BeginScope("Second");
		second.EndScope();
		first.EndScope();

		first.EndFrame();
		second.EndFrame();

		Test.Assert(first.CompletedFrame.Samples.Count == 1);
		Test.Assert(first.CompletedFrame.Samples[0].Name == "First");
		Test.Assert(first.CompletedFrame.Samples[0].Depth == 0, "not nested inside the other profiler's scope");
		Test.Assert(second.CompletedFrame.Samples.Count == 1);
		Test.Assert(second.CompletedFrame.Samples[0].Name == "Second");
		Test.Assert(second.CompletedFrame.Samples[0].Depth == 0);
	}

	private static int32 DepthOf(Profiler profiler, StringView name)
	{
		for (let sample in profiler.CompletedFrame.Samples)
		{
			if (sample.Name == name)
				return sample.Depth;
		}
		return -1;
	}

	/// Burns at least this many microseconds of wall clock. Sleep has millisecond
	/// granularity at best and can undershoot; this cannot.
	private static void Spin(int64 micros)
	{
		let until = ProfileClock.Now() + micros;
		while (ProfileClock.Now() < until)
		{
		}
	}
}
