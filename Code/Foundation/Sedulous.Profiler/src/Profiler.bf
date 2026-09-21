using System;
using System.Collections;
using System.Threading;

namespace Sedulous.Profiler;

/// A hierarchical CPU scope profiler.
///
/// Scopes nest into a per thread tree; at frame end every thread's samples merge into the
/// completed frame snapshot, which is what a report or an overlay reads.
///
/// An ordinary object rather than a singleton, so a test can hold its own and two of them
/// cannot see each other's threads. The process wide one that instrumentation reaches for
/// is installed separately, the same way the logger is.
///
/// Thread safety: BeginScope and EndScope touch only their own thread's data. The thread
/// registry and the frame swap are guarded. EndFrame drains the worker buffers WITHOUT
/// their owners' cooperation, which is safe only because a frame ends when the workers are
/// idle; that is the contract.
class Profiler
{
	private const int32 kHistory = 64;

	private bool mEnabled = true;
	private uint64 mFrameNumber;
	private int64 mFrameStartTick;
	private ProfileFrame mCompleted = new .() ~ delete _;
	/// Guards the thread registry and the frame swap.
	private Monitor mLock = new .() ~ delete _;
	private List<ProfileThreadData> mThreads = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<int, ProfileThreadData> mThreadsById = new .() ~ delete _;
	private int32 mNextThreadIndex;
	private double[kHistory] mHistory;
	private int32 mHistoryHead;
	private int32 mHistoryCount;

	/// Identity rather than the pointer, so a thread's cached slot cannot be mistaken for
	/// a later profiler that happened to be allocated at the same address.
	private static int32 sNextProfilerId;
	private int32 mId;

	[ThreadStatic] private static int32 sCachedOwnerId;
	[ThreadStatic] private static ProfileThreadData sCachedLocal;

	public this()
	{
		mId = Interlocked.Increment(ref sNextProfilerId);
	}

	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// The last finished frame. Valid until the next EndFrame, which reuses it.
	public ProfileFrame CompletedFrame => mCompleted;

	public void BeginFrame()
	{
		if (!mEnabled)
			return;
		mFrameStartTick = ProfileClock.Now();
	}

	public void EndFrame()
	{
		if (!mEnabled)
			return;

		let endTick = ProfileClock.Now();
		using (mLock.Enter())
		{
			mCompleted.Samples.Clear();
			mCompleted.FrameNumber = mFrameNumber;
			mCompleted.FrameStartTick = mFrameStartTick;
			mCompleted.FrameDurationTicks = (endTick >= mFrameStartTick) ? (endTick - mFrameStartTick) : 0;

			for (let thread in mThreads)
			{
				for (let sample in thread.Samples)
					mCompleted.Samples.Add(sample);
				thread.Samples.Clear();
				// Defensive: an unbalanced scope must not leak into the next frame.
				thread.Stack.Clear();
			}

			PushHistory(mCompleted.FrameMs);
			mFrameNumber++;
		}
	}

	public void BeginScope(StringView name)
	{
		if (!mEnabled)
			return;

		let thread = Local();
		thread.Stack.Add(ProfileThreadData.ActiveScope()
			{
				Name = name,
				StartTick = ProfileClock.Now(),
				Depth = (int32)thread.Stack.Count
			});
	}

	public void EndScope()
	{
		if (!mEnabled)
			return;

		let thread = Local();
		if (thread.Stack.IsEmpty)
			return;

		let active = thread.Stack.PopBack();
		let now = ProfileClock.Now();
		thread.Samples.Add(ProfileSample()
			{
				Name = active.Name,
				StartTick = active.StartTick,
				DurationTicks = (now >= active.StartTick) ? (now - active.StartTick) : 0,
				Depth = active.Depth,
				ThreadIndex = thread.Index
			});
	}

	/// Rolling average of recent frame times in milliseconds, which is the number worth
	/// putting on screen: a single frame jitters too much to read.
	public double AverageFrameMs
	{
		get
		{
			if (mHistoryCount == 0)
				return 0.0;
			var sum = 0.0;
			for (int32 i < mHistoryCount)
				sum += mHistory[i];
			return sum / mHistoryCount;
		}
	}

	/// How many threads have recorded anything, which is also the range of ThreadIndex.
	public int32 ThreadCount
	{
		get
		{
			using (mLock.Enter())
				return mNextThreadIndex;
		}
	}

	/// A human readable dump: the frame headline, then the scope tree indented by depth.
	///
	/// Ordered by start tick and THEN by depth. Start tick alone, relying on the sort being
	/// stable, puts a child before its parent whenever the two share a tick; at microsecond
	/// resolution they routinely do. Depth breaks the tie correctly, since a parent both
	/// starts no later than its child and is shallower.
	public void BuildReport(String outReport)
	{
		let frame = mCompleted;
		outReport.AppendF("=== Profile: frame {}  {:F3} ms (avg {:F3} ms)  {} samples ===\n",
			frame.FrameNumber, frame.FrameMs, AverageFrameMs, frame.Samples.Count);

		let order = scope List<int>();
		for (int i < frame.Samples.Count)
			order.Add(i);
		order.Sort(scope (a, b) =>
			{
				let left = frame.Samples[a];
				let right = frame.Samples[b];
				if (left.StartTick != right.StartTick)
					return left.StartTick <=> right.StartTick;
				return left.Depth <=> right.Depth;
			});

		for (let index in order)
		{
			let sample = frame.Samples[index];
			outReport.Append("  ");
			for (int32 d < sample.Depth)
				outReport.Append("  ");
			outReport.Append(sample.Name);
			outReport.AppendF(": {:F3} ms [t{}]\n", sample.DurationMs, sample.ThreadIndex);
		}
	}

	/// This thread's data, created and registered on first use.
	private ProfileThreadData Local()
	{
		if (sCachedOwnerId == mId)
			return sCachedLocal;

		using (mLock.Enter())
		{
			let id = Thread.CurrentThread.Id;
			ProfileThreadData thread;
			if (!mThreadsById.TryGetValue(id, out thread))
			{
				thread = new ProfileThreadData();
				thread.Index = mNextThreadIndex++;
				mThreadsById[id] = thread;
				mThreads.Add(thread);
			}
			sCachedOwnerId = mId;
			sCachedLocal = thread;
			return thread;
		}
	}

	private void PushHistory(double ms)
	{
		mHistory[mHistoryHead] = ms;
		mHistoryHead = (mHistoryHead + 1) % kHistory;
		if (mHistoryCount < kHistory)
			mHistoryCount++;
	}
}
