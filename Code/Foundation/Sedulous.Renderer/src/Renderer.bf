namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;

/// Flags passed to Renderer.RenderBatch to convey pass-level hints.
/// The same renderer is invoked by multiple passes (depth prepass, forward opaque,
/// forward transparent, shadow caster, etc.) — these flags let the renderer adjust
/// per-draw behavior without needing pass-specific subclasses.
public enum RenderBatchFlags : uint32
{
	None = 0,

	/// The pass binds material bind groups (forward / color passes).
	/// Depth-only passes leave this off — the shader doesn't read material textures.
	BindMaterial = 1,
}

/// Abstract per-type drawer. Concrete subclasses handle a specific RenderData subtype
/// (MeshRenderer → MeshRenderData, ParticleRenderer → ParticleRenderData, etc.) and
/// issue draw calls for a batch of matching entries.
///
/// Renderers are registered with a Pipeline against the categories they participate in
/// via GetSupportedCategories(). A pass then calls Pipeline.RenderCategory(category),
/// which dispatches to every registered renderer for that category. Each renderer
/// filters the batch by casting entries to its concrete RenderData type and skipping
/// mismatches.
///
/// Pattern mirrors ezEngine's ezRenderer: the pass owns render target + pipeline state
/// setup, the renderer owns iteration + draw call emission.
public abstract class Renderer
{
	/// Categories this renderer participates in. The pipeline registers the renderer
	/// against each of these; passes invoking those categories will call RenderBatch.
	public abstract Span<RenderDataCategory> GetSupportedCategories();

	/// Draws a batch of render data entries.
	///
	/// The batch is the full category list — the renderer is responsible for casting
	/// entries to its concrete type and skipping mismatches. This keeps the pipeline
	/// dispatch zero-copy (no filtered sub-span allocation per call).
	public abstract void RenderBatch(
		IRenderPassEncoder encoder,
		List<RenderData> batch,
		RenderContext renderContext,
		Pipeline pipeline,
		PerFrameResources frame,
		RenderView view,
		RenderBatchFlags flags);
}
