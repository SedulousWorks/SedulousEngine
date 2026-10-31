using System;

namespace Sedulous.UI;

/// Padding, margin and border, with the symmetric constructors those are usually written
/// with.
struct Thickness
{
	public float Left = 0.0f;
	public float Top = 0.0f;
	public float Right = 0.0f;
	public float Bottom = 0.0f;

	/// Zero on every side.
	public this() {}

	/// Every side equal.
	public this(float all)
	{
		Left = all;
		Top = all;
		Right = all;
		Bottom = all;
	}

	/// A horizontal and a vertical pair.
	public this(float horizontal, float vertical)
	{
		Left = horizontal;
		Top = vertical;
		Right = horizontal;
		Bottom = vertical;
	}

	/// Each side stated.
	public this(float left, float top, float right, float bottom)
	{
		Left = left;
		Top = top;
		Right = right;
		Bottom = bottom;
	}

	public float TotalHorizontal => Left + Right;
	public float TotalVertical => Top + Bottom;
	public bool IsZero => (Left == 0.0f) && (Top == 0.0f) && (Right == 0.0f) && (Bottom == 0.0f);

	[Commutable]
	public static bool operator==(Thickness a, Thickness b) =>
		(a.Left == b.Left) && (a.Top == b.Top) && (a.Right == b.Right) && (a.Bottom == b.Bottom);
}
