using System;

namespace Sedulous.Core;

/// Unit quaternion rotation, stored (X, Y, Z, W).
[CRepr]
struct Quaternion
{
	public float X = 0.0f;
	public float Y = 0.0f;
	public float Z = 0.0f;
	public float W = 1.0f;

	[Inline]
	public this() { }
	[Inline]
	public this(float x, float y, float z, float w)
	{
		this.X = x; this.Y = y; this.Z = z; this.W = w;
	}

	public const Quaternion Identity = .(0.0f, 0.0f, 0.0f, 1.0f);

	public static Quaternion FromAxisAngle(Float3 axis, float radians)
	{
		let half = radians * 0.5f;
		let s = Sin(half);
		let a = Normalized(axis);
		return .(a.X * s, a.Y * s, a.Z * s, Cos(half));
	}

	/// Hamilton product: applies b, then a, to a vector.
	[Inline]
	public static Quaternion operator*(Quaternion a, Quaternion b) => .(
		a.W * b.X + a.X * b.W + a.Y * b.Z - a.Z * b.Y,
		a.W * b.Y - a.X * b.Z + a.Y * b.W + a.Z * b.X,
		a.W * b.Z + a.X * b.Y - a.Y * b.X + a.Z * b.W,
		a.W * b.W - a.X * b.X - a.Y * b.Y - a.Z * b.Z);
}

