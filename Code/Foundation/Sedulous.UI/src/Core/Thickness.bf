namespace Sedulous.UI;

/// Thickness for padding, margin, and border — with symmetric constructors.
public struct Thickness
{
	public float Left, Top, Right, Bottom;

	/// Zero thickness.
	public this()
	{
		Left = 0; Top = 0; Right = 0; Bottom = 0;
	}

	/// All sides equal.
	public this(float all)
	{
		Left = all; Top = all; Right = all; Bottom = all;
	}

	/// Horizontal and vertical pairs.
	public this(float horizontal, float vertical)
	{
		Left = horizontal; Top = vertical; Right = horizontal; Bottom = vertical;
	}

	/// Each side explicit.
	public this(float left, float top, float right, float bottom)
	{
		Left = left; Top = top; Right = right; Bottom = bottom;
	}

	public float TotalHorizontal => Left + Right;
	public float TotalVertical => Top + Bottom;
	public bool IsZero => Left == 0 && Top == 0 && Right == 0 && Bottom == 0;
}
