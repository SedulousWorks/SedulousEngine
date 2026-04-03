namespace Sedulous.RHI;

using System;

/// Encodes compute dispatch commands within a compute pass.
/// Obtained from ICommandEncoder.BeginComputePass().
/// Must call End() when finished.
interface IComputePassEncoder
{
	/// Sets the compute pipeline.
	void SetPipeline(IComputePipeline pipeline);

	/// Binds a bind group at the given index.
	void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default);

	/// Sets push constant data.
	void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data);

	/// Dispatches compute work groups.
	void Dispatch(uint32 x, uint32 y = 1, uint32 z = 1);

	/// Dispatches compute work groups with parameters read from a buffer.
	void DispatchIndirect(IBuffer buffer, uint64 offset);

	/// Inserts a full compute-to-compute memory barrier.
	/// Ensures all prior compute writes are visible to subsequent dispatches.
	void ComputeBarrier();

	/// Writes a GPU timestamp within the compute pass.
	void WriteTimestamp(IQuerySet querySet, uint32 index);

	/// Ends the compute pass. The encoder must not be used after this call.
	void End();
}
