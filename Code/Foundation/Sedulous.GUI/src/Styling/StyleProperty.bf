namespace Sedulous.GUI;

/// Identifies a style property that can be set in a StyleRule.
///
/// Most visual sub-parts (tracks, thumbs, knobs, etc.) are now styled
/// via pseudo-elements rather than flat properties. The remaining
/// Drawable properties here are for element-level backgrounds and
/// shared icons.
public enum StyleProperty
{
	// =================================================================
	// Drawable properties - filled visual regions, themeable with images
	// =================================================================

	/// General background (Button, Panel, EditText, etc.)
	Background,
	/// Checked/toggled background (ToggleButton)
	CheckedBackground,

	/// ContextMenu item hover background
	MenuItemHoverDrawable,

	// =================================================================
	// Color properties - text, tints, strokes, indicators
	// =================================================================

	/// Primary text color (inheritable)
	TextColor,
	/// Dimmed/secondary text color
	TextDimColor,
	/// Placeholder text color (EditText)
	PlaceholderColor,
	/// Border/divider stroke color
	BorderColor,
	/// Text cursor color
	CursorColor,
	/// Text selection highlight color
	SelectionColor,
	/// Accent indicator color (tab active bar, focus ring)
	AccentColor,

	// =================================================================
	// Float properties - dimensions
	// =================================================================

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

	// =================================================================
	// Thickness properties
	// =================================================================

	/// Padding inside the view
	Padding,
	/// Margin around the view
	Margin,

	// =================================================================
	// Bool properties
	// =================================================================

	/// Whether text wraps
	WordWrap,

	/// Number of known properties (for array sizing).
	COUNT
}
