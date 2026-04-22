using System;

namespace Sedulous.GUI;

/// Drag data format for dockable panels.
public static class DockPanelDragDataFormat
{
	public const String DockPanel = "application/dock-panel";
}

/// Drag data containing a dockable panel reference.
public class DockPanelDragData : DragData
{
	private DockablePanel mPanel;
	private DockTabGroup mSourceGroup;
	private int mSourceTabIndex;

	/// Creates drag data for a dockable panel.
	public this(DockablePanel panel, DockTabGroup sourceGroup, int sourceTabIndex)
		: base(DockPanelDragDataFormat.DockPanel)
	{
		mPanel = panel;
		mSourceGroup = sourceGroup;
		mSourceTabIndex = sourceTabIndex;
	}

	/// The panel being dragged.
	public DockablePanel Panel => mPanel;

	/// The source tab group (where the panel came from).
	public DockTabGroup SourceGroup => mSourceGroup;

	/// The tab index in the source group.
	public int SourceTabIndex => mSourceTabIndex;
}
