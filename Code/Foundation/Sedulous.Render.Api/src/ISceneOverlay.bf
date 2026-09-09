using Sedulous.RHI;

namespace Sedulous.Render;

/// A per view overlay source, meaning scene attached UI.
///
/// The pass and the colour target are ALREADY BOUND: an implementer records draws and
/// configures its own pipeline state, and never opens a pass of its own. Every overlay of a
/// view shares one load op pass over the final image.
interface ISceneOverlay : IOverlay
{
	void Render(IRenderPassEncoder encoder, SceneOverlayView view);
}
