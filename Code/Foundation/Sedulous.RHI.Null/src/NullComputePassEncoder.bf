using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullComputePassEncoder : IComputePassEncoder
{
	public void SetPipeline(IComputePipeline pipeline) {}
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets) {}
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}
	public void Dispatch(uint32 x, uint32 y, uint32 z) {}
	public void DispatchIndirect(IBuffer buffer, uint64 offset) {}
	public void ComputeBarrier() {}
	public void WriteTimestamp(IQuerySet querySet, uint32 index) {}
	public void End() {}
}
