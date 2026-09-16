using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A buffer, with the Map emulation that makes WebGPU keep the RHI's contract.
///
/// That contract is VULKAN SHAPED: a persistent coherent pointer. A caller may Map
/// once, hold the pointer, write to it every frame, and never Unmap, because Vulkan's
/// Unmap is a no-op. WebGPU forbids mapping a buffer that carries normal usages at all,
/// so each memory location gets there differently.
///
/// CpuToGpu maps to a CPU SHADOW. Unmap flushes it with a queue ordered write and
/// closes the mapping. A mapping left OPEN is what emulates coherence: the queue
/// re-flushes every outstanding shadow before each submit, so writes through a held
/// pointer become visible the way Vulkan's would.
///
/// Each flush SKIPS the upload when the shadow is byte identical to what was last sent.
/// That is not a micro optimisation: on web every queue write marshals a copy across
/// the wasm to JS boundary, and re-sending unchanged persistent buffers every submit
/// was the dominant frame cost. A native compare is nearly free beside it, and the skip
/// is safe because the GPU provably already holds those exact bytes.
///
/// GpuToCpu is a genuine WebGPU mapping, an async map plus a pump. Its usage is forced
/// to MapRead and CopyDst, which is all WebGPU allows alongside MapRead.
///
/// GpuOnly returns null, as it does on every backend.
sealed class WebGpuBuffer : IBuffer
{
	private WGPUInstance mInstance;
	private WGPUDevice mDevice;
	private WGPUQueue mQueue;
	private WGPUBuffer mHandle;
	private BufferDesc mDesc;

	private List<uint8> mShadow = new .() ~ delete _;
	/// The bytes last actually uploaded, which is what the skip compares against.
	private List<uint8> mLastUploaded = new .() ~ delete _;
	private bool mShadowOutstanding = false;
	/// This mapping's writes went through FlushRange, so Unmap has nothing left to send.
	private bool mRangeFlushed = false;
	private bool mReadMapped = false;
	private uint64 mUploadCount = 0;

	public BufferDesc Desc => mDesc;
	public WGPUBuffer Handle => mHandle;

	/// Queue writes require a size that is a multiple of four, so both the shadow and
	/// the buffer itself round up.
	private uint64 AlignedSize => (mDesc.Size + 3) & ~(uint64)3;

