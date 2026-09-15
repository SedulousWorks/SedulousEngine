using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Per pass GPU timing, from a pair of timestamps around each pass.
///
/// The timestamps are written into a query set and resolved into a readback buffer, so the
/// results are a FRAME BEHIND at least: they are read once the GPU has actually finished,
/// which is the caller's business rather than this one's.
class GraphProfiler
{
	private IDevice mDevice = null;
	private IQuerySet mQuerySet = null;
	private IBuffer mReadbackBuffer = null;
	private int32 mMaxPasses = 0;
	private bool mInitialized = false;
	private List<String> mPassNames = new .() ~ DeleteContainerAndItems!(_);
	private List<float> mPassTimesMs = new .() ~ delete _;
	private float mTimestampPeriod = 0.0f;

	public bool Enabled = true;

	public ~this()
	{
		Destroy();
	}

	public bool IsInitialized => mInitialized;

	/// Two timestamps per pass, and a readback buffer to resolve them into.
	public Result<void> Init(IDevice device, int32 maxPasses = 64)
	{
		mDevice = device;
		mMaxPasses = maxPasses;

		var queryDesc = QuerySetDesc();
		queryDesc.Type = .Timestamp;
		queryDesc.Count = (uint32)(maxPasses * 2);
		queryDesc.Label = "RG_Profiler_Queries";
		if (!(device.CreateQuerySet(queryDesc) case .Ok(let querySet)))
			return .Err;
		mQuerySet = querySet;

		var bufferDesc = BufferDesc();
		bufferDesc.Size = (uint64)maxPasses * 2 * sizeof(uint64);
		bufferDesc.Usage = .CopyDst;
		bufferDesc.Memory = .GpuToCpu;
		bufferDesc.Label = "RG_Profiler_Readback";
		if (!(device.CreateBuffer(bufferDesc) case .Ok(let buffer)))
			return .Err;
		mReadbackBuffer = buffer;

		mPassTimesMs.Resize(maxPasses);
		mInitialized = true;
		return .Ok;
	}

	/// Resets the query set at the START of the frame's encoder.
	///
	/// A timestamp can only be written into a freshly reset pool, and the reset itself has to
	/// be outside any render pass, which is why it happens here rather than per pass.
	public void BeginFrame(ICommandEncoder encoder)
	{
		if (!mInitialized || !Enabled)
			return;

		encoder.ResetQuerySet(mQuerySet, 0, (uint32)(mMaxPasses * 2));
		ClearAndDeleteItems!(mPassNames);
	}

	public void BeginPass(ICommandEncoder encoder, int32 passIndex, StringView passName)
	{
		if (!mInitialized || !Enabled || (passIndex >= mMaxPasses))
			return;

		while ((int32)mPassNames.Count <= passIndex)
			mPassNames.Add(new String());
		mPassNames[passIndex].Set(passName);

		encoder.WriteTimestamp(mQuerySet, (uint32)(passIndex * 2));
	}

	public void EndPass(ICommandEncoder encoder, int32 passIndex)
	{
		if (!mInitialized || !Enabled || (passIndex >= mMaxPasses))
			return;

		encoder.WriteTimestamp(mQuerySet, (uint32)(passIndex * 2 + 1));
	}

	/// Copies the written timestamps into the readback buffer, after every pass is recorded.
	public void Resolve(ICommandEncoder encoder, int32 passCount)
	{
		if (!mInitialized || !Enabled || (passCount == 0))
			return;

		let queryCount = (uint32)Min(passCount * 2, mMaxPasses * 2);
		encoder.ResolveQuerySet(mQuerySet, 0, queryCount, mReadbackBuffer, 0);
	}

	/// Reads the results and appends a report. ONLY once the GPU has finished the frame those
	/// timestamps came from, or the numbers are whatever was in the buffer before.
	public void ReadResults(int32 passCount, String outReport)
	{
		if (!mInitialized || !Enabled || (passCount == 0))
			return;

		let mapped = (uint64*)mReadbackBuffer.Map();
		if (mapped == null)
			return;
		defer mReadbackBuffer.Unmap();

		let count = Min(passCount, mMaxPasses);
		var totalMs = 0.0f;

		outReport.Append("=== GPU Pass Timing ===\n");
		for (int32 i = 0; i < count; i++)
		{
			let begin = mapped[i * 2];
			let end = mapped[i * 2 + 1];
			// A pass that never ran leaves its pair untouched, which reads as no time at all
			// rather than as an enormous negative one.
			let ticks = (end > begin) ? (end - begin) : 0;
			let ms = (float)ticks * mTimestampPeriod / 1000000.0f;
			mPassTimesMs[i] = ms;
			totalMs += ms;

			outReport.AppendF("  {} ms  {}\n", ms, NameOf(i));
		}
		outReport.AppendF("  --------\n  {} ms  TOTAL\n", totalMs);

		AppendAggregate(count, outReport);
	}

	/// The same numbers gathered BY NAME, so twenty four identically named probe passes read
	/// as one line rather than twenty four, sorted with the expensive first.
	private void AppendAggregate(int32 count, String outReport)
	{
		// VIEWS into the profiler's own name list, never copies. A copy here was allocated
		// inside the loop body, so it was freed at the end of the iteration that made it and
		// the next comparison read a dangling string.
		let names = scope List<StringView>();
		let sums = scope List<float>();
		let counts = scope List<int32>();

		for (int32 i = 0; i < count; i++)
		{
			let name = NameOf(i);
			var found = -1;
			for (int a < names.Count)
			{
				if (names[a] == name)
				{
					found = a;
					break;
				}
			}

			if (found < 0)
			{
				names.Add(name);
				sums.Add(mPassTimesMs[i]);
				counts.Add(1);
				continue;
			}

			sums[found] += mPassTimesMs[i];
			counts[found]++;
		}

		// A selection sort, because there are only ever a handful of distinct names.
		for (int i < names.Count)
		{
			for (int j = i + 1; j < names.Count; j++)
			{
				if (sums[j] <= sums[i])
					continue;

				Swap!(names[i], names[j]);
				Swap!(sums[i], sums[j]);
				Swap!(counts[i], counts[j]);
			}
		}

		outReport.Append("=== GPU by pass name (expensive first) ===\n");
		for (int i < names.Count)
			outReport.AppendF("  {} ms  (x{})  {}\n", sums[i], counts[i], names[i]);
	}

	private StringView NameOf(int32 index) =>
		(index < (int32)mPassNames.Count) ? mPassNames[index] : "???";

	public float GetPassTimeMs(int32 passIndex)
	{
		if ((passIndex < 0) || (passIndex >= (int32)mPassTimesMs.Count))
			return 0.0f;
		return mPassTimesMs[passIndex];
	}

	/// Nanoseconds per tick, which is the backend's to tell us.
	public void SetTimestampPeriod(float nanosecondsPerTick)
	{
		mTimestampPeriod = nanosecondsPerTick;
	}

	public void Destroy()
	{
		if (mDevice != null)
		{
			if (mReadbackBuffer != null)
				mDevice.DestroyBuffer(ref mReadbackBuffer);
			if (mQuerySet != null)
				mDevice.DestroyQuerySet(ref mQuerySet);
		}
		mInitialized = false;
	}
}
