using System;

namespace Sedulous.RHI;

/// Records draws inside a render pass: the shared surface, plus the pass level dynamic
/// state, queries, bundle execution, and ending the pass.
///
/// Mesh shader support is asked for by CASTING to IMeshShaderPassExt, which an encoder
/// implements only if it has it.
interface IRenderPassEncoder : IRenderCommandEncoder
{
	void SetViewport(float x, float y, float width, float height,
		float minDepth = 0.0f, float maxDepth = 1.0f);

	void SetScissor(int32 x, int32 y, uint32 width, uint32 height);

	/// The colour BlendFactor.Constant reads.
	void SetBlendConstant(float r, float g, float b, float a);

	void SetStencilReference(uint32 reference);

	/// Replays pre recorded bundles into this pass, in order. The pass must have been begun
	/// with RenderPassContents.SecondaryCommandBuffers.
	void ExecuteBundles(Span<IRenderBundle> bundles);

	void WriteTimestamp(IQuerySet querySet, uint32 index);
	void BeginOcclusionQuery(IQuerySet querySet, uint32 index);
	void EndOcclusionQuery(IQuerySet querySet, uint32 index);

	void End();
}
