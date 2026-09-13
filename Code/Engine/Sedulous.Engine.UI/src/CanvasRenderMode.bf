namespace Sedulous.Engine.UI;

/// Where a canvas is drawn.
enum CanvasRenderMode : uint8
{
	/// In the scene overlay pass, which is the screen tier.
	case ScreenOverlay = 0;
	/// Into an offscreen texture, which is what an in world screen samples.
	case RenderTexture;
}
