using System;
using System.Diagnostics;

namespace Sedulous.Profiler;

/// The profiler's time base: a monotonic counter in microseconds, ABSOLUTE, so a GPU's
/// calibrated timestamps (IQueue.CalibrateTimestamps) land on it: CLOCK_MONOTONIC on POSIX
/// (what Stopwatch reads there), QueryPerformanceCounter on Windows, read here directly because
/// Stopwatch counts that one from its own first call.
///
/// Microseconds rather than nanoseconds, because that is the finest thing corlib exposes
/// portably. It is enough for frame scopes, but it does mean a short scope can measure
/// zero and that a parent and its first child routinely share a start tick, which is why
/// the report orders by depth as well as by time.
static class ProfileClock
{
	public const int64 TicksPerSecond = 1000000;

#if BF_PLATFORM_WINDOWS
	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern int32 QueryPerformanceCounter(int64* count);
	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern int32 QueryPerformanceFrequency(int64* frequency);

	private static int64 sFrequency;

	public static int64 Now()
	{
		if (sFrequency == 0)
		{
			int64 frequency = 0;
			QueryPerformanceFrequency(&frequency);
			sFrequency = (frequency > 0) ? frequency : 1;
		}
		int64 count = 0;
		QueryPerformanceCounter(&count);
		// Whole seconds and the remainder apart, so the product cannot overflow.
		return (count / sFrequency) * TicksPerSecond + (count % sFrequency) * TicksPerSecond / sFrequency;
	}
#else
	public static int64 Now() => Stopwatch.GetTimestamp();
#endif

	public static double ToMilliseconds(int64 ticks) => ticks / 1000.0;
}
