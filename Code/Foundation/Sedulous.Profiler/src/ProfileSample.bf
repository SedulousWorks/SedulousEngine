using System;

namespace Sedulous.Profiler;

/// A single profiling sample representing a timed code section.
struct ProfileSample
{
	/// The name/identifier of this sample.
	public StringView Name;
	/// Start time in microseconds from frame start.
	public int64 StartTimeUs;
	/// Duration in microseconds.
	public int64 DurationUs;
	/// Depth in the call hierarchy (0 = top level).
	public int32 Depth;
	/// Thread ID where this sample was recorded.
	public int32 ThreadId;
	/// Parent sample index (-1 if root).
	public int32 ParentIndex;

	public this(StringView name, int64 startTimeUs, int64 durationUs, int32 depth, int32 threadId, int32 parentIndex = -1)
	{
		Name = name;
		StartTimeUs = startTimeUs;
		DurationUs = durationUs;
		Depth = depth;
		ThreadId = threadId;
		ParentIndex = parentIndex;
	}

	/// End time in microseconds from frame start.
	public int64 EndTimeUs => StartTimeUs + DurationUs;

	/// Duration in milliseconds.
	public float DurationMs => (float)DurationUs / 1000.0f;
}
