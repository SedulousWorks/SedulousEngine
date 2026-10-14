using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// The render graph's half of the profiler. Each executed pass is timed by a pair of GPU
/// timestamps and, where the device counts them, a pipeline statistics query, into query sets
/// of the frame's slot; when the slot comes round (the GPU finished that frame), its results
/// are put on the CPU's clock and handed to the profiler as that frame's GPU passes. Nothing is
/// measured, nor any query written, while the profiler is not armed.
class GraphProfiler
{
	/// Passes timed in one frame of one graph.
	public const uint32 MaxPasses = 256;

	private class Slot
	{
		public IQuerySet Timestamps;
		public IQuerySet Statistics;
		public IBuffer TimestampReadback;
		public IBuffer StatisticsReadback;
		/// The passes measured, in order.
		public List<uint32> Names = new .() ~ delete _;
		public uint64 FrameNumber;
		public bool Pending;
	}

	private IDevice mDevice;
	private IQueue mQueue;
	private List<Slot> mSlots = new .() ~ DeleteContainerAndItems!(_);
	/// The slot being measured this frame, and the profiler measuring it.
	private Slot mCurrent;
	private Profiler mProfiler;
	private bool mInPass;
	private uint32 mStatisticsSize;
	/// Nanoseconds per GPU tick.
	private double mPeriod = 1.0;
	private bool mCalibrated;
	private uint64 mGpuOrigin;
	private int64 mCpuOrigin;
	private int64 mLastCalibration;

	public ~this()
	{
		Destroy();
	}

	/// Makes the query sets and readbacks for `slots` frames in flight. Needs a device with
	/// timestamps (DeviceFeatures.TimestampQueries); statistics where it has them.
	public Result<void> Init(IDevice device, uint32 slots)
	{
		if (!device.Features.TimestampQueries || (slots == 0))
			return .Err;
		mDevice = device;
		mQueue = device.GetQueue(.Graphics);
		if (mQueue == null)
			return .Err;
		mStatisticsSize = device.Features.PipelineStatisticsQueries ? device.QueryResultSize(.PipelineStatistics) : 0;
		for (uint32 i < slots)
		{
			let slot = new Slot();
			mSlots.Add(slot);
			var desc = QuerySetDesc();
			desc.Type = .Timestamp;
			desc.Count = MaxPasses * 2;
			desc.Label = "RG_Profiler_Timestamps";
			if (!(device.CreateQuerySet(desc) case .Ok(let timestamps)))
			{
				Destroy();
				return .Err;
			}
			slot.Timestamps = timestamps;
			slot.TimestampReadback = MakeReadback((uint64)MaxPasses * 2 * sizeof(uint64));
			if (slot.TimestampReadback == null)
			{
				Destroy();
				return .Err;
			}
			if (mStatisticsSize > 0)
			{
				desc.Type = .PipelineStatistics;
				desc.Count = MaxPasses;
				desc.Label = "RG_Profiler_Statistics";
				if (!(device.CreateQuerySet(desc) case .Ok(let statistics)))
				{
					Destroy();
					return .Err;
				}
				slot.Statistics = statistics;
				slot.StatisticsReadback = MakeReadback((uint64)MaxPasses * mStatisticsSize);
				if (slot.StatisticsReadback == null)
				{
					Destroy();
					return .Err;
				}
			}
		}
		mPeriod = mQueue.TimestampPeriod();
		return .Ok;
	}

	/// Starts a frame in `slot`: first hands `profiler` what the slot's last frame measured (its
	/// GPU work is done by now), then, when the profiler is armed, starts measuring this one.
	/// False when nothing is measured this frame.
	public bool BeginFrame(ICommandEncoder encoder, uint32 slot, Profiler profiler)
	{
		if (mSlots.IsEmpty)
			return false;
		mCurrent = mSlots[(int)(slot % (uint32)mSlots.Count)];
		Collect(mCurrent, profiler);
		if ((profiler == null) || !profiler.Armed || !Calibrate())
		{
			mCurrent = null;
			return false;
		}
		mProfiler = profiler;
		mCurrent.FrameNumber = profiler.CurrentFrameNumber;
		mCurrent.Names.Clear();
		encoder.ResetQuerySet(mCurrent.Timestamps, 0, MaxPasses * 2);
		if (mCurrent.Statistics != null)
			encoder.ResetQuerySet(mCurrent.Statistics, 0, MaxPasses);
		return true;
	}

