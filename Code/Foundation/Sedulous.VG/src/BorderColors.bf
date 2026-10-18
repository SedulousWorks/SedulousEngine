using Sedulous.Core;

namespace Sedulous.VG;

/// A box's border colour on each side (VGContext.DrawBox); where two sides meet, the corner splits
/// along the line from the outer corner to the inner one, as CSS draws it.
struct BorderColors
{
	public Color Top = .(0, 0, 0, 0);
	public Color Right = .(0, 0, 0, 0);
	public Color Bottom = .(0, 0, 0, 0);
	public Color Left = .(0, 0, 0, 0);

	public this() {}

	/// Every side the same colour.
	public this(Color uniform)
	{
		Top = uniform;
		Right = uniform;
		Bottom = uniform;
		Left = uniform;
	}

	/// Clockwise from the top, as CSS states them.
	public this(Color top, Color right, Color bottom, Color left)
	{
		Top = top;
		Right = right;
		Bottom = bottom;
		Left = left;
	}

	public bool IsUniform => (Top == Right) && (Top == Bottom) && (Top == Left);
	public bool IsTransparent => (Top.A <= 0.0f) && (Right.A <= 0.0f) && (Bottom.A <= 0.0f) && (Left.A <= 0.0f);

	public static bool operator==(BorderColors a, BorderColors b)
		=> (a.Top == b.Top) && (a.Right == b.Right) && (a.Bottom == b.Bottom) && (a.Left == b.Left);

	public static bool operator!=(BorderColors a, BorderColors b) => !(a == b);
}
