namespace Sedulous.Shell;

/// How a window takes the screen.
enum WindowFullscreen : uint8
{
	/// A window of its own size.
	case None;
	/// Exclusive fullscreen, the display switched to the closest mode to the window's size.
	case Exclusive;
	/// A borderless window over the whole display at the display's own mode.
	case Desktop;
}
