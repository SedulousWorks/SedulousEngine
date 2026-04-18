namespace Sedulous.UI.Toolkit;

/// Interface for a window containing a dockable panel.
public interface IDockableWindow
{
	/// Detach and return the panel. Caller takes ownership.
	DockablePanel DetachPanel();
}
