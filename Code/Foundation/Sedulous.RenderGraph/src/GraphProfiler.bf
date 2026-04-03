using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Optional GPU profiler for per-pass timing via timestamp queries.
/// Attach to a RenderGraph to automatically profile pass execution.
public class GraphProfiler
{
	private IDevice mDevice;
	private IQuerySet mQuerySet;
	private IBuffer mReadbackBuffer;
	private int32 mMaxPasses;
	private bool mInitialized;
	private List<String> mPassNames = new .() ~ { for (let s in _) delete s; delete _; };
	private float[] mPassTimesMs ~ delete _;
	private float mGpuTimestampPeriod;

	/// Whether profiling is enabled
	public bool Enabled = true;

	/// Initialize the profiler with a maximum number of passes to track
	public Result<void> Init(IDevice device, int32 maxPasses = 64)
	{
		mDevice = device;
		mMaxPasses = maxPasses;

		// Create timestamp query set (2 queries per pass: begin + end)
		let queryDesc = QuerySetDesc()
		{
			Type = .Timestamp,
			Count = (uint32)(maxPasses * 2),
			Label = "RG_Profiler_Queries"
		};
		if (device.CreateQuerySet(queryDesc) case .Ok(let qs))
			mQuerySet = qs;
		else
			return .Err;

		// Create readback buffer for query results
		let bufSize = (uint64)(maxPasses * 2 * sizeof(uint64));
		let bufDesc = BufferDesc()
		{
			Size = bufSize,
			Usage = .CopyDst,
			Memory = .GpuToCpu,
			Label = "RG_Profiler_Readback"
		};
		if (device.CreateBuffer(bufDesc) case .Ok(let buf))
			mReadbackBuffer = buf;
		else
			return .Err;

		mPassTimesMs = new float[maxPasses];
		mInitialized = true;
		return .Ok;
	}

	/// Record a timestamp before a pass begins
	public void BeginPass(ICommandEncoder encoder, int32 passIndex, StringView passName)
	{
		if (!mInitialized || !Enabled || passIndex >= mMaxPasses)
			return;

		// Store pass name
		while (mPassNames.Count <= passIndex)
			mPassNames.Add(new String());
		mPassNames[passIndex].Set(passName);

		encoder.WriteTimestamp(mQuerySet, (uint32)(passIndex * 2));
	}

	/// Record a timestamp after a pass ends
	public void EndPass(ICommandEncoder encoder, int32 passIndex)
	{
		if (!mInitialized || !Enabled || passIndex >= mMaxPasses)
			return;

		encoder.WriteTimestamp(mQuerySet, (uint32)(passIndex * 2 + 1));
	}

	/// Resolve query results and copy to readback buffer.
	/// Call after all passes have been recorded.
	public void Resolve(ICommandEncoder encoder, int32 passCount)
	{
		if (!mInitialized || !Enabled || passCount == 0)
			return;

		let queryCount = (uint32)Math.Min(passCount * 2, mMaxPasses * 2);
		encoder.ResetQuerySet(mQuerySet, 0, queryCount);
		encoder.ResolveQuerySet(mQuerySet, 0, queryCount, mReadbackBuffer, 0);
	}

	/// Read back results and generate a timing report.
	/// Call after the GPU has finished (fence wait).
	public void ReadResults(int32 passCount, String outReport)
	{
		if (!mInitialized || !Enabled || passCount == 0)
			return;

		let mapped = (uint64*)mReadbackBuffer.Map();
		if (mapped == null)
			return;

		let count = Math.Min(passCount, mMaxPasses);
		float totalMs = 0;

		outReport.Append("=== GPU Pass Timing ===\n");
		for (int32 i = 0; i < count; i++)
		{
			let begin = mapped[i * 2];
			let end = mapped[i * 2 + 1];
			let ticks = (end > begin) ? end - begin : 0;
			let ms = (float)ticks * mGpuTimestampPeriod / 1000000.0f;
			mPassTimesMs[i] = ms;
			totalMs += ms;

			let name = (i < mPassNames.Count) ? mPassNames[i] : "???";
			outReport.AppendF("  {:6.3f} ms  {}\n", ms, name);
		}
		outReport.AppendF("  --------\n  {:6.3f} ms  TOTAL\n", totalMs);

		mReadbackBuffer.Unmap();
	}

	/// Get the last measured time for a pass in milliseconds
	public float GetPassTimeMs(int32 passIndex)
	{
		if (mPassTimesMs == null || passIndex >= mMaxPasses)
			return 0;
		return mPassTimesMs[passIndex];
	}

	/// Set the GPU timestamp period (nanoseconds per tick). Backend-specific.
	public void SetTimestampPeriod(float nanosecondsPerTick)
	{
		mGpuTimestampPeriod = nanosecondsPerTick;
	}

	/// Destroy GPU resources
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

	public ~this()
	{
		Destroy();
	}
}
