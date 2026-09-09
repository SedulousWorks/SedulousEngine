namespace Sedulous.Render;

/// The extension seam: a downstream system contributes render data into the frame's snapshot.
///
/// SCENE AGNOSTIC by design. An implementer already holds its own data, since it is typically
/// a scene system that stored its scene, and this interface never mentions one. The subsystem
/// registers providers per scene, which is where the scene is known, and calls the current
/// scene's during extraction.
interface IRenderDataProvider
{
	void ExtractRenderData(ExtractedScene snapshot);
}
