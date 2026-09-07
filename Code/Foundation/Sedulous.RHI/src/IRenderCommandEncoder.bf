using System;

namespace Sedulous.RHI;

/// The draw recording surface shared by a render PASS and a render BUNDLE.
///
/// A renderer that takes one of these records identically whether it targets a live inline
/// pass or an off thread bundle encoder, which is what makes parallel command recording
/// fall out: split a draw list across threads, record a bundle on each, then execute them
/// all into one pass.
///
/// This is exactly the subset valid inside a WebGPU render bundle. No pass level dynamic
/// state, viewport, scissor, blend constant and stencil reference all being inherited from
/// the pass, and no queries.
interface IRenderCommandEncoder
{
	void SetPipeline(IRenderPipeline pipeline);

	/// Binds a resource group at a group index. The dynamic offsets apply, in order, to the
	/// group's slots that declared HasDynamicOffset.
	void SetBindGroup(uint32 index, IBindGroup group,
		Span<uint32> dynamicOffsets = default);

	void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size,
		void* data);

	void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0);
	void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0);

	void Draw(uint32 vertexCount, uint32 instanceCount = 1,
		uint32 firstVertex = 0, uint32 firstInstance = 0);

	void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1,
		uint32 firstIndex = 0, int32 baseVertex = 0, uint32 firstInstance = 0);

	/// A draw whose parameters are read from a buffer the GPU filled. `stride` of zero means
	/// tightly packed.
	void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0);

	void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0);
}
