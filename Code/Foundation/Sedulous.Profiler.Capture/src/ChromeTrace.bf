using System;
using Sedulous.Json;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Capture;

/// A profile source's frames as Chrome trace JSON, the format chrome://tracing and Perfetto
/// open: a "Frames" lane with one bar a frame, a lane per thread with its scopes as complete
/// events (they nest by time), a "GPU" lane with the passes (their pipeline statistics as
/// arguments), and each counter as a counter track. Times are microseconds from the first
/// frame's start, converted by the source's tick frequency, so a capture recorded on another
/// clock (Raptor's nanoseconds) exports the same.
static class ChromeTrace
{
	private const double cFramesLane = 0;
	private const double cGpuLane = 1000000;

	/// Frames `firstFrame`..`lastFrame` of `source` (those it holds) as Chrome trace JSON text,
	/// appended to `outText`. `title` names the process (the application).
	public static void Write(IProfileSource source, uint64 firstFrame, uint64 lastFrame, StringView title, String outText)
	{
		let events = JsonValue.MakeArray();
		let frequency = (double)Math.Max(source.TickFrequency, 1);
		int64 origin = 0;
		for (var n = firstFrame; n <= lastFrame; n++)
		{
			if (let frame = source.Frame(n))
			{
				origin = frame.BeginTick;
				break;
			}
		}
		double Us(int64 tick) => ((double)tick - (double)origin) * 1.0e6 / frequency;
		double LengthUs(int64 begin, int64 end) => (double)((end >= begin) ? (end - begin) : 0) * 1.0e6 / frequency;

		// Lanes: the frames, each thread (its index + 1), the GPU.
		let process = Event("process_name", "M", 0);
		let processArgs = JsonValue.MakeObject();
		processArgs.Set("name", JsonValue.MakeString(title));
		process.Set("args", processArgs);
		events.Add(process);
		AddLane(events, cFramesLane, "Frames", 0);
		for (let thread in source.Threads)
			AddLane(events, (double)thread.Index + 1.0, thread.Name, (double)thread.Index + 1.0);
		AddLane(events, cGpuLane, "GPU", cGpuLane);

		let frameName = scope String();
		for (var n = firstFrame; n <= lastFrame; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			frameName.Clear();
			frameName.AppendF("Frame {}", frame.FrameNumber);
			events.Add(Complete(frameName, cFramesLane, Us(frame.BeginTick), LengthUs(frame.BeginTick, frame.EndTick)));
			for (let thread in frame.Threads)
			{
				for (let scopeEvent in thread.Scopes)
				{
					events.Add(Complete(source.NameOf(scopeEvent.Name), (double)thread.Thread + 1.0,
						Us(scopeEvent.BeginTick), LengthUs(scopeEvent.BeginTick, scopeEvent.EndTick)));
				}
			}
			for (let pass in frame.Gpu)
			{
				let e = Complete(source.NameOf(pass.Name), cGpuLane, Us(pass.BeginTick), LengthUs(pass.BeginTick, pass.EndTick));
				if (pass.HasCounts)
				{
					let args = JsonValue.MakeObject();
					args.Set("input primitives", JsonValue.MakeNumber((double)pass.Counts.InputPrimitives));
					args.Set("vertex invocations", JsonValue.MakeNumber((double)pass.Counts.VertexInvocations));
					args.Set("fragment invocations", JsonValue.MakeNumber((double)pass.Counts.FragmentInvocations));
					args.Set("compute invocations", JsonValue.MakeNumber((double)pass.Counts.ComputeInvocations));
					e.Set("args", args);
				}
				events.Add(e);
			}
			let counters = source.Counters;
			for (let value in frame.Counters)
			{
				if (value.Counter >= (uint32)counters.Length)
					continue;
				let e = Event(counters[value.Counter].Name, "C", 0);
				e.Set("ts", JsonValue.MakeNumber(Us(frame.BeginTick)));
				let args = JsonValue.MakeObject();
				args.Set("value", JsonValue.MakeNumber(value.Value));
				e.Set("args", args);
				events.Add(e);
			}
		}

		let root = scope JsonValue();
		root.Set("traceEvents", events);
		root.Set("displayTimeUnit", JsonValue.MakeString("ms"));
		root.ToString(outText);
	}

	private static JsonValue Event(StringView name, StringView phase, double lane)
	{
		let e = JsonValue.MakeObject();
		e.Set("name", JsonValue.MakeString(name));
		e.Set("ph", JsonValue.MakeString(phase));
		e.Set("pid", JsonValue.MakeNumber(1));
		e.Set("tid", JsonValue.MakeNumber(lane));
		return e;
	}

	/// A lane's name and its place among the lanes.
	private static void AddLane(JsonValue events, double lane, StringView name, double sortIndex)
	{
		let e = Event("thread_name", "M", lane);
		let args = JsonValue.MakeObject();
		args.Set("name", JsonValue.MakeString(name));
		e.Set("args", args);
		events.Add(e);
		let sort = Event("thread_sort_index", "M", lane);
		let sortArgs = JsonValue.MakeObject();
		sortArgs.Set("sort_index", JsonValue.MakeNumber(sortIndex));
		sort.Set("args", sortArgs);
		events.Add(sort);
	}

	private static JsonValue Complete(StringView name, double lane, double startUs, double durationUs)
	{
		let e = Event(name, "X", lane);
		e.Set("ts", JsonValue.MakeNumber(startUs));
		e.Set("dur", JsonValue.MakeNumber(durationUs));
		return e;
	}
}
