using System;
using System.Collections;

namespace Sedulous.Profiler;

/// Contains all profiling data for a single frame.
class ProfileFrame
{
	/// Frame number.
	public int64 FrameNumber;
	/// Frame start timestamp (high resolution counter).
	public int64 FrameStartTicks;
	/// Total frame duration in microseconds.
	public int64 FrameDurationUs;
	/// All samples collected this frame.
	public List<ProfileSample> Samples = new .() ~ delete _;
	/// String storage for sample names (owns the memory).
	private List<String> mNameStorage = new .() ~ DeleteContainerAndItems!(_);

	public this(int64 frameNumber = 0)
	{
		FrameNumber = frameNumber;
		FrameStartTicks = 0;
		FrameDurationUs = 0;
	}

	/// Clears all samples for reuse.
	public void Clear()
	{
		Samples.Clear();
		DeleteContainerAndItems!(mNameStorage);
		mNameStorage = new .();
		FrameStartTicks = 0;
		FrameDurationUs = 0;
	}

	/// Adds a sample with an owned copy of the name.
	public int32 AddSample(StringView name, int64 startTimeUs, int64 durationUs, int32 depth, int32 threadId, int32 parentIndex = -1)
	{
		let ownedName = new String(name);
		mNameStorage.Add(ownedName);
		let index = (int32)Samples.Count;
		Samples.Add(.(ownedName, startTimeUs, durationUs, depth, threadId, parentIndex));
		return index;
	}

	/// Frame duration in milliseconds.
	public float FrameDurationMs => (float)FrameDurationUs / 1000.0f;

	/// Number of samples in this frame.
	public int SampleCount => Samples.Count;
}
