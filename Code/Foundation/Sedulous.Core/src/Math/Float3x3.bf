using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 3x3 row-major matrix under the row-vector convention: rotation and normal matrices.
///
/// Element access is a two-argument indexer where Raptor spells it operator()(row, col).
[CRepr]
[Scriptable(.AllPublic)]
struct Float3x3
{
	public float[3][3] M;

	[Inline]
	public this() { M = default; }

	/// Row-major, reading left to right and top to bottom.
	[Inline]
	public this(
		float m00, float m01, float m02,
		float m10, float m11, float m12,
		float m20, float m21, float m22)
	{
		M = .(.(m00, m01, m02),
			  .(m10, m11, m12),
			  .(m20, m21, m22));
	}

	public float this[int row, int col]
	{
		[Inline] get
		{
			Debug.Assert((row >= 0) && (row < 3) && (col >= 0) && (col < 3));
			return M[row][col];
		}
		[Inline] set mut
		{
			Debug.Assert((row >= 0) && (row < 3) && (col >= 0) && (col < 3));
			M[row][col] = value;
		}
	}

	public static Float3x3 Identity() => .(
		1.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f,
		0.0f, 0.0f, 1.0f);

	/// The upper-left 3x3 of a Float4x4: the rotation and scale part, dropping
	/// translation.
	public static Float3x3 FromMat4(Float4x4 mat) => .(
		mat.M[0][0], mat.M[0][1], mat.M[0][2],
		mat.M[1][0], mat.M[1][1], mat.M[1][2],
		mat.M[2][0], mat.M[2][1], mat.M[2][2]);

	[Inline]
	public static Float3x3 operator*(Float3x3 a, Float3x3 b)
	{
		Float3x3 result = .();
		for (int row < 3)
		{
			for (int col < 3)
			{
				var sum = 0.0f;
				for (int k < 3)
					sum += a.M[row][k] * b.M[k][col];
				result.M[row][col] = sum;
			}
		}
		return result;
	}

	/// Row-vector transform: v' = v * M.
	[Inline]
	public static Float3 operator*(Float3 v, Float3x3 M) => .(
		v.X * M.M[0][0] + v.Y * M.M[1][0] + v.Z * M.M[2][0],
		v.X * M.M[0][1] + v.Y * M.M[1][1] + v.Z * M.M[2][1],
		v.X * M.M[0][2] + v.Y * M.M[1][2] + v.Z * M.M[2][2]);
}

static
{
	[Scriptable]
	public static Float3x3 Transpose(Float3x3 a)
	{
		Float3x3 result = .();
		for (int row < 3)
			for (int col < 3)
				result.M[row][col] = a.M[col][row];
		return result;
	}

	[Scriptable]
	public static float Determinant(Float3x3 m) =>
		m.M[0][0] * (m.M[1][1] * m.M[2][2] - m.M[1][2] * m.M[2][1]) -
		m.M[0][1] * (m.M[1][0] * m.M[2][2] - m.M[1][2] * m.M[2][0]) +
		m.M[0][2] * (m.M[1][0] * m.M[2][1] - m.M[1][1] * m.M[2][0]);

	/// Adjugate over determinant. Returns Identity when singular.
	[Scriptable]
	public static Float3x3 Inverse(Float3x3 m)
	{
		let det = Determinant(m);
		if (NearlyZero(det))
			return Float3x3.Identity();
		let invDet = 1.0f / det;

		Float3x3 result = .();
		result.M[0][0] = (m.M[1][1] * m.M[2][2] - m.M[1][2] * m.M[2][1]) * invDet;
		result.M[0][1] = (m.M[0][2] * m.M[2][1] - m.M[0][1] * m.M[2][2]) * invDet;
		result.M[0][2] = (m.M[0][1] * m.M[1][2] - m.M[0][2] * m.M[1][1]) * invDet;
		result.M[1][0] = (m.M[1][2] * m.M[2][0] - m.M[1][0] * m.M[2][2]) * invDet;
		result.M[1][1] = (m.M[0][0] * m.M[2][2] - m.M[0][2] * m.M[2][0]) * invDet;
		result.M[1][2] = (m.M[0][2] * m.M[1][0] - m.M[0][0] * m.M[1][2]) * invDet;
		result.M[2][0] = (m.M[1][0] * m.M[2][1] - m.M[1][1] * m.M[2][0]) * invDet;
		result.M[2][1] = (m.M[0][1] * m.M[2][0] - m.M[0][0] * m.M[2][1]) * invDet;
		result.M[2][2] = (m.M[0][0] * m.M[1][1] - m.M[0][1] * m.M[1][0]) * invDet;
		return result;
	}

	[Scriptable]
	public static bool NearlyEqual(Float3x3 a, Float3x3 b, float epsilon = Epsilon)
	{
		for (int row < 3)
			for (int col < 3)
				if (!NearlyEqual(a.M[row][col], b.M[row][col], epsilon))
					return false;
		return true;
	}
}
