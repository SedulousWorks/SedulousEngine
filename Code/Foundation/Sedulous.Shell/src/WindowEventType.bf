namespace Sedulous.Shell;

enum WindowEventType : uint8
{
	case Resized;
	/// By the user or the system: X, Y the new top left in screen coordinates.
	case Moved;
	case FocusGained;
	case FocusLost;
	case CloseRequested;
	/// The window system wants a frame drawn (SDL's exposed): an app that skips idle frames
	/// draws one anyway. On Wayland a window's new state (focus, size, tiling) takes effect
	/// only when the app commits a frame; left idle, the decorations' resize edges cover the
	/// content and the pointer never reaches it.
	case Exposed;
}
