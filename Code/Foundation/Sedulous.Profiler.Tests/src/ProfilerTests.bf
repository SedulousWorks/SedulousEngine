using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Tests;

/// The capture store: threads record the scopes they finish into rings of their own, the frame
/// end gathers them into a frame record that refers to nothing in the process (names are ids,
/// threads indices), and the last few seconds of records are kept. Each case builds its own
/// profiler rather than poking a shared one.
class ProfilerTests
{
	/// Busy until the tick counter moves, so a scope has a duration it can see.
	private static void Spin()
	{
		let start = ProfileClock.Now();
		while (ProfileClock.Now() == start)
		{
		}
	}

	private static bool Contains(StringView text, StringView needle) => text.IndexOf(needle) >= 0;

	[Test]
	public static void UnarmedNothingIsRecordedAndNothingIsKept()
	{
		let p = scope Profiler();
		Test.Assert(!p.Armed);
		p.BeginFrame();
		Test.Assert(!p.BeginScope("Alpha"));
		p.EndFrame();
		Test.Assert(p.LatestFrame == null);
		Test.Assert(p.CurrentFrameNumber == 1, "frames are counted anyway");
		let report = scope String();
		p.BuildReport(report);
		Test.Assert(Contains(report, "not armed"), report);
	}

	[Test]
	public static void AFrameHoldsItsThreadsScopesNestedInTicks()
	{
		let p = scope Profiler();
		p.Arm();
		p.BeginFrame();
		Test.Assert(p.BeginScope("Outer"));
		Test.Assert(p.BeginScope("Inner"));
		Test.Assert(p.BeginScope("Deepest"));
		Spin();
		p.EndScope();
		p.EndScope();
		p.EndScope();
		Test.Assert(p.BeginScope("Sibling"));
		p.EndScope();
		p.EndFrame();

		let frame = p.LatestFrame;
		Test.Assert(frame != null);
		Test.Assert(frame.FrameNumber == 0);
		Test.Assert(frame.EndTick >= frame.BeginTick);
		Test.Assert(frame.Threads.Count == 1);
		let thread = frame.Threads[0];
		Test.Assert(thread.Dropped == 0);
		// Recorded as they finished: the deepest first.
		Test.Assert(thread.Scopes.Count == 4);
		Test.Assert((p.NameOf(thread.Scopes[0].Name) == "Deepest") && (thread.Scopes[0].Depth == 2));
		Test.Assert((p.NameOf(thread.Scopes[1].Name) == "Inner") && (thread.Scopes[1].Depth == 1));
		Test.Assert((p.NameOf(thread.Scopes[2].Name) == "Outer") && (thread.Scopes[2].Depth == 0));
		Test.Assert((p.NameOf(thread.Scopes[3].Name) == "Sibling") && (thread.Scopes[3].Depth == 0));
		// Each lies inside its parent, and the frame holds them all.
		Test.Assert(thread.Scopes[0].BeginTick >= thread.Scopes[1].BeginTick);
		Test.Assert(thread.Scopes[0].EndTick <= thread.Scopes[1].EndTick);
		Test.Assert(thread.Scopes[1].EndTick <= thread.Scopes[2].EndTick);
		Test.Assert(thread.Scopes[0].EndTick > thread.Scopes[0].BeginTick);
		Test.Assert(thread.Scopes[2].BeginTick >= frame.BeginTick);
		Test.Assert(thread.Scopes[3].EndTick <= frame.EndTick);
		// A name used twice is one name.
		let outer = thread.Scopes[2].Name;
		p.BeginFrame();
		Test.Assert(p.BeginScope("Outer"));
		p.EndScope();
		p.EndFrame();
		Test.Assert(p.LatestFrame.Threads[0].Scopes[0].Name == outer);
	}

	/// A record refers to nothing in the process: a name made at run time is copied into the
	/// table, and outlives the string it came from.
	[Test]
	public static void NamesOutliveTheStringsTheyCameFrom()
	{
		let p = scope Profiler();
		p.Arm();
		p.BeginFrame();
		{
			let made = scope String()..AppendF("Pass {}", 7);
			Test.Assert(p.BeginScope(made));
			p.EndScope();
			made.Set("overwritten");
		}
		p.EndFrame();
		let name = p.LatestFrame.Threads[0].Scopes[0].Name;
		Test.Assert(p.NameOf(name) == "Pass 7");
		Test.Assert(p.InternName("Pass 7") == name);
	}

