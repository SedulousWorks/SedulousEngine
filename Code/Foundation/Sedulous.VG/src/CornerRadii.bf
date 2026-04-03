namespace Sedulous.VG;

/// Per-corner radii for rounded rectangles
public struct CornerRadii
{
	public float TopLeft;
	public float TopRight;
	public float BottomRight;
	public float BottomLeft;

	/// All corners with the same radius
	public this(float uniform)
	{
		TopLeft = uniform;
		TopRight = uniform;
		BottomRight = uniform;
		BottomLeft = uniform;
	}

	/// Each corner with a different radius
	public this(float topLeft, float topRight, float bottomRight, float bottomLeft)
	{
		TopLeft = topLeft;
		TopRight = topRight;
		BottomRight = bottomRight;
		BottomLeft = bottomLeft;
	}

	/// Whether all corners have the same radius
	public bool IsUniform => TopLeft == TopRight && TopRight == BottomRight && BottomRight == BottomLeft;

	/// Whether all corners have zero radius
	public bool IsZero => TopLeft == 0 && TopRight == 0 && BottomRight == 0 && BottomLeft == 0;
}
