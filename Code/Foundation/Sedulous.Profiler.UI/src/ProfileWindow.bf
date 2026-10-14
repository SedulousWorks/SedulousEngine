using System;
using System.Collections;
using Sedulous.Profiler;

namespace Sedulous.Profiler.UI;

/// One frame's times. The GPU time is the span of its passes, from the first to start to the
/// last to end; it is missing for the newest frames, whose passes have not arrived yet.
struct FrameTime
{
	public uint64 Frame;
	public float CpuMs;
	public float GpuMs;
	public bool HasGpu;
}

/// Min, median, max and mean of a set of times; Count nought when there were none.
struct TimeStats
{
	public float Min;
	public float Median;
	public float Max;
	public float Mean;
	public uint32 Count;
}

/// CPU and GPU statistics over a set of frame times (the GPU's over the frames that have it).
struct FrameWindowStats
{
	public TimeStats Cpu;
	public TimeStats Gpu;
}

/// The frames a view looks at: the last few frame numbers up to the source's newest.
struct FrameRange
{
	public uint64 First;
	public uint64 Last;
	public bool Empty = true;

	public this()
	{
		First = 0;
		Last = 0;
	}
}

/// Which events a top list ranks.
enum TopLane : uint8
{
	/// CPU scopes on every thread, by their own time (their children's taken out).
	Scopes,
	/// GPU passes, by their time.
	GpuPasses
}

/// A name's time over a range of frames: MsPerFrame is its total over the frames with a
/// record, averaged per frame; CallsPerFrame its count, likewise.
struct TopEntry
{
	public uint32 Name;
	public float MsPerFrame;
	public float CallsPerFrame;
}

/// A counter's value in the newest frame that set it, and its mean over the range.
struct CounterReading
{
	public uint32 Counter;
	public double Latest;
	public double Mean;
	public bool Present;
}

/// What the views show, computed from a source and nothing drawn: the frame times of the last
/// frames, their statistics, the scopes or GPU passes that took longest over them, and the
/// counters' values. Views call these as they draw; tests call them on a source of known
/// frames.
static class ProfileWindow
{
	public static FrameRange LastFrames(IProfileSource source, uint32 count)
	{
		var range = FrameRange();
		if (!source.HasFrames || (count == 0))
			return range;
		range.Last = source.NewestFrame;
		let oldest = source.OldestFrame;
		range.First = (range.Last - oldest + 1 > count) ? (range.Last + 1 - count) : oldest;
		range.Empty = false;
		return range;
	}

	public static float TicksToMs(int64 ticks, uint64 tickFrequency) =>
		(float)((double)ticks * 1000.0 / (double)Math.Max(tickFrequency, 1));

	/// The times of the frames in `range` that have a record, oldest first.
	public static void CollectFrameTimes(IProfileSource source, FrameRange range, List<FrameTime> outTimes)
	{
		outTimes.Clear();
		if (range.Empty)
			return;
		let frequency = source.TickFrequency;
		for (var n = range.First; n <= range.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			var time = FrameTime();
			time.Frame = n;
			time.CpuMs = TicksToMs(frame.EndTick - frame.BeginTick, frequency);
			if (frame.GpuValid && !frame.Gpu.IsEmpty)
			{
				var begin = frame.Gpu[0].BeginTick;
				var end = frame.Gpu[0].EndTick;
				for (let pass in frame.Gpu)
				{
					begin = Math.Min(begin, pass.BeginTick);
					end = Math.Max(end, pass.EndTick);
				}
				time.GpuMs = TicksToMs(end - begin, frequency);
				time.HasGpu = true;
			}
			outTimes.Add(time);
		}
	}

	/// The statistics of `values` (sorted in place).
	public static TimeStats StatsOf(List<float> values)
	{
		var stats = TimeStats();
		if (values.IsEmpty)
			return stats;
		values.Sort();
		double sum = 0.0;
		for (let v in values)
			sum += v;
		stats.Min = values[0];
		stats.Median = values[values.Count / 2];
		stats.Max = values.Back;
		stats.Mean = (float)(sum / (double)values.Count);
		stats.Count = (uint32)values.Count;
		return stats;
	}

	public static FrameWindowStats StatsOf(Span<FrameTime> times)
	{
		let cpu = scope List<float>();
		let gpu = scope List<float>();
		for (let t in times)
		{
			cpu.Add(t.CpuMs);
			if (t.HasGpu)
				gpu.Add(t.GpuMs);
		}
		var stats = FrameWindowStats();
		stats.Cpu = StatsOf(cpu);
		stats.Gpu = StatsOf(gpu);
		return stats;
	}

