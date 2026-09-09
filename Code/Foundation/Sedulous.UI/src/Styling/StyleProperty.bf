namespace Sedulous.UI;

/// A style property settable in a rule. COUNT sizes the per property arrays.
///
/// The ORDER matters past the bool group: the parser's range predicates depend on it, so new
/// properties are APPENDED rather than slotted in beside their relatives.
enum StyleProperty
{
	// Drawables.
	Background,
	CheckedBackground,
	MenuItemHoverDrawable,

	// Colours.
	TextColor,
	TextDimColor,
	PlaceholderColor,
	BorderColor,
	CursorColor,
	SelectionColor,
	AccentColor,
	/// Semantic status colours, for toasts and validation.
	SuccessColor,
	WarningColor,
	ErrorColor,

	// Floats.
	FontSize,
	FontFamily,
	CornerRadius,
	BorderWidth,
	Spacing,
	Opacity,
	Width,
	Height,

	// Thicknesses.
	Padding,
	Margin,

	// Bools.
	WordWrap,

	// ---- The box model, appended ----
	/// `box-shadow: x y blur spread color [inset]`.
	BoxShadow,
	// Lengths feeding LayoutStyle.
	MinWidth,
	MinHeight,
	MaxWidth,
	MaxHeight,
	Top,
	Right,
	Bottom,
	Left,
	// Floats feeding LayoutStyle.
	ZIndex,
	FlexGrow,
	FlexShrink,
	// Keywords.
	/// `static` or `absolute`.
	Position,
	/// `visible` or `hidden`; hidden clips children to the border box.
	Overflow,
	/// `start`, `end`, `center`, `stretch` or `baseline`.
	AlignSelf,

	// ---- Transitions ----
	/// `transition: <property|all> <duration> [<easing>] [<delay>], ...`, or `none`.
	Transition,

	// ---- Wrap, gap and ellipsis ----
	/// A length feeding LayoutStyle.FlexBasis.
	FlexBasis,
	/// `clip` or `ellipsis`.
	TextOverflow,

	/// How many properties there are, for sizing arrays. Not a property.
	COUNT
}
