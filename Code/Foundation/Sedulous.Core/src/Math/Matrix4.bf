using System;
using System.Numerics;

namespace Sedulous.Core;

/// A sixteen byte aligned SIMD 4x4 matrix, four float4 rows.
///
/// SAME CONVENTION as the packed Float4x4: row major storage, row vectors, so v' = v * M and
/// composition reads left to right. Reach for this where many multiplies happen back to back,
/// a transform hierarchy or a skinning palette; store as Float4x4 and convert to compute.
///
/// The CONSTRUCTION helpers stay on Float4x4 deliberately. Perspective, look at and the
/// rotations are built once and multiplied many times, so they belong with the storage type;
/// build there and convert one Matrix4 to do the multiplying.
///
/// NOT a storage type; see [[Vector4]] for why.
[Align(16)]
struct Matrix4
{
	/// NO field initialiser. Beef skips a nested initialiser on a struct typed fixed array,
	/// which would leave this uninitialised rather than identity, silently. Set in the
	/// constructor, where it actually happens.
	public float4[4] Row;

	[Inline]
	public this()
	{
		Row = .(.(1, 0, 0, 0), .(0, 1, 0, 0), .(0, 0, 1, 0), .(0, 0, 0, 1));
	}

	[Inline]
	public this(float4 r0, float4 r1, float4 r2, float4 r3)
	{
		Row = .(r0, r1, r2, r3);
	}

	public this(Float4x4 m)
	{
		Row = .(.(m.M[0][0], m.M[0][1], m.M[0][2], m.M[0][3]),
				.(m.M[1][0], m.M[1][1], m.M[1][2], m.M[1][3]),
				.(m.M[2][0], m.M[2][1], m.M[2][2], m.M[2][3]),
				.(m.M[3][0], m.M[3][1], m.M[3][2], m.M[3][3]));
	}

	public Float4x4 ToFloat4x4()
	{
		Float4x4 result = .();
		for (int i < 4)
		{
			result.M[i][0] = Row[i].x;
			result.M[i][1] = Row[i].y;
			result.M[i][2] = Row[i].z;
			result.M[i][3] = Row[i].w;
		}
		return result;
	}

	[Inline] public static Matrix4 Identity() => .();

	/// Row vector times matrix: v.x*row0 + v.y*row1 + v.z*row2 + v.w*row3.
	///
	/// Each component is SPLAT across four lanes and multiplied into a whole row, so the four
	/// components of the result are computed together and no horizontal add is needed. This is
	/// the shape SIMD is actually for.
	[Inline]
	private static float4 TransformRow(float4 v, float4[4] rows)
	{
		var result = float4.SplatX(v) * rows[0];
		result += float4.SplatY(v) * rows[1];
		result += float4.SplatZ(v) * rows[2];
		result += float4.SplatW(v) * rows[3];
		return result;
	}

	public static Matrix4 operator*(Matrix4 a, Matrix4 b)
	{
		return .(TransformRow(a.Row[0], b.Row), TransformRow(a.Row[1], b.Row),
			TransformRow(a.Row[2], b.Row), TransformRow(a.Row[3], b.Row));
	}

	/// Row vector transform: v' = v * M.
	[Inline]
	public static Vector4 operator*(Vector4 v, Matrix4 m) => .(TransformRow(v.R, m.Row));

}

static
{
	/// A POSITION, so w is implicitly one and the translation row is added outright.
	[Inline]
	public static Vector3 TransformPoint(Vector3 p, Matrix4 m)
	{
		var result = float4.SplatX(p.R) * m.Row[0];
		result += float4.SplatY(p.R) * m.Row[1];
		result += float4.SplatZ(p.R) * m.Row[2];
		result += m.Row[3]; // the implicit w = 1
		return .(result);
	}

	/// Transpose, which DELEGATES to the packed path rather than shuffling here.
	///
	/// Deliberate: transposing is infrequent next to multiplying, and the packed one is the
	/// tested path. A four register shuffle network would be a second implementation of
	/// something nothing calls in a loop.
	[Inline]
	public static Matrix4 Transpose(Matrix4 m) => .(Transpose(m.ToFloat4x4()));

	/// A DIRECTION, so w is implicitly zero and the translation row is skipped.
	[Inline]
	public static Vector3 TransformDirection(Vector3 d, Matrix4 m)
	{
		var result = float4.SplatX(d.R) * m.Row[0];
		result += float4.SplatY(d.R) * m.Row[1];
		result += float4.SplatZ(d.R) * m.Row[2];
		return .(result);
	}
}
