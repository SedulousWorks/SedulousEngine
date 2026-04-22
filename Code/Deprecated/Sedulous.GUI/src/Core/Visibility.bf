namespace Sedulous.GUI;

/// Specifies the display state of an element.
public enum Visibility
{
	/// The element is visible and participates in layout.
	Visible,
	/// The element is not visible but still occupies space in layout.
	Hidden,
	/// The element is not visible and does not occupy space in layout.
	Collapsed
}
