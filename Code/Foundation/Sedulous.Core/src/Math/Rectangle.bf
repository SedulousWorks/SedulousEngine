using System;

namespace Sedulous.Core;

/// A 2D rectangle whose x and y are the min corner.
[CRepr]
struct Rectangle
{
	public float x;
	public float y;
	public float width;
	public float height;

	public this() { x = 0; y = 0; width = 0; height = 0; }
	public this(float x, float y, float width, float height)
	{
		this.x = x; this.y = y; this.width = width; this.height = height;
	}

	public Float2 Min() => .(x, y);
	public Float2 Max() => .(x + width, y + height);
	public Float2 Center() => .(x + width * 0.5f, y + height * 0.5f);

	public bool Contains(Float2 p) =>
		(p.x >= x) && (p.x <= x + width) && (p.y >= y) && (p.y <= y + height);

	public bool Intersects(Rectangle other) =>
		(x <= other.x + other.width) && (x + width >= other.x) &&
		(y <= other.y + other.height) && (y + height >= other.y);

	/// The overlapping rectangle of two rects, empty with zero size when they are
	/// disjoint.
	///
	/// Raptor writes this with ternaries rather than the free Min/Max because its
	/// Min()/Max() member accessors shadow them inside the struct. Beef has the same
	/// shadowing, so the shape is kept.
	public static Rectangle Intersect(Rectangle a, Rectangle b)
	{
		let ax1 = a.x + a.width;
		let bx1 = b.x + b.width;
		let ay1 = a.y + a.height;
		let by1 = b.y + b.height;
		let x0 = a.x > b.x ? a.x : b.x;
		let y0 = a.y > b.y ? a.y : b.y;
		let x1 = ax1 < bx1 ? ax1 : bx1;
		let y1 = ay1 < by1 ? ay1 : by1;
		let w = (x1 - x0) > 0.0f ? (x1 - x0) : 0.0f;
		let h = (y1 - y0) > 0.0f ? (y1 - y0) : 0.0f;
		return .(x0, y0, w, h);
	}
}
