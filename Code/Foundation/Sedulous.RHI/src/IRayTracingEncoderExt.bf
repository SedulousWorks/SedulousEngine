using System;

namespace Sedulous.RHI;

/// The ray tracing half of a command encoder, reached by CASTING the encoder to this: it
/// answers null on a backend without ray tracing.
///
/// It carries its own SetBindGroup and SetPushConstants because ray tracing binds against
/// its own pipeline outside any render or compute pass, so the pass encoders' versions do
/// not apply.
interface IRayTracingEncoderExt
{
	/// Builds a bottom level structure. Triangles and boxes may both be given: a structure
	/// can hold several geometries.
	void BuildBottomLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, Span<AccelStructGeometryTriangles> triangles,
		Span<AccelStructGeometryAABBs> aabbs);

	/// Builds a top level structure from a buffer of instances, each naming a bottom level
	/// by device address.
	void BuildTopLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, IBuffer instanceBuffer, uint64 instanceOffset,
		uint32 instanceCount);

	void SetRayTracingPipeline(IRayTracingPipeline pipeline);

	void SetBindGroup(uint32 index, IBindGroup group,
		Span<uint32> dynamicOffsets = default);

	void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size,
		void* data);

	/// Dispatches a grid of rays. Each shader binding table is a buffer region with an
	/// offset and a stride, which is how the driver finds the shader for a given hit.
	void TraceRays(
		IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth = 1);
}
