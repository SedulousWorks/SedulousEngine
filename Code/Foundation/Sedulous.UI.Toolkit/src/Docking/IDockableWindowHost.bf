namespace Sedulous.UI.Toolkit;

using Sedulous.UI;

/// Bridge between the docking system (UI layer) and the application (framework layer).
/// Abstracts whether dockable windows are real OS windows or virtual (PopupLayer) overlays.
/// Implement in the Application class and assign to DockManager.DockableWindowHost.
///
/// Coordinate frame: all positions exposed by this interface are in **logical
/// pixels, relative to the main editor window's client-area top-left**.
/// Sizes are in logical pixels. The host translates to OS coordinates
/// internally. (Note that on SDL3, `Window.X/Y/Width/Height` are already
/// in logical units, so the translation is just adding the main window's
/// `X/Y`.)
public interface IDockableWindowHost
{
	/// Whether this host supports creating real OS windows.
	bool SupportsOSWindows { get; }

	/// Create a real OS window to host the given dockable window view.
	/// The view becomes the content of a new secondary window with its own RootView.
	/// `x`/`y` are logical px relative to the main editor window's top-left.
	/// `onCloseRequested` is called when the OS window close button is clicked.
	void CreateDockableWindow(View dockableWindow, float width, float height,
		float x, float y,
		delegate void(View) onCloseRequested = null);

	/// Destroy the OS window hosting the given dockable window view.
	void DestroyDockableWindow(View dockableWindow);

	/// Move the OS window hosting the given dockable window. Position is
	/// logical px relative to the main editor window's top-left. Called
	/// during drag to smoothly reposition the window.
	void MoveDockableWindow(View dockableWindow, float x, float y);

	/// Resize and reposition the OS window hosting the given dockable window.
	/// `x`/`y` are the new logical-px top-left, relative to the main window.
	/// Called during edge/corner resize drag.
	void ResizeDockableWindow(View dockableWindow, float x, float y, float width, float height);

	/// Read the OS window's current logical-px position (main-window-relative)
	/// AND size in the same screen-coord frame the resize/move calls
	/// expect. Returns false when the view isn't OS-hosted.
	///
	/// Size matters because `View.Width`/`View.Height` reflect the inner
	/// LAYOUT extent, which `RootView` divides by `DpiScale` from the OS
	/// window size. Writing those layout values back into `Window.Width`
	/// would shrink the OS window. Anchor resize state from these
	/// host-frame values instead.
	bool TryGetDockableWindowBounds(View dockableWindow, out float x, out float y, out float width, out float height);

	/// Current desktop-global mouse position in logical px. Resize / drag
	/// deltas computed from per-window-local coordinates are unreliable
	/// when the window itself follows the cursor or resizes mid-event;
	/// global deltas stay valid regardless. Same frame as
	/// `IMouse.GlobalX/GlobalY` in Sedulous.Platform.
	void GetGlobalMousePosition(out float globalX, out float globalY);
}
