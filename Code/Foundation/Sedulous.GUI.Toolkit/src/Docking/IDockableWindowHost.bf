namespace Sedulous.GUI.Toolkit;

using Sedulous.GUI;

/// Bridge between the docking system (UI layer) and the application (framework layer).
/// Abstracts whether dockable windows are real OS windows or virtual (PopupLayer) overlays.
/// Implement in the Application class and assign to DockManager.DockableWindowHost.
public interface IDockableWindowHost
{
	/// Whether this host supports creating real OS windows.
	bool SupportsOSWindows { get; }

	/// Create a real OS window to host the given dockable window view.
	/// The view becomes the content of a new secondary window with its own RootView.
	/// screenX/screenY: desired global screen position.
	/// onCloseRequested is called when the OS window close button is clicked.
	void CreateDockableWindow(View dockableWindow, float width, float height,
		float screenX, float screenY,
		delegate void(View) onCloseRequested = null);

	/// Destroy the OS window hosting the given dockable window view.
	void DestroyDockableWindow(View dockableWindow);

	/// Move the OS window hosting the given dockable window to a new screen position.
	/// Called during drag to smoothly reposition the window.
	void MoveDockableWindow(View dockableWindow, float screenX, float screenY);
}
