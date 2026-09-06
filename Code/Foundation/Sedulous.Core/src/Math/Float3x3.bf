using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 3x3 row-major matrix under the row-vector convention: rotation and normal matrices.
///
/// Element access is a two-argument indexer where Raptor spells it operator()(row, col).
[CRepr]
struct Float3x3
{
	public float[3][3] m;

	public this() { m = default; }

	/// Row-major, reading left to right and top to bottom.
	public this(
		float m00, float m01, float m02,
		float m10, float m11, float m12,
		float m20, float m21, float m22)
	{
		m = .(.(m00, m01, m02),
			  .(m10, m11, m12),
			  .(m20, m21, m22));
	}

	public float this[int row, int col]
	{
		[Inline] get
		{
			Debug.Assert((row >= 0) && (row < 3) && (col >= 0) && (col < 3));
			return m[row][col];
		}
		[Inline] set mut
		{
			Debug.Assert((row >= 0) && (row < 3) && (col >= 0) && (col < 3));
			m[row][col] = value;
		}
	}

	public static Float3x3 Identity() => .(
		1.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f,
		0.0f, 0.0f, 1.0f);

	/// The upper-left 3x3 of a Float4x4: the rotation and scale part, dropping
	/// translation.
	public static Float3x3 FromMat4(Float4x4 mat) => .(
		mat.m[0][0], mat.m[0][1], mat.m[0][2],
		mat.m[1][0], mat.m[1][1], mat.m[1][2],
		mat.m[2][0], mat.m[2][1], mat.m[2][2]);

	public static Float3x3 operator*(Float3x3 a, Float3x3 b)
	{
		Float3x3 result = .();
		for (int row < 3)
		{
			for (int col < 3)
			{
				var sum = 0.0f;
				for (int k < 3)
					sum += a.m[row][k] * b.m[k][col];
				result.m[row][col] = sum;
			}
		}
		return result;
	}

	/// Row-vector transform: v' = v * M.
	public static Float3 operator*(Float3 v, Float3x3 m) => .(
		v.x * m.m[0][0] + v.y * m.m[1][0] + v.z * m.m[2][0],
		v.x * m.m[0][1] + v.y * m.m[1][1] + v.z * m.m[2][1],
		v.x * m.m[0][2] + v.y * m.m[1][2] + v.z * m.m[2][2]);
}

static
{
	public static Float3x3 Transpose(Float3x3 a)
	{
		Float3x3 result = .();
		for (int row < 3)
			for (int col < 3)
				result.m[row][col] = a.m[col][row];
		return result;
	}

	public static float Determinant(Float3x3 m) =>
		m.m[0][0] * (m.m[1][1] * m.m[2][2] - m.m[1][2] * m.m[2][1]) -
		m.m[0][1] * (m.m[1][0] * m.m[2][2] - m.m[1][2] * m.m[2][0]) +
		m.m[0][2] * (m.m[1][0] * m.m[2][1] - m.m[1][1] * m.m[2][0]);

	/// Adjugate over determinant. Returns Identity when singular.
	public static Float3x3 Inverse(Float3x3 m)
	{
		let det = Determinant(m);
		if (NearlyZero(det))
			return Float3x3.Identity();
		let invDet = 1.0f / det;

		Float3x3 result = .();
		result.m[0][0] = (m.m[1][1] * m.m[2][2] - m.m[1][2] * m.m[2][1]) * invDet;
		result.m[0][1] = (m.m[0][2] * m.m[2][1] - m.m[0][1] * m.m[2][2]) * invDet;
		result.m[0][2] = (m.m[0][1] * m.m[1][2] - m.m[0][2] * m.m[1][1]) * invDet;
		result.m[1][0] = (m.m[1][2] * m.m[2][0] - m.m[1][0] * m.m[2][2]) * invDet;
		result.m[1][1] = (m.m[0][0] * m.m[2][2] - m.m[0][2] * m.m[2][0]) * invDet;
		result.m[1][2] = (m.m[0][2] * m.m[1][0] - m.m[0][0] * m.m[1][2]) * invDet;
		result.m[2][0] = (m.m[1][0] * m.m[2][1] - m.m[1][1] * m.m[2][0]) * invDet;
		result.m[2][1] = (m.m[0][1] * m.m[2][0] - m.m[0][0] * m.m[2][1]) * invDet;
		result.m[2][2] = (m.m[0][0] * m.m[1][1] - m.m[0][1] * m.m[1][0]) * invDet;
		return result;
	}

	public static bool NearlyEqual(Float3x3 a, Float3x3 b, float epsilon = Epsilon)
	{
		for (int row < 3)
			for (int col < 3)
				if (!NearlyEqual(a.m[row][col], b.m[row][col], epsilon))
					return false;
		return true;
	}
}
