namespace Sedulous.UI;

/// The tag of a StyleValue, for the code that wants to reason about the KIND without taking
/// the payload apart.
enum StyleValueKind
{
	None,
	Color,
	Float,
	Thickness,
	Drawable,
	Bool,
	String,
	/// A length carrying units: percentages, em, and calc sums. A plain number stays a Float.
	Length,
	Shadow,
	Transitions,
	/// The `inherit` keyword: take the parent's computed value.
	Inherit,
	/// The `initial` keyword: as if never set.
	Initial,
	/// A `var(--name, fallback)` reference.
	Variable
}