	private static ThreadFrame ThreadNamed(Profiler p, FrameRecord frame, StringView name)
	{
		for (let thread in frame.Threads)
		{
			if ((thread.Thread < (uint32)p.Threads.Length) && (p.Threads[thread.Thread].Name == name))
				return thread;
		}
		return null;
	}

	/// Every thread's scopes reach the frame, under the thread's name.
	[Test]
	public static void EveryThreadsScopesReachTheFrameUnderTheThreadsName()
	{
		let p = scope Profiler();
		p.Arm();
		p.BeginFrame();
		{
			let a = scope Thread(new () =>
				{
					ThreadNames.SetCurrent("Loader");
					for (int i < 5)
					{
						p.BeginScope("Load");
						p.EndScope();
					}
				});
			let b = scope Thread(new () =>
				{
					ThreadNames.SetCurrent("Mixer");
					p.BeginScope("Mix");
					p.BeginScope("Voice");
					p.EndScope();
					p.EndScope();
				});
			a.Start(false);
			b.Start(false);
			a.Join();
			b.Join();
		}
		p.EndFrame();

		let frame = p.LatestFrame;
		Test.Assert(frame != null);
		let loader = ThreadNamed(p, frame, "Loader");
		let mixer = ThreadNamed(p, frame, "Mixer");
		Test.Assert((loader != null) && (mixer != null));
		Test.Assert(loader.Scopes.Count == 5);
		Test.Assert(mixer.Scopes.Count == 2);
		Test.Assert((p.NameOf(mixer.Scopes[0].Name) == "Voice") && (mixer.Scopes[0].Depth == 1));
		Test.Assert(loader.Thread != mixer.Thread);
	}

	/// A full ring drops new scopes and says how many; the next frame has room again.
	[Test]
	public static void AFullRingDropsNewScopesAndSaysHowMany()
	{
		let p = scope Profiler();
		p.SetRingCapacity(4, 4);
		p.Arm();
		p.BeginFrame();
		for (int i < 10)
		{
			Test.Assert(p.BeginScope("Burst"));
			p.EndScope();
		}
		p.EndFrame();
		Test.Assert(p.LatestFrame.Threads[0].Scopes.Count == 4);
		Test.Assert(p.LatestFrame.Threads[0].Dropped == 6);

		p.BeginFrame();
		Test.Assert(p.BeginScope("Burst"));
		p.EndScope();
		p.EndFrame();
		Test.Assert(p.LatestFrame.Threads[0].Scopes.Count == 1);
		Test.Assert(p.LatestFrame.Threads[0].Dropped == 0);
	}

	/// The history keeps the last frames, each found by its number.
	[Test]
	public static void TheHistoryKeepsTheLastFramesEachFoundByItsNumber()
	{
		let p = scope Profiler();
		p.SetHistoryLength(3);
		p.Arm();
		for (int f < 5)
		{
			p.BeginFrame();
			Test.Assert(p.BeginScope("Work"));
			p.EndScope();
			p.EndFrame();
		}
		Test.Assert(p.Frame(0) == null);
		Test.Assert(p.Frame(1) == null);
		Test.Assert((p.Frame(2) != null) && (p.Frame(2).FrameNumber == 2));
		Test.Assert(p.Frame(4) != null);
		Test.Assert(p.LatestFrame == p.Frame(4));
		Test.Assert(p.Frame(5) == null, "not run yet");
		Test.Assert(p.Frame(3).BeginTick >= p.Frame(2).EndTick);
	}

	/// Arms are counted, and an unarmed frame keeps no record; scopes left in a ring when the
	/// profiler is disarmed are let go, not shown later.
	[Test]
	public static void ArmsAreCountedAndAnUnarmedFrameKeepsNoRecord()
	{
		let p = scope Profiler();
		p.Arm();
		p.Arm();
		p.Disarm();
		Test.Assert(p.Armed);
		p.Disarm();
		Test.Assert(!p.Armed);
		p.Disarm(); // one too many does not wrap
		Test.Assert(!p.Armed);
		p.Arm();
		Test.Assert(p.Armed);
		p.Disarm();

		p.Arm();
		p.BeginFrame();
		Test.Assert(p.BeginScope("Before"));
		p.EndScope();
		p.Disarm();
		p.EndFrame();
		p.Arm();
		p.BeginFrame();
		p.EndFrame();
		Test.Assert(p.LatestFrame != null);
		Test.Assert(p.LatestFrame.Threads.IsEmpty);
	}

