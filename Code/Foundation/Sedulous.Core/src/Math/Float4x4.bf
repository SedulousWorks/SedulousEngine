using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 4x4 row-major matrix: transforms, projections, multiply, Transpose/Determinant/
/// Inverse, point and direction transforms.
///
/// Conventions: row-major storage M[row][col]; row vectors, so v' = v * M;
/// composition reads left to right; XNA style right-handed projections with NDC depth
/// in [0, 1]; translation in the last row.
///
/// Element access is a two-argument indexer, M[row, col]. Large matrices are taken by `in`.
[CRepr]
[Scriptable(.AllPublic)]
struct Float4x4
{
	/// Hidden from a script: a fixed array does not cross.
	[Hidden]
	public float[4][4] M;

	[Inline]
	[Scriptable]
	public this() { M = default; }

	/// Row-major, reading left to right and top to bottom.
	[Inline]
	[Scriptable]
	public this(
		float m00, float m01, float m02, float m03,
		float m10, float m11, float m12, float m13,
		float m20, float m21, float m22, float m23,
		float m30, float m31, float m32, float m33)
	{
		M = .(.(m00, m01, m02, m03),
			  .(m10, m11, m12, m13),
			  .(m20, m21, m22, m23),
			  .(m30, m31, m32, m33));
	}

	/// Raw row-major float pointer, sixteen contiguous floats, for GPU upload.
	[Hidden]
	public float* Data mut => &M[0][0];

	public float this[int row, int col]
	{
		[Inline] get
		{
			Debug.Assert((row >= 0) && (row < 4) && (col >= 0) && (col < 4));
			return M[row][col];
		}
		[Inline] set mut
		{
			Debug.Assert((row >= 0) && (row < 4) && (col >= 0) && (col < 4));
			M[row][col] = value;
		}
	}

	[Scriptable]
	public static Float4x4 Identity() => .(
		1.0f, 0.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 1.0f, 0.0f,
		0.0f, 0.0f, 0.0f, 1.0f);

	[Scriptable]
	public static Float4x4 Translation(Float3 t) => .(
		1.0f, 0.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 1.0f, 0.0f,
		t.X,  t.Y,  t.Z,  1.0f);

	[Scriptable]
	public static Float4x4 Scale(Float3 s) => .(
		s.X,  0.0f, 0.0f, 0.0f,
		0.0f, s.Y,  0.0f, 0.0f,
		0.0f, 0.0f, s.Z,  0.0f,
		0.0f, 0.0f, 0.0f, 1.0f);

	[Scriptable]
	public static Float4x4 RotationX(float radians)
	{
		let c = Cos(radians);
		let s = Sin(radians);
		return .(
			1.0f, 0.0f, 0.0f, 0.0f,
			0.0f, c,    s,    0.0f,
			0.0f, -s,   c,    0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);
	}

	[Scriptable]
	public static Float4x4 RotationY(float radians)
	{
		let c = Cos(radians);
		let s = Sin(radians);
		return .(
			c,    0.0f, -s,   0.0f,
			0.0f, 1.0f, 0.0f, 0.0f,
			s,    0.0f, c,    0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);
	}

	[Scriptable]
	public static Float4x4 RotationZ(float radians)
	{
		let c = Cos(radians);
		let s = Sin(radians);
		return .(
			c,    s,    0.0f, 0.0f,
			-s,   c,    0.0f, 0.0f,
			0.0f, 0.0f, 1.0f, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);
	}

	/// Right-handed perspective, REVERSE-Z: NDC z in [0, 1] with the NEAR plane at 1 and the
	/// FAR plane at 0, the engine's one depth convention (see [Projection]). With a float depth
	/// buffer this spends the float's precision where a perspective divide starves it, far
	/// away: the resolvable depth step grows linearly with distance instead of quadratically.
	/// Derivation, row vector, view z negative forward (ze = -d):
	///   ndc = n (f - d) / ((f - n) d)  ->  z' = ze * n/(f-n) + n f/(f-n),  w' = -ze.
	[Scriptable]
	public static Float4x4 PerspectiveFovRH(float fovYRadians, float aspect, float zNear, float zFar)
	{
		let yScale = 1.0f / Tan(fovYRadians * 0.5f);
		let xScale = yScale / aspect;
		let zRange = zNear / (zFar - zNear);
		return .(
			xScale, 0.0f,   0.0f,            0.0f,
			0.0f,   yScale, 0.0f,            0.0f,
			0.0f,   0.0f,   zRange,          -1.0f,
			0.0f,   0.0f,   zFar * zRange,   0.0f);
	}

	/// Right-handed orthographic, REVERSE-Z (near to 1, far to 0), the same convention as the
	/// perspective builder so shadow cascades, thumbnails and the camera share one depth
	/// reading: ndc = (f - d) / (f - n)  ->  z' = ze / (f - n) + f / (f - n).
	[Scriptable]
	public static Float4x4 OrthographicRH(float width, float height, float zNear, float zFar)
	{
		let zRange = 1.0f / (zFar - zNear);
		return .(
			2.0f / width, 0.0f,          0.0f,           0.0f,
			0.0f,         2.0f / height, 0.0f,           0.0f,
			0.0f,         0.0f,          zRange,         0.0f,
			0.0f,         0.0f,          zFar * zRange,  1.0f);
	}

