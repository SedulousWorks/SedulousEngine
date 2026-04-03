namespace Sedulous.RHI;

using System;

/// Records GPU commands, then finishes into an immutable ICommandBuffer.
///
/// Usage:
/// ```
/// let encoder = pool.CreateEncoder().Value;
/// encoder.Barrier(barriers);
/// let rp = encoder.BeginRenderPass(rpDesc);
/// rp.SetPipeline(pipeline);
/// rp.Draw(3);
/// rp.End();
/// let cmdBuf = encoder.Finish();
/// queue.Submit(.(&cmdBuf, 1));
/// ```
interface ICommandEncoder
{
	// ===== Render Pass =====

	/// Begins a render pass. Returns an encoder for recording render commands.
	/// Must call End() on the returned encoder before continuing with this encoder.
	IRenderPassEncoder BeginRenderPass(RenderPassDesc desc);

	// ===== Compute Pass =====

	/// Begins a compute pass.
	/// Must call End() on the returned encoder before continuing with this encoder.
	IComputePassEncoder BeginComputePass(StringView label = default);

	// ===== Barriers (outside passes) =====

	/// Inserts pipeline barriers for resource state transitions.
	void Barrier(BarrierGroup barriers);

	/// Convenience: inserts a single texture state transition barrier.
	void TransitionTexture(ITexture texture, ResourceState oldState, ResourceState newState)
	{
		if (oldState == newState) return;
		var tb = Sedulous.RHI.TextureBarrier() { Texture = texture, OldState = oldState, NewState = newState };
		Barrier(.() { TextureBarriers = .(&tb, 1) });
	}

	/// Convenience: inserts a single buffer state transition barrier.
	void TransitionBuffer(IBuffer buffer, ResourceState oldState, ResourceState newState)
	{
		if (oldState == newState) return;
		var bb = Sedulous.RHI.BufferBarrier() { Buffer = buffer, OldState = oldState, NewState = newState };
		Barrier(.() { BufferBarriers = .(&bb, 1) });
	}

	// ===== Copy Operations (outside passes) =====

	/// Copies data between buffers.
	void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset, uint64 size);

	/// Copies data from a buffer to a texture.
	void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region);

	/// Copies data from a texture to a buffer.
	void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region);

	/// Copies data between textures.
	void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region);

	// ===== Blit & Mipmap Generation (outside passes) =====

	/// Blits (scaled copy with linear filtering) from source to destination texture.
	/// Both textures must be in the appropriate transfer states (CopySrc / CopyDst).
	/// Vulkan: uses vkCmdBlitImage. DX12: uses internal fullscreen blit pipeline.
	void Blit(ITexture src, ITexture dst);

	/// Generates mipmaps for a texture by blitting from mip 0 down to the smallest level.
	/// The texture must be in CopySrc+CopyDst state and have been created with CopySrc | CopyDst usage.
	/// Caller is responsible for barriers before and after.
	void GenerateMipmaps(ITexture texture);

	// ===== MSAA Resolve (outside passes) =====

	/// Resolves a multisample texture to a single-sample texture.
	/// Both textures must be in appropriate states (CopySrc / CopyDst).
	void ResolveTexture(ITexture src, ITexture dst);

	// ===== Queries (outside passes) =====

	/// Resets a range of queries. Must be called before writing new results.
	void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count);

	/// Writes a GPU timestamp.
	void WriteTimestamp(IQuerySet querySet, uint32 index);

	/// Copies query results to a buffer for CPU readback.
	void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count,
		IBuffer dst, uint64 dstOffset);

	// ===== Debug Markers =====

	/// Begins a named debug region (visible in GPU debuggers like RenderDoc).
	void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1);

	/// Ends the current debug region.
	void EndDebugLabel();

	/// Inserts a single debug marker point.
	void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1);

	// ===== Finish =====

	/// Finishes recording. Returns an immutable command buffer for submission.
	/// The encoder must not be used after this call.
	ICommandBuffer Finish();
}
