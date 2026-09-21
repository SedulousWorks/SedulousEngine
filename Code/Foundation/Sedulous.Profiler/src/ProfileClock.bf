using System;
using System.Diagnostics;

namespace Sedulous.Profiler;

/// The profiler's time base: a monotonic counter in microseconds, on both platforms
/// (clock_gettime(CLOCK_MONOTONIC) on POSIX, QueryPerformanceCounter on Windows).
///
/// Microseconds rather than nanoseconds, because that is the finest thing corlib exposes
/// portably. It is enough for frame scopes, but it does mean a short scope can measure
/// zero and that a parent and its first child routinely share a start tick, which is why
/// the report orders by depth as well as by time.
static class ProfileClock
{
	public const int64 TicksPerSecond = 1000000;

	public static int64 Now() => Stopwatch.GetTimestamp();

	public static double ToMilliseconds(int64 ticks) => ticks / 1000.0;
}
