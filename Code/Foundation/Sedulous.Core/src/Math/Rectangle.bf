using System;

namespace Sedulous.Core;

/// A 2D rectangle whose X and Y are the min corner.
[CRepr]
struct Rectangle
{
	public float X;
	public float Y;
	public float Width;
	public float Height;

	[Inline]
	public this() { X = 0; Y = 0; Width = 0; Height = 0; }
	[Inline]
	public this(float x, float y, float width, float height)
	{
		this.X = x; this.Y = y; this.Width = width; this.Height = height;
	}

	public Float2 Min() => .(X, Y);
	public Float2 Max() => .(X + Width, Y + Height);
	public Float2 Center() => .(X + Width * 0.5f, Y + Height * 0.5f);

	public bool Contains(Float2 p) =>
		(p.X >= X) && (p.X <= X + Width) && (p.Y >= Y) && (p.Y <= Y + Height);

	public bool Intersects(Rectangle other) =>
		(X <= other.X + other.Width) && (X + Width >= other.X) &&
		(Y <= other.Y + other.Height) && (Y + Height >= other.Y);

	/// The overlapping rectangle of two rects, empty with zero size when they are
	/// disjoint.
	///
	/// Raptor writes this with ternaries rather than the free Min/Max because its
	/// Min()/Max() member accessors shadow them inside the struct. Beef has the same
	/// shadowing, so the shape is kept.
	public static Rectangle Intersect(Rectangle a, Rectangle b)
	{
		let ax1 = a.X + a.Width;
		let bx1 = b.X + b.Width;
		let ay1 = a.Y + a.Height;
		let by1 = b.Y + b.Height;
		let x0 = a.X > b.X ? a.X : b.X;
		let y0 = a.Y > b.Y ? a.Y : b.Y;
		let x1 = ax1 < bx1 ? ax1 : bx1;
		let y1 = ay1 < by1 ? ay1 : by1;
		let w = (x1 - x0) > 0.0f ? (x1 - x0) : 0.0f;
		let h = (y1 - y0) > 0.0f ? (y1 - y0) : 0.0f;
		return .(x0, y0, w, h);
	}
}
