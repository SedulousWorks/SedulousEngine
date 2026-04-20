namespace Sedulous.Particles;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Renderer;

/// Render data for a particle emitter - submitted to the render pipeline.
///
/// Allocated from RenderContext.FrameAllocator - trivially destructible.
/// Points to the emitter's pre-extracted vertex array (valid for this frame).
/// Submitted to RenderCategories.Transparent (back-to-front sorted by emitter position).
public class ParticleBatchRenderData : RenderData
{
	/// Pointer to the extracted ParticleVertex array (owned by emitter, valid this frame).
	public ParticleVertex* Vertices;

	/// Number of valid vertices.
	public int32 VertexCount;

	/// Blend mode for this emitter.
	public ParticleBlendMode BlendMode;

	/// Render mode (billboard type).
	public ParticleRenderMode RenderMode;

	/// Material bind group (texture + sampler at set 2). Emitters sharing this
	/// bind group are batched into a single instanced draw.
	public IBindGroup MaterialBindGroup;

	/// Material batch key (for grouping draws with same state).
	public uint32 MaterialKey;

	/// Trail vertex data (only set when RenderMode == .Trail).
	public TrailVertex* TrailVertices;

	/// Number of valid trail vertices.
	public int32 TrailVertexCount;
}
