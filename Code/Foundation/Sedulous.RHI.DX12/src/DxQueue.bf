#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.System.Threading;
using Win32.System.WindowsProgramming;

namespace Sedulous.RHI.DX12;

/// One command queue, and the fence it uses to answer WaitIdle.
///
/// The internal fence is SEPARATE from any the caller passes to Submit: WaitIdle has to be
/// able to block on this queue without disturbing whatever the caller is tracking, so it
/// signals its own monotonic value and waits on that.
///
/// The queue and its fence are owned here. The device that made it is not.
class DxQueue : IQueue
{
	private ID3D12CommandQueue* mQueue = null; // owned, released in Cleanup
	private ID3D12Fence* mInternalFence = null; // owned, released in Cleanup
	private HANDLE mFenceEvent = default;
	private uint64 mFenceValue = 0;
	private float mTsPeriod = 1.0f;
	private QueueType mQueueType = .Graphics;
	private DxDevice mDevice = null; // NOT owned, the device outlives its queues
	private ID3D12Device* mD3dDevice = null; // NOT owned

	public QueueType QueueType => mQueueType;
	public ID3D12CommandQueue* Handle => mQueue;
	public DxDevice Owner => mDevice;

	public Result<void> Initialize(ID3D12Device* device, QueueType type, DxDevice owner)
	{
		mQueueType = type;
		mDevice = owner;
		mD3dDevice = device;

		D3D12_COMMAND_QUEUE_DESC qd = .();
		qd.Type = DxConversions.ToCommandListType(type);
		if (FAILED(device.CreateCommandQueue(&qd, ID3D12CommandQueue.IID, (void**)&mQueue)))
			return .Err;

		if (FAILED(device.CreateFence(0, .D3D12_FENCE_FLAG_NONE, ID3D12Fence.IID,
			(void**)&mInternalFence)))
			return .Err;

		mFenceEvent = CreateEventW(null, FALSE, FALSE, null);

		// Timestamps come back in ticks, so the period is what turns them into nanoseconds.
		uint64 freq = 0;
		mQueue.GetTimestampFrequency(&freq);
		mTsPeriod = (freq > 0) ? (1e9f / (float)freq) : 1.0f;
		return .Ok;
	}

	public void Submit(Span<ICommandBuffer> commandBuffers)
	{
		if (commandBuffers.Length == 0)
			return;

		let lists = scope List<ID3D12CommandList*>();
		lists.Resize(commandBuffers.Length);
		for (int i = 0; i < commandBuffers.Length; i++)
		{
			if (let dxCb = commandBuffers[i] as DxCommandBuffer)
				lists[i] = (ID3D12CommandList*)dxCb.Handle;
		}

		mQueue.ExecuteCommandLists((uint32)lists.Count, lists.Ptr);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence, uint64 signalValue)
	{
		Submit(commandBuffers);
		if (let f = signalFence as DxFence)
			mQueue.Signal(f.Handle, signalValue);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
	{
		// The waits are enqueued BEFORE the work, so they order on the GPU rather than
		// blocking here.
		for (int i = 0; i < waitFences.Length; i++)
		{
			if (let f = waitFences[i] as DxFence)
				mQueue.Wait(f.Handle, waitValues[i]);
		}

		Submit(commandBuffers);

		if (let f = signalFence as DxFence)
			mQueue.Signal(f.Handle, signalValue);
	}

	public void WaitIdle()
	{
		mFenceValue++;
		mQueue.Signal(mInternalFence, mFenceValue);

		if (mInternalFence.GetCompletedValue() < mFenceValue)
		{
			mInternalFence.SetEventOnCompletion(mFenceValue, mFenceEvent);
			WaitForSingleObject(mFenceEvent, INFINITE);
		}
	}

	public Result<ITransferBatch> CreateTransferBatch()
	{
		let batch = new DxTransferBatch();
		if (batch.Initialize(mD3dDevice, mQueue, mQueueType) case .Err)
		{
			delete batch;
			return .Err;
		}
		return .Ok(batch);
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		if (let dx = batch as DxTransferBatch)
		{
			dx.Destroy();
			delete dx;
		}
		batch = null;
	}

	public float TimestampPeriod() => mTsPeriod;

	public void Cleanup()
	{
		if (mFenceEvent != default)
		{
			CloseHandle(mFenceEvent);
			mFenceEvent = default;
		}

		if (mInternalFence != null)
		{
			mInternalFence.Release();
			mInternalFence = null;
		}

		if (mQueue != null)
		{
			mQueue.Release();
			mQueue = null;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
