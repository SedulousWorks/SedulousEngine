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

	// ---- Filters, drawn through the VG's layers ----
	/// `filter: blur(<sigma>) grayscale(<a>) saturate(<a>) brightness(<a>) | none` (a Filter, or a
	/// plain number as a blur's sigma): the view and its children drawn as one layer, blurred by a
	/// Gaussian of that sigma in dp and their colour filtered at its composite.
	Filter,
	/// `backdrop-filter: blur(<sigma>) | none` (a Filter, or a plain number): what is drawn behind
	/// the view blurred inside its corners, under its own background. Only the blur is drawn.
	BackdropFilter,

	// ---- Text effects, the VG's TextEffects drawn under text ----
	// A Shadow value each. They carry to what the view draws and its children, as CSS's
	// text-shadow does, through the VG's state rather than the cascade; `none` turns one off.
	/// `text-shadow: <x> <y> [blur] [color]`.
	TextShadow,
	/// `text-outline: <width> [color]`: the width rides as the shadow's spread.
	TextOutline,
	/// `text-glow: <radius> [color]`: the radius rides as the shadow's blur.
	TextGlow,

	// ---- Motion ----
	/// `transform: <function> ... | none` (a Transform): translate, scale, rotate and skew, and
	/// their X and Y forms, composed in written order about the transform-origin; drawn and hit
	/// tested over the view's own Transform, while layout keeps its box.
	Transform,
	/// `transform-origin: <x> [<y>]` (a Point): keywords, lengths or percentages of the view; the
	/// centre when unset.
	TransformOrigin,
	/// `animation: <name> <duration> [timing] [delay] [count | infinite] [direction] [fill], ...
	/// | none` (Animations): plays the sheet's @keyframes of that name on the view; while one
	/// runs, the properties it animates take its values over the cascade's.
	Animation,

	/// How many properties there are, for sizing arrays. Not a property.
	COUNT
}
