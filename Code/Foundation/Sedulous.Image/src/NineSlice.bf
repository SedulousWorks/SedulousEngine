namespace Sedulous.Image;

/// Border insets, in pixels, for nine slice scaling.
///
/// The corners keep their size, the edges stretch along one axis each, and the centre
/// stretches both ways. That is what lets one small image be a panel of any size without
/// the border thickening as it grows.
struct NineSlice
{
	public float Left;
	public float Top;
	public float Right;
	public float Bottom;

	public this() { Left = 0; Top = 0; Right = 0; Bottom = 0; }

	public this(float left, float top, float right, float bottom)
	{
		Left = left; Top = top; Right = right; Bottom = bottom;
	}

	/// The same border on every side.
	public this(float all) { Left = all; Top = all; Right = all; Bottom = all; }

	/// Horizontal and vertical borders.
	public this(float horizontal, float vertical)
	{
		Left = horizontal; Top = vertical; Right = horizontal; Bottom = vertical;
	}

	public float HorizontalBorder => Left + Right;
	public float VerticalBorder => Top + Bottom;

	/// Whether any border is set at all. A slice of nothing is just a stretched image, and
	/// a caller checks this to skip the nine slice path entirely.
	public bool IsValid => (Left > 0.0f) || (Top > 0.0f) || (Right > 0.0f) || (Bottom > 0.0f);
}
