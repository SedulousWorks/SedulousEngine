namespace Sedulous.UI;

/// Where a view sits inside the space its parent gave it. Combine one horizontal and one
/// vertical flag.
enum Gravity : uint32
{
	None = 0,

	Left = 1,
	Right = 2,
	CenterH = 4,
	FillH = 8,

	Top = 16,
	Bottom = 32,
	CenterV = 64,
	FillV = 128,

	Center = CenterH | CenterV,
	Fill = FillH | FillV,
	TopLeft = Top | Left,
	TopRight = Top | Right,
	BottomLeft = Bottom | Left,
	BottomRight = Bottom | Right
}
