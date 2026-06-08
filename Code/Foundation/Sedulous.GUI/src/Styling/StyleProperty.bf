namespace Sedulous.GUI;

/// Identifies a style property that can be set in a StyleRule.
///
/// Visual regions (backgrounds, tracks, thumbs) are Drawable properties -
/// flat themes use ColorDrawable, game themes use NineSlice/Atlas drawables.
///
/// Tints, text, and stroke colors remain Color properties.
public enum StyleProperty
{
	// =================================================================
	// Drawable properties - filled visual regions, themeable with images
	// =================================================================

	/// General background (Button, Panel, EditText, etc.)
	Background,
	/// Checked/toggled background (ToggleButton)
	CheckedBackground,

	/// Slider/ScrollBar/ProgressBar track
	TrackDrawable,
	/// Slider/ScrollBar thumb
	ThumbDrawable,
	/// Slider/ProgressBar fill region
	FillDrawable,
	/// ToggleSwitch knob
	KnobDrawable,
	/// ToggleSwitch track when on
	TrackOnDrawable,
	/// CheckBox/RadioButton box/circle
	BoxDrawable,

	/// TabView strip background
	StripDrawable,
	/// TabView content area background
	ContentDrawable,
	/// TabView active tab background
	ActiveTabDrawable,
	/// TabView hovered tab background
	HoverTabDrawable,

	/// ContextMenu item hover background
	MenuItemHoverDrawable,

	/// Expander header background
	HeaderDrawable,
	/// Expander header hovered background
	HeaderHoverDrawable,

	/// NumericField spin up button background
	SpinUpDrawable,
	/// NumericField spin down button background
	SpinDownDrawable,

	// --- Icon drawables (SVG or image) ---

	/// Checkmark icon (CheckBox)
	CheckmarkIcon,
	/// Radio selection mark icon (RadioButton)
	RadioMarkIcon,
	/// Close button icon (TabView)
	CloseIcon,
	/// Chevron expanded icon (Expander)
	ChevronExpandedIcon,
	/// Chevron collapsed icon (Expander)
	ChevronCollapsedIcon,
	/// Dropdown arrow icon (ComboBox)
	ArrowDownIcon,
	/// Up arrow icon (NumericField)
	ArrowUpIcon,

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
	/// Checkmark/radio dot color
	CheckColor,
	/// Arrow/chevron stroke color
	ArrowColor,
	/// Accent indicator color (tab active bar, focus ring)
	AccentColor,

	/// TabView active tab text color
	ActiveTabTextColor,
	/// TabView inactive tab text color
	InactiveTabTextColor,
	/// TabView hovered tab text color
	HoverTabTextColor,
	/// Close button icon color
	CloseButtonColor,
	/// Close button icon color on hover/active
	CloseButtonHoverColor,

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
	/// Thumb diameter (Slider)
	ThumbSize,
	/// Track height/width (Slider, ProgressBar)
	TrackHeight,
	/// Box size (CheckBox, RadioButton)
	BoxSize,
	/// View opacity
	Opacity,
	/// Header height (Expander, TabView)
	HeaderHeight,
	/// Close button icon size (TabView)
	CloseButtonSize,
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
