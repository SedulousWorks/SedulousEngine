namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;

/// Minimal interface implemented by both Pipeline and ShadowPipeline.
/// Renderer.RenderBatch takes this so per-type drawers can be invoked from
/// either pipeline without knowing the concrete type.
///
/// Note: NOT named IRenderPipeline because that conflicts with
/// Sedulous.RHI.IRenderPipeline (the GPU pipeline state interface).
public interface IRenderingPipeline
{
	/// The shared rendering infrastructure.
	RenderContext RenderContext { get; }

	/// Per-frame resources for the given frame in flight.
	PerFrameResources GetFrameResources(int32 frameIndex);

	/// Appends per-draw object uniforms (world + prev world) to the per-frame
	/// ring buffer and returns the dynamic offset for the draw call bind group.
	/// Returns uint32.MaxValue if the buffer is full.
	uint32 WriteObjectUniforms(int32 frameIndex, Matrix worldMatrix, Matrix prevWorldMatrix);

	/// Binds the frame-level bind group (set 0) with the current scene offset.
	/// Must be called after setting a new pipeline (layout change invalidates bindings).
	void BindFrameGroup(IRenderPassEncoder encoder, PerFrameResources frame);

	/// Output texture format (HDR scene color for main pipeline, Undefined for shadow).
	TextureFormat OutputFormat { get; }
}

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
	/// Called once when this renderer is registered on a RenderContext. Subclasses
	/// override this to create shared GPU resources (material templates, bind
	/// group layouts, per-frame buffers) that depend on the context. Default
	/// implementation is a no-op.
	public virtual void OnRegistered(RenderContext context) { }

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
		IRenderingPipeline pipeline,
		PerFrameResources frame,
		RenderView view,
		RenderBatchFlags flags,
		PipelineConfig passConfig);
}
