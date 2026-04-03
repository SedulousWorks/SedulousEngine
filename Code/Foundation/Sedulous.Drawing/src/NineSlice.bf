namespace Sedulous.Drawing;

/// Defines the border insets for 9-slice image scaling.
/// 9-slice divides an image into 9 regions: corners (fixed size),
/// edges (stretch in one direction), and center (stretch both ways).
public struct NineSlice
{
	/// Left border width in pixels
	public float Left;
	/// Top border height in pixels
	public float Top;
	/// Right border width in pixels
	public float Right;
	/// Bottom border height in pixels
	public float Bottom;

	public this(float left, float top, float right, float bottom)
	{
		Left = left;
		Top = top;
		Right = right;
		Bottom = bottom;
	}

	/// Create with uniform borders on all sides
	public this(float all)
	{
		Left = all;
		Top = all;
		Right = all;
		Bottom = all;
	}

	/// Create with horizontal and vertical borders
	public this(float horizontal, float vertical)
	{
		Left = horizontal;
		Top = vertical;
		Right = horizontal;
		Bottom = vertical;
	}

	/// Total horizontal border (left + right)
	public float HorizontalBorder => Left + Right;

	/// Total vertical border (top + bottom)
	public float VerticalBorder => Top + Bottom;

	/// Check if this is a valid 9-slice (has non-zero borders)
	public bool IsValid => Left > 0 || Top > 0 || Right > 0 || Bottom > 0;
}
