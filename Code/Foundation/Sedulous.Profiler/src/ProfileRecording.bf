using System;
using System.Collections;

namespace Sedulous.Profiler;

/// A viewer's own copy of frames: the editor's panel records what the store keeps into one of
/// these, so its pause, its longer history and its selection never touch the store another
/// viewer reads (a game's overlay). Frames are copied once their GPU passes have had time to
/// arrive (`settleFrames` behind the newest), with the name, thread and counter tables they
/// point into; the oldest go when it is full. It is a source, so the views read it and a
/// capture file is written from it like any other.
class ProfileRecording : IProfileSource
{
	/// A minute at 60 frames a second.
	public const uint32 DefaultCapacity = 3600;
	/// Frames in flight before a frame's GPU passes land.
	public const uint32 SettleFrames = 4;

	/// A ring once full: mHead is the oldest.
	private List<FrameRecord> mFrames = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);
	private List<ThreadInfo> mThreads = new .() ~ DeleteContainerAndItems!(_);
	private List<CounterInfo> mCounters = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mCapacity;
	private uint32 mCount;
	private uint32 mHead;
	private uint64 mNext;
	private uint64 mTickFrequency = 1;
	private bool mStarted;

	public this(uint32 capacity = DefaultCapacity)
	{
		mCapacity = Math.Max(capacity, 1);
	}

	/// Starts afresh from `source`: frames after its newest now are recorded, none before.
	public void Begin(IProfileSource source)
	{
		Clear();
		mTickFrequency = source.TickFrequency;
		mNext = source.HasFrames ? (source.NewestFrame + 1) : 0;
		mStarted = true;
	}

	/// Copies the frames `source` has settled since the last pull (`settleFrames` behind its
	/// newest, so their GPU passes are in; nought when stopping, taking the rest as they are).
	public void Pull(IProfileSource source, uint32 settleFrames = SettleFrames)
	{
		if (!mStarted || !source.HasFrames || (source.NewestFrame < settleFrames))
			return;
		let last = source.NewestFrame - settleFrames;
		if (mNext < source.OldestFrame)
			mNext = source.OldestFrame; // fell behind the store's history: what is left
		if (mNext > last)
			return;
		SyncTables(source);
		for (var n = mNext; n <= last; n++)
		{
			if (let frame = source.Frame(n))
				Append(frame);
		}
		mNext = last + 1;
	}

	/// Drops every frame (the tables stay: ids keep their meaning).
	public void Clear()
	{
		mCount = 0;
		mHead = 0;
	}

	public uint32 Capacity => mCapacity;
	public uint32 FrameCount => mCount;

	public uint64 TickFrequency => mTickFrequency;
	public bool HasFrames => mCount > 0;
	public uint64 OldestFrame => (mCount > 0) ? At(0).FrameNumber : 0;
	public uint64 NewestFrame => (mCount > 0) ? At(mCount - 1).FrameNumber : 0;

	public FrameRecord Frame(uint64 frameNumber)
	{
		// Frames are kept in order, mostly consecutive: looked for where it would be, else
		// searched.
		if ((mCount == 0) || (frameNumber < OldestFrame) || (frameNumber > NewestFrame))
			return null;
		let guess = frameNumber - OldestFrame;
		if ((guess < mCount) && (At((uint32)guess).FrameNumber == frameNumber))
			return At((uint32)guess);
		uint32 low = 0;
		uint32 high = mCount;
		while (low < high)
		{
			let mid = (low + high) / 2;
			if (At(mid).FrameNumber < frameNumber)
				low = mid + 1;
			else
				high = mid;
		}
		return ((low < mCount) && (At(low).FrameNumber == frameNumber)) ? At(low) : null;
	}

	public StringView NameOf(uint32 id) => (id < (uint32)mNames.Count) ? mNames[id] : StringView();
	public uint32 NameCount => (uint32)mNames.Count;
	public Span<ThreadInfo> Threads => mThreads;
	public Span<CounterInfo> Counters => mCounters;

	private FrameRecord At(uint32 index) => mFrames[(int)((mHead + index) % (uint32)mFrames.Count)];

	/// The tables only grow in a source, so what is new is what lies past ours.
	private void SyncTables(IProfileSource source)
	{
		for (var id = (uint32)mNames.Count; id < source.NameCount; id++)
			mNames.Add(new .(source.NameOf(id)));
		let threads = source.Threads;
		for (int i = mThreads.Count; i < threads.Length; i++)
		{
			let info = new ThreadInfo();
			info.Index = threads[i].Index;
			info.Name.Set(threads[i].Name);
			mThreads.Add(info);
		}
		let counters = source.Counters;
		for (int i = mCounters.Count; i < counters.Length; i++)
		{
			let info = new CounterInfo();
			info.Name.Set(counters[i].Name);
			info.Unit = counters[i].Unit;
			mCounters.Add(info);
		}
	}

	/// Into the next slot, reusing its record once the ring has filled.
	private void Append(FrameRecord frame)
	{
		FrameRecord slot;
		if (mCount < (uint32)mFrames.Count)
		{
			slot = mFrames[(int)((mHead + mCount) % (uint32)mFrames.Count)]; // a slot a Clear freed
			mCount++;
		}
		else if ((uint32)mFrames.Count < mCapacity)
		{
			slot = new FrameRecord();
			mFrames.Add(slot);
			mCount++;
		}
		else
		{
			slot = mFrames[(int)mHead]; // the oldest goes
			mHead = (mHead + 1) % (uint32)mFrames.Count;
		}
		slot.Clear();
		slot.FrameNumber = frame.FrameNumber;
		slot.BeginTick = frame.BeginTick;
		slot.EndTick = frame.EndTick;
		slot.GpuValid = frame.GpuValid;
		for (let thread in frame.Threads)
		{
			let copy = new ThreadFrame();
			copy.Thread = thread.Thread;
			copy.Dropped = thread.Dropped;
			copy.Scopes.AddRange(thread.Scopes);
			slot.Threads.Add(copy);
		}
		slot.Gpu.AddRange(frame.Gpu);
		slot.Counters.AddRange(frame.Counters);
	}
}
