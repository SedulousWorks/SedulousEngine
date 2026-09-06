using System;
using System.Collections;

namespace Sedulous.Profiler;

/// A finished frame: every thread's samples, and the frame's own wall clock span.
class ProfileFrame
{
	public uint64 FrameNumber;
	public int64 FrameStartTick;
	public int64 FrameDurationTicks;
	public List<ProfileSample> Samples = new .() ~ delete _;

	public double FrameMs => ProfileClock.ToMilliseconds(FrameDurationTicks);
}
