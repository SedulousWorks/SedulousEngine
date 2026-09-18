#if BF_PLATFORM_WINDOWS
using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.System.Threading;
using Win32.System.WindowsProgramming;

namespace Sedulous.RHI.DX12;

/// An ID3D12Fence, which is what the RHI's fence is.
///
/// D3D12 fences are already MONOTONIC COUNTERS rather than binary, so one object orders many
/// submissions and a waiter names the value it cares about. That is the same shape the Vulkan
/// backend gets from a timeline semaphore.
///
/// The win32 EVENT beside it is how a wait blocks: D3D12 has no wait call of its own, it
/// signals an event at a value and the caller waits on that.
class DxFence : IFence
{
	private ID3D12Fence* mFence = null;
	private HANDLE mEvent = default;

	public ID3D12Fence* Handle => mFence;

	public Result<void> Initialize(ID3D12Device* device, uint64 initialValue)
	{
		let hr = device.CreateFence(initialValue, .D3D12_FENCE_FLAG_NONE, ID3D12Fence.IID,
			(void**)&mFence);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxFence: CreateFence failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		mEvent = CreateEventW(null, FALSE, FALSE, null);
		return .Ok;
	}

	public void Cleanup()
	{
		if (mEvent != default)
		{
			CloseHandle(mEvent);
			mEvent = default;
		}

		if (mFence != null)
		{
			mFence.Release();
			mFence = null;
		}
	}

	/// Enqueue a signal of `value` ON THE QUEUE, which is how the fence advances: the value
	/// lands when the GPU reaches that point in the queue, not when this returns.
	public void Signal(ID3D12CommandQueue* queue, uint64 value)
	{
		queue.Signal(mFence, value);
	}

	public uint64 CompletedValue() => mFence.GetCompletedValue();

	/// Returns whether the value was reached. False is a TIMEOUT, not an error, and leaves
	/// the fence perfectly usable.
	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		if (mFence.GetCompletedValue() >= value)
			return true;

		mFence.SetEventOnCompletion(value, mEvent);
		let timeoutMs = (timeoutNs == uint64.MaxValue) ? INFINITE : (uint32)(timeoutNs / 1000000);
		return WaitForSingleObject(mEvent, timeoutMs) == .WAIT_OBJECT_0;
	}
}

#endif // BF_PLATFORM_WINDOWS
