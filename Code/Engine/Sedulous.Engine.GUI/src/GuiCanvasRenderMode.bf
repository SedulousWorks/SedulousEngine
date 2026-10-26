namespace Sedulous.Engine.GUI;

/// Where a canvas is drawn.
enum GuiCanvasRenderMode : uint8
{
	/// In its scene's GUI, over the view.
	case ScreenOverlay = 0;
	/// Into a texture of its own, which its entity's sprite or decal shows.
	case RenderTexture;
}
