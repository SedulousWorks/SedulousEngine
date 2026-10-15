using System;
using System.Collections;
using Sedulous.Profiler;

namespace Sedulous.Profiler.UI.Tests;

/// A profile source of hand-made frames on a millisecond clock (a tick is a millisecond), so a
/// test's numbers come out exact.
class KnownSource : IProfileSource
{
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);
	private List<ThreadInfo> mThreads = new .() ~ DeleteContainerAndItems!(_);
	private List<CounterInfo> mCounters = new .() ~ DeleteContainerAndItems!(_);
	private List<FrameRecord> mFrames = new .() ~ DeleteContainerAndItems!(_);
	private int64 mNextTick = 1000;

	public this()
	{
		let main = new ThreadInfo();
		main.Name.Set("Main");
		mThreads.Add(main);
	}

	public uint32 Name(StringView name)
	{
		for (int i < mNames.Count)
		{
			if (mNames[i] == name)
				return (uint32)i;
		}
		mNames.Add(new .(name));
		return (uint32)(mNames.Count - 1);
	}

	public uint32 Counter(StringView name, CounterUnit unit)
	{
		let info = new CounterInfo();
		info.Name.Set(name);
		info.Unit = unit;
		mCounters.Add(info);
		return (uint32)(mCounters.Count - 1);
	}

	/// A frame `cpuMs` long after the last; its scopes and passes added through the result.
	public FrameRecord AddFrame(int64 cpuMs)
	{
		let frame = new FrameRecord();
		frame.FrameNumber = mFrames.IsEmpty ? 0 : mFrames.Back.FrameNumber + 1;
		frame.BeginTick = mNextTick;
		frame.EndTick = mNextTick + cpuMs;
		mNextTick = frame.EndTick;
		frame.Threads.Add(new ThreadFrame());
		mFrames.Add(frame);
		return frame;
	}

	public static void AddScope(FrameRecord frame, uint32 name, uint32 depth, int64 begin, int64 end)
	{
		frame.Threads[0].Scopes.Add(.(name, depth, frame.BeginTick + begin, frame.BeginTick + end));
	}

	/// A second thread's table entry; its scopes go in with AddScopeOn.
	public uint32 Thread(StringView name)
	{
		let info = new ThreadInfo();
		info.Index = (uint32)mThreads.Count;
		info.Name.Set(name);
		mThreads.Add(info);
		return (uint32)(mThreads.Count - 1);
	}

	public static void AddScopeOn(FrameRecord frame, uint32 thread, uint32 name, uint32 depth, int64 begin, int64 end)
	{
		ThreadFrame lane = null;
		for (let t in frame.Threads)
		{
			if (t.Thread == thread)
				lane = t;
		}
		if (lane == null)
		{
			lane = new ThreadFrame();
			lane.Thread = thread;
			frame.Threads.Add(lane);
		}
		lane.Scopes.Add(.(name, depth, frame.BeginTick + begin, frame.BeginTick + end));
	}

	public static void AddPass(FrameRecord frame, uint32 name, int64 begin, int64 end)
	{
		frame.Gpu.Add(.(name, 0, 0, frame.BeginTick + begin, frame.BeginTick + end));
		frame.GpuValid = true;
	}

	public uint64 TickFrequency => 1000;
	public bool HasFrames => !mFrames.IsEmpty;
	public uint64 OldestFrame => mFrames.IsEmpty ? 0 : mFrames[0].FrameNumber;
	public uint64 NewestFrame => mFrames.IsEmpty ? 0 : mFrames.Back.FrameNumber;

	public FrameRecord Frame(uint64 frameNumber)
	{
		for (let frame in mFrames)
		{
			if (frame.FrameNumber == frameNumber)
				return frame;
		}
		return null;
	}

	public StringView NameOf(uint32 id) => (id < (uint32)mNames.Count) ? mNames[id] : StringView();
	public uint32 NameCount => (uint32)mNames.Count;
	public Span<ThreadInfo> Threads => mThreads;
	public Span<CounterInfo> Counters => mCounters;
}
