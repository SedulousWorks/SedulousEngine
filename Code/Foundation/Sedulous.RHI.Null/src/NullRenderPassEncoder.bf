using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// Records nothing, and implements the mesh shader seam so a caller casting to
/// IMeshShaderPassExt succeeds. That is what lets a mesh shader path be exercised
/// headlessly rather than skipped.
class NullRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	/// The device's counts, BORROWED, set by the command encoder; null counts nothing.
	public DeviceCounterBlock Counters;

	public void SetPipeline(IRenderPipeline pipeline) => Counters?.PipelineBinds();
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets) => Counters?.BindGroupBinds();
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}
	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset) {}
	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset) {}
	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance) => Counters?.Draws();
	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance) => Counters?.Draws();
	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride) => Counters?.Draws(drawCount);
	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride) => Counters?.Draws(drawCount);

	public void SetViewport(float x, float y, float width, float height, float minDepth,
		float maxDepth) {}
	public void SetScissor(int32 x, int32 y, uint32 width, uint32 height) {}
	public void SetBlendConstant(float r, float g, float b, float a) {}
	public void SetStencilReference(uint32 reference) {}
	/// A bundle's recorded work counts each time it runs.
	public void ExecuteBundles(Span<IRenderBundle> bundles)
	{
		if (Counters == null)
			return;
		for (let bundle in bundles)
		{
			if (let recorded = bundle as NullRenderBundle)
				recorded.Counts.AddTo(Counters);
		}
	}
	public void WriteTimestamp(IQuerySet querySet, uint32 index) {}
	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index) {}
	public void EndOcclusionQuery(IQuerySet querySet, uint32 index) {}
	public void End() {}

	// IMeshShaderPassExt
	public void SetMeshPipeline(IMeshPipeline pipeline) => Counters?.PipelineBinds();
	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ) => Counters?.Draws();
	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride) => Counters?.Draws(drawCount);
	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset, IBuffer countBuffer,
		uint64 countOffset, uint32 maxDrawCount, uint32 stride) => Counters?.Draws(maxDrawCount); // the count is on the GPU: at most this many
}