	[Scriptable]
	public static Float4x4 LookAtRH(Float3 eye, Float3 target, Float3 up)
	{
		let zAxis = Normalized(eye - target);   // the camera looks down -z
		let xAxis = Normalized(Cross(up, zAxis));
		let yAxis = Cross(zAxis, xAxis);
		return .(
			xAxis.X,          yAxis.X,          zAxis.X,          0.0f,
			xAxis.Y,          yAxis.Y,          zAxis.Y,          0.0f,
			xAxis.Z,          yAxis.Z,          zAxis.Z,          0.0f,
			-Dot(xAxis, eye), -Dot(yAxis, eye), -Dot(zAxis, eye), 1.0f);
	}

	[Inline]
	public static Float4x4 operator*(Float4x4 a, Float4x4 b)
	{
		Float4x4 result = .();
		for (int row < 4)
		{
			for (int col < 4)
			{
				var sum = 0.0f;
				for (int k < 4)
					sum += a.M[row][k] * b.M[k][col];
				result.M[row][col] = sum;
			}
		}
		return result;
	}

	/// Row-vector transform: v' = v * M.
	[Inline]
	public static Float4 operator*(Float4 v, Float4x4 M) => .(
		v.X * M.M[0][0] + v.Y * M.M[1][0] + v.Z * M.M[2][0] + v.W * M.M[3][0],
		v.X * M.M[0][1] + v.Y * M.M[1][1] + v.Z * M.M[2][1] + v.W * M.M[3][1],
		v.X * M.M[0][2] + v.Y * M.M[1][2] + v.Z * M.M[2][2] + v.W * M.M[3][2],
		v.X * M.M[0][3] + v.Y * M.M[1][3] + v.Z * M.M[2][3] + v.W * M.M[3][3]);

	/// Exact element-wise equality, for an identity fast path.
	/// [Commutable] so Beef can derive != from this one declaration. Without it every use
	/// of != warns, and a warning costs the whole incremental build.
	[Commutable]
	[Inline]
	public static bool operator==(Float4x4 a, Float4x4 b)
	{
		for (int row < 4)
			for (int col < 4)
				if (a.M[row][col] != b.M[row][col])
					return false;
		return true;
	}
}