	/// Around a pass's work, its barriers included, outside any render pass.
	public void BeginPass(ICommandEncoder encoder, uint32 name)
	{
		if ((mCurrent == null) || (mCurrent.Names.Count >= MaxPasses))
			return;
		let index = (uint32)mCurrent.Names.Count;
		mCurrent.Names.Add(name);
		encoder.WriteTimestamp(mCurrent.Timestamps, index * 2);
		if (mCurrent.Statistics != null)
			encoder.BeginPipelineStatisticsQuery(mCurrent.Statistics, index);
		mInPass = true;
	}

	public void EndPass(ICommandEncoder encoder)
	{
		if ((mCurrent == null) || !mInPass)
			return;
		let index = (uint32)(mCurrent.Names.Count - 1);
		if (mCurrent.Statistics != null)
			encoder.EndPipelineStatisticsQuery(mCurrent.Statistics, index);
		encoder.WriteTimestamp(mCurrent.Timestamps, index * 2 + 1);
		mInPass = false;
	}

	/// After the frame's last pass: copies the results out, to be read when the slot comes
	/// round.
	public void EndFrame(ICommandEncoder encoder)
	{
		if (mCurrent == null)
			return;
		let count = (uint32)mCurrent.Names.Count;
		if (count > 0)
		{
			encoder.ResolveQuerySet(mCurrent.Timestamps, 0, count * 2, mCurrent.TimestampReadback, 0);
			if (mCurrent.Statistics != null)
				encoder.ResolveQuerySet(mCurrent.Statistics, 0, count, mCurrent.StatisticsReadback, 0);
			mCurrent.Pending = true;
		}
		mCurrent = null;
	}

	public void Destroy()
	{
		if (mDevice != null)
		{
			for (let slot in mSlots)
			{
				if (slot.Timestamps != null)
					mDevice.DestroyQuerySet(ref slot.Timestamps);
				if (slot.Statistics != null)
					mDevice.DestroyQuerySet(ref slot.Statistics);
				if (slot.TimestampReadback != null)
					mDevice.DestroyBuffer(ref slot.TimestampReadback);
				if (slot.StatisticsReadback != null)
					mDevice.DestroyBuffer(ref slot.StatisticsReadback);
			}
		}
		ClearAndDeleteItems(mSlots);
		mCurrent = null;
		mDevice = null;
	}

	private IBuffer MakeReadback(uint64 size)
	{
		var desc = BufferDesc();
		desc.Size = size;
		desc.Usage = .CopyDst;
		desc.Memory = .GpuToCpu;
		desc.Label = "RG_Profiler_Readback";
		if (mDevice.CreateBuffer(desc) case .Ok(let buffer))
			return buffer;
		return null;
	}

	/// Keeps the GPU to CPU clock mapping fresh: a calibrated pair once a second where the
	/// device reads both clocks together (drift corrected as it goes), else one sync point.
	private bool Calibrate()
	{
		let now = ProfileClock.Now();
		if (mDevice.Features.TimestampCalibration)
		{
			if (mCalibrated && (now - mLastCalibration < ProfileClock.TicksPerSecond))
				return true;
			if (mQueue.CalibrateTimestamps(let gpu, let cpu))
			{
				mGpuOrigin = gpu;
				mCpuOrigin = cpu;
				mLastCalibration = now;
				mCalibrated = true;
			}
			return mCalibrated;
		}
		if (!mCalibrated)
			mCalibrated = SyncPoint();
		return mCalibrated;
	}

