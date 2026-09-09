namespace Sedulous.UI;

/// View visibility state.
enum Visibility
{
	/// Visible, and takes part in layout.
	Visible,
	/// Invisible, but still occupies its space in layout.
	Hidden,
	/// Invisible, and takes no part in layout at all.
	Gone
}
