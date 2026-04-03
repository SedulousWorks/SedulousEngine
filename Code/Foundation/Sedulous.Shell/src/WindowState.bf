namespace Sedulous.Shell;

/// Represents the current state of a window.
public enum WindowState
{
	/// Window is in normal state (not minimized, maximized, or fullscreen).
	Normal,
	/// Window is minimized.
	Minimized,
	/// Window is maximized.
	Maximized,
	/// Window is in fullscreen mode.
	Fullscreen
}
