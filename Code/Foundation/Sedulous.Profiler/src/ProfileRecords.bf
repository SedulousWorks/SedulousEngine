using System;
using System.Collections;

namespace Sedulous.Profiler;

/// One scope a thread finished: its name (an id into the profiler's name table), how deeply it
/// nested on that thread, and its ticks (ProfileClock).
struct ScopeEvent
{
	public uint32 Name;
	public uint32 Depth;
	public int64 BeginTick;
	public int64 EndTick;

	public this(uint32 name, uint32 depth, int64 beginTick, int64 endTick)
	{
		Name = name;
		Depth = depth;
		BeginTick = beginTick;
		EndTick = endTick;
	}
}

/// One GPU pass of a frame, its ticks already on the CPU clock.
struct GpuPassEvent
{
	public uint32 Name;
	public uint32 Depth;
	/// Nought graphics, one async compute.
	public uint32 Queue;
	public int64 BeginTick;
	public int64 EndTick;

	public this(uint32 name, uint32 depth, uint32 queue, int64 beginTick, int64 endTick)
	{
		Name = name;
		Depth = depth;
		Queue = queue;
		BeginTick = beginTick;
		EndTick = endTick;
	}
}

enum CounterUnit : uint8
{
	Count,
	Bytes,
	Milliseconds,
	Percent
}

struct CounterValue
{
	public uint32 Counter;
	public double Value;

	public this(uint32 counter, double value)
	{
		Counter = counter;
		Value = value;
	}
}

/// The scopes one thread finished during a frame, and how many it dropped (its ring was full).
class ThreadFrame
{
	public uint32 Thread;
	public uint32 Dropped;
	public List<ScopeEvent> Scopes = new .() ~ delete _;
}

/// One frame: when it ran, what every thread did in it, its GPU passes once they arrive (a
/// frame or two late), and its counters. Refers to nothing in the process: names are ids,
/// threads indices, so a capture file or another process reads it the same.
class FrameRecord
{
	public uint64 FrameNumber;
	public int64 BeginTick;
	public int64 EndTick;
	public List<ThreadFrame> Threads = new .() ~ DeleteContainerAndItems!(_);
	public bool GpuValid;
	public List<GpuPassEvent> Gpu = new .() ~ delete _;
	public List<CounterValue> Counters = new .() ~ delete _;

	public double Ms => ProfileClock.ToMilliseconds((EndTick >= BeginTick) ? (EndTick - BeginTick) : 0);

	/// Empties it for reuse as another frame's record.
	public void Clear()
	{
		ClearAndDeleteItems(Threads);
		GpuValid = false;
		Gpu.Clear();
		Counters.Clear();
	}
}

/// A recording thread as the tables show it: its index in a record, and its name.
class ThreadInfo
{
	public uint32 Index;
	public String Name = new .() ~ delete _;
}

class CounterInfo
{
	public String Name = new .() ~ delete _;
	public CounterUnit Unit;
}
