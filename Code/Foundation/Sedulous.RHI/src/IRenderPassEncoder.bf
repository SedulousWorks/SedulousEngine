namespace Sedulous.RHI;

using System;

/// Encodes drawing commands within a render pass.
/// Obtained from ICommandEncoder.BeginRenderPass().
/// Must call End() when finished.
interface IRenderPassEncoder
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

	// ===== Dynamic State =====

	/// Sets the viewport.
	void SetViewport(float x, float y, float w, float h, float minDepth, float maxDepth);

	/// Sets the scissor rectangle.
	void SetScissor(int32 x, int32 y, uint32 w, uint32 h);

	/// Sets the blend constant color.
	void SetBlendConstant(float r, float g, float b, float a);

	/// Sets the stencil reference value.
	void SetStencilReference(uint32 reference);

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

	// ===== Queries =====

	/// Writes a GPU timestamp within the render pass.
	void WriteTimestamp(IQuerySet querySet, uint32 index);

	/// Begins an occlusion query.
	void BeginOcclusionQuery(IQuerySet querySet, uint32 index);

	/// Ends an occlusion query.
	void EndOcclusionQuery(IQuerySet querySet, uint32 index);

	// ===== End =====

	/// Ends the render pass. The encoder must not be used after this call.
	void End();
}
