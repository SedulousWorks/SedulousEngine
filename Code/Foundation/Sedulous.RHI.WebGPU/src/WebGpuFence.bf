using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A timeline fence, kept on the CPU.
///
/// WebGPU has no fence object, so the RHI's timeline is emulated: a fenced submit
/// registers a work-done callback that records its value here when the GPU passes that
/// submission, and Wait pumps until the value arrives. Single threaded safe, which is
/// exactly the web model.
///
/// CompletedValue only advances when callbacks are DELIVERED. Wait pumps; anything just
/// watching sees new values after any pump on the same instance.
class WebGpuFence : IFence
{
	/// The stand-in for a timeout: wgpu-native's timed waits are unimplemented, so the
	/// iteration guard is what bounds the wait.
	private const uint32 cWaitSpins = 1000000;

	private WGPUInstance mInstance;
	private WGPUDevice mDevice;
	private uint64 mCompleted;

	private uint64 mNotedValue = 0;
	private WGPUSubmissionIndex mNotedIndex = default;
	private bool mHasNote = false;

	/// Queued callbacks still pointing at this fence. BORROWED: each record is owned by
	/// the callback that will free it.
	private List<WebGpuPendingSignal> mPending = new .() ~ delete _;

	public this(WGPUInstance instance, WGPUDevice device, uint64 initialValue)
	{
		mInstance = instance;
		mDevice = device;
		mCompleted = initialValue;
	}

	public ~this()
	{
		// Undelivered work-done callbacks still point here. Sever them, so the one that
		// fires during device teardown does not write through a freed fence.
		for (let pending in mPending)
			pending.Fence = null;
	}

	/// Registers a queued record so this fence can sever it on destruction.
	public void AttachPending(WebGpuPendingSignal pending)
	{
		mPending.Add(pending);
	}

	/// Drops a record the callback is about to free.
	public void DetachPending(WebGpuPendingSignal pending)
	{
		let index = mPending.IndexOf(pending);
		if (index >= 0)
			mPending.RemoveAt(index);
	}

	public uint64 CompletedValue()
	{
		return mCompleted;
	}

	/// The queue records each fenced submission's wgpu SUBMISSION INDEX here.
	///
	/// Values are monotonic, so the latest note supersedes for lower values too.
	public void NoteSubmission(uint64 value, WGPUSubmissionIndex submissionIndex)
	{
		mNotedValue = value;
		mNotedIndex = submissionIndex;
		mHasNote = true;
	}

	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		if (mCompleted >= value)
			return true;

		// The fast path, and the reason NoteSubmission exists: polling on that exact
		// submission index returns when THAT submission retires, immune to unrelated
		// queue state. A presented frame in flight can otherwise starve a blanket poll
		// on Wayland with FIFO present. This is the ONE place a blocking poll is safe,
		// because it is waiting on something specific rather than on the queue at large.
		if (mHasNote && (mNotedValue >= value) && (mDevice != null))
		{
			WebGpuApi.NativeOnly.DevicePollUntil(mDevice, ref mNotedIndex);
			SignalFromCallback(mNotedValue);
			mHasNote = false;
			return true;
		}

		// Work-done callbacks fire on DEVICE polls, and those polls do not block here:
		// blocking on an empty queue can hang forever, which is why the fast path above
		// is the only blocking one.
		for (uint32 i = 0; (i < cWaitSpins) && (mCompleted < value); i++)
		{
			wgpuInstanceProcessEvents(mInstance);
			if (mCompleted >= value)
				break;

			if (mDevice != null)
				WebGpuApi.NativeOnly.DevicePoll(mDevice);

			// On web the callback resolves from a browser microtask that cannot run
			// while this loop spins. Without yielding, the completed value never
			// advances and the loop burns the whole guard walking event maps every
			// frame, which was the dominant web frame cost. A no-op on desktop, where
			// the polls above deliver.
			WebGpuApi.YieldToEventLoop();
		}

		return mCompleted >= value;
	}

	/// Only ever advances, callbacks being able to arrive out of order.
	public void SignalFromCallback(uint64 value)
	{
		if (value > mCompleted)
			mCompleted = value;
	}
}
