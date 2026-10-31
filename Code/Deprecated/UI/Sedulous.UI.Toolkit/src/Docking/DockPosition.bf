namespace Sedulous.UI.Toolkit;

/// Where a panel lands relative to whatever it was dropped on.
enum DockPosition
{
	Left,
	Right,
	Top,
	Bottom,
	/// Into the target's own tab group, as another tab.
	Center,
	/// Out of the dock tree entirely, into a window of its own.
	Float
}
