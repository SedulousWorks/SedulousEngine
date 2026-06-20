using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// Defines the style for stroking shapes and lines
public class Pen
{
	/// Stroke color
	public Color Color;
	/// Stroke thickness in pixels
	public float Thickness;
	/// Style for line end caps
	public LineCap LineCap;
	/// Style for joining line segments
	public LineJoin LineJoin;
	/// Miter limit for sharp corners (ratio of miter length to thickness)
	public float MiterLimit;

	public this(Color color, float thickness = 1.0f)
	{
		Color = color;
		Thickness = thickness;
		LineCap = .Butt;
		LineJoin = .Miter;
		MiterLimit = 10.0f;
	}

	public this(Color color, float thickness, LineCap cap, LineJoin join)
	{
		Color = color;
		Thickness = thickness;
		LineCap = cap;
		LineJoin = join;
		MiterLimit = 10.0f;
	}

	/// Create a copy of this pen
	public Pen Clone()
	{
		let pen = new Pen(Color, Thickness, LineCap, LineJoin);
		pen.MiterLimit = MiterLimit;
		return pen;
	}

	// Common predefined pens - use fully qualified type to avoid conflict with Color field
	public static Pen Black(float thickness = 1.0f) => new .(Sedulous.Core.Mathematics.Color.Black, thickness);
	public static Pen White(float thickness = 1.0f) => new .(Sedulous.Core.Mathematics.Color.White, thickness);
	public static Pen Red(float thickness = 1.0f) => new .(Sedulous.Core.Mathematics.Color.Red, thickness);
	public static Pen Green(float thickness = 1.0f) => new .(Sedulous.Core.Mathematics.Color.Green, thickness);
	public static Pen Blue(float thickness = 1.0f) => new .(Sedulous.Core.Mathematics.Color.Blue, thickness);
}