	/// Without calibrated timestamps: lets the queue go idle, then writes one timestamp and waits
	/// for it. It ran between the submit and the wait's end, so its CPU time is the middle of the
	/// two, off by half that round trip at most. Once, when profiling first starts.
	private bool SyncPoint()
	{
		var desc = QuerySetDesc();
		desc.Type = .Timestamp;
		desc.Count = 1;
		desc.Label = "RG_Profiler_Sync";
		IQuerySet set = null;
		IBuffer readback = null;
		ICommandPool pool = null;
		IFence fence = null;
		defer
		{
			if (fence != null)
				mDevice.DestroyFence(ref fence);
			if (pool != null)
				mDevice.DestroyCommandPool(ref pool);
			if (readback != null)
				mDevice.DestroyBuffer(ref readback);
			if (set != null)
				mDevice.DestroyQuerySet(ref set);
		}
		if (!(mDevice.CreateQuerySet(desc) case .Ok(let createdSet)))
			return false;
		set = createdSet;
		readback = MakeReadback(sizeof(uint64));
		if (readback == null)
			return false;
		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let createdPool)))
			return false;
		pool = createdPool;
		if (!(mDevice.CreateFence(0) case .Ok(let createdFence)))
			return false;
		fence = createdFence;
		if (!(pool.CreateEncoder() case .Ok(var encoder)))
			return false;
		defer pool.DestroyEncoder(ref encoder);
		encoder.ResetQuerySet(set, 0, 1);
		encoder.WriteTimestamp(set, 0);
		encoder.ResolveQuerySet(set, 0, 1, readback, 0);
		let commandBuffer = encoder.Finish();
		if (commandBuffer == null)
			return false;
		mQueue.WaitIdle();
		let before = ProfileClock.Now();
		var buffers = ICommandBuffer[1](commandBuffer);
		mQueue.Submit(.(&buffers[0], 1), fence, 1);
		let waited = fence.Wait(1);
		let after = ProfileClock.Now();
		if (!waited)
			return false;
		let mapped = (uint64*)readback.Map();
		if (mapped == null)
			return false;
		let stamp = mapped[0];
		readback.Unmap();
		if (stamp == 0)
			return false;
		mGpuOrigin = stamp;
		mCpuOrigin = before + (after - before) / 2;
		return true;
	}

	private int64 ToCpuTicks(uint64 gpu)
	{
		let nanoseconds = (double)(int64)(gpu - mGpuOrigin) * mPeriod;
		return mCpuOrigin + (int64)(nanoseconds * ProfileClock.TicksPerSecond / 1.0e9);
	}

	/// A slot's last frame, done on the GPU: its passes on the CPU's clock, to the profiler.
	private void Collect(Slot slot, Profiler profiler)
	{
		if (!slot.Pending)
			return;
		slot.Pending = false;
		let stamps = (uint64*)slot.TimestampReadback.Map();
		if (stamps == null)
			return;
		let statistics = (slot.Statistics != null) ? (uint8*)slot.StatisticsReadback.Map() : null;
		let passes = scope List<GpuPassEvent>();
		for (int i < slot.Names.Count)
		{
			let begin = stamps[i * 2];
			let end = stamps[i * 2 + 1];
			if ((begin == 0) || (end < begin))
				continue; // not written, or the counter wrapped
			var pass = GpuPassEvent(slot.Names[i], 0, 0, ToCpuTicks(begin), ToCpuTicks(end));
			if (statistics != null)
			{
				let counts = mDevice.DecodePipelineStatistics(statistics + i * mStatisticsSize);
				pass.HasCounts = true;
				pass.Counts.InputVertices = counts.InputVertices;
				pass.Counts.InputPrimitives = counts.InputPrimitives;
				pass.Counts.VertexInvocations = counts.VertexInvocations;
				pass.Counts.ClippingPrimitives = counts.ClippingPrimitives;
				pass.Counts.FragmentInvocations = counts.FragmentInvocations;
				pass.Counts.ComputeInvocations = counts.ComputeInvocations;
			}
			passes.Add(pass);
		}
		if (statistics != null)
			slot.StatisticsReadback.Unmap();
		slot.TimestampReadback.Unmap();
		// The frame numbers are the profiler's that measured them; another has none of them.
		if ((profiler != null) && (profiler == mProfiler))
			profiler.SubmitGpuPasses(slot.FrameNumber, passes);
	}
}
