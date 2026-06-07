namespace Sedulous.GUI;

/// Controls whether a view is drawn and whether it participates in layout.
public enum Visibility
{
	/// Visible and participates in layout.
	Visible,
	/// Invisible but still occupies space in layout (like CSS visibility: hidden).
	Hidden,
	/// Invisible and removed from layout entirely (like CSS display: none).
	Gone
}
