using Sedulous.RHI;

namespace Sedulous.Render;

/// A window space overlay source, under the same recording contract as the scene tier's.
interface IScreenOverlay : IOverlay
{
	void Render(IRenderPassEncoder encoder, ScreenOverlayView view);
}
