namespace Sedulous.GUI;

/// Describes how a child element is positioned horizontally within a parent element.
public enum HorizontalAlignment
{
	/// Align to the left edge of the parent.
	Left,
	/// Center horizontally within the parent.
	Center,
	/// Align to the right edge of the parent.
	Right,
	/// Stretch to fill the available horizontal space.
	Stretch
}

/// Describes how a child element is positioned vertically within a parent element.
public enum VerticalAlignment
{
	/// Align to the top edge of the parent.
	Top,
	/// Center vertically within the parent.
	Center,
	/// Align to the bottom edge of the parent.
	Bottom,
	/// Stretch to fill the available vertical space.
	Stretch
}
