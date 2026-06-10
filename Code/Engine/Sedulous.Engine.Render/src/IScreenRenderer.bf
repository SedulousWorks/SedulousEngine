namespace Sedulous.Engine.Render;

using Sedulous.RHI;

/// Coordinator role for window-space overlay rendering. Implemented by
/// `RenderSubsystem`. Owns the registry of `IScreenOverlay` sources
/// and drives a single shared render pass per `RenderOverlays` call.
///
/// Companion to `ISceneRenderer` (top-level scene rendering coordinator).
/// The pair forms the engine's two-tier render coordination model:
/// `ISceneRenderer` for 3D scenes + per-pipeline overlays,
/// `IScreenRenderer` for window-space overlays after the scene blit.
public interface IScreenRenderer
{
	/// Register an overlay source. Idempotent - duplicate registrations
	/// are a no-op. Sort order is recomputed on next render.
	void RegisterOverlay(IScreenOverlay overlay);

	/// Remove a previously-registered overlay. No-op if not registered.
	/// Callers must unregister before deletion.
	void UnregisterOverlay(IScreenOverlay overlay);

	/// Open one render pass against `target` with `LoadOp.Load`, walk
	/// every registered overlay in `OverlayOrder` order, and call each
	/// one's `Render` with the active encoder. No-op when no overlays
	/// are registered or `target` / `encoder` is null.
	///
	/// `target` is the window's current backbuffer view (caller owns its
	/// lifetime). `width` / `height` are its pixel dimensions.
	void RenderOverlays(ICommandEncoder encoder, ITextureView target,
		uint32 width, uint32 height, int32 frameIndex);
}
