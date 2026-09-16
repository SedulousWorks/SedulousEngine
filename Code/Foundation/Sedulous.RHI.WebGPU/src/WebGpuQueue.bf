using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A queue, over the device's single one.
///
/// WebGPU exposes exactly ONE queue per device. The RHI models graphics, compute and
/// transfer queues, so the device hands out three thin wrappers that all funnel into
/// that one: correct by construction, there being a single timeline, and still the shape
/// a caller asking for a specific queue type expects.
sealed class WebGpuQueue : IQueue
{
	/// How many command buffers go per submit. Batched and flushed when full, so a long
	/// list costs a bounded number of calls.
	private const int cSubmitBatch = 16;

	private WGPUInstance mInstance;
	private WGPUDevice mDevice;
	private WGPUQueue mQueue;
	private QueueType mType;
	/// BORROWED, owned by the device.
	private WebGpuBufferRegistry mBufferRegistry;
	private List<WebGpuTransferBatch> mBatches = new .() ~ DeleteContainerAndItems!(_);

	public QueueType QueueType => mType;
	public WGPUQueue Handle => mQueue;

	public void Initialize(WGPUInstance instance, WGPUDevice device, WGPUQueue queue,
		QueueType type, WebGpuBufferRegistry bufferRegistry)
	{
		mInstance = instance;
		mDevice = device;
		mQueue = queue;
		mType = type;
		mBufferRegistry = bufferRegistry;
	}

