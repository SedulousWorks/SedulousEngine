namespace Sedulous.Engine;

using Sedulous.Shell;

/// Interface for subsystems that need to react to window events.
/// Subsystems implementing this are notified by the application when
/// the window is resized or other window events occur.
interface IWindowAware
{
	/// Called when the main window is resized.
	void OnWindowResized(IWindow window, int32 width, int32 height);
}
