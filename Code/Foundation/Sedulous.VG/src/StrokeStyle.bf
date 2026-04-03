namespace Sedulous.VG;

/// Style parameters for path stroking
public struct StrokeStyle
{
	/// Stroke width in pixels
	public float Width;
	/// Line cap style
	public VGLineCap Cap;
	/// Line join style
	public VGLineJoin Join;
	/// Miter limit (ratio of miter length to stroke width)
	public float MiterLimit;
	/// Dash pattern offset
	public float DashOffset;

	public this()
	{
		Width = 1.0f;
		Cap = .Butt;
		Join = .Miter;
		MiterLimit = 4.0f;
		DashOffset = 0;
	}

	public this(float width)
	{
		Width = width;
		Cap = .Butt;
		Join = .Miter;
		MiterLimit = 4.0f;
		DashOffset = 0;
	}

	public this(float width, VGLineCap cap, VGLineJoin join, float miterLimit = 4.0f)
	{
		Width = width;
		Cap = cap;
		Join = join;
		MiterLimit = miterLimit;
		DashOffset = 0;
	}
}
