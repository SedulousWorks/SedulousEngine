namespace Sedulous.GUI;

/// Controls what kind of invalidation a property change triggers.
public enum InvalidationKind
{
	/// Property change triggers re-measure + re-layout + redraw.
	/// This is the default for all properties unless explicitly overridden.
	Layout,
	/// Property change triggers redraw only (no layout recalculation).
	/// Used for visual-only properties like Opacity, TextColor, Cursor.
	Visual
}
