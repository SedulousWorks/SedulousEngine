namespace Sedulous.GUI;

/// View visibility state.
public enum Visibility
{
	/// View is visible and participates in layout.
	Visible,
	/// View is invisible but still occupies space in layout.
	Hidden,
	/// View is invisible and does not participate in layout.
	Gone
}
