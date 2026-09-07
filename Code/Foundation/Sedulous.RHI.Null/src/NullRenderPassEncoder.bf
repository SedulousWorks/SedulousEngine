using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// Records nothing, and implements the mesh shader seam so a caller casting to
/// IMeshShaderPassExt succeeds. That is what lets a mesh shader path be exercised
/// headlessly rather than skipped.
class NullRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	public void SetPipeline(IRenderPipeline pipeline) {}
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets) {}
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}
	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset) {}
	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset) {}
	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance) {}
	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance) {}
	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride) {}
	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride) {}

	public void SetViewport(float x, float y, float width, float height, float minDepth,
		float maxDepth) {}
	public void SetScissor(int32 x, int32 y, uint32 width, uint32 height) {}
	public void SetBlendConstant(float r, float g, float b, float a) {}
	public void SetStencilReference(uint32 reference) {}
	public void ExecuteBundles(Span<IRenderBundle> bundles) {}
	public void WriteTimestamp(IQuerySet querySet, uint32 index) {}
	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index) {}
	public void EndOcclusionQuery(IQuerySet querySet, uint32 index) {}
	public void End() {}

	// IMeshShaderPassExt
	public void SetMeshPipeline(IMeshPipeline pipeline) {}
	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ) {}
	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride) {}
	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset, IBuffer countBuffer,
		uint64 countOffset, uint32 maxDrawCount, uint32 stride) {}
}