	/// GPU passes join their frame's record when they arrive, a frame or two late; passes for
	/// a frame the history no longer keeps are let go.
	[Test]
	public static void GpuPassesJoinTheirFramesRecordWhenTheyArrive()
	{
		let p = scope Profiler();
		p.SetHistoryLength(2);
		p.Arm();
		p.BeginFrame();
		p.EndFrame(); // frame 0
		p.BeginFrame();
		p.EndFrame(); // frame 1
		Test.Assert(!p.Frame(0).GpuValid);

		let shadow = p.InternName("shadow");
		GpuPassEvent[2] passes = .(.(shadow, 0, 0, 100, 250), .(shadow, 0, 1, 260, 300));
		p.SubmitGpuPasses(0, passes);
		Test.Assert(p.Frame(0).GpuValid);
		Test.Assert(p.Frame(0).Gpu.Count == 2);
		Test.Assert(p.Frame(0).Gpu[1].Queue == 1);
		Test.Assert(p.Frame(0).Gpu[0].EndTick == 250);

		p.BeginFrame();
		p.EndFrame(); // frame 2 takes frame 0's slot
		p.SubmitGpuPasses(0, passes);
		Test.Assert(!p.Frame(2).GpuValid);
		Test.Assert(p.Frame(0) == null);
	}

	/// Counters are registered once, and a frame keeps the values set in it, the last one set
	/// winning.
	[Test]
	public static void CountersAreRegisteredOnceAndAFrameKeepsTheValuesSetInIt()
	{
		let p = scope Profiler();
		let draws = p.RegisterCounter("Draws", .Count);
		let memory = p.RegisterCounter("Texture memory", .Bytes);
		Test.Assert(p.RegisterCounter("Draws", .Count) == draws);
		Test.Assert(p.Counters.Length == 2);
		Test.Assert(p.Counters[memory].Unit == .Bytes);

		p.Arm();
		p.BeginFrame();
		p.SetCounter(draws, 10.0);
		p.SetCounter(draws, 12.0);
		p.SetCounter(memory, 4096.0);
		p.EndFrame();
		Test.Assert(p.LatestFrame.Counters.Count == 2);
		Test.Assert(p.LatestFrame.Counters[0].Counter == draws);
		Test.Assert(p.LatestFrame.Counters[0].Value == 12.0);

		p.BeginFrame();
		p.SetCounter(memory, 8192.0);
		p.EndFrame();
		Test.Assert(p.LatestFrame.Counters.Count == 1, "draws was not set this frame");
		Test.Assert(p.LatestFrame.Counters[0].Counter == memory);
	}

	/// The report shows the newest frame by thread, indented by depth, then the GPU passes.
	[Test]
	public static void TheReportShowsTheNewestFrameByThreadIndentedByDepth()
	{
		let p = scope Profiler();
		p.Arm();
		p.BeginFrame();
		Test.Assert(p.BeginScope("Update"));
		Test.Assert(p.BeginScope("Physics"));
		p.EndScope();
		p.EndScope();
		p.EndFrame();
		let pass = p.InternName("forward");
		GpuPassEvent[1] gpu = .(.(pass, 0, 0, 0, 10));
		p.SubmitGpuPasses(0, gpu);
		let report = scope String();
		p.BuildReport(report);
		Test.Assert(Contains(report, "=== Profile: frame 0"), report);
		Test.Assert(Contains(report, "2 scopes"), report);
		Test.Assert(Contains(report, "    Update: "), report);
		Test.Assert(Contains(report, "      Physics: "), report);
		Test.Assert(Contains(report, "[GPU]"), report);
		Test.Assert(Contains(report, "    forward: "), report);
		// Update begins first, so it is listed before its child.
		Test.Assert(report.IndexOf("Update") < report.IndexOf("Physics"));
	}
}
