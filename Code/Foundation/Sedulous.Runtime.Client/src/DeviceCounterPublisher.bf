using System;
using Sedulous.Profiler;
using Sedulous.RHI;

namespace Sedulous.Runtime.Client;

/// Hands a device's counts to the profiler once a frame: what the frame recorded (the
/// differences of the device's running totals: draws, dispatches, passes, binds, bytes through
/// transfer batches), the GPU memory its resources hold now, and the driver's own budget and use
/// where it gives them, read once a second. The host calls it at each frame's end.
class DeviceCounterPublisher
{
	/// The profiler the counters below were registered in; another one registers its own.
	private Profiler mRegisteredIn;
	private uint32 mDraws;
	private uint32 mDispatches;
	private uint32 mRenderPasses;
	private uint32 mComputePasses;
	private uint32 mPipelineBinds;
	private uint32 mBindGroupBinds;
	private uint32 mTransferBytes;
	private uint32 mBufferBytes;
	private uint32 mTextureBytes;
	private uint32 mRenderTargetBytes;
	private uint32 mBudgetId;
	private uint32 mUsedId;
	private DeviceCounters mLast;
	private bool mHaveLast;
	private bool mHaveBudget;
	private int64 mBudgetTick;
	private uint64 mBudget;
	private uint64 mUsed;

	/// Sets this frame's counters from `device`, on the frame thread before the frame ends. Keeps
	/// its totals current whether or not the profiler is armed, so an armed frame's numbers are
	/// that frame's.
	public void Publish(IDevice device, Profiler profiler)
	{
		if (mRegisteredIn != profiler)
			Register(profiler);
		let now = device.Counters();
		if (mHaveLast)
		{
			profiler.SetCounter(mDraws, Delta(now.Draws, mLast.Draws));
			profiler.SetCounter(mDispatches, Delta(now.Dispatches, mLast.Dispatches));
			profiler.SetCounter(mRenderPasses, Delta(now.RenderPasses, mLast.RenderPasses));
			profiler.SetCounter(mComputePasses, Delta(now.ComputePasses, mLast.ComputePasses));
			profiler.SetCounter(mPipelineBinds, Delta(now.PipelineBinds, mLast.PipelineBinds));
			profiler.SetCounter(mBindGroupBinds, Delta(now.BindGroupBinds, mLast.BindGroupBinds));
			profiler.SetCounter(mTransferBytes, Delta(now.TransferBytes, mLast.TransferBytes));
		}
		profiler.SetCounter(mBufferBytes, (double)now.BufferBytes);
		profiler.SetCounter(mTextureBytes, (double)now.TextureBytes);
		profiler.SetCounter(mRenderTargetBytes, (double)now.RenderTargetBytes);
		mLast = now;
		mHaveLast = true;

		let tick = ProfileClock.Now();
		if (device.Features.MemoryBudget && (!mHaveBudget || (tick - mBudgetTick >= ProfileClock.TicksPerSecond)))
		{
			mHaveBudget = device.MemoryBudget(out mBudget, out mUsed);
			mBudgetTick = tick;
		}
		if (mHaveBudget)
		{
			profiler.SetCounter(mBudgetId, (double)mBudget);
			profiler.SetCounter(mUsedId, (double)mUsed);
		}
	}

	private void Register(Profiler profiler)
	{
		mDraws = profiler.RegisterCounter("Draws", .Count);
		mDispatches = profiler.RegisterCounter("Dispatches", .Count);
		mRenderPasses = profiler.RegisterCounter("Render passes", .Count);
		mComputePasses = profiler.RegisterCounter("Compute passes", .Count);
		mPipelineBinds = profiler.RegisterCounter("Pipeline binds", .Count);
		mBindGroupBinds = profiler.RegisterCounter("Bind group binds", .Count);
		mTransferBytes = profiler.RegisterCounter("Transfer", .Bytes);
		mBufferBytes = profiler.RegisterCounter("Buffer memory", .Bytes);
		mTextureBytes = profiler.RegisterCounter("Texture memory", .Bytes);
		mRenderTargetBytes = profiler.RegisterCounter("Render target memory", .Bytes);
		mBudgetId = profiler.RegisterCounter("GPU memory budget", .Bytes);
		mUsedId = profiler.RegisterCounter("GPU memory used", .Bytes);
		mRegisteredIn = profiler;
	}

	private static double Delta(uint64 now, uint64 last) => (double)((now >= last) ? (now - last) : 0);
}
