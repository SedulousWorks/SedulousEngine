using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Profiler;
using Sedulous.Profiler.Capture;

namespace Sedulous.Profiler.Capture.Tests;

/// The Chrome trace export: a source's frames as the JSON chrome://tracing and Perfetto open, a
/// lane per thread plus the frames and the GPU, counters as counter tracks.
class ChromeTraceTests
{
	public static void Record(Profiler p)
	{
		let draws = p.RegisterCounter("Draws", .Count);
		p.Arm();
		for (uint32 f < 2)
		{
			p.BeginFrame();
			Test.Assert(p.BeginScope("Update"));
			Test.Assert(p.BeginScope("Physics"));
			let start = ProfileClock.Now();
			while (ProfileClock.Now() == start)
			{
			}
			p.EndScope();
			p.EndScope();
			p.SetCounter(draws, 7.0 + f);
			p.EndFrame();
		}
		let begin = p.Frame(0).BeginTick;
		var pass = GpuPassEvent(p.InternName("forward"), 0, 0, begin, begin + ProfileClock.TicksPerSecond / 1000); // 1 ms
		pass.HasCounts = true;
		pass.Counts.FragmentInvocations = 4096;
		p.SubmitGpuPasses(0, .(&pass, 1));
	}

	/// The events named `name` with phase `phase`, borrowed from `trace`.
	private static void Events(JsonValue trace, StringView name, StringView phase, List<JsonValue> outEvents)
	{
		let events = trace.Get("traceEvents");
		for (int i < events.Count)
		{
			let e = events.At(i);
			if ((e.Get("name").AsString() == name) && (e.Get("ph").AsString() == phase))
				outEvents.Add(e);
		}
	}

	private static bool LaneNamed(JsonValue trace, StringView laneName)
	{
		for (let e in Events(trace, "thread_name", "M", .. scope .()))
		{
			if (e.Get("args").Get("name").AsString() == laneName)
				return true;
		}
		return false;
	}

	[Test]
	public static void FramesALanePerThreadTheGpuLaneAndTheCounters()
	{
		let p = scope Profiler();
		Record(p);
		let live = scope LiveProfileSource(p);
		let text = ChromeTrace.Write(live, 0, 1, "Probe", .. scope .());
		let trace = JsonValue.Parse(text);
		defer delete trace;
		Test.Assert(trace.Get("traceEvents").IsArray);

		Test.Assert(LaneNamed(trace, "Frames"));
		Test.Assert(LaneNamed(trace, "GPU"));
		Test.Assert(LaneNamed(trace, p.Threads[0].Name));

		// A bar for each frame, the first at zero.
		let frames = Events(trace, "Frame 0", "X", .. scope .());
		Test.Assert(frames.Count == 1);
		Test.Assert(frames[0].Get("ts").AsNumber(-1) == 0.0);
		Test.Assert(Events(trace, "Frame 1", "X", .. scope .()).Count == 1);

		// Scopes nest by time on their thread's lane.
		let update = Events(trace, "Update", "X", .. scope .());
		let physics = Events(trace, "Physics", "X", .. scope .());
		Test.Assert((update.Count == 2) && (physics.Count == 2));
		let outerStart = update[0].Get("ts").AsNumber();
		let innerStart = physics[0].Get("ts").AsNumber();
		Test.Assert(innerStart >= outerStart);
		Test.Assert(innerStart + physics[0].Get("dur").AsNumber() <= outerStart + update[0].Get("dur").AsNumber() + 0.001);
		Test.Assert(physics[0].Get("dur").AsNumber() > 0, "the spin shows");
		Test.Assert(physics[0].Get("tid").AsNumber() == update[0].Get("tid").AsNumber());

		// The GPU pass with its counts, a millisecond long.
		let forward = Events(trace, "forward", "X", .. scope .());
		Test.Assert(forward.Count == 1);
		Test.Assert(Math.Abs(forward[0].Get("dur").AsNumber() - 1000.0) < 10.0, scope $"{forward[0].Get("dur").AsNumber()} us");
		Test.Assert(forward[0].Get("args").Get("fragment invocations").AsNumber() == 4096.0);

		// The counter: a value each frame.
		let draws = Events(trace, "Draws", "C", .. scope .());
		Test.Assert(draws.Count == 2);
		Test.Assert(draws[1].Get("args").Get("value").AsNumber() == 8.0);
	}

	[Test]
	public static void ACaptureReadBackExportsAsTheLiveStoreDid()
	{
		let p = scope Profiler();
		Record(p);
		let live = scope LiveProfileSource(p);
		let bytes = scope MemoryStream();
		let writer = scope ProfileStreamWriter(bytes);
		let header = scope StreamHeader();
		header.TickFrequency = live.TickFrequency;
		Test.Assert(writer.WriteHeader(header));
		for (uint64 n <= 1)
			Test.Assert(writer.WriteFrame(live, live.Frame(n)));
		bytes.Seek(0, .Begin);
		let capture = scope ProfileCapture();
		Test.Assert(capture.Read(bytes));
		let fromCapture = ChromeTrace.Write(capture, 0, 1, "Probe", .. scope .());
		let fromLive = ChromeTrace.Write(live, 0, 1, "Probe", .. scope .());
		Test.Assert(fromCapture == fromLive);
	}

	/// A capture on another clock (Raptor's nanoseconds) exports in microseconds all the same.
	[Test]
	public static void ACaptureOnAnotherClockExportsInMicroseconds()
	{
		let bytes = scope MemoryStream();
		let w = scope BinaryWriter(bytes);
		w.Write(ProfileStream.Magic);
		w.Write(ProfileStream.Version);
		w.Write((uint64)1000000000);
		w.WriteString("Raptor");
		w.WriteString("Linux64");
		w.WriteString("test");
		// One frame of 2 ms: tag, length, then the record with no threads, GPU or counters.
		let frame = scope MemoryStream();
		let f = scope BinaryWriter(frame);
		f.Write((uint64)0);
		f.Write((int64)5000000);
		f.Write((int64)7000000);
		f.Write((uint32)0);
		f.Write((uint8)0);
		f.Write((uint32)0);
		f.Write((uint32)0);
		w.Write((uint8)StreamChunk.Frame);
		w.Write((uint32)frame.Bytes.Length);
		w.WriteBytes(frame.Bytes);
		bytes.Seek(0, .Begin);
		let capture = scope ProfileCapture();
		Test.Assert(capture.Read(bytes));
		let trace = JsonValue.Parse(ChromeTrace.Write(capture, 0, 0, "Raptor", .. scope .()));
		defer delete trace;
		let frames = Events(trace, "Frame 0", "X", .. scope .());
		Test.Assert(frames.Count == 1);
		Test.Assert(frames[0].Get("dur").AsNumber() == 2000.0, scope $"{frames[0].Get("dur").AsNumber()}");
	}
}
