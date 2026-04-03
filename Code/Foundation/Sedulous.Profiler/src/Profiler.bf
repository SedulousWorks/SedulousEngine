using System;
using System.Collections;
using System.Threading;
using System.Diagnostics;
using Sedulous.Profiler.Internal;

namespace Sedulous.Profiler;

/// Alias to avoid conflict with System.Diagnostics.Profiler
typealias SProfiler = Sedulous.Profiler.Profiler;

/// Static profiler API for collecting timing data.
/// Thread-safe for multi-threaded profiling.
static class Profiler
{
	private static bool sEnabled = false;
	private static Monitor sLock = new .() ~ delete _;
	private static Dictionary<int32, ThreadProfileData> sThreadData = new .() ~ DeleteDictionaryAndValues!(_);
	private static ProfileFrame sCurrentFrame = new .() ~ delete _;
	private static ProfileFrame sCompletedFrame = new .() ~ delete _;
	private static List<IProfilerBackend> sBackends = new .() ~ delete _;
	private static int64 sFrameNumber = 0;
	private static Stopwatch sStopwatch = new .() ~ delete _;

	/// Whether profiling is enabled.
	public static bool Enabled
	{
		get => sEnabled;
		set => sEnabled = value;
	}

	/// Initialize the profiler.
	public static void Initialize()
	{
		sStopwatch.Start();
		sEnabled = true;
	}

	/// Shutdown the profiler and notify backends.
	public static void Shutdown()
	{
		sEnabled = false;
		sStopwatch.Stop();
		using (sLock.Enter())
		{
			for (let backend in sBackends)
				backend.OnShutdown();
		}
	}

	/// Register a backend to receive profiling data.
	public static void AddBackend(IProfilerBackend backend)
	{
		using (sLock.Enter())
		{
			sBackends.Add(backend);
		}
	}

	/// Remove a backend.
	public static bool RemoveBackend(IProfilerBackend backend)
	{
		using (sLock.Enter())
		{
			return sBackends.Remove(backend);
		}
	}

	/// Begin a new frame. Call at the start of each frame.
	public static void BeginFrame()
	{
		if (!sEnabled) return;

		using (sLock.Enter())
		{
			sCurrentFrame.Clear();
			sCurrentFrame.FrameNumber = sFrameNumber;
			sCurrentFrame.FrameStartTicks = GetCurrentMicroseconds();

			// Clear per-thread state
			for (let (_, threadData) in sThreadData)
				threadData.Clear();
		}
	}

	/// End the current frame. Call at the end of each frame.
	public static void EndFrame()
	{
		if (!sEnabled) return;

		using (sLock.Enter())
		{
			let endUs = GetCurrentMicroseconds();
			sCurrentFrame.FrameDurationUs = endUs - sCurrentFrame.FrameStartTicks;
			sFrameNumber++;

			// Swap frames
			let temp = sCompletedFrame;
			sCompletedFrame = sCurrentFrame;
			sCurrentFrame = temp;

			// Notify backends
			for (let backend in sBackends)
				backend.OnFrameComplete(sCompletedFrame);
		}
	}

	/// Begin a profiling scope and return a scope that auto-disposes.
	/// Use with `using` for automatic scope end.
	/// Example: using (Profiler.Begin("Update")) { ... }
	[Inline]
	public static ProfileScope Begin(StringView name)
	{
		return .(name);
	}

	/// Begin a profiling scope. Must be paired with EndScope.
	public static void BeginScope(StringView name)
	{
		if (!sEnabled) return;

		let threadId = GetCurrentThreadId();
		let startUs = GetCurrentMicroseconds();

		using (sLock.Enter())
		{
			let threadData = GetOrCreateThreadData(threadId);
			threadData.BeginScope(name, startUs);
		}
	}

	/// End the current profiling scope.
	public static void EndScope()
	{
		if (!sEnabled) return;

		let endUs = GetCurrentMicroseconds();
		let threadId = GetCurrentThreadId();

		using (sLock.Enter())
		{
			if (!sThreadData.TryGetValue(threadId, let threadData))
				return;

			StringView name;
			int64 startUs;
			int32 depth;
			int32 parentIndex;
			if (!threadData.EndScope(out name, out startUs, out depth, out parentIndex))
				return;

			let relativeStartUs = startUs - sCurrentFrame.FrameStartTicks;
			let durationUs = endUs - startUs;

			threadData.LastSampleIndex = sCurrentFrame.AddSample(name, relativeStartUs, durationUs, depth, threadId, parentIndex);
		}
	}

	/// Get the last completed frame (for display/analysis).
	public static ProfileFrame GetCompletedFrame()
	{
		return sCompletedFrame;
	}

	/// Get current frame number.
	public static int64 FrameNumber => sFrameNumber;

	private static ThreadProfileData GetOrCreateThreadData(int32 threadId)
	{
		if (sThreadData.TryGetValue(threadId, let data))
			return data;

		let newData = new ThreadProfileData(threadId);
		sThreadData[threadId] = newData;
		return newData;
	}

	private static int32 GetCurrentThreadId()
	{
		return (int32)Thread.CurrentThread.Id;
	}

	private static int64 GetCurrentMicroseconds()
	{
		return (int64)(sStopwatch.Elapsed.TotalSeconds * 1000000.0);
	}
}
