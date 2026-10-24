using System;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A 2D float rectangle stored as (X, Y, Width, Height), matching Rectangle and the VG render
/// surface, so it converts losslessly for DrawContext. Adapts eepp's Rectf (which stores
/// Left/Right/Top/Bottom): the edge accessors reproduce eepp's field reads, while storage stays
/// x/y/w/h for the render path. (X, Y) is the top-left (min) corner.
struct Rect : IEquatable<Rect>
{
	public float X = 0.0f;
	public float Y = 0.0f;
	public float Width = 0.0f;
	public float Height = 0.0f;

	public this() { }

	public this(float x, float y, float width, float height)
	{
		X = x;
		Y = y;
		Width = width;
		Height = height;
	}

	public this(Float2 position, Float2 size)
	{
		X = position.X;
		Y = position.Y;
		Width = size.X;
		Height = size.Y;
	}

	/// Built from edges (eepp Rectf's Left/Top/Right/Bottom layout).
	public static Rect FromLTRB(float left, float top, float right, float bottom) => .(left, top, right - left, bottom - top);
	public static Rect FromMinMax(Float2 min, Float2 max) => .(min.X, min.Y, max.X - min.X, max.Y - min.Y);
	public static Rect FromRectangle(Rectangle r) => .(r.X, r.Y, r.Width, r.Height);

	// Edge accessors (eepp field reads).
	public float Left => X;
	public float Top => Y;
	public float Right => X + Width;
	public float Bottom => Y + Height;

	public Float2 Position => .(X, Y);
	public Float2 Size => .(Width, Height);
	public Float2 Center => .(X + Width * 0.5f, Y + Height * 0.5f);

	public bool IsEmpty => (Width <= 0.0f) || (Height <= 0.0f);

	public bool Contains(Float2 p) => (p.X >= X) && (p.X <= X + Width) && (p.Y >= Y) && (p.Y <= Y + Height);
	public bool Contains(Rect r) => (r.X >= X) && (r.Y >= Y) && (r.Right <= Right) && (r.Bottom <= Bottom);

	public bool Intersects(Rect other) => (X < other.Right) && (Right > other.X) && (Y < other.Bottom) && (Bottom > other.Y);

	public Rectangle ToRectangle() => .(X, Y, Width, Height);

	/// The smallest rect holding both.
	public static Rect Union(Rect a, Rect b)
	{
		let x0 = (a.X < b.X) ? a.X : b.X;
		let y0 = (a.Y < b.Y) ? a.Y : b.Y;
		let x1 = (a.Right > b.Right) ? a.Right : b.Right;
		let y1 = (a.Bottom > b.Bottom) ? a.Bottom : b.Bottom;
		return .(x0, y0, x1 - x0, y1 - y0);
	}

	/// The overlapping rectangle of two rects; empty (zero size) if disjoint.
	public static Rect Intersect(Rect a, Rect b)
	{
		let x0 = (a.X > b.X) ? a.X : b.X;
		let y0 = (a.Y > b.Y) ? a.Y : b.Y;
		let x1 = (a.Right < b.Right) ? a.Right : b.Right;
		let y1 = (a.Bottom < b.Bottom) ? a.Bottom : b.Bottom;
		let w = ((x1 - x0) > 0.0f) ? (x1 - x0) : 0.0f;
		let h = ((y1 - y0) > 0.0f) ? (y1 - y0) : 0.0f;
		return .(x0, y0, w, h);
	}

	/// The smallest rectangle enclosing both.
	public static Rect Merge(Rect a, Rect b)
	{
		let x0 = (a.X < b.X) ? a.X : b.X;
		let y0 = (a.Y < b.Y) ? a.Y : b.Y;
		let x1 = (a.Right > b.Right) ? a.Right : b.Right;
		let y1 = (a.Bottom > b.Bottom) ? a.Bottom : b.Bottom;
		return .(x0, y0, x1 - x0, y1 - y0);
	}

	/// `x` mirrored across `within` when `mirror`: a widget's own part in right to left, as far
	/// from the right edge as it was from the left. Its shape mirrors with its points.
	public static float MirroredX(float x, Rect within, bool mirror) => mirror ? within.X + within.Right - x : x;

	/// `r` mirrored across `within` when `mirror`: a part placed from the left, placed from the
	/// right.
	public static Rect MirroredIn(Rect r, Rect within, bool mirror) =>
		mirror ? .(within.X + within.Right - r.Right, r.Y, r.Width, r.Height) : r;

	public bool Equals(Rect other) => this == other;

	[Commutable]
	public static bool operator==(Rect a, Rect b) => (a.X == b.X) && (a.Y == b.Y) && (a.Width == b.Width) && (a.Height == b.Height);
}
