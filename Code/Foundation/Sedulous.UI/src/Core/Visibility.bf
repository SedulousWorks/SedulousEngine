namespace Sedulous.UI;

/// Three-state visibility controlling both rendering and layout participation.
public enum Visibility
{
	/// Rendered and participates in layout.
	Visible,
	/// Not rendered but still takes space in layout.
	Invisible,
	/// Not rendered and takes no space in layout (skipped entirely).
	Gone
}