	public void Submit(Span<ICommandBuffer> commandBuffers)
	{
		SubmitInternal(commandBuffers);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence,
		uint64 signalValue)
	{
		let index = SubmitInternal(commandBuffers);
		NoteAndSignal(signalFence, signalValue, index);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
	{
		// ONE queue, one timeline: anything already submitted here is ordered before
		// this submission, so a same queue wait is satisfied by construction. A cross
		// queue wait cannot exist, there being no second queue. Waiting on the CPU
		// deadlocks nothing but costs latency, and the values are still honoured for
		// fences an earlier submission signalled.
		let count = Math.Min(waitFences.Length, waitValues.Length);
		for (int i = 0; i < count; i++)
		{
			if (let fence = waitFences[i] as WebGpuFence)
				fence.Wait(waitValues[i], 0);
		}

		let index = SubmitInternal(commandBuffers);
		NoteAndSignal(signalFence, signalValue, index);
	}

	public void WaitIdle()
	{
		// The same heap record and orphan on timeout the fence uses: a pump that gives
		// up leaves the callback registered, and it must not write through a frame that
		// is gone by the time a later ProcessEvents delivers it.
		let request = new WorkDoneRequest();

		WGPUQueueWorkDoneCallbackInfo info = .();
		info.mode = WebGpuApi.cCallbackMode;
		info.callback = (status, message, userdata1, userdata2) =>
			{
				let r = (WorkDoneRequest)Internal.UnsafeCastToObject(userdata1);
				if (r.Orphaned)
				{
					delete r;
					return;
				}

				r.Done = true;
			};
		info.userdata1 = Internal.UnsafeCastToPtr(request);

		wgpuQueueOnSubmittedWorkDone(mQueue, info);
		WebGpuApi.PumpUntilDevice(mInstance, mDevice, ref request.Done);

		if (!request.Done)
		{
			request.Orphaned = true; // the callback owns the record now
			return;
		}

		delete request;
	}

	/// Releases a texture only once every submission queued SO FAR has been consumed.
	///
	/// Fire and forget, the record owning itself. The web swapchain releases its
	/// borrowed surface texture through this: on web a submit validates ASYNCHRONOUSLY,
	/// so releasing the borrow on any fixed frame boundary races that validation.
	public void ReleaseTextureWhenConsumed(WGPUTexture texture)
	{
		let pending = new PendingTextureRelease() { Texture = texture };

		WGPUQueueWorkDoneCallbackInfo info = .();
		info.mode = WebGpuApi.cCallbackMode;
		info.callback = (status, message, userdata1, userdata2) =>
			{
				let p = (PendingTextureRelease)Internal.UnsafeCastToObject(userdata1);
				wgpuTextureRelease(p.Texture);
				delete p;
			};
		info.userdata1 = Internal.UnsafeCastToPtr(pending);

		wgpuQueueOnSubmittedWorkDone(mQueue, info);
	}

	public Result<ITransferBatch> CreateTransferBatch()
	{
		let batch = new WebGpuTransferBatch();
		batch.Initialize(mInstance, mDevice, mQueue);
		mBatches.Add(batch);
		return .Ok(batch);
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		if (batch == null)
			return;

		if (let wgpuBatch = batch as WebGpuTransferBatch)
		{
			let index = mBatches.IndexOf(wgpuBatch);
			if (index >= 0)
				mBatches.RemoveAt(index);

			delete wgpuBatch;
		}

		batch = null;
	}

	public float TimestampPeriod()
	{
		return WebGpuApi.NativeOnly.QueueTimestampPeriod(mQueue);
	}

	private WGPUSubmissionIndex SubmitInternal(Span<ICommandBuffer> commandBuffers)
	{
		// Persistent map coherence: every OPEN shadow flushes FIRST, those writes being
		// queue ordered so they land before this submission reads them.
		mBufferRegistry.FlushOutstanding();

		WGPUCommandBuffer[cSubmitBatch] handles = .();
		var count = 0;
		WGPUSubmissionIndex last = default;

		for (let commandBuffer in commandBuffers)
		{
			let wrapper = commandBuffer as WebGpuCommandBuffer;
			if (wrapper == null)
				continue;

			// Take transfers the handle; submission is what consumes it.
			let handle = wrapper.Take();
			if (handle == null)
				continue; // already submitted, or never finished

			if (count == cSubmitBatch)
			{
				last = SubmitAndRelease(&handles[0], count);
				count = 0;
			}

			handles[count] = handle;
			count++;
		}

		// An EMPTY submit still goes through: it is how a caller flushes the queue and
		// gets a submission index to wait on.
		if ((count > 0) || commandBuffers.IsEmpty)
			last = SubmitAndRelease(&handles[0], count);

		return last;
	}

	private WGPUSubmissionIndex SubmitAndRelease(WGPUCommandBuffer* handles, int count)
	{
		// The indexed submit is a wgpu EXTENSION and hands back this submission's index,
		// which is what lets a fence wait on exactly this one. A browser takes the plain
		// submit and gets no index.
		let index = WebGpuApi.NativeOnly.SubmitForIndex(mQueue, (uint)count, handles);

		for (int i = 0; i < count; i++)
			wgpuCommandBufferRelease(handles[i]);

		return index;
	}

	private void NoteAndSignal(IFence fence, uint64 value, WGPUSubmissionIndex index)
	{
		let wgpuFence = fence as WebGpuFence;
		if (wgpuFence == null)
			return;

		wgpuFence.NoteSubmission(value, index);

		// The record OUTLIVES the fence on purpose. Wait's submission index fast path
		// resolves without this callback, so it can still be queued when the fence is
		// destroyed and then fire during device teardown. Attaching lets the fence null
		// itself out of the record; the callback frees it either way.
		let pending = new WebGpuPendingSignal() { Fence = wgpuFence, Value = value };
		wgpuFence.AttachPending(pending);

		WGPUQueueWorkDoneCallbackInfo info = .();
		info.mode = WebGpuApi.cCallbackMode;
		info.callback = (status, message, userdata1, userdata2) =>
			{
				let p = (WebGpuPendingSignal)Internal.UnsafeCastToObject(userdata1);
				if (p.Fence != null) // still alive, and it detaches us on destruction
				{
					p.Fence.DetachPending(p);
					p.Fence.SignalFromCallback(p.Value);
				}

				delete p;
			};
		info.userdata1 = Internal.UnsafeCastToPtr(pending);

		wgpuQueueOnSubmittedWorkDone(mQueue, info);
	}

	/// What a WaitIdle callback fills in, heap allocated for the same reason the fence's
	/// map request is.
	private class WorkDoneRequest
	{
		public bool Done = false;
		public bool Orphaned = false;
	}

	/// A texture waiting for the queue to drain before it is released.
	private class PendingTextureRelease
	{
		public WGPUTexture Texture;
	}
}
