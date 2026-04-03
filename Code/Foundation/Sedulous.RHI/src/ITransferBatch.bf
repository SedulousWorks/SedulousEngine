namespace Sedulous.RHI;

using System;

/// Batches multiple staging upload operations into a single GPU submission.
/// Created from IQueue.CreateTransferBatch().
///
/// Usage:
/// ```
/// var batch = queue.CreateTransferBatch().Value;
/// batch.WriteBuffer(vertexBuffer, 0, vertexData);
/// batch.WriteTexture(texture, pixelData, layout, extent);
/// batch.Submit();
/// queue.DestroyTransferBatch(ref batch);
/// ```
interface ITransferBatch
{
	/// Records a buffer upload. Data is copied to staging memory immediately.
	void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data);

	/// Records a texture upload. Data is copied to staging memory immediately.
	void WriteTexture(ITexture dst, Span<uint8> data,
		TextureDataLayout dataLayout, Extent3D extent,
		uint32 mipLevel = 0, uint32 arrayLayer = 0);

	/// Submits all recorded transfers synchronously (blocks until GPU completes).
	Result<void> Submit();

	/// Submits all recorded transfers asynchronously.
	/// Signals `fence` to `signalValue` when the GPU transfer completes.
	Result<void> SubmitAsync(IFence fence, uint64 signalValue);

	/// Resets for reuse — clears recorded operations and frees staging memory.
	void Reset();

	/// Destroys the transfer batch and frees all resources.
	void Destroy();
}
