namespace Sedulous.UI;

/// Where the tooltip appears relative to the anchor view.
public enum TooltipPlacement
{
	/// Below the anchor; flips above if clipping bottom.
	Bottom,
	/// Above the anchor; flips below if clipping top.
	Top,
	/// Right of the anchor; flips left if clipping right.
	Right,
	/// Left of the anchor; flips right if clipping left.
	Left
}
