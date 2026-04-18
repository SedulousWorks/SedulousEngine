namespace Sedulous.UI.Toolkit;

using Sedulous.UI;

/// Bridge between the docking system (UI layer) and the application (framework layer).
/// Abstracts whether floating windows are real OS windows or virtual (PopupLayer) overlays.
/// Implement in the Application class and assign to DockManager.FloatingWindowHost.
public interface IFloatingWindowHost
{
	/// Whether this host supports creating real OS windows.
	bool SupportsOSWindows { get; }

	/// Create a real OS window to host the given floating window view.
	/// The view becomes the content of a new secondary window with its own RootView.
	/// screenX/screenY: desired global screen position.
	/// onCloseRequested is called when the OS window close button is clicked.
	void CreateFloatingWindow(View floatingWindow, float width, float height,
		float screenX, float screenY,
		delegate void(View) onCloseRequested = null);

	/// Destroy the OS window hosting the given floating window view.
	void DestroyFloatingWindow(View floatingWindow);

	/// Move the OS window hosting the given floating window to a new screen position.
	/// Called during drag to smoothly reposition the window.
	void MoveFloatingWindow(View floatingWindow, float screenX, float screenY);
}