	/// The `count` names that took longest over `range`, longest first.
	public static void CollectTop(IProfileSource source, FrameRange range, TopLane lane, uint32 count, List<TopEntry> outTop)
	{
		outTop.Clear();
		if (range.Empty)
			return;
		let ticks = scope List<int64>(); // by name id
		let calls = scope List<uint64>();
		let childTicks = scope List<int64>(); // per depth: the time the scopes ended below it took
		uint32 frames = 0;
		void Add(uint32 name, int64 duration)
		{
			if (name >= (uint32)ticks.Count)
			{
				while (ticks.Count <= name)
				{
					ticks.Add(0);
					calls.Add(0);
				}
			}
			ticks[name] += duration;
			calls[name]++;
		}
		for (var n = range.First; n <= range.Last; n++)
		{
			let frame = source.Frame(n);
			if ((frame == null) || ((lane == .GpuPasses) && !frame.GpuValid))
				continue;
			frames++;
			if (lane == .GpuPasses)
			{
				for (let pass in frame.Gpu)
					Add(pass.Name, pass.EndTick - pass.BeginTick);
				continue;
			}
			// A thread's scopes are in the order they ended, so a scope's children come before
			// it: what ended one level deeper since the last scope at its depth is its children.
			for (let thread in frame.Threads)
			{
				childTicks.Clear();
				for (let scopeEvent in thread.Scopes)
				{
					while (childTicks.Count < scopeEvent.Depth + 2)
						childTicks.Add(0);
					let duration = scopeEvent.EndTick - scopeEvent.BeginTick;
					let children = Math.Min(childTicks[scopeEvent.Depth + 1], duration);
					childTicks[scopeEvent.Depth + 1] = 0;
					childTicks[scopeEvent.Depth] += duration;
					Add(scopeEvent.Name, duration - children);
				}
			}
		}
		if (frames == 0)
			return;
		let frequency = source.TickFrequency;
		for (int id < ticks.Count)
		{
			if (calls[id] == 0)
				continue;
			var entry = TopEntry();
			entry.Name = (uint32)id;
			entry.MsPerFrame = TicksToMs(ticks[id], frequency) / (float)frames;
			entry.CallsPerFrame = (float)calls[id] / (float)frames;
			// Inserted in order, longest first, keeping `count`.
			var at = outTop.Count;
			while ((at > 0) && (outTop[at - 1].MsPerFrame < entry.MsPerFrame))
				at--;
			if (at >= count)
				continue;
			outTop.Insert(at, entry);
			if (outTop.Count > count)
				outTop.PopBack();
		}
	}

	/// One reading per registered counter, in registration order.
	public static void CollectCounters(IProfileSource source, FrameRange range, List<CounterReading> outReadings)
	{
		outReadings.Clear();
		let counters = source.Counters.Length;
		for (int i < counters)
		{
			var reading = CounterReading();
			reading.Counter = (uint32)i;
			outReadings.Add(reading);
		}
		if (range.Empty)
			return;
		let sums = scope double[counters];
		let seen = scope uint32[counters];
		for (var n = range.First; n <= range.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			for (let value in frame.Counters)
			{
				if (value.Counter < (uint32)counters)
				{
					sums[value.Counter] += value.Value;
					seen[value.Counter]++;
					outReadings[value.Counter].Latest = value.Value; // frames run oldest first
				}
			}
		}
		for (int i < counters)
		{
			outReadings[i].Present = seen[i] > 0;
			outReadings[i].Mean = (seen[i] > 0) ? (sums[i] / (double)seen[i]) : 0.0;
		}
	}

	/// A counter's value as text in its unit: a count whole, bytes in KiB, MiB or GiB, times
	/// in ms, a percentage with its sign.
	public static void FormatCounter(double value, CounterUnit unit, String outText)
	{
		const double cKiB = 1024.0;
		switch (unit)
		{
		case .Bytes:
			if (value >= cKiB * cKiB * cKiB)
				outText.AppendF("{:F2} GiB", value / (cKiB * cKiB * cKiB));
			else if (value >= cKiB * cKiB)
				outText.AppendF("{:F1} MiB", value / (cKiB * cKiB));
			else
				outText.AppendF("{:F1} KiB", value / cKiB);
		case .Milliseconds:
			outText.AppendF("{:F2} ms", value);
		case .Percent:
			outText.AppendF("{:F1}%", value);
		case .Count:
			outText.AppendF("{}", (int64)(value + ((value < 0.0) ? -0.5 : 0.5)));
		}
	}
}
