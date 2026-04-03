namespace Sedulous.RHI;

using System;

/// Convenience methods for GPU data uploads, matching Serenity's
/// queue.WriteMappedBuffer / queue.WriteStagedBufferSync / queue.WriteTextureSync patterns.
///
/// Mapped methods write directly to CpuToGpu buffers via Map/Unmap.
/// Staged methods create a temporary TransferBatch for GpuOnly resources.
static class TransferHelper
{
	// ===== Mapped Buffer Writes (CpuToGpu buffers) =====

	/// Writes data to a CpuToGpu mapped buffer at the given byte offset.
	/// Asserts if the buffer is not mappable (GpuOnly). Use WriteStagedBufferSync for device-local buffers.
	public static void WriteMappedBuffer(IBuffer buffer, uint64 offset, Span<uint8> data)
	{
		if (buffer == null || data.Length == 0) return;
		let ptr = buffer.Map();
		if (ptr != null)
		{
			Internal.MemCpy((uint8*)ptr + offset, data.Ptr, data.Length);
			buffer.Unmap();
		}
		else
		{
			Runtime.FatalError("WriteMappedBuffer called on non-mappable buffer. Use WriteStagedBufferSync for device-local buffers.");
		}
	}

	/// Writes a single struct to a CpuToGpu mapped buffer at the given byte offset.
	/// Asserts if the buffer is not mappable.
	public static void WriteMappedBuffer<T>(IBuffer buffer, uint64 offset, T* data) where T : struct
	{
		if (buffer == null) return;
		let ptr = buffer.Map();
		if (ptr != null)
		{
			Internal.MemCpy((uint8*)ptr + offset, data, sizeof(T));
			buffer.Unmap();
		}
		else
		{
			Runtime.FatalError("WriteMappedBuffer called on non-mappable buffer. Use WriteStagedBufferSync for device-local buffers.");
		}
	}

	// ===== Staged Buffer Writes (GpuOnly buffers via TransferBatch) =====

	/// Synchronous buffer upload via staging. Creates a temp TransferBatch,
	/// writes the data, submits, and waits for completion.
	public static void WriteStagedBufferSync(IQueue queue, IDevice device, IBuffer buffer, uint64 offset, Span<uint8> data)
	{
		if (queue.CreateTransferBatch() case .Ok(let tb))
		{
			tb.WriteBuffer(buffer, offset, data);
			tb.Submit();
			device.WaitIdle();
			var tbRef = tb;
			queue.DestroyTransferBatch(ref tbRef);
		}
	}

	/// Staged buffer upload using an existing TransferBatch (batched, non-blocking until Submit).
	public static void WriteStagedBuffer(ITransferBatch batch, IBuffer buffer, uint64 offset, Span<uint8> data)
	{
		batch.WriteBuffer(buffer, offset, data);
	}

	// ===== Staged Texture Writes =====

	/// Synchronous texture upload via staging. Creates a temp TransferBatch,
	/// writes the data, submits, and waits for completion.
	public static void WriteTextureSync(IQueue queue, IDevice device, ITexture texture, Span<uint8> data,
		TextureDataLayout dataLayout, Extent3D extent, uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		if (queue.CreateTransferBatch() case .Ok(let tb))
		{
			tb.WriteTexture(texture, data, dataLayout, extent, mipLevel, arrayLayer);
			tb.Submit();
			device.WaitIdle();
			var tbRef = tb;
			queue.DestroyTransferBatch(ref tbRef);
		}
	}

	/// Texture upload using an existing TransferBatch (batched, non-blocking until Submit).
	public static void WriteTexture(ITransferBatch batch, ITexture texture, Span<uint8> data,
		TextureDataLayout dataLayout, Extent3D extent, uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		batch.WriteTexture(texture, data, dataLayout, extent, mipLevel, arrayLayer);
	}

	// ===== Mapped Buffer Reads (GpuToCpu buffers) =====

	/// Reads data from a GpuToCpu mapped buffer at the given byte offset.
	/// Asserts if the buffer is not mappable.
	public static void ReadMappedBuffer(IBuffer buffer, uint64 offset, Span<uint8> outData)
	{
		if (buffer == null || outData.Length == 0) return;
		let ptr = buffer.Map();
		if (ptr != null)
		{
			Internal.MemCpy(outData.Ptr, (uint8*)ptr + offset, outData.Length);
			buffer.Unmap();
		}
		else
		{
			Runtime.FatalError("ReadMappedBuffer called on non-mappable buffer. Use a GpuToCpu buffer for readback.");
		}
	}
}
