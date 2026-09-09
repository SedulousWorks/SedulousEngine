namespace Sedulous.UI;

/// Where a tooltip sits relative to the view it belongs to.
enum TooltipPlacement
{
	/// Below, flipping above when that would clip.
	Bottom,
	/// Above, flipping below when that would clip.
	Top,
	/// To the right, flipping left when that would clip.
	Right,
	/// To the left, flipping right when that would clip.
	Left,
	/// At the pointer, offset slightly down and right and clamped to the screen.
	///
	/// For a large view whose tooltip content varies BY REGION, such as a code editor's
	/// diagnostics: anchoring to the whole view's bounds would land nowhere near the line
	/// being hovered.
	Pointer
}
