namespace Sedulous.Renderer;

using Sedulous.RHI;

/// Per-pipeline overlay extension point.
///
/// Implementers register with a `Pipeline` via `RegisterOverlay`; the
/// `OverlayPass` then calls `Render` once per frame with the pipeline's
/// render-pass encoder, active `RenderView`, and owning `Pipeline`.
///
/// All overlays for a pipeline draw into one shared render pass with
/// `LoadOp.Load` on the pipeline output (no depth attachment). Implementers
/// configure their own pipeline state for any draws they emit.
///
/// Signature uses only renderer-level types (`IRenderPassEncoder`,
/// `RenderView`, `Pipeline`) so the renderer stays unaware of higher-level
/// rendering tech (VG, fonts, UI). Callers own their implementation's
/// lifetime; the pipeline registry is non-owning.
public interface IPipelineOverlay
{
	/// Draw priority. Lower runs first. Registration is insertion-sorted by
	/// this value; ties preserve registration order.
	int32 Order { get; }

	/// Record draws into the active overlay render pass.
	void Render(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline);
}
