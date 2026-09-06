using System;

namespace Sedulous.Profiler;

/// One completed scope.
///
/// Name is BORROWED, not owned: instrumentation passes a literal, which outlives every
/// frame. A sample built from a temporary string would dangle by the time the report is
/// written.
struct ProfileSample
{
	public StringView Name;
	/// ProfileClock.Now() at scope entry.
	public int64 StartTick;
	public int64 DurationTicks;
	/// Nesting depth within its own thread.
	public int32 Depth;
	public int32 ThreadIndex;

	public double DurationMs => ProfileClock.ToMilliseconds(DurationTicks);
}
