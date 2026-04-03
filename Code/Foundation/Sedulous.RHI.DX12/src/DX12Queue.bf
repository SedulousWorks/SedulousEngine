namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.System.Threading;
using Sedulous.RHI;

/// DX12 implementation of IQueue.
class DX12Queue : IQueue
{
	private ID3D12CommandQueue* mQueue;
	private QueueType mType;
	private DX12Device mDevice;

	// Per-queue fence for synchronization
	private ID3D12Fence* mFence;
	private uint64 mFenceValue;
	private HANDLE mFenceEvent;

	public QueueType Type => mType;
	public float TimestampPeriod => 1.0f; // DX12: query via GetTimestampFrequency

	public this() { }

	public Result<void> Init(DX12Device device, QueueType type)
	{
		mDevice = device;
		mType = type;

		D3D12_COMMAND_QUEUE_DESC desc = .()
		{
			Type = DX12Conversions.ToCommandListType(type),
			Priority = 0,
			Flags = .D3D12_COMMAND_QUEUE_FLAG_NONE,
			NodeMask = 0
		};

		HRESULT hr = device.Handle.CreateCommandQueue(&desc, ID3D12CommandQueue.IID, (void**)&mQueue);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12Queue: CreateCommandQueue failed (0x{hr:X})");
			return .Err;
		}

		// Create fence for this queue
		hr = device.Handle.CreateFence(0, .D3D12_FENCE_FLAG_NONE, ID3D12Fence.IID, (void**)&mFence);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12Queue: CreateFence failed (0x{hr:X})");
			return .Err;
		}

		mFenceEvent = CreateEventW(null, FALSE, FALSE, null);
		mFenceValue = 0;

		// Query timestamp frequency
		uint64 freq = 0;
		mQueue.GetTimestampFrequency(&freq);

		return .Ok;
	}

	public void Submit(Span<ICommandBuffer> commandBuffers)
	{
		if (commandBuffers.Length == 0) return;

		ID3D12CommandList*[] lists = scope ID3D12CommandList*[commandBuffers.Length];
		for (int i = 0; i < commandBuffers.Length; i++)
		{
			if (let dxCb = commandBuffers[i] as DX12CommandBuffer)
				lists[i] = (ID3D12CommandList*)dxCb.Handle;
		}

		mQueue.ExecuteCommandLists((uint32)commandBuffers.Length, lists.CArray());
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence fence, uint64 signalValue)
	{
		Submit(commandBuffers);

		if (let dxFence = fence as DX12Fence)
			mQueue.Signal(dxFence.Handle, signalValue);
	}

	public void Submit(
		Span<ICommandBuffer> commandBuffers,
		Span<IFence> waitFences,
		Span<uint64> waitValues,
		IFence signalFence,
		uint64 signalValue)
	{
		// Wait on fences before executing
		for (int i = 0; i < waitFences.Length; i++)
		{
			if (let dxFence = waitFences[i] as DX12Fence)
				mQueue.Wait(dxFence.Handle, waitValues[i]);
		}

		Submit(commandBuffers);

		if (let dxFence = signalFence as DX12Fence)
			mQueue.Signal(dxFence.Handle, signalValue);
	}

	public void WaitIdle()
	{
		mFenceValue++;
		mQueue.Signal(mFence, mFenceValue);
		if (mFence.GetCompletedValue() < mFenceValue)
		{
			mFence.SetEventOnCompletion(mFenceValue, mFenceEvent);
			WaitForSingleObject(mFenceEvent, 0xFFFFFFFF);
		}
	}

	public Result<ITransferBatch> CreateTransferBatch()
	{
		let batch = new DX12TransferBatch();
		if (batch.Init(mDevice, this) case .Err)
		{
			delete batch;
			return .Err;
		}
		return .Ok(batch);
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		if (let dx = batch as DX12TransferBatch) { dx.Destroy(); delete dx; }
		batch = null;
	}

	public void Cleanup()
	{
		if (mFenceEvent != 0)
		{
			CloseHandle(mFenceEvent);
			mFenceEvent = default;
		}
		if (mFence != null)
		{
			mFence.Release();
			mFence = null;
		}
		if (mQueue != null)
		{
			mQueue.Release();
			mQueue = null;
		}
	}

	// --- Internal ---
	public ID3D12CommandQueue* Handle => mQueue;
}
