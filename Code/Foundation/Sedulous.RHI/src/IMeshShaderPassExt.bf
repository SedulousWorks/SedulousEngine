using System;

namespace Sedulous.RHI;

/// The mesh shader half of a render pass encoder.
///
/// Kept off IRenderPassEncoder so a backend without mesh shaders implements nothing extra.
/// A caller finds out by CASTING the encoder to this, which answers null when the backend
/// has no mesh shaders, rather than by making a call that quietly does nothing.
interface IMeshShaderPassExt
{
	void SetMeshPipeline(IMeshPipeline pipeline);

	/// Dispatches a grid of mesh WORKGROUPS. The analogue of a draw, except the shader
	/// produces the primitives.
	void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY = 1,
		uint32 groupCountZ = 1);

	void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset,
		uint32 drawCount = 1, uint32 stride = 0);

	/// Indirect, with the DRAW COUNT itself read from a buffer, so the GPU decides how many
	/// dispatches happen and the CPU never learns the number.
	void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset,
		IBuffer countBuffer, uint64 countOffset, uint32 maxDrawCount, uint32 stride);
}
