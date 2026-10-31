namespace Sedulous.UI;

/// What a property change has to invalidate.
enum InvalidationKind
{
	/// Re-measure, re-layout, redraw. The default, because a property that changes size is
	/// the common case and getting it wrong leaves stale geometry on screen.
	Layout,
	/// Redraw only. For properties that cannot affect size: Opacity, TextColor, Cursor.
	Visual
}
