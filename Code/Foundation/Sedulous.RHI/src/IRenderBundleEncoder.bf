namespace Sedulous.RHI;

using System;

/// Records draw commands into a render bundle. Shares the same draw-recording
/// surface as IRenderPassEncoder (pipeline, bind groups, vertex/index buffers,
/// draw calls) but NOT the pass-level dynamic state (viewport, scissor, blend
/// constant, stencil ref) or queries. This is exactly the subset valid inside
/// a WebGPU render bundle.
///
/// A Renderer that accepts an IRenderBundleEncoder records identically whether
/// it targets a live pass (inline) or an off-thread bundle, which is what makes
/// parallel command recording fall out: split a draw list into N bundles
/// recorded on N threads, then ExecuteBundles.
interface IRenderBundleEncoder
{
	// ===== Pipeline & Binding =====

	/// Sets the render pipeline for subsequent draw calls.
	void SetPipeline(IRenderPipeline pipeline);

	/// Binds a bind group at the given index.
	void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default);

	/// Sets push constant data.
	void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data);

	// ===== Vertex & Index Buffers =====

	/// Binds a vertex buffer to a slot.
	void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0);

	/// Binds an index buffer.
	void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0);

	// ===== Draw Commands =====

	/// Draws non-indexed primitives.
	void Draw(uint32 vertexCount, uint32 instanceCount = 1,
		uint32 firstVertex = 0, uint32 firstInstance = 0);

	/// Draws indexed primitives.
	void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1,
		uint32 firstIndex = 0, int32 baseVertex = 0, uint32 firstInstance = 0);

	/// Draws non-indexed primitives with parameters read from a buffer.
	void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0);

	/// Draws indexed primitives with parameters read from a buffer.
	void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0);

	// ===== Finish =====

	/// Finish recording and return the immutable bundle (owned by the command pool).
	IRenderBundle Finish();
}
