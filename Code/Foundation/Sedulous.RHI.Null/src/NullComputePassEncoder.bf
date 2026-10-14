using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullComputePassEncoder : IComputePassEncoder
{
	/// The device's counts, BORROWED, set by the command encoder; null counts nothing.
	public DeviceCounterBlock Counters;

	public void SetPipeline(IComputePipeline pipeline) => Counters?.PipelineBinds();
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets) => Counters?.BindGroupBinds();
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}
	public void Dispatch(uint32 x, uint32 y, uint32 z) => Counters?.Dispatches();
	public void DispatchIndirect(IBuffer buffer, uint64 offset) => Counters?.Dispatches();
	public void ComputeBarrier() {}
	public void WriteTimestamp(IQuerySet querySet, uint32 index) {}
	public void End() {}
}