	/// How many queue writes this buffer has actually issued. A redundant flush is
	/// skipped and NOT counted, which is what lets a test prove the skip fires.
	public uint64 UploadCount => mUploadCount;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuBufferRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUInstance instance, WGPUDevice device, WGPUQueue queue,
		BufferDesc desc)
	{
		mInstance = instance;
		mDevice = device;
		mQueue = queue;
		mDesc = desc;

		// wgpu does NOT return null for an invalid descriptor. It returns an "invalid"
		// object and raises an uncaptured error, so the cases the validator would reject
		// are rejected here instead: a buffer needs a size and at least one usage.
		// GpuToCpu is exempt, its usage being forced to MapRead and CopyDst below.
		if ((desc.Size == 0)
			|| ((desc.Usage == .None) && (desc.Memory != .GpuToCpu)))
			return .Err;

		WGPUBufferDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.usage = WebGpuConversions.ToWgpuBufferUsage(desc.Usage, desc.Memory);
		wgpu.size = AlignedSize;

		mHandle = wgpuDeviceCreateBuffer(device, &wgpu);
		if (mHandle == null)
			return .Err;

		if ((desc.Memory == .CpuToGpu) || (desc.Memory == .Auto))
			mShadow.Resize((int)AlignedSize);

		return .Ok;
	}

	public void* Map()
	{
		if (!mShadow.IsEmpty)
		{
			// Flushed on Unmap AND before every submit, which is the coherence part.
			mShadowOutstanding = true;
			mRangeFlushed = false; // a fresh mapping: Unmap flushes the whole of it unless ranged
			return mShadow.Ptr;
		}

		if (mDesc.Memory != .GpuToCpu)
			return null; // GpuOnly has no host view

		return MapForRead();
	}

	public void Unmap()
	{
		if (!mShadow.IsEmpty)
		{
			// A mapping that flushed its writes by range has nothing left to send: the whole
			// shadow compare would only re-read every byte to learn that.
			if (!mRangeFlushed)
				UploadShadowIfChanged();

			mShadowOutstanding = false; // a paired caller pays exactly one upload
			mRangeFlushed = false;
			return;
		}

		if (mReadMapped)
		{
			wgpuBufferUnmap(mHandle);
			mReadMapped = false;
		}
	}

	/// The ranged half of the emulation: uploads exactly the window, aligned OUTWARD to four
	/// bytes as a queue write demands, and skips it when the GPU already holds those bytes.
	///
	/// Marks the mapping range flushed, so neither Unmap nor the submit hook walks the whole
	/// shadow again: from here the caller owns every write.
	public void FlushRange(uint64 offset, uint64 size)
	{
		if (mShadow.IsEmpty || (size == 0))
			return;

		let total = (uint64)mShadow.Count;
		let begin = offset & ~(uint64)3;
		if (begin >= total)
			return;

		var end = (offset + size + 3) & ~(uint64)3;
		end = Math.Min(end, total);

		let first = (int)begin;
		let count = (int)(end - begin);

		if (mLastUploaded.Count != mShadow.Count)
		{
			// The first upload through this buffer. The GPU side is zero initialised and so is
			// an untouched shadow, so a zeroed ledger is an honest picture of it.
			mLastUploaded.Resize(mShadow.Count);
		}

		mRangeFlushed = true;
		mShadowOutstanding = false;

		if (RawMemory.Equal(mLastUploaded.Ptr + first, mShadow.Ptr + first, count))
			return;

		wgpuQueueWriteBuffer(mQueue, mHandle, begin, mShadow.Ptr + first, (uint)count);
		Internal.MemCpy(mLastUploaded.Ptr + first, mShadow.Ptr + first, count);
		mUploadCount++;
	}

	/// The queue's hook: re-upload the shadow while a mapping is left open, which is the
	/// persistent coherent emulation.
	public void FlushShadowIfOutstanding()
	{
		if (mShadowOutstanding)
			UploadShadowIfChanged();
	}

	/// What a MapAsync callback fills in.
	///
	/// Heap allocated and ORPHANED on timeout rather than kept on the stack: a pump that
	/// gives up leaves the callback registered, and a later ProcessEvents will still
	/// deliver it. A stack record would be a dead frame by then.
	private class MapRequest
	{
		public bool Done = false;
		public bool Mapped = false;
		/// The waiter gave up, so the callback owns deleting this.
		public bool Orphaned = false;
	}

	private void* MapForRead()
	{
		let request = new MapRequest();

		WGPUBufferMapCallbackInfo callback = .();
		callback.mode = WebGpuApi.cCallbackMode;
		callback.callback = (status, message, userdata1, userdata2) =>
			{
				let r = (MapRequest)Internal.UnsafeCastToObject(userdata1);
				if (r.Orphaned)
				{
					delete r;
					return;
				}

				r.Mapped = status == .WGPUMapAsyncStatus_Success;
				r.Done = true;
			};
		callback.userdata1 = Internal.UnsafeCastToPtr(request);

		wgpuBufferMapAsync(mHandle, WGPUMapMode_Read, 0, (uint)AlignedSize, callback);
		WebGpuApi.PumpUntilDevice(mInstance, mDevice, ref request.Done);

		if (!request.Done)
		{
			// STILL PENDING, and a pending map keeps the buffer in the mapped state, so
			// every later submission touching it fails. Loud, because the caller only
			// ever sees a null back.
			GlobalLog(.Error, "[webgpu] Buffer.Map timed out with the map request PENDING");
			request.Orphaned = true; // the callback owns the record now
			return null;
		}

		let mapped = request.Mapped;
		delete request;

		if (!mapped)
		{
			GlobalLog(.Error, "[webgpu] Buffer.Map failed (MapAsync error)");
			return null;
		}

		mReadMapped = true;
		// Readback is a read ONLY view. The RHI hands out a plain pointer, so reading
		// through it is fine and writing through it would be lost, as documented.
		return (void*)wgpuBufferGetConstMappedRange(mHandle, 0, (uint)AlignedSize);
	}

	/// Sends the shadow unless the GPU already holds exactly these bytes. See the type's
	/// own notes for why the compare earns its keep.
	private void UploadShadowIfChanged()
	{
		// RawMemory, not Internal.MemCmp: the latter compares a byte at a time, and these
		// shadows are megabytes. See RawMemory for the measurement.
		if ((mLastUploaded.Count == mShadow.Count)
			&& RawMemory.Equal(mLastUploaded.Ptr, mShadow.Ptr, mShadow.Count))
			return;

		wgpuQueueWriteBuffer(mQueue, mHandle, 0, mShadow.Ptr, (uint)mShadow.Count);

		// Resize and MemCpy, the way Raptor does it, NOT Clear plus AddRange. Handing
		// AddRange another List binds the IEnumerator overload, which copies one bounds
		// checked byte at a time: measured at 0.06 GB/s against 13.7 GB/s for this, and it
		// cost more than every other part of the frame put together.
		mLastUploaded.Resize(mShadow.Count);
		Internal.MemCpy(mLastUploaded.Ptr, mShadow.Ptr, mShadow.Count);
		mUploadCount++;
	}
}
