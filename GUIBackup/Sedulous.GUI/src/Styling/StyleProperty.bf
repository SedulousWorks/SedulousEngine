namespace Sedulous.GUI;

/// Generic style properties applicable to any element or pseudo-element.
/// Component-specific visuals (thumb, track, checkmark, etc.) are
/// addressed through pseudo-element selectors, not dedicated properties.
public enum StyleProperty
{
	// === Drawable ===

	/// Visual background (solid color, rounded rect, image, etc.)
	Background,

	// === Color ===

	/// Primary text color (inheritable)
	TextColor,
	/// Placeholder text color (EditText)
	PlaceholderColor,
	/// Border/divider stroke color
	BorderColor,
	/// Text cursor color
	CursorColor,
	/// Text selection highlight color
	SelectionColor,
	/// Accent indicator color (focus ring, active bar)
	AccentColor,

	// === Float ===

	/// Font size (inheritable)
	FontSize,
	/// Corner radius for rounded elements
	CornerRadius,
	/// Border stroke width
	BorderWidth,
	/// Spacing between elements
	Spacing,
	/// View opacity
	Opacity,
	/// Explicit width for pseudo-elements (e.g., thumb size, box size)
	Width,
	/// Explicit height for pseudo-elements
	Height,

	// === Thickness ===

	/// Padding inside the element
	Padding,
	/// Margin around the element
	Margin,

	// === Bool ===

	/// Whether text wraps
	WordWrap,

	/// Number of known properties (for array sizing).
	COUNT
}
