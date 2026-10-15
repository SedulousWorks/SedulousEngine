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

/// A name's time over a range of frames: every scope (or GPU pass) by that name, their total
/// time, their own time (children taken out; a pass's is its total) and their count.
struct NameTotal
{
	public uint32 Name;
	public bool Gpu;
	public int64 TotalTicks;
	public int64 SelfTicks;
	public uint64 Count;
}

/// Totals by name over a range, CPU scopes on every thread and GPU passes apart; Frames is how
/// many frames had a record (for the scopes; GpuFrames counts the frames whose passes landed).
class RangeTotals
{
	public List<NameTotal> Scopes = new .() ~ delete _;
	public List<NameTotal> Passes = new .() ~ delete _;
	public uint32 Frames;
	public uint32 GpuFrames;
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

	public static void CollectTotals(IProfileSource source, FrameRange range, RangeTotals outTotals)
	{
		outTotals.Scopes.Clear();
		outTotals.Passes.Clear();
		outTotals.Frames = 0;
		outTotals.GpuFrames = 0;
		if (range.Empty)
			return;
		let scopeAt = scope List<int32>(); // by name id: its index in Scopes, or -1
		let passAt = scope List<int32>();
		let childTicks = scope List<int64>(); // per depth: the time the scopes ended below it took
		int Entry(List<NameTotal> list, List<int32> at, uint32 name, bool gpu)
		{
			while ((uint32)at.Count <= name)
				at.Add(-1);
			if (at[(int)name] < 0)
			{
				at[(int)name] = (int32)list.Count;
				var total = NameTotal();
				total.Name = name;
				total.Gpu = gpu;
				list.Add(total);
			}
			return at[(int)name];
		}
		for (var n = range.First; n <= range.Last; n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			outTotals.Frames++;
			// A thread's scopes are in the order they ended, so a scope's children come before
			// it: what ended one level deeper since the last scope at its depth is its children.
			for (let thread in frame.Threads)
			{
				childTicks.Clear();
				for (let scopeEvent in thread.Scopes)
				{
					let depth = (int)scopeEvent.Depth;
					while (childTicks.Count < depth + 2)
						childTicks.Add(0);
					let duration = scopeEvent.EndTick - scopeEvent.BeginTick;
					let children = Math.Min(childTicks[depth + 1], duration);
					childTicks[depth + 1] = 0;
					childTicks[depth] += duration;
					let index = Entry(outTotals.Scopes, scopeAt, scopeEvent.Name, false);
					outTotals.Scopes[index].TotalTicks += duration;
					outTotals.Scopes[index].SelfTicks += duration - children;
					outTotals.Scopes[index].Count++;
				}
			}
			if (frame.GpuValid)
			{
				outTotals.GpuFrames++;
				for (let pass in frame.Gpu)
				{
					let index = Entry(outTotals.Passes, passAt, pass.Name, true);
					let duration = pass.EndTick - pass.BeginTick;
					outTotals.Passes[index].TotalTicks += duration;
					outTotals.Passes[index].SelfTicks += duration;
					outTotals.Passes[index].Count++;
				}
			}
		}
	}

	/// The `count` names that took longest over `range` (scopes by their own time), longest
	/// first.
	public static void CollectTop(IProfileSource source, FrameRange range, TopLane lane, uint32 count, List<TopEntry> outTop)
	{
		outTop.Clear();
		let totals = scope RangeTotals();
		CollectTotals(source, range, totals);
		let gpu = lane == .GpuPasses;
		let frames = gpu ? totals.GpuFrames : totals.Frames;
		if (frames == 0)
			return;
		let frequency = source.TickFrequency;
		for (let total in gpu ? totals.Passes : totals.Scopes)
		{
			var entry = TopEntry();
			entry.Name = total.Name;
			entry.MsPerFrame = TicksToMs(total.SelfTicks, frequency) / (float)frames;
			entry.CallsPerFrame = (float)total.Count / (float)frames;
			// Inserted in order, longest first (the earlier name first on a tie), keeping `count`.
			var at = outTop.Count;
			while ((at > 0) && (outTop[at - 1].MsPerFrame < entry.MsPerFrame))
				at--;
			if (at >= (int)count)
				continue;
			outTop.Insert(at, entry);
			if (outTop.Count > (int)count)
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
					sums[(int)value.Counter] += value.Value;
					seen[(int)value.Counter]++;
					outReadings[(int)value.Counter].Latest = value.Value; // frames run oldest first
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
