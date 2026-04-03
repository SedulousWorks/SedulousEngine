namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.System.Threading;
using Sedulous.RHI;

/// DX12 implementation of IFence using ID3D12Fence.
class DX12Fence : IFence
{
	private ID3D12Fence* mFence;
	private HANDLE mEvent;

	public this() { }

	public Result<void> Init(DX12Device device, uint64 initialValue)
	{
		HRESULT hr = device.Handle.CreateFence(initialValue, .D3D12_FENCE_FLAG_NONE,
			ID3D12Fence.IID, (void**)&mFence);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12Fence: CreateFence failed (0x{hr:X})");
			return .Err;
		}

		mEvent = CreateEventW(null, FALSE, FALSE, null);
		return .Ok;
	}

	public uint64 CompletedValue => mFence.GetCompletedValue();

	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		if (mFence.GetCompletedValue() >= value)
			return true;

		mFence.SetEventOnCompletion(value, mEvent);

		// Convert nanoseconds to milliseconds for WaitForSingleObject
		uint32 timeoutMs = (timeoutNs == uint64.MaxValue) ? 0xFFFFFFFF : (uint32)(timeoutNs / 1000000);
		let result = WaitForSingleObject(mEvent, timeoutMs);
		return result == 0; // WAIT_OBJECT_0
	}

	public void Cleanup(DX12Device device)
	{
		if (mEvent != 0)
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

	// --- Internal ---
	public ID3D12Fence* Handle => mFence;
}
