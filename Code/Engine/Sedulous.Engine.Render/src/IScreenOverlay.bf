namespace Sedulous.Engine.Render;

using Sedulous.RHI;

/// Source role for window-space overlay rendering.
///
/// Implementers register with `IScreenRenderer` (`RenderSubsystem`) and
/// get called once per frame from a single shared render pass that the
/// renderer opens against the active window target. Implementers only
/// record draw commands - they do NOT open their own render passes.
///
/// Companion to `Sedulous.Renderer.IPipelineOverlay` (per-pipeline
/// overlay source for scene-attached UI). Use `IScreenOverlay` for
/// window-level chrome (HUD, profiler, screen UI); use
/// `IPipelineOverlay` for content scoped to a specific pipeline's
/// output (scene HUD, billboards).
public interface IScreenOverlay
{
	/// Sort order. Lower draws first (background); higher draws last
	/// (foreground). Editor / debug overlays typically sit above the
	/// engine's own screen UI.
	int32 OverlayOrder { get; }

	/// Record draws into the active screen-overlay render pass.
	/// The pass and color target are bound by `IScreenRenderer.RenderOverlays`
	/// before this is called. `width` / `height` are the target's pixel
	/// dimensions (use for viewport / scissor / projection); `frameIndex`
	/// indexes per-frame GPU resources.
	void Render(IRenderPassEncoder encoder, uint32 width, uint32 height, int32 frameIndex);
}