static
{
	[Scriptable]
	[Scriptable]
	public static Float4x4 Transpose(Float4x4 a)
	{
		Float4x4 result = .();
		for (int row < 4)
			for (int col < 4)
				result.M[row][col] = a.M[col][row];
		return result;
	}

	/// Transforms a position: implicit w = 1, so translation applies.
	[Scriptable]
	public static Float3 TransformPoint(Float3 p, Float4x4 m) => .(
		p.X * m.M[0][0] + p.Y * m.M[1][0] + p.Z * m.M[2][0] + m.M[3][0],
		p.X * m.M[0][1] + p.Y * m.M[1][1] + p.Z * m.M[2][1] + m.M[3][1],
		p.X * m.M[0][2] + p.Y * m.M[1][2] + p.Z * m.M[2][2] + m.M[3][2]);

	/// Transforms a direction: implicit w = 0, so translation is ignored.
	[Scriptable]
	public static Float3 TransformDirection(Float3 d, Float4x4 m) => .(
		d.X * m.M[0][0] + d.Y * m.M[1][0] + d.Z * m.M[2][0],
		d.X * m.M[0][1] + d.Y * m.M[1][1] + d.Z * m.M[2][1],
		d.X * m.M[0][2] + d.Y * m.M[1][2] + d.Z * m.M[2][2]);

	/// Transforms a 2D position held in a 4x4 affine transform: implicit z = 0, w = 1,
	/// translation applies, and the result projects back to 2D.
	[Scriptable]
	public static Float2 TransformPoint2D(Float2 p, Float4x4 m) => .(
		p.X * m.M[0][0] + p.Y * m.M[1][0] + m.M[3][0],
		p.X * m.M[0][1] + p.Y * m.M[1][1] + m.M[3][1]);

	[Scriptable]
	public static bool NearlyEqual(Float4x4 a, Float4x4 b, float epsilon = Epsilon)
	{
		for (int row < 4)
			for (int col < 4)
				if (!NearlyEqual(a.M[row][col], b.M[row][col], epsilon))
					return false;
		return true;
	}

	[Scriptable]
	[Scriptable]
	public static float Determinant(Float4x4 mat)
	{
		var mat;
		let m = &mat.M[0][0];
		let s0 = m[0] * m[5] - m[1] * m[4];
		let s1 = m[0] * m[6] - m[2] * m[4];
		let s2 = m[0] * m[7] - m[3] * m[4];
		let s3 = m[1] * m[6] - m[2] * m[5];
		let s4 = m[1] * m[7] - m[3] * m[5];
		let s5 = m[2] * m[7] - m[3] * m[6];
		let c5 = m[10] * m[15] - m[11] * m[14];
		let c4 = m[9] * m[15] - m[11] * m[13];
		let c3 = m[9] * m[14] - m[10] * m[13];
		let c2 = m[8] * m[15] - m[11] * m[12];
		let c1 = m[8] * m[14] - m[10] * m[12];
		let c0 = m[8] * m[13] - m[9] * m[12];
		return s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;
	}

	/// Full inverse by adjugate over determinant. Returns Identity for a singular matrix
	/// rather than producing infinities.
	[Scriptable]
	[Scriptable]
	public static Float4x4 Inverse(Float4x4 mat)
	{
		var mat;
		let m = &mat.M[0][0];
		float[16] inv = ?;

		inv[0] = m[5] * m[10] * m[15] - m[5] * m[11] * m[14] - m[9] * m[6] * m[15] +
			m[9] * m[7] * m[14] + m[13] * m[6] * m[11] - m[13] * m[7] * m[10];
		inv[4] = -m[4] * m[10] * m[15] + m[4] * m[11] * m[14] + m[8] * m[6] * m[15] -
			m[8] * m[7] * m[14] - m[12] * m[6] * m[11] + m[12] * m[7] * m[10];
		inv[8] = m[4] * m[9] * m[15] - m[4] * m[11] * m[13] - m[8] * m[5] * m[15] +
			m[8] * m[7] * m[13] + m[12] * m[5] * m[11] - m[12] * m[7] * m[9];
		inv[12] = -m[4] * m[9] * m[14] + m[4] * m[10] * m[13] + m[8] * m[5] * m[14] -
			m[8] * m[6] * m[13] - m[12] * m[5] * m[10] + m[12] * m[6] * m[9];
		inv[1] = -m[1] * m[10] * m[15] + m[1] * m[11] * m[14] + m[9] * m[2] * m[15] -
			m[9] * m[3] * m[14] - m[13] * m[2] * m[11] + m[13] * m[3] * m[10];
		inv[5] = m[0] * m[10] * m[15] - m[0] * m[11] * m[14] - m[8] * m[2] * m[15] +
			m[8] * m[3] * m[14] + m[12] * m[2] * m[11] - m[12] * m[3] * m[10];
		inv[9] = -m[0] * m[9] * m[15] + m[0] * m[11] * m[13] + m[8] * m[1] * m[15] -
			m[8] * m[3] * m[13] - m[12] * m[1] * m[11] + m[12] * m[3] * m[9];
		inv[13] = m[0] * m[9] * m[14] - m[0] * m[10] * m[13] - m[8] * m[1] * m[14] +
			m[8] * m[2] * m[13] + m[12] * m[1] * m[10] - m[12] * m[2] * m[9];
		inv[2] = m[1] * m[6] * m[15] - m[1] * m[7] * m[14] - m[5] * m[2] * m[15] +
			m[5] * m[3] * m[14] + m[13] * m[2] * m[7] - m[13] * m[3] * m[6];
		inv[6] = -m[0] * m[6] * m[15] + m[0] * m[7] * m[14] + m[4] * m[2] * m[15] -
			m[4] * m[3] * m[14] - m[12] * m[2] * m[7] + m[12] * m[3] * m[6];
		inv[10] = m[0] * m[5] * m[15] - m[0] * m[7] * m[13] - m[4] * m[1] * m[15] +
			m[4] * m[3] * m[13] + m[12] * m[1] * m[7] - m[12] * m[3] * m[5];
		inv[14] = -m[0] * m[5] * m[14] + m[0] * m[6] * m[13] + m[4] * m[1] * m[14] -
			m[4] * m[2] * m[13] - m[12] * m[1] * m[6] + m[12] * m[2] * m[5];
		inv[3] = -m[1] * m[6] * m[11] + m[1] * m[7] * m[10] + m[5] * m[2] * m[11] -
			m[5] * m[3] * m[10] - m[9] * m[2] * m[7] + m[9] * m[3] * m[6];
		inv[7] = m[0] * m[6] * m[11] - m[0] * m[7] * m[10] - m[4] * m[2] * m[11] +
			m[4] * m[3] * m[10] + m[8] * m[2] * m[7] - m[8] * m[3] * m[6];
		inv[11] = -m[0] * m[5] * m[11] + m[0] * m[7] * m[9] + m[4] * m[1] * m[11] -
			m[4] * m[3] * m[9] - m[8] * m[1] * m[7] + m[8] * m[3] * m[5];
		inv[15] = m[0] * m[5] * m[10] - m[0] * m[6] * m[9] - m[4] * m[1] * m[10] +
			m[4] * m[2] * m[9] + m[8] * m[1] * m[6] - m[8] * m[2] * m[5];

		let det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];
		if (NearlyZero(det))
			return Float4x4.Identity();

		let invDet = 1.0f / det;
		Float4x4 result = .();
		let outp = &result.M[0][0];
		for (int i < 16)
			outp[i] = inv[i] * invDet;
		return result;
	}
}
