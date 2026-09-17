using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A batch of uploads, replayed as queue writes.
///
/// WebGPU's queue writes ARE staged uploads, the runtime owning the staging ring, so
/// there is nothing here to stage into. What the batch does instead is record COPIES of
/// the payloads and replay them at Submit, which is what preserves the RHI's ordering
/// contract: a write lands at submit time rather than at write time.
sealed class WebGpuTransferBatch : ITransferBatch
{
	private struct BufferWrite
	{
		public WGPUBuffer Destination;
		public uint64 Offset;
		public int DataOffset;
		public int Size;
	}

	private struct TextureWrite
	{
		public WGPUTexture Destination;
		public TextureDataLayout Layout;
		public Extent3D Extent;
		public uint32 MipLevel;
		public uint32 ArrayLayer;
		public int DataOffset;
		public int Size;
	}

	private WGPUInstance mInstance;
	private WGPUDevice mDevice;
	private WGPUQueue mQueue;

	private List<uint8> mPayload = new .() ~ delete _;
	private List<BufferWrite> mBufferWrites = new .() ~ delete _;
	private List<TextureWrite> mTextureWrites = new .() ~ delete _;

	public void Initialize(WGPUInstance instance, WGPUDevice device, WGPUQueue queue)
	{
		mInstance = instance;
		mDevice = device;
		mQueue = queue;
	}

	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		let destination = dst as WebGpuBuffer;
		if (destination == null)
			return;

		BufferWrite write = .();
		write.Destination = destination.Handle;
		write.Offset = dstOffset;
		write.DataOffset = mPayload.Count;
		write.Size = data.Length;
		AppendPayload(data);
		mBufferWrites.Add(write);
	}

	public void WriteTexture(ITexture dst, Span<uint8> data, TextureDataLayout layout,
		Extent3D extent, uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		let destination = dst as WebGpuTexture;
		if (destination == null)
			return;

		TextureWrite write = .();
		write.Destination = destination.Handle;
		write.Layout = layout;
		write.Extent = extent;
		write.MipLevel = mipLevel;
		write.ArrayLayer = arrayLayer;
		write.DataOffset = mPayload.Count;
		write.Size = data.Length;
		AppendPayload(data);
		mTextureWrites.Add(write);
	}

	public Result<void> Submit()
	{
		Replay();

#if !BF_PLATFORM_WASM
		// The Vulkan batch drains the queue before returning, so desktop matches it.
		//
		// On WEB this drain is SKIPPED, and the reason is not performance. A queue write
		// copies its payload at CALL time and the single queue preserves ordering, so every
		// later submit already sees the data and nothing here needs completion. Pumping
		// would yield to the browser MID FRAME, and a lazy first use upload runs inside a
		// frame: the yield returns the animation frame, the browser expires the canvas
		// texture, and that frame's submit is dropped entirely with "Destroyed texture used
		// in a submit". It is the startup killer for one shot bakes and uploads.
		var done = false;

		WGPUQueueWorkDoneCallbackInfo info = .();
		info.mode = WebGpuApi.cCallbackMode;
		info.callback = (status, message, userdata1, userdata2) =>
			{
				*(bool*)userdata1 = true;
			};
		info.userdata1 = &done;

		wgpuQueueOnSubmittedWorkDone(mQueue, info);
		WebGpuApi.PumpUntilDevice(mInstance, mDevice, ref done);
#endif

		Reset();
		return .Ok;
	}

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		Replay();

		if (let wgpuFence = fence as WebGpuFence)
		{
			let pending = new WebGpuPendingSignal()
				{ Fence = wgpuFence, Value = signalValue };
			wgpuFence.AttachPending(pending);

			WGPUQueueWorkDoneCallbackInfo info = .();
			info.mode = WebGpuApi.cCallbackMode;
			info.callback = (status, message, userdata1, userdata2) =>
				{
					let p = (WebGpuPendingSignal)Internal.UnsafeCastToObject(userdata1);
					if (p.Fence != null)
					{
						p.Fence.DetachPending(p);
						p.Fence.SignalFromCallback(p.Value);
					}

					delete p;
				};
			info.userdata1 = Internal.UnsafeCastToPtr(pending);

			wgpuQueueOnSubmittedWorkDone(mQueue, info);
		}

		Reset();
		return .Ok;
	}

	public void Reset()
	{
		mPayload.Clear();
		mBufferWrites.Clear();
		mTextureWrites.Clear();
	}

	/// Drops the recorded work. The QUEUE owns this object in Beef and frees it through
	/// DestroyTransferBatch, so this clears rather than deletes.
	public void Destroy()
	{
		Reset();
	}

	private void AppendPayload(Span<uint8> data)
	{
		let start = mPayload.Count;
		mPayload.Count = start + data.Length;
		Internal.MemCpy(mPayload.Ptr + start, data.Ptr, data.Length);
	}

	private void Replay()
	{
		for (let write in mBufferWrites)
		{
			// A queue write's size must be a multiple of four. Rounding up WITHIN the
			// payload would read past this record into the next one, so a write whose
			// tail is short is copied into an aligned scratch first.
			let aligned = (write.Size + 3) & ~3;
			if (aligned == write.Size)
			{
				wgpuQueueWriteBuffer(mQueue, write.Destination, write.Offset,
					mPayload.Ptr + write.DataOffset, (uint)write.Size);
			}
			else
			{
				let padded = scope List<uint8>();
				padded.Count = aligned;
				Internal.MemCpy(padded.Ptr, mPayload.Ptr + write.DataOffset, write.Size);
				wgpuQueueWriteBuffer(mQueue, write.Destination, write.Offset, padded.Ptr,
					(uint)aligned);
			}
		}

		for (let write in mTextureWrites)
		{
			WGPUTexelCopyTextureInfo destination = .();
			destination.texture = write.Destination;
			destination.mipLevel = write.MipLevel;
			destination.origin.z = write.ArrayLayer;

			WGPUTexelCopyBufferLayout layout = .();
			layout.offset = write.Layout.Offset;
			layout.bytesPerRow = write.Layout.BytesPerRow;
			layout.rowsPerImage = write.Layout.RowsPerImage;

			WGPUExtent3D extent = .() { width = write.Extent.Width,
				height = write.Extent.Height, depthOrArrayLayers = write.Extent.Depth };

			wgpuQueueWriteTexture(mQueue, &destination, mPayload.Ptr + write.DataOffset,
				(uint)write.Size, &layout, &extent);
		}
	}
}
