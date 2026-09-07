using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// Accepts writes and drops them. Submitting SUCCEEDS, and the async form signals its fence
/// at once, so a caller that waits on the upload makes progress instead of hanging.
class NullTransferBatch : ITransferBatch
{
	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data) {}

	public void WriteTexture(ITexture dst, Span<uint8> data, TextureDataLayout layout,
		Extent3D extent, uint32 mipLevel, uint32 arrayLayer) {}

	public Result<void> Submit() => .Ok;

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (let nullFence = fence as NullFence)
			nullFence.Signal(signalValue);
		return .Ok;
	}

	public void Reset() {}
	public void Destroy() {}
}
