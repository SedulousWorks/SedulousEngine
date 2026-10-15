using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Profiler;

/// The capture store every profiler view reads. Threads record the scopes they finish into
/// rings of their own, without a lock; at the end of each frame the frame thread gathers them
/// into a FRAME RECORD and keeps the last few seconds of records. A record refers to nothing in
/// the process (names are ids into a table, threads are indices), so the same record can be
/// saved to a capture file or sent to another process and mean the same there.
///
/// Recording costs a branch until something ARMS the profiler (a view, a capture, the P key);
/// arms are counted, so two watchers keep it on until both let go.
///
/// An ordinary object rather than a singleton, so a test can hold its own; the process wide one
/// instrumentation reaches for is installed beside it (GlobalProfiler).
///
/// Threads: any thread may record scopes and intern names. Everything else (frames, counters,
/// GPU passes, reading records and tables) belongs to the FRAME THREAD, the one calling
/// BeginFrame.
class Profiler
{
	/// About five seconds at 60 frames a second.
	public const uint32 DefaultHistory = 300;
	/// Scopes a frame thread, and any other thread, can hold unread between two frame ends.
	public const uint32 DefaultFrameThreadRing = 65536;
	public const uint32 DefaultThreadRing = 16384;

	private const int32 cFrameTimes = 64;

	/// One recording thread. The ring is single producer (its thread), single consumer (the
	/// frame thread at frame end): Written and Read count events ever, and the ring indexes them
	/// modulo its power of two size.
	private class ThreadData
	{
		public uint32 Index;
		public int ThreadId;
		public String Name = new .() ~ delete _;
		public ScopeEvent[] Ring ~ delete _;
		public volatile int64 Written;
		public volatile int64 Read;
		public int32 Dropped;
		/// The open scopes: its thread only.
		public List<OpenScope> Stack = new .() ~ delete _;
		/// Names it has interned, by content: its thread only. Keys owned.
		public Dictionary<String, uint32> NameIds = new .() ~ DeleteDictionaryAndKeys!(_);
	}

	private struct OpenScope
	{
		public uint32 Name;
		public int64 BeginTick;
	}

	/// Identity rather than the pointer, so a thread's cached slot cannot be mistaken for a later
	/// profiler that happened to be allocated at the same address.
	private static int32 sNextProfilerId;
	private int32 mId;
	[ThreadStatic] private static int32 sCachedOwnerId;
	[ThreadStatic] private static ThreadData sCachedLocal;

	private int32 mArmCount;
	private uint32 mFrameThreadRing = DefaultFrameThreadRing;
	private uint32 mThreadRing = DefaultThreadRing;

	/// Guards the thread registry, the pending names and the name lookup.
	private Monitor mLock = new .() ~ delete _;
	private List<ThreadData> mThreads = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mPendingNames = new .() ~ DeleteContainerAndItems!(_);
	/// Keys borrowed from mNames or mPendingNames, which own them.
	private Dictionary<StringView, uint32> mNameIds = new .() ~ delete _;

