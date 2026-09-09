using Sedulous.RHI;

namespace Sedulous.Render;

/// The window space overlay coordinator.
///
/// The pair of this and the scene renderer is the engine's two tier model: scene attached UI
/// renders per view inside the compose, and window chrome renders once per target after the
/// scene has been composed onto it.
interface IScreenRenderer
{
	/// Idempotent and NON OWNING: unregister before destroying.
	void RegisterOverlay(IScreenOverlay overlay);
	void UnregisterOverlay(IScreenOverlay overlay);

	/// Opens ONE load op pass against the target, which must be in the render target state
	/// and is left there, and calls every registered overlay in order with the active
	/// encoder. Does nothing when nothing is registered or the target is null.
	void RenderOverlays(ICommandEncoder encoder, ITextureView target, TextureFormat targetFormat,
		uint32 width, uint32 height, uint32 frameIndex);
}
