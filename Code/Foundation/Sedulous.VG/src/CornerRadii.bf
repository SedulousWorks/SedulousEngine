namespace Sedulous.VG;

/// The four corner radii of a rounded rectangle.
struct CornerRadii
{
	public float TopLeft = 0.0f;
	public float TopRight = 0.0f;
	public float BottomRight = 0.0f;
	public float BottomLeft = 0.0f;

	public this() {}

	/// Every corner the same.
	public this(float uniform)
	{
		TopLeft = uniform;
		TopRight = uniform;
		BottomRight = uniform;
		BottomLeft = uniform;
	}

	/// Clockwise from the top left, which is the order everything else states them in.
	public this(float topLeft, float topRight, float bottomRight, float bottomLeft)
	{
		TopLeft = topLeft;
		TopRight = topRight;
		BottomRight = bottomRight;
		BottomLeft = bottomLeft;
	}

	public bool IsUniform => (TopLeft == TopRight) && (TopRight == BottomRight)
		&& (BottomRight == BottomLeft);

	public bool IsZero => (TopLeft == 0.0f) && (TopRight == 0.0f) && (BottomRight == 0.0f)
		&& (BottomLeft == 0.0f);
}
