using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph.Tests;

/// A command encoder that RECORDS the barriers and stubs the rest.
///
/// The barrier solver's whole job is deciding what to emit, so what it emitted is the thing
/// to assert on. A real backend would swallow that decision into a command buffer.
class RecordingEncoder : ICommandEncoder
{
	public List<TextureBarrier> TextureBarriers = new .() ~ delete _;
	public List<BufferBarrier> BufferBarriers = new .() ~ delete _;
	/// How many separate groups were flushed, which is how many pipeline stalls there are.
	public int GroupCount = 0;

	public void Clear()
	{
		TextureBarriers.Clear();
		BufferBarriers.Clear();
		GroupCount = 0;
	}

	public void Barrier(BarrierGroup group)
	{
		GroupCount++;
		for (let barrier in group.TextureBarriers)
			TextureBarriers.Add(barrier);
		for (let barrier in group.BufferBarriers)
			BufferBarriers.Add(barrier);
	}

	// ---- everything else is a stub: none of it is what these tests are about ----

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc) => null;
	public IComputePassEncoder BeginComputePass(StringView label) => null;
	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc) => null;

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size) {}
	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region) {}
	public void Blit(ITexture src, ITexture dst) {}
	public void GenerateMipmaps(ITexture texture) {}
	public void ResolveTexture(ITexture src, ITexture dst) {}

	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count) {}
	public void WriteTimestamp(IQuerySet querySet, uint32 index) {}
	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst,
		uint64 dstOffset) {}

	public void BeginDebugLabel(StringView label, float r, float g, float b, float a) {}
	public void EndDebugLabel() {}
	public void InsertDebugLabel(StringView label, float r, float g, float b, float a) {}

	public ICommandBuffer Finish() => null;
}
