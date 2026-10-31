using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// What a docked panel needs from whatever is managing it. Implemented by [[DockManager]].
interface IDockHost
{
	/// Pulls a panel out of the tree into a window of its own at a position.
	void FloatPanel(DockablePanel panel, float x, float y);

	void DestroyDockableWindow(DockableWindow window);

	/// NAMED this way, not Context, because a manager is also a view and a view already has a
	/// Context field. Two members cannot share the name.
	UIContext HostContext { get; }
}
