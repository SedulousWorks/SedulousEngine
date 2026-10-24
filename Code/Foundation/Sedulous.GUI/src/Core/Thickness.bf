using System;

namespace Sedulous.GUI;

/// Four edge insets (padding, margin, border, layer inset). Adapts eepp, which overloads Rectf's
/// Left/Top/Right/Bottom for this; a dedicated type is clearer.
struct Thickness : IEquatable<Thickness>
{
	public float Left = 0.0f;
	public float Top = 0.0f;
	public float Right = 0.0f;
	public float Bottom = 0.0f;

	public this() { }

	public this(float all)
	{
		Left = all;
		Top = all;
		Right = all;
		Bottom = all;
	}

	public this(float horizontal, float vertical)
	{
		Left = horizontal;
		Top = vertical;
		Right = horizontal;
		Bottom = vertical;
	}

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

	public bool Equals(Thickness other) => this == other;

	[Commutable]
	public static bool operator==(Thickness a, Thickness b) =>
		(a.Left == b.Left) && (a.Top == b.Top) && (a.Right == b.Right) && (a.Bottom == b.Bottom);
}
