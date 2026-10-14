using System;
using Sedulous.Core.IO;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Tests;

/// A viewer's own copy of frames: the frames after it began, once their GPU passes have had
/// time to land, with the tables they lean on; the oldest dropped when full; a source like any
/// other, so it saves as a capture. The store it copies from is left alone.
class ProfileRecordingTests
{
	/// `count` frames, each an Update scope (a new name on the frame numbered `lateNameAt`).
	private static void RunFrames(Profiler p, uint32 count, uint64 lateNameAt = uint64.MaxValue)
	{
		for (uint32 f < count)
		{
			p.BeginFrame();
			Test.Assert(p.BeginScope((p.CurrentFrameNumber == lateNameAt) ? "Late" : "Update"));
			p.EndScope();
			p.EndFrame();
		}
	}

	[Test]
	public static void FramesAfterItBeganOnceSettledWithTheirTables()
	{
		let p = scope Profiler();
		p.Arm();
		RunFrames(p, 3); // before it began: not recorded
		let live = scope LiveProfileSource(p);
		let recording = scope ProfileRecording();
		Test.Assert(!recording.HasFrames);
		recording.Begin(live);
		Test.Assert(recording.TickFrequency == live.TickFrequency);

		RunFrames(p, 6, 5); // frames 3..8; frame 5 interns a new name
		// A GPU pass for frame 4 arrives late, as a pass does; the recording waits for it.
		let begin = p.Frame(4).BeginTick;
		var pass = GpuPassEvent(p.InternName("forward"), 0, 0, begin, begin + 10);
		p.SubmitGpuPasses(4, .(&pass, 1));

		recording.Pull(live); // settled: up to 8 - 4 = frame 4
		Test.Assert(recording.HasFrames);
		Test.Assert(recording.OldestFrame == 3);
		Test.Assert(recording.NewestFrame == 4);
		Test.Assert(recording.Frame(4) != null);
		Test.Assert(recording.Frame(4).GpuValid);
		Test.Assert(recording.Frame(4).Gpu.Count == 1);
		Test.Assert(recording.NameOf(recording.Frame(4).Gpu[0].Name) == "forward");
		Test.Assert(recording.Frame(2) == null, "before it began");

		recording.Pull(live, 0); // stopping: the rest as they are
		Test.Assert(recording.NewestFrame == 8);
		Test.Assert(recording.FrameCount == 6);
		let late = recording.Frame(5);
		Test.Assert(late != null);
		Test.Assert((late.Threads.Count == 1) && (late.Threads[0].Scopes.Count == 1));
		Test.Assert(recording.NameOf(late.Threads[0].Scopes[0].Name) == "Late");
		Test.Assert(recording.Threads.Length == live.Threads.Length);

		// A second pull with nothing new copies nothing twice.
		recording.Pull(live, 0);
		Test.Assert(recording.FrameCount == 6);
		// The store it copies from is untouched: its history is all still there.
		Test.Assert(live.OldestFrame == 0);
		Test.Assert(live.NewestFrame == 8);
	}

	[Test]
	public static void FullItDropsTheOldestClearedItStartsAgain()
	{
		let p = scope Profiler();
		p.Arm();
		let live = scope LiveProfileSource(p);
		let recording = scope ProfileRecording(4);
		recording.Begin(live);
		RunFrames(p, 10);
		recording.Pull(live, 0);
		Test.Assert(recording.FrameCount == 4);
		Test.Assert(recording.OldestFrame == 6);
		Test.Assert(recording.NewestFrame == 9);
		for (uint64 n = 6; n <= 9; n++)
		{
			Test.Assert(recording.Frame(n) != null);
			Test.Assert(recording.Frame(n).FrameNumber == n);
		}
		Test.Assert(recording.Frame(5) == null);

		recording.Begin(live); // afresh: only what comes next
		Test.Assert(!recording.HasFrames);
		RunFrames(p, 2);
		recording.Pull(live, 0);
		Test.Assert(recording.OldestFrame == 10);
		Test.Assert(recording.NewestFrame == 11);
		Test.Assert(recording.Frame(10) != null);
		Test.Assert(recording.Frame(10).FrameNumber == 10);
	}

	[Test]
	public static void SavesAsACaptureThatReadsBackFrameForFrame()
	{
		let p = scope Profiler();
		p.Arm();
		let live = scope LiveProfileSource(p);
		let recording = scope ProfileRecording();
		recording.Begin(live);
		RunFrames(p, 5, 2);
		recording.Pull(live, 0);

		let bytes = scope MemoryStream();
		let writer = scope ProfileStreamWriter(bytes);
		let header = scope StreamHeader();
		header.TickFrequency = recording.TickFrequency;
		header.Application.Set("Editor");
		Test.Assert(writer.WriteHeader(header));
		for (var n = recording.OldestFrame; n <= recording.NewestFrame; n++)
			Test.Assert(writer.WriteFrame(recording, recording.Frame(n)));
		bytes.Seek(0, .Begin);
		let capture = scope ProfileCapture();
		Test.Assert(capture.Read(bytes));
		Test.Assert(capture.FrameCount == 5);
		Test.Assert(capture.OldestFrame == recording.OldestFrame);
		let frame = capture.Frame(2);
		Test.Assert(frame != null);
		Test.Assert(capture.NameOf(frame.Threads[0].Scopes[0].Name) == "Late");
		Test.Assert(frame.EndTick - frame.BeginTick == recording.Frame(2).EndTick - recording.Frame(2).BeginTick);
	}
}
