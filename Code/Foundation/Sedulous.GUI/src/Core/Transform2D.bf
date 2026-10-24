using System;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A 2D affine transform, the primitive Transformable composes and hands to the VG backed
/// DrawContext. Stored as 6 floats in column-vector affine form (eepp/SFML style):
///
///     | a  c  tx |          x' = a*x + c*y + tx
///     | b  d  ty |          y' = b*x + d*y + ty
///     | 0  0  1  |
///
/// ToMatrix lays those into a Float4x4 in the exact convention VG's TransformPoint2D reads
/// (row vectors, translation in row 3), so a subtree transform feeds DrawContext losslessly and
/// rotation matches Float4x4's. Derived from eepp's Transform; angles are RADIANS (VG's
/// convention, not eepp's degrees).
struct Transform2D : IEquatable<Transform2D>
{
	// Column-vector affine coefficients (see above).
	public float A = 1.0f;
	public float B = 0.0f;
	public float C = 0.0f;
	public float D = 1.0f;
	public float Tx = 0.0f;
	public float Ty = 0.0f;

	public this() { }

	public this(float a, float b, float c, float d, float tx, float ty)
	{
		A = a;
		B = b;
		C = c;
		D = d;
		Tx = tx;
		Ty = ty;
	}

	public static Transform2D Identity => .();

	public bool IsIdentity => (A == 1.0f) && (B == 0.0f) && (C == 0.0f) && (D == 1.0f) && (Tx == 0.0f) && (Ty == 0.0f);

	// ---- point and rect application ----

	public Float2 TransformPoint(Float2 p) => .(A * p.X + C * p.Y + Tx, B * p.X + D * p.Y + Ty);
	public Float2 TransformPoint(float px, float py) => .(A * px + C * py + Tx, B * px + D * py + Ty);

	/// The axis-aligned bounding box of the four transformed corners.
	public Rect TransformRect(Rect r)
	{
		let p0 = TransformPoint(r.Left, r.Top);
		let p1 = TransformPoint(r.Right, r.Top);
		let p2 = TransformPoint(r.Left, r.Bottom);
		let p3 = TransformPoint(r.Right, r.Bottom);
		let minX = Min4(p0.X, p1.X, p2.X, p3.X);
		let maxX = Max4(p0.X, p1.X, p2.X, p3.X);
		let minY = Min4(p0.Y, p1.Y, p2.Y, p3.Y);
		let maxY = Max4(p0.Y, p1.Y, p2.Y, p3.Y);
		return .(minX, minY, maxX - minX, maxY - minY);
	}

	// ---- composition ----

	/// this = this * rhs (post-multiply, eepp's Transform::combine): applying the result to p
	/// equals this.TransformPoint(rhs.TransformPoint(p)).
	public ref Transform2D Combine(Transform2D r) mut
	{
		this = Multiply(this, r);
		return ref this;
	}

	public ref Transform2D Translate(float x, float y) mut => ref Combine(.(1.0f, 0.0f, 0.0f, 1.0f, x, y));
	public ref Transform2D Translate(Float2 offset) mut => ref Translate(offset.X, offset.Y);

	public ref Transform2D Rotate(float radians) mut
	{
		let cs = Math.Cos(radians);
		let sn = Math.Sin(radians);
		return ref Combine(.(cs, sn, -sn, cs, 0.0f, 0.0f));
	}

	public ref Transform2D Rotate(float radians, float centerX, float centerY) mut
	{
		let cs = Math.Cos(radians);
		let sn = Math.Sin(radians);
		return ref Combine(.(cs, sn, -sn, cs, centerX * (1.0f - cs) + centerY * sn, -centerX * sn + centerY * (1.0f - cs)));
	}

	public ref Transform2D Rotate(float radians, Float2 center) mut => ref Rotate(radians, center.X, center.Y);

	public ref Transform2D Scale(float sx, float sy) mut => ref Combine(.(sx, 0.0f, 0.0f, sy, 0.0f, 0.0f));
	public ref Transform2D Scale(Float2 factors) mut => ref Scale(factors.X, factors.Y);

	public ref Transform2D Scale(float sx, float sy, float centerX, float centerY) mut =>
		ref Combine(.(sx, 0.0f, 0.0f, sy, centerX * (1.0f - sx), centerY * (1.0f - sy)));

	public ref Transform2D Scale(Float2 factors, Float2 center) mut => ref Scale(factors.X, factors.Y, center.X, center.Y);

	// ---- inverse ----

	/// The inverse, or the identity when this has none.
	public Transform2D GetInverse()
	{
		let det = A * D - C * B;
		if (NearlyZero(det))
			return Identity;
		let invDet = 1.0f / det;
		let ia = D * invDet;
		let ic = -C * invDet;
		let ib = -B * invDet;
		let id = A * invDet;
		return .(ia, ib, ic, id, -(ia * Tx + ic * Ty), -(ib * Tx + id * Ty));
	}

	// ---- Float4x4 for the VG DrawContext (row vectors, translation in row 3) ----

	public Float4x4 ToMatrix()
	{
		var m = Float4x4.Identity();
		m.M[0][0] = A;
		m.M[0][1] = B;
		m.M[1][0] = C;
		m.M[1][1] = D;
		m.M[3][0] = Tx;
		m.M[3][1] = Ty;
		return m;
	}

	/// p' = a * (b * p): the result applies b first, then a.
	public static Transform2D Multiply(Transform2D a, Transform2D b) => .(
		a.A * b.A + a.C * b.B, a.B * b.A + a.D * b.B,
		a.A * b.C + a.C * b.D, a.B * b.C + a.D * b.D,
		a.A * b.Tx + a.C * b.Ty + a.Tx, a.B * b.Tx + a.D * b.Ty + a.Ty);

	public static Transform2D operator*(Transform2D a, Transform2D b) => Multiply(a, b);

	public bool Equals(Transform2D other) => this == other;

	[Commutable]
	public static bool operator==(Transform2D l, Transform2D r) =>
		(l.A == r.A) && (l.B == r.B) && (l.C == r.C) && (l.D == r.D) && (l.Tx == r.Tx) && (l.Ty == r.Ty);

	private static float Min4(float w, float x, float y, float z)
	{
		let a = (w < x) ? w : x;
		let b = (y < z) ? y : z;
		return (a < b) ? a : b;
	}

	private static float Max4(float w, float x, float y, float z)
	{
		let a = (w > x) ? w : x;
		let b = (y > z) ? y : z;
		return (a > b) ? a : b;
	}
}

static
{
	/// Each coefficient within `epsilon` of the other's.
	public static bool NearlyEqual(Transform2D x, Transform2D y, float epsilon = Epsilon) =>
		(Math.Abs(x.A - y.A) <= epsilon) && (Math.Abs(x.B - y.B) <= epsilon) && (Math.Abs(x.C - y.C) <= epsilon) &&
		(Math.Abs(x.D - y.D) <= epsilon) && (Math.Abs(x.Tx - y.Tx) <= epsilon) && (Math.Abs(x.Ty - y.Ty) <= epsilon);
}
