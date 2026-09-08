namespace Sedulous.VG;

/// How a path is stroked.
struct StrokeStyle
{
	/// In pixels.
	public float Width = 1.0f;
	public VGLineCap Cap = .Butt;
	public VGLineJoin Join = .Miter;
	/// The ratio of miter length to stroke width past which a miter becomes a bevel. A
	/// shallow enough angle produces an arbitrarily long spike without it.
	public float MiterLimit = 4.0f;
	public float DashOffset = 0.0f;

	public this() {}

	public this(float width)
	{
		Width = width;
	}

	public this(float width, VGLineCap cap, VGLineJoin join, float miterLimit = 4.0f)
	{
		Width = width;
		Cap = cap;
		Join = join;
		MiterLimit = miterLimit;
	}
}
