namespace Sedulous.VG;

/// A box's border width on each side (VGContext.DrawBox).
struct BorderWidths
{
	public float Top = 0.0f;
	public float Right = 0.0f;
	public float Bottom = 0.0f;
	public float Left = 0.0f;

	public this() {}

	/// Every side the same width.
	public this(float uniform)
	{
		Top = uniform;
		Right = uniform;
		Bottom = uniform;
		Left = uniform;
	}

	/// Clockwise from the top, as CSS states them.
	public this(float top, float right, float bottom, float left)
	{
		Top = top;
		Right = right;
		Bottom = bottom;
		Left = left;
	}

	public bool IsZero => (Top == 0.0f) && (Right == 0.0f) && (Bottom == 0.0f) && (Left == 0.0f);

	public static bool operator==(BorderWidths a, BorderWidths b)
		=> (a.Top == b.Top) && (a.Right == b.Right) && (a.Bottom == b.Bottom) && (a.Left == b.Left);

	public static bool operator!=(BorderWidths a, BorderWidths b) => !(a == b);
}
