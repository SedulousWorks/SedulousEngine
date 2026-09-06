using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 3D float vector: arithmetic, Dot/Cross/Length/Normalized, Min/Max, Lerp, component
/// constants. Converts from Float2.
[CRepr]
struct Float3
{
	public float x = 0.0f;
	public float y = 0.0f;
	public float z = 0.0f;

	public this() { }
	public this(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
	public this(float s) { this.x = s; this.y = s; this.z = s; }
	public this(Float2 xy, float z) { this.x = xy.x; this.y = xy.y; this.z = z; }

	public const Float3 Zero = .(0.0f, 0.0f, 0.0f);
	public const Float3 One = .(1.0f, 1.0f, 1.0f);
	public const Float3 UnitX = .(1.0f, 0.0f, 0.0f);
	public const Float3 UnitY = .(0.0f, 1.0f, 0.0f);
	public const Float3 UnitZ = .(0.0f, 0.0f, 1.0f);

	public float this[int i]
	{
		[Inline] get
		{
			Debug.Assert((i >= 0) && (i < 3));
			return (i == 0) ? x : ((i == 1) ? y : z);
		}
		[Inline] set mut
		{
			Debug.Assert((i >= 0) && (i < 3));
			if (i == 0) x = value; else if (i == 1) y = value; else z = value;
		}
	}

	public static Float3 operator-(Float3 v) => .(-v.x, -v.y, -v.z);

	public void operator+=(Float3 r) mut { x += r.x; y += r.y; z += r.z; }
	public void operator-=(Float3 r) mut { x -= r.x; y -= r.y; z -= r.z; }
	public void operator*=(float s) mut { x *= s; y *= s; z *= s; }
	public void operator/=(float s) mut { x /= s; y /= s; z /= s; }

	public static Float3 operator+(Float3 a, Float3 b) => .(a.x + b.x, a.y + b.y, a.z + b.z);
	public static Float3 operator-(Float3 a, Float3 b) => .(a.x - b.x, a.y - b.y, a.z - b.z);
	/// Component-wise, not a dot or a cross.
	public static Float3 operator*(Float3 a, Float3 b) => .(a.x * b.x, a.y * b.y, a.z * b.z);
	public static Float3 operator*(Float3 v, float s) => .(v.x * s, v.y * s, v.z * s);
	public static Float3 operator*(float s, Float3 v) => .(v.x * s, v.y * s, v.z * s);
	public static Float3 operator/(Float3 v, float s) => .(v.x / s, v.y / s, v.z / s);
	/// Component-wise.
	public static Float3 operator/(Float3 a, Float3 b) => .(a.x / b.x, a.y / b.y, a.z / b.z);
	public static bool operator==(Float3 a, Float3 b) =>
		(a.x == b.x) && (a.y == b.y) && (a.z == b.z);
}

static
{
	[Inline]
	public static float Dot(Float3 a, Float3 b) => a.x * b.x + a.y * b.y + a.z * b.z;

	[Inline]
	public static Float3 Cross(Float3 a, Float3 b) => .(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x);

	[Inline] public static float LengthSquared(Float3 v) => Dot(v, v);
	[Inline] public static float Length(Float3 v) => Sqrt(LengthSquared(v));
	[Inline] public static float Distance(Float3 a, Float3 b) => Length(b - a);

	/// A unit vector, or Zero when the input is near-zero length.
	public static Float3 Normalized(Float3 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return Float3.Zero;
		return v / Sqrt(lengthSq);
	}

	[Inline]
	public static Float3 Lerp(Float3 a, Float3 b, float t) => a + (b - a) * t;

	public static Float3 Min(Float3 a, Float3 b) => .(
		a.x < b.x ? a.x : b.x,
		a.y < b.y ? a.y : b.y,
		a.z < b.z ? a.z : b.z);

	public static Float3 Max(Float3 a, Float3 b) => .(
		a.x > b.x ? a.x : b.x,
		a.y > b.y ? a.y : b.y,
		a.z > b.z ? a.z : b.z);

	public static bool NearlyEqual(Float3 a, Float3 b, float epsilon = Epsilon) =>
		NearlyEqual(a.x, b.x, epsilon) &&
		NearlyEqual(a.y, b.y, epsilon) &&
		NearlyEqual(a.z, b.z, epsilon);
}
