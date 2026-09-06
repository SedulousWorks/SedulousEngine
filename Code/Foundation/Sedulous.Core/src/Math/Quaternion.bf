using System;

namespace Sedulous.Core;

/// Unit quaternion rotation, stored (x, y, z, w).
[CRepr]
struct Quaternion
{
	public float x = 0.0f;
	public float y = 0.0f;
	public float z = 0.0f;
	public float w = 1.0f;

	public this() { }
	public this(float x, float y, float z, float w)
	{
		this.x = x; this.y = y; this.z = z; this.w = w;
	}

	public const Quaternion Identity = .(0.0f, 0.0f, 0.0f, 1.0f);

	public static Quaternion FromAxisAngle(Float3 axis, float radians)
	{
		let half = radians * 0.5f;
		let s = Sin(half);
		let a = Normalized(axis);
		return .(a.x * s, a.y * s, a.z * s, Cos(half));
	}

	/// Hamilton product: applies b, then a, to a vector.
	public static Quaternion operator*(Quaternion a, Quaternion b) => .(
		a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
		a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
		a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
		a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z);
}

static
{
	public static Quaternion Conjugate(Quaternion q) => .(-q.x, -q.y, -q.z, q.w);

	[Inline]
	public static float Dot(Quaternion a, Quaternion b) =>
		a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;

	/// General inverse, conjugate over the squared length. Equals the conjugate for a
	/// unit quaternion.
	public static Quaternion Inverse(Quaternion q)
	{
		let lengthSq = Dot(q, q);
		if (lengthSq <= Epsilon * Epsilon)
			return Quaternion.Identity;
		let inv = 1.0f / lengthSq;
		return .(-q.x * inv, -q.y * inv, -q.z * inv, q.w * inv);
	}

	public static Quaternion Normalized(Quaternion q)
	{
		let lengthSq = Dot(q, q);
		if (lengthSq <= Epsilon * Epsilon)
			return Quaternion.Identity;
		let inv = 1.0f / Sqrt(lengthSq);
		return .(q.x * inv, q.y * inv, q.z * inv, q.w * inv);
	}

	public static Float3 RotateVector(Quaternion q, Float3 v)
	{
		let u = Float3(q.x, q.y, q.z);
		let s = q.w;
		return u * (2.0f * Dot(u, v)) + v * (s * s - Dot(u, u)) + Cross(u, v) * (2.0f * s);
	}

	public static bool NearlyEqual(Quaternion a, Quaternion b, float epsilon = Epsilon) =>
		NearlyEqual(a.x, b.x, epsilon) && NearlyEqual(a.y, b.y, epsilon) &&
		NearlyEqual(a.z, b.z, epsilon) && NearlyEqual(a.w, b.w, epsilon);

	/// Spherical linear interpolation along the shortest arc; the result is unit.
	public static Quaternion Slerp(Quaternion a, Quaternion b, float t)
	{
		var b;
		var cosTheta = Dot(a, b);
		if (cosTheta < 0.0f)   // shortest path
		{
			b = Quaternion(-b.x, -b.y, -b.z, -b.w);
			cosTheta = -cosTheta;
		}

		if (cosTheta > 0.9995f) // nearly parallel: lerp and normalize
		{
			return Normalized(Quaternion(
				a.x + (b.x - a.x) * t,
				a.y + (b.y - a.y) * t,
				a.z + (b.z - a.z) * t,
				a.w + (b.w - a.w) * t));
		}

		let theta0 = Acos(cosTheta);
		let theta = theta0 * t;
		let sinTheta = Sin(theta);
		let sinTheta0 = Sin(theta0);
		let s1 = sinTheta / sinTheta0;
		let s0 = Cos(theta) - cosTheta * s1;
		return .(
			a.x * s0 + b.x * s1,
			a.y * s0 + b.y * s1,
			a.z * s0 + b.z * s1,
			a.w * s0 + b.w * s1);
	}

	/// Rotation matrix for a unit quaternion, row-vector convention, XNA layout.
	public static Float4x4 RotationMatrix(Quaternion q)
	{
		let xx = q.x * q.x; let yy = q.y * q.y; let zz = q.z * q.z;
		let xy = q.x * q.y; let xz = q.x * q.z; let yz = q.y * q.z;
		let wx = q.w * q.x; let wy = q.w * q.y; let wz = q.w * q.z;
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
		pitch = Asin(Clamp(2.0f * (q.w * q.x - q.y * q.z), -1.0f, 1.0f));
		yaw = Atan2(2.0f * (q.w * q.y + q.x * q.z), 1.0f - 2.0f * (q.x * q.x + q.y * q.y));
		roll = Atan2(2.0f * (q.w * q.z + q.x * q.y), 1.0f - 2.0f * (q.x * q.x + q.z * q.z));
	}

	/// RotationMatrix's inverse: the unit quaternion of a pure rotation matrix, using
	/// Shepperd's method over the trace and the dominant diagonal element.
	public static Quaternion QuaternionFromRotationMatrix(Float4x4 m)
	{
		let trace = m.m[0][0] + m.m[1][1] + m.m[2][2];
		Quaternion result = .();
		if (trace > 0.0f)
		{
			var s = Sqrt(trace + 1.0f);
			result.w = s * 0.5f;
			s = 0.5f / s;
			result.x = (m.m[1][2] - m.m[2][1]) * s;
			result.y = (m.m[2][0] - m.m[0][2]) * s;
			result.z = (m.m[0][1] - m.m[1][0]) * s;
		}
		else if ((m.m[0][0] >= m.m[1][1]) && (m.m[0][0] >= m.m[2][2]))
		{
			let s = Sqrt(1.0f + m.m[0][0] - m.m[1][1] - m.m[2][2]);
			let invS = 0.5f / s;
			result.x = 0.5f * s;
			result.y = (m.m[0][1] + m.m[1][0]) * invS;
			result.z = (m.m[0][2] + m.m[2][0]) * invS;
			result.w = (m.m[1][2] - m.m[2][1]) * invS;
		}
		else if (m.m[1][1] > m.m[2][2])
		{
			let s = Sqrt(1.0f + m.m[1][1] - m.m[0][0] - m.m[2][2]);
			let invS = 0.5f / s;
			result.x = (m.m[1][0] + m.m[0][1]) * invS;
			result.y = 0.5f * s;
			result.z = (m.m[2][1] + m.m[1][2]) * invS;
			result.w = (m.m[2][0] - m.m[0][2]) * invS;
		}
		else
		{
			let s = Sqrt(1.0f + m.m[2][2] - m.m[0][0] - m.m[1][1]);
			let invS = 0.5f / s;
			result.x = (m.m[2][0] + m.m[0][2]) * invS;
			result.y = (m.m[2][1] + m.m[1][2]) * invS;
			result.z = 0.5f * s;
			result.w = (m.m[0][1] - m.m[1][0]) * invS;
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
		translation = .(m.m[3][0], m.m[3][1], m.m[3][2]);

		scale = .(
			Sqrt(m.m[0][0] * m.m[0][0] + m.m[0][1] * m.m[0][1] + m.m[0][2] * m.m[0][2]),
			Sqrt(m.m[1][0] * m.m[1][0] + m.m[1][1] * m.m[1][1] + m.m[1][2] * m.m[1][2]),
			Sqrt(m.m[2][0] * m.m[2][0] + m.m[2][1] * m.m[2][1] + m.m[2][2] * m.m[2][2]));

		if ((scale.x == 0.0f) || (scale.y == 0.0f) || (scale.z == 0.0f))
		{
			scale = Float3.One;
			rotation = Quaternion.Identity;
			return false;
		}

		// A mirrored basis has a negative determinant and cannot be a pure rotation, so
		// one axis takes the sign.
		let det =
			m.m[0][0] * (m.m[1][1] * m.m[2][2] - m.m[1][2] * m.m[2][1]) -
			m.m[0][1] * (m.m[1][0] * m.m[2][2] - m.m[1][2] * m.m[2][0]) +
			m.m[0][2] * (m.m[1][0] * m.m[2][1] - m.m[1][1] * m.m[2][0]);
		if (det < 0.0f)
			scale.z = -scale.z;

		var r = Float4x4.Identity();
		for (int c < 3)
		{
			r.m[0][c] = m.m[0][c] / scale.x;
			r.m[1][c] = m.m[1][c] / scale.y;
			r.m[2][c] = m.m[2][c] / scale.z;
		}
		rotation = QuaternionFromRotationMatrix(r);
		return true;
	}
}