	// The frame thread's view, published at frame end.
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);
	private List<ThreadInfo> mThreadInfos = new .() ~ DeleteContainerAndItems!(_);

	private uint64 mFrameNumber;
	private int64 mFrameBeginTick;
	private volatile int mFrameThreadId = -1;
	private List<FrameRecord> mHistory = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mRecordedFrames;
	private uint64 mLatestRecorded;

	private List<CounterInfo> mCounters = new .() ~ DeleteContainerAndItems!(_);
	private List<double> mCounterValues = new .() ~ delete _;
	private List<bool> mCounterSet = new .() ~ delete _;

	private double[cFrameTimes] mFrameTimes;
	private int32 mFrameTimeHead;
	private int32 mFrameTimeCount;

	public this()
	{
		mId = Interlocked.Increment(ref sNextProfilerId);
		SetHistoryLength(DefaultHistory);
	}

	// ---- arming -----------------------------------------------------------------------------

	/// Starts recording; each Arm is undone by one Disarm.
	public void Arm() => Interlocked.Increment(ref mArmCount);

	/// Undoes one Arm; one too many does not wrap.
	public void Disarm()
	{
		var count = Volatile.Read(ref mArmCount);
		while (count > 0)
		{
			let seen = Interlocked.CompareExchange(ref mArmCount, count, count - 1);
			if (seen == count)
				return;
			count = seen;
		}
	}

	public bool Armed => Volatile.Read(ref mArmCount) > 0;

	/// How many scopes a thread can hold between two frame ends before it drops new ones.
	/// Read when a thread first records, so set it before arming.
	public void SetRingCapacity(uint32 frameThread, uint32 otherThreads)
	{
		mFrameThreadRing = RoundUpPow2(frameThread);
		mThreadRing = RoundUpPow2(otherThreads);
	}

	// ---- scopes (any thread) ----------------------------------------------------------------

	/// Opens a scope. False when nothing was opened (unarmed); then do not EndScope. Each
	/// thread interns a name once and looks it up by content after, so a name made at run time
	/// (a pass's) works as a literal does.
	public bool BeginScope(StringView name)
	{
		if (!Armed)
			return false;
		let thread = Local();
		uint32 id = 0;
		if (!thread.NameIds.TryGetValueAlt(name, out id))
		{
			id = InternName(name);
			thread.NameIds[new String(name)] = id;
		}
		thread.Stack.Add(.() { Name = id, BeginTick = ProfileClock.Now() });
		return true;
	}

	/// Opens a scope by a name already interned (InternName), which a caller naming the same
	/// scopes every frame keeps.
	public bool BeginScope(uint32 name)
	{
		if (!Armed)
			return false;
		Local().Stack.Add(.() { Name = name, BeginTick = ProfileClock.Now() });
		return true;
	}

	/// Closes the scope this thread opened last.
	public void EndScope()
	{
		let thread = Local();
		if (thread.Stack.IsEmpty)
			return;
		let open = thread.Stack.PopBack();
		let written = thread.Written;
		if (written - Volatile.Read(ref thread.Read) >= thread.Ring.Count)
		{
			Interlocked.Increment(ref thread.Dropped);
			return;
		}
		thread.Ring[(int)(written & (thread.Ring.Count - 1))] =
			ScopeEvent(open.Name, (uint32)thread.Stack.Count, open.BeginTick, ProfileClock.Now());
		Volatile.Write(ref thread.Written, written + 1);
	}

	/// The id of `name`, added to the table if new. Any thread: a name another thread adds joins
	/// the table the frame thread reads at the next frame end; one the frame thread adds (a GPU
	/// pass's) joins it at once.
	public uint32 InternName(StringView name)
	{
		using (mLock.Enter())
		{
			if (mNameIds.TryGetValue(name, let known))
				return known;
			let id = (uint32)(mNames.Count + mPendingNames.Count);
			let copy = new String(name);
			mPendingNames.Add(copy);
			mNameIds[copy] = id;
			if (Thread.CurrentThread.Id == mFrameThreadId)
				PublishPendingNames();
			return id;
		}
	}

	// ---- frames (the frame thread) ----------------------------------------------------------

	public void BeginFrame()
	{
		mFrameBeginTick = ProfileClock.Now();
		mFrameThreadId = Thread.CurrentThread.Id;
	}

	/// Closes the frame: gathers what every thread finished into its record (when armed),
	/// publishes new names and threads, and moves on to the next frame number.
	public void EndFrame()
	{
		let endTick = ProfileClock.Now();
		let threads = scope List<ThreadData>();
		using (mLock.Enter())
		{
			PublishPendingNames();
			for (let thread in mThreads)
			{
				threads.Add(thread);
				if (thread.Index >= (uint32)mThreadInfos.Count)
				{
					let info = new ThreadInfo();
					info.Index = thread.Index;
					info.Name.Set(thread.Name);
					mThreadInfos.Add(info);
				}
			}
		}

		FrameRecord record = null;
		if (Armed)
		{
			record = mHistory[(int)(mFrameNumber % (uint64)mHistory.Count)];
			record.Clear();
			record.FrameNumber = mFrameNumber;
			record.BeginTick = mFrameBeginTick;
			record.EndTick = endTick;
			mRecordedFrames++;
			mLatestRecorded = mFrameNumber;
		}
		for (let thread in threads)
		{
			let written = thread.Written;
			let read = thread.Read;
			let dropped = Interlocked.Exchange(ref thread.Dropped, 0);
			if ((record != null) && ((written > read) || (dropped > 0)))
			{
				let frame = new ThreadFrame();
				frame.Thread = thread.Index;
				frame.Dropped = (uint32)dropped;
				for (var i = read; i < written; i++)
					frame.Scopes.Add(thread.Ring[(int)(i & (thread.Ring.Count - 1))]);
				record.Threads.Add(frame);
			}
			// Unarmed, what was left is let go.
			Volatile.Write(ref thread.Read, written);
		}
		if (record != null)
		{
			for (int id < mCounterSet.Count)
			{
				if (mCounterSet[id])
				{
					record.Counters.Add(.((uint32)id, mCounterValues[id]));
					mCounterSet[id] = false;
				}
			}
		}
		PushFrameTime(ProfileClock.ToMilliseconds((endTick >= mFrameBeginTick) ? (endTick - mFrameBeginTick) : 0));
		mFrameNumber++;
	}

	/// The number the frame now running will have.
	public uint64 CurrentFrameNumber => mFrameNumber;

	/// Keeps the last `frames` records (at least one); forgets the ones kept so far.
	public void SetHistoryLength(uint32 frames)
	{
		let count = (frames > 0) ? frames : 1;
		ClearAndDeleteItems(mHistory);
		for (uint32 i < count)
			mHistory.Add(new FrameRecord());
		mRecordedFrames = 0;
	}

	public uint32 HistoryLength => (uint32)mHistory.Count;

	/// Frame `frameNumber`'s record while it is still kept, else null.
	public FrameRecord Frame(uint64 frameNumber)
	{
		if (mRecordedFrames == 0)
			return null;
		let record = mHistory[(int)(frameNumber % (uint64)mHistory.Count)];
		return ((record.FrameNumber == frameNumber) && (record.EndTick != 0)) ? record : null;
	}

	/// The newest record, null when nothing was recorded.
	public FrameRecord LatestFrame => (mRecordedFrames == 0) ? null : Frame(mLatestRecorded);

	/// Whether any frame was recorded; then the frames kept lie between OldestKeptFrame and
	/// LatestRecordedFrame (an unarmed frame between them has no record).
	public bool HasFrames => mRecordedFrames > 0;
	public uint64 LatestRecordedFrame => mLatestRecorded;
	public uint64 OldestKeptFrame
	{
		get
		{
			let size = (uint64)mHistory.Count;
			return (mLatestRecorded + 1 > size) ? (mLatestRecorded + 1 - size) : 0;
		}
	}

	// ---- GPU passes (the frame thread) ------------------------------------------------------

	/// Adds GPU passes to frame `frameNumber`'s record when they arrive (each render graph of
	/// the frame sends its own); let go once the record is gone.
	public void SubmitGpuPasses(uint64 frameNumber, Span<GpuPassEvent> passes)
	{
		let record = Frame(frameNumber);
		if (record == null)
			return;
		for (let pass in passes)
			record.Gpu.Add(pass);
		record.GpuValid = true;
	}

	// ---- counters (the frame thread) --------------------------------------------------------

	/// A counter's id, registered once under its name.
	public uint32 RegisterCounter(StringView name, CounterUnit unit)
	{
		for (int id < mCounters.Count)
		{
			if (mCounters[id].Name == name)
				return (uint32)id;
		}
		let info = new CounterInfo();
		info.Name.Set(name);
		info.Unit = unit;
		mCounters.Add(info);
		mCounterValues.Add(0.0);
		mCounterSet.Add(false);
		return (uint32)(mCounters.Count - 1);
	}

	/// This frame's value of counter `id`; the frame's record takes the last one set.
	public void SetCounter(uint32 id, double value)
	{
		if (id < (uint32)mCounterValues.Count)
		{
			mCounterValues[(int)id] = value;
			mCounterSet[(int)id] = true;
		}
	}

	// ---- tables (the frame thread; as of the last frame end) --------------------------------

	public StringView NameOf(uint32 id) => (id < (uint32)mNames.Count) ? mNames[(int)id] : StringView();
	public uint32 NameCount => (uint32)mNames.Count;
	public Span<ThreadInfo> Threads => mThreadInfos;
	public Span<CounterInfo> Counters => mCounters;

	// ---- summaries --------------------------------------------------------------------------

	/// The mean of the last 64 frame times in milliseconds, armed or not.
	public double AverageFrameMs
	{
		get
		{
			if (mFrameTimeCount == 0)
				return 0.0;
			var sum = 0.0;
			for (int32 i < mFrameTimeCount)
				sum += mFrameTimes[i];
			return sum / mFrameTimeCount;
		}
	}

	/// The newest record as text (the P key): its time, then each thread's scopes in the order
	/// they began, indented by depth, then the GPU passes.
	public void BuildReport(String outReport)
	{
		let frame = LatestFrame;
		if (frame == null)
		{
			outReport.Append(Armed ? "=== Profile: no frame recorded yet ===\n" : "=== Profile: not armed ===\n");
			return;
		}
		var scopes = 0;
		for (let thread in frame.Threads)
			scopes += thread.Scopes.Count;
		outReport.AppendF("=== Profile: frame {}  {:F3} ms (avg {:F3} ms)  {} scopes ===\n",
			frame.FrameNumber, frame.Ms, AverageFrameMs, scopes);
		for (let thread in frame.Threads)
		{
			let threadName = (thread.Thread < (uint32)mThreadInfos.Count) ? (StringView)mThreadInfos[(int)thread.Thread].Name : "?";
			outReport.AppendF("  [{}]", threadName);
			if (thread.Dropped > 0)
				outReport.AppendF(" ({} dropped)", thread.Dropped);
			outReport.Append("\n");
			// Parents begin before their children; scopes are recorded as they finish, children
			// first, so a tick shared with the parent is broken by depth.
			let order = scope List<int>();
			for (int i < thread.Scopes.Count)
				order.Add(i);
			order.Sort(scope (a, b) =>
				{
					let left = thread.Scopes[a];
					let right = thread.Scopes[b];
					if (left.BeginTick != right.BeginTick)
						return left.BeginTick <=> right.BeginTick;
					return left.Depth <=> right.Depth;
				});
			for (let index in order)
			{
				let recorded = thread.Scopes[index];
				outReport.Append("    ");
				for (uint32 d < recorded.Depth)
					outReport.Append("  ");
				outReport.AppendF("{}: {:F3} ms\n", NameOf(recorded.Name), ProfileClock.ToMilliseconds(recorded.EndTick - recorded.BeginTick));
			}
		}
		if (frame.GpuValid)
		{
			outReport.Append("  [GPU]\n");
			for (let pass in frame.Gpu)
				outReport.AppendF("    {}: {:F3} ms\n", NameOf(pass.Name), ProfileClock.ToMilliseconds(pass.EndTick - pass.BeginTick));
		}
	}

	// ---- internals --------------------------------------------------------------------------

	/// The calling thread's data for THIS profiler: a per thread cache of the last profiler it
	/// recorded into, else found or made under the lock.
	private ThreadData Local()
	{
		if (sCachedOwnerId == mId)
			return sCachedLocal;
		let threadId = Thread.CurrentThread.Id;
		ThreadData found = null;
		using (mLock.Enter())
		{
			for (let thread in mThreads)
			{
				if (thread.ThreadId == threadId)
				{
					found = thread;
					break;
				}
			}
			if (found == null)
			{
				found = new ThreadData();
				found.Index = (uint32)mThreads.Count;
				found.ThreadId = threadId;
				let named = ThreadNames.Current;
				if (named.IsEmpty)
					found.Name.AppendF("Thread {}", found.Index);
				else
					found.Name.Set(named);
				found.Ring = new ScopeEvent[(threadId == mFrameThreadId) ? mFrameThreadRing : mThreadRing];
				mThreads.Add(found);
			}
		}
		sCachedOwnerId = mId;
		sCachedLocal = found;
		return found;
	}

	/// Under the lock, on the frame thread: pending names join the table it reads, in id order.
	private void PublishPendingNames()
	{
		for (let name in mPendingNames)
			mNames.Add(name);
		mPendingNames.Clear();
	}

	private static uint32 RoundUpPow2(uint32 value)
	{
		uint32 result = 1;
		while ((result < value) && (result < (1U << 30)))
			result <<= 1;
		return result;
	}

	private void PushFrameTime(double ms)
	{
		mFrameTimes[mFrameTimeHead] = ms;
		mFrameTimeHead = (mFrameTimeHead + 1) % cFrameTimes;
		if (mFrameTimeCount < cFrameTimes)
			mFrameTimeCount++;
	}
}
