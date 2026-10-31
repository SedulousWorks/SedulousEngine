using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A 2D affine transform, what a sheet's `transform` composes and a view is drawn and hit tested
/// through. Six floats in column-vector affine form:
///
///     | a  c  tx |          x' = a*x + c*y + tx
///     | b  d  ty |          y' = b*x + d*y + ty
///
/// ToMatrix lays them into a Float4x4 in VG's convention (row vectors, translation in row 3), so
/// a view's transform feeds VGContext.SetTransform losslessly.
struct Transform2D
{
	public float A = 1.0f;
	public float B = 0.0f;
	public float C = 0.0f;
	public float D = 1.0f;
	public float Tx = 0.0f;
	public float Ty = 0.0f;

	public this() {}

	public this(float a, float b, float c, float d, float tx, float ty)
	{
		A = a;
		B = b;
		C = c;
		D = d;
		Tx = tx;
		Ty = ty;
	}

	public bool IsIdentity => (A == 1.0f) && (B == 0.0f) && (C == 0.0f) && (D == 1.0f) && (Tx == 0.0f) && (Ty == 0.0f);

	public Float2 Apply(Float2 p) => .(A * p.X + C * p.Y + Tx, B * p.X + D * p.Y + Ty);

	/// `l` then `r` read right to left: Multiply(l, r).Apply(p) == l.Apply(r.Apply(p)).
	public static Transform2D Multiply(Transform2D l, Transform2D r) => .(
		l.A * r.A + l.C * r.B, l.B * r.A + l.D * r.B,
		l.A * r.C + l.C * r.D, l.B * r.C + l.D * r.D,
		l.A * r.Tx + l.C * r.Ty + l.Tx, l.B * r.Tx + l.D * r.Ty + l.Ty);

	/// this = this * r: what `r` does happens first, inside this.
	public void Combine(Transform2D r) mut => this = Multiply(this, r);
	public void Translate(float x, float y) mut => Combine(.(1, 0, 0, 1, x, y));
	public void Scale(float sx, float sy) mut => Combine(.(sx, 0, 0, sy, 0, 0));
	public void Rotate(float radians) mut
	{
		let cs = Math.Cos(radians);
		let sn = Math.Sin(radians);
		Combine(.(cs, sn, -sn, cs, 0.0f, 0.0f));
	}
	/// CSS's skew(ax, ay): x' = x + tan(ax) y, y' = tan(ay) x + y.
	public void Skew(float radiansX, float radiansY) mut => Combine(.(1.0f, Math.Tan(radiansY), Math.Tan(radiansX), 1.0f, 0.0f, 0.0f));

	/// The inverse; identity for a transform that flattens (a scale of 0).
	public Transform2D Inverse()
	{
		let det = A * D - C * B;
		if (Math.Abs(det) < 1e-12f)
			return .();
		let inv = 1.0f / det;
		let ia = D * inv;
		let ic = -C * inv;
		let ib = -B * inv;
		let id = A * inv;
		return .(ia, ib, ic, id, -(ia * Tx + ic * Ty), -(ib * Tx + id * Ty));
	}

	/// The uniform scale it draws at, when it is one: a scale (and a move), no turn or skew.
	public bool UniformScale(out float scale)
	{
		scale = 1.0f;
		if ((B == 0.0f) && (C == 0.0f) && (A == D) && (A > 0.0f))
		{
			scale = A;
			return true;
		}
		return false;
	}

	/// In VG's convention: row vectors, translation in row 3.
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

	[Commutable]
	public static bool operator==(Transform2D l, Transform2D r) =>
		(l.A == r.A) && (l.B == r.B) && (l.C == r.C) && (l.D == r.D) && (l.Tx == r.Tx) && (l.Ty == r.Ty);
}
