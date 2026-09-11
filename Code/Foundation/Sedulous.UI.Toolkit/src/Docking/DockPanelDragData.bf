using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// What a dock drag carries: which panel is moving, and, when it started from a floating window,
/// enough to let the manager move that window along with the cursor.
class DockPanelDragData : DragData
{
	/// BORROWED: the tree owns the panel.
	public DockablePanel Panel = null;
	/// BORROWED. Set when the drag began in a floating window, so the manager can carry it.
	public DockableWindow SourceWindow = null;
	/// Where in that window the pointer was when the drag began, so the window keeps its
	/// grabbed point under the cursor instead of snapping its corner to it.
	public float DragOffsetX = 0.0f;
	public float DragOffsetY = 0.0f;

	public this(DockablePanel panel) : base("dock/panel")
	{
		Panel = panel;
	}
}
