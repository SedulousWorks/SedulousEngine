using System;

namespace Sedulous.RHI;

/// Records dispatches inside a compute pass.
interface IComputePassEncoder
{
	void SetPipeline(IComputePipeline pipeline);

	void SetBindGroup(uint32 index, IBindGroup group,
		Span<uint32> dynamicOffsets = default);

	void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size,
		void* data);

	/// Dispatches a grid of WORKGROUPS, not of threads: the total thread count is this
	/// times the workgroup size the shader declared.
	void Dispatch(uint32 x, uint32 y = 1, uint32 z = 1);

	void DispatchIndirect(IBuffer buffer, uint64 offset);

	/// Orders one dispatch's writes before the next dispatch's reads, within the pass.
	void ComputeBarrier();

	void WriteTimestamp(IQuerySet querySet, uint32 index);
	void End();
}
