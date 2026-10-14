using System;

namespace Sedulous.Profiler;

/// What every profiler view reads: frames by number and the tables their ids point into. Today
/// a source is the live store in this process or a capture read from a file (ProfileCapture);
/// later it is a running player over the network, and no view changes for it.
interface IProfileSource
{
	/// Ticks a second of the clock the frames' ticks are on (the recording process's).
	uint64 TickFrequency { get; }

	/// Whether it holds any frame; then they lie between OldestFrame and NewestFrame, a number
	/// in between possibly without a record (Frame answers null).
	bool HasFrames { get; }
	uint64 OldestFrame { get; }
	uint64 NewestFrame { get; }
	FrameRecord Frame(uint64 frameNumber);

	StringView NameOf(uint32 id);
	uint32 NameCount { get; }
	Span<ThreadInfo> Threads { get; }
	Span<CounterInfo> Counters { get; }
}

/// The store in this process, read on its frame thread.
class LiveProfileSource : IProfileSource
{
	private Profiler mProfiler;

	/// The profiler is borrowed and must outlive the source.
	public this(Profiler profiler)
	{
		mProfiler = profiler;
	}

	public uint64 TickFrequency => (uint64)ProfileClock.TicksPerSecond;
	public bool HasFrames => mProfiler.HasFrames;
	public uint64 OldestFrame => mProfiler.OldestKeptFrame;
	public uint64 NewestFrame => mProfiler.LatestRecordedFrame;
	public FrameRecord Frame(uint64 frameNumber) => mProfiler.Frame(frameNumber);
	public StringView NameOf(uint32 id) => mProfiler.NameOf(id);
	public uint32 NameCount => mProfiler.NameCount;
	public Span<ThreadInfo> Threads => mProfiler.Threads;
	public Span<CounterInfo> Counters => mProfiler.Counters;
}