static
{
	public static Quaternion Conjugate(Quaternion q) => .(-q.X, -q.Y, -q.Z, q.W);

	[Inline]
	public static float Dot(Quaternion a, Quaternion b) =>
		a.X * b.X + a.Y * b.Y + a.Z * b.Z + a.W * b.W;

	/// General inverse, conjugate over the squared length. Equals the conjugate for a
	/// unit quaternion.
	public static Quaternion Inverse(Quaternion q)
	{
		let lengthSq = Dot(q, q);
		if (lengthSq <= Epsilon * Epsilon)
			return Quaternion.Identity;
		let inv = 1.0f / lengthSq;
		return .(-q.X * inv, -q.Y * inv, -q.Z * inv, q.W * inv);
	}

	public static Quaternion Normalized(Quaternion q)
	{
		let lengthSq = Dot(q, q);
		if (lengthSq <= Epsilon * Epsilon)
			return Quaternion.Identity;
		let inv = 1.0f / Sqrt(lengthSq);
		return .(q.X * inv, q.Y * inv, q.Z * inv, q.W * inv);
	}

	public static Float3 RotateVector(Quaternion q, Float3 v)
	{
		let u = Float3(q.X, q.Y, q.Z);
		let s = q.W;
		return u * (2.0f * Dot(u, v)) + v * (s * s - Dot(u, u)) + Cross(u, v) * (2.0f * s);
	}

	public static bool NearlyEqual(Quaternion a, Quaternion b, float epsilon = Epsilon) =>
		NearlyEqual(a.X, b.X, epsilon) && NearlyEqual(a.Y, b.Y, epsilon) &&
		NearlyEqual(a.Z, b.Z, epsilon) && NearlyEqual(a.W, b.W, epsilon);

	/// Spherical linear interpolation along the shortest arc; the result is unit.
	public static Quaternion Slerp(Quaternion a, Quaternion b, float t)
	{
		var b;
		var cosTheta = Dot(a, b);
		if (cosTheta < 0.0f)   // shortest path
		{
			b = Quaternion(-b.X, -b.Y, -b.Z, -b.W);
			cosTheta = -cosTheta;
		}

		if (cosTheta > 0.9995f) // nearly parallel: lerp and normalize
		{
			return Normalized(Quaternion(
				a.X + (b.X - a.X) * t,
				a.Y + (b.Y - a.Y) * t,
				a.Z + (b.Z - a.Z) * t,
				a.W + (b.W - a.W) * t));
		}

		let theta0 = Acos(cosTheta);
		let theta = theta0 * t;
		let sinTheta = Sin(theta);
		let sinTheta0 = Sin(theta0);
		let s1 = sinTheta / sinTheta0;
		let s0 = Cos(theta) - cosTheta * s1;
		return .(
			a.X * s0 + b.X * s1,
			a.Y * s0 + b.Y * s1,
			a.Z * s0 + b.Z * s1,
			a.W * s0 + b.W * s1);
	}

	/// Rotation matrix for a unit quaternion, row-vector convention, XNA layout.
	public static Float4x4 RotationMatrix(Quaternion q)
	{
		let xx = q.X * q.X; let yy = q.Y * q.Y; let zz = q.Z * q.Z;
		let xy = q.X * q.Y; let xz = q.X * q.Z; let yz = q.Y * q.Z;
		let wx = q.W * q.X; let wy = q.W * q.Y; let wz = q.W * q.Z;
		return .(
			1.0f - 2.0f * (yy + zz), 2.0f * (xy + wz),        2.0f * (xz - wy),        0.0f,
			2.0f * (xy - wz),        1.0f - 2.0f * (xx + zz), 2.0f * (yz + wx),        0.0f,
			2.0f * (xz + wy),        2.0f * (yz - wx),        1.0f - 2.0f * (xx + yy), 0.0f,
			0.0f,                    0.0f,                    0.0f,                    1.0f);
	}

	/// Yaw (Y), pitch (X), roll (Z) in radians. XNA convention: q = qY * qX * qZ.
	public static Quaternion FromYawPitchRoll(float yaw, float pitch, float roll)
	{
		let sr = Sin(roll * 0.5f);  let cr = Cos(roll * 0.5f);
		let sp = Sin(pitch * 0.5f); let cp = Cos(pitch * 0.5f);
		let sy = Sin(yaw * 0.5f);   let cy = Cos(yaw * 0.5f);
		return .(
			cy * sp * cr + sy * cp * sr,
			sy * cp * cr - cy * sp * sr,
			cy * cp * sr - sy * sp * cr,
			cy * cp * cr + sy * sp * sr);
	}

	/// FromYawPitchRoll's inverse, pitch clamped to +-90 degrees. At the gimbal poles
	/// yaw and roll are not unique. This is the editor's rotation-as-euler seam.
	public static void ToYawPitchRoll(Quaternion q, out float yaw, out float pitch, out float roll)
	{
		pitch = Asin(Clamp(2.0f * (q.W * q.X - q.Y * q.Z), -1.0f, 1.0f));
		yaw = Atan2(2.0f * (q.W * q.Y + q.X * q.Z), 1.0f - 2.0f * (q.X * q.X + q.Y * q.Y));
		roll = Atan2(2.0f * (q.W * q.Z + q.X * q.Y), 1.0f - 2.0f * (q.X * q.X + q.Z * q.Z));
	}

	/// RotationMatrix's inverse: the unit quaternion of a pure rotation matrix, using
	/// Shepperd's method over the trace and the dominant diagonal element.
	public static Quaternion QuaternionFromRotationMatrix(Float4x4 m)
	{
		let trace = m.M[0][0] + m.M[1][1] + m.M[2][2];
		Quaternion result = .();
		if (trace > 0.0f)
		{
			var s = Sqrt(trace + 1.0f);
			result.W = s * 0.5f;
			s = 0.5f / s;
			result.X = (m.M[1][2] - m.M[2][1]) * s;
			result.Y = (m.M[2][0] - m.M[0][2]) * s;
			result.Z = (m.M[0][1] - m.M[1][0]) * s;
		}
		else if ((m.M[0][0] >= m.M[1][1]) && (m.M[0][0] >= m.M[2][2]))
		{
			let s = Sqrt(1.0f + m.M[0][0] - m.M[1][1] - m.M[2][2]);
			let invS = 0.5f / s;
			result.X = 0.5f * s;
			result.Y = (m.M[0][1] + m.M[1][0]) * invS;
			result.Z = (m.M[0][2] + m.M[2][0]) * invS;
			result.W = (m.M[1][2] - m.M[2][1]) * invS;
		}
		else if (m.M[1][1] > m.M[2][2])
		{
			let s = Sqrt(1.0f + m.M[1][1] - m.M[0][0] - m.M[2][2]);
			let invS = 0.5f / s;
			result.X = (m.M[1][0] + m.M[0][1]) * invS;
			result.Y = 0.5f * s;
			result.Z = (m.M[2][1] + m.M[1][2]) * invS;
			result.W = (m.M[2][0] - m.M[0][2]) * invS;
		}
		else
		{
			let s = Sqrt(1.0f + m.M[2][2] - m.M[0][0] - m.M[1][1]);
			let invS = 0.5f / s;
			result.X = (m.M[2][0] + m.M[0][2]) * invS;
			result.Y = (m.M[2][1] + m.M[1][2]) * invS;
			result.Z = 0.5f * s;
			result.W = (m.M[0][1] - m.M[1][0]) * invS;
		}
		return result;
	}

	/// TRS decompose of a row-vector S*R*T matrix: translation from row 3, per-axis
	/// scale from the basis row lengths, rotation from the normalized basis. Returns
	/// false with identity outputs when a scale axis is zero, since the rotation is then
	/// unrecoverable. As in Raptor, a mirrored matrix lands the sign on an arbitrary axis.
	public static bool Decompose(Float4x4 m, out Float3 translation, out Quaternion rotation,
		out Float3 scale)
	{
		translation = .(m.M[3][0], m.M[3][1], m.M[3][2]);

		scale = .(
			Sqrt(m.M[0][0] * m.M[0][0] + m.M[0][1] * m.M[0][1] + m.M[0][2] * m.M[0][2]),
			Sqrt(m.M[1][0] * m.M[1][0] + m.M[1][1] * m.M[1][1] + m.M[1][2] * m.M[1][2]),
			Sqrt(m.M[2][0] * m.M[2][0] + m.M[2][1] * m.M[2][1] + m.M[2][2] * m.M[2][2]));

		if ((scale.X == 0.0f) || (scale.Y == 0.0f) || (scale.Z == 0.0f))
		{
			scale = Float3.One;
			rotation = Quaternion.Identity;
			return false;
		}

		// A mirrored basis has a negative determinant and cannot be a pure rotation, so
		// one axis takes the sign.
		let det =
			m.M[0][0] * (m.M[1][1] * m.M[2][2] - m.M[1][2] * m.M[2][1]) -
			m.M[0][1] * (m.M[1][0] * m.M[2][2] - m.M[1][2] * m.M[2][0]) +
			m.M[0][2] * (m.M[1][0] * m.M[2][1] - m.M[1][1] * m.M[2][0]);
		if (det < 0.0f)
			scale.Z = -scale.Z;

		var r = Float4x4.Identity();
		for (int c < 3)
		{
			r.M[0][c] = m.M[0][c] / scale.X;
			r.M[1][c] = m.M[1][c] / scale.Y;
			r.M[2][c] = m.M[2][c] / scale.Z;
		}
		rotation = QuaternionFromRotationMatrix(r);
		return true;
	}
}
