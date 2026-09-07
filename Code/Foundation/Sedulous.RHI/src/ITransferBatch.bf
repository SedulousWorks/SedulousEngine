using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// Batches CPU to GPU writes through staging memory.
///
/// Batched because each write would otherwise want its own staging allocation and its own
/// submission; collecting them lets the backend use one staging buffer and one copy.
interface ITransferBatch
{
	void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data);

	void WriteTexture(ITexture dst, Span<uint8> data, TextureDataLayout layout,
		Extent3D extent, uint32 mipLevel = 0, uint32 arrayLayer = 0);

	/// Submits everything staged and WAITS for it.
	Result<void> Submit();

	/// Submits everything staged and signals `fence` with `signalValue` when the GPU is
	/// done, rather than blocking.
	Result<void> SubmitAsync(IFence fence, uint64 signalValue);

	/// Drops what is staged so the batch can be filled again.
	void Reset();

	void Destroy();
}
