namespace Sedulous.GUI;

using System;

/// Alignment flags for positioning a view within its parent's available space.
/// Combine horizontal and vertical flags with bitwise OR.
public enum Gravity
{
	None     = 0,

	// Horizontal
	Left     = 1,
	Right    = 2,
	CenterH  = 4,
	FillH    = 8,

	// Vertical
	Top      = 16,
	Bottom   = 32,
	CenterV  = 64,
	FillV    = 128,

	// Combined
	Center   = CenterH | CenterV,
	Fill     = FillH | FillV,
	TopLeft  = Top | Left,
	TopRight = Top | Right,
	BottomLeft = Bottom | Left,
	BottomRight = Bottom | Right,
}
