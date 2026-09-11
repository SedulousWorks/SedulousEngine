using Sedulous.Graphics;

namespace Sedulous.UI.Runtime;

/// One attached window: the render window and the payload sitting on it.
///
/// Both are BORROWED. The render window belongs to the graphics host and the payload to the
/// render window, so a UIHost holding this holds nothing it must free.
struct AttachedWindow
{
	public RenderWindow Window;
	public UIWindowData Data;

	public this(RenderWindow window, UIWindowData data)
	{
		Window = window;
		Data = data;
	}
}
