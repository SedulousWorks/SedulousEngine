using Sedulous.RHI;

namespace Sedulous.Render;

/// A window space overlay source, under the same recording contract as the scene tier's, plus a
/// step before the shared pass opens.
interface IScreenOverlay : IOverlay
{
	/// Work recorded on the host's encoder before the shared pass begins, since passes do not
	/// nest: offscreen layers Render then composites, say. `view` is the one Render receives.
	/// Most sources need none.
	void PrepareOverlay(ICommandEncoder encoder, ScreenOverlayView view) {}

	void Render(IRenderPassEncoder encoder, ScreenOverlayView view);
}
