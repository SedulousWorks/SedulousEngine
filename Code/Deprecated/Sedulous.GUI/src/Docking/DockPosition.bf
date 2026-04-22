namespace Sedulous.GUI;

/// Specifies where a panel can be docked within a DockManager.
public enum DockPosition
{
	/// Dock to the left edge.
	Left,
	/// Dock to the right edge.
	Right,
	/// Dock to the top edge.
	Top,
	/// Dock to the bottom edge.
	Bottom,
	/// Dock as a tab in the center (adds to existing tab group).
	Center,
	/// Float as a separate popup window.
	Float
}
