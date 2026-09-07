using System;

namespace Sedulous.RHI;

/// Records GPU work: passes, barriers, copies, queries and debug labels.
///
/// Ray tracing support is asked for by CASTING to IRayTracingEncoderExt, which an encoder
/// implements only if it has it.
interface ICommandEncoder
{
	IRenderPassEncoder BeginRenderPass(RenderPassDesc desc);
	IComputePassEncoder BeginComputePass(StringView label = default);

	/// Begins a bundle on THIS encoder's pool. A convenience for the pool's own call: the
	/// bundle is owned by the pool and lives until its next reset. Null when the backend
	/// has no bundles.
	IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc);

	void Barrier(BarrierGroup group);

	/// One texture between two states. Provided here rather than left to callers because a
	/// single transition is the overwhelmingly common case and building a group by hand for
	/// it is noise.
	void TransitionTexture(ITexture texture, ResourceState oldState, ResourceState newState)
	{
		TextureBarrier barrier = .();
		barrier.Texture = texture;
		barrier.OldState = oldState;
		barrier.NewState = newState;

		BarrierGroup group = .();
		group.TextureBarriers = .(&barrier, 1);
		Barrier(group);
	}

	void TransitionBuffer(IBuffer buffer, ResourceState oldState, ResourceState newState)
	{
		BufferBarrier barrier = .();
		barrier.Buffer = buffer;
		barrier.OldState = oldState;
		barrier.NewState = newState;

		BarrierGroup group = .();
		group.BufferBarriers = .(&barrier, 1);
		Barrier(group);
	}

	void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size);
	void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region);
	void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region);
	void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region);

	/// A SCALED copy, unlike CopyTextureToTexture, so source and destination need not match
	/// in size.
	void Blit(ITexture src, ITexture dst);

	void GenerateMipmaps(ITexture texture);

	/// Resolves a multisampled texture into a single sampled one.
	void ResolveTexture(ITexture src, ITexture dst);

	void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count);
	void WriteTimestamp(IQuerySet querySet, uint32 index);

	/// Copies query results into a buffer, which is how they are read back.
	void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst,
		uint64 dstOffset);

	void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0,
		float a = 1);
	void EndDebugLabel();
	void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0,
		float a = 1);

	/// Ends recording and returns the immutable buffer to submit.
	ICommandBuffer Finish();
}
