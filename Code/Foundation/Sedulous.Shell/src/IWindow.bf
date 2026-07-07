using System;
using Sedulous.Surface;

namespace Sedulous.Shell;

/// Represents a platform window.
public interface IWindow
{
	/// Gets the unique window identifier.
	uint32 ID { get; }

	/// Gets or sets the window title.
	StringView Title { get; set; }

	/// Gets or sets the window X position.
	int32 X { get; set; }

	/// Gets or sets the window Y position.
	int32 Y { get; set; }

	/// Gets or sets the window width.
	int32 Width { get; set; }

	/// Gets or sets the window height.
	int32 Height { get; set; }

	/// Atomically sets the window position in one call. The per-axis X/Y setters
	/// each read the other axis back to preserve it, but SDL_SetWindowPosition is
	/// asynchronous on X11 - the read-back returns the stale (pre-move) value, so
	/// setting X then Y makes the Y-set re-apply the old X and pin it. Moving both
	/// axes must go through this single call. (Confirmed by tracing the editor's
	/// float-window drag: X stayed pinned while only Y followed the cursor.)
	void SetPosition(int32 x, int32 y);

	/// Atomically sets the window size in one call (same asynchronous-readback
	/// reason as SetPosition when changing width and height together).
	void SetSize(int32 width, int32 height);

	/// Gets the current window state.
	WindowState State { get; }

	/// Gets or sets whether the window is visible.
	bool Visible { get; set; }

	/// Gets whether the window has input focus.
	bool Focused { get; }

	/// Gets the display content scale (DPI scaling factor).
	/// Returns 1.0 for standard DPI (96 DPI on Windows, 72 DPI on macOS).
	/// Returns 1.5 for 150% scaling, 2.0 for 200% scaling (Retina), etc.
	/// Use this to scale UI elements for proper display on high-DPI screens.
	float ContentScale { get; }

	/// Shows the window.
	void Show();

	/// Hides the window.
	void Hide();

	/// Minimizes the window.
	void Minimize();

	/// Maximizes the window.
	void Maximize();

	/// Restores the window from minimized/maximized state.
	void Restore();

	/// Requests the window to close.
	void Close();

	/// Sets or clears fullscreen mode.
	void SetFullscreen(bool fullscreen);

	/// Gets the native surface description for this window: the platform handles
	/// plus the windowing system that produced them (Win32/X11/Wayland/...), ready
	/// to hand to a rendering backend's CreateSurface.
	SurfaceInfo SurfaceInfo { get; }
}
