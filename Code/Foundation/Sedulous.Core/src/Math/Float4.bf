using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 4D float vector: arithmetic, Dot/Length/Normalized, XYZ, component constants.
/// Converts from Float3.
[CRepr]
struct Float4
{
	public float x = 0.0f;
	public float y = 0.0f;
	public float z = 0.0f;
	public float w = 0.0f;

	public this() { }
	public this(float x, float y, float z, float w)
	{
		this.x = x; this.y = y; this.z = z; this.w = w;
	}
	public this(float s) { this.x = s; this.y = s; this.z = s; this.w = s; }
	public this(Float3 xyz, float w)
	{
		this.x = xyz.x; this.y = xyz.y; this.z = xyz.z; this.w = w;
	}

	public const Float4 Zero = .(0.0f, 0.0f, 0.0f, 0.0f);
	public const Float4 One = .(1.0f, 1.0f, 1.0f, 1.0f);

	public float this[int i]
	{
		[Inline] get
		{
			Debug.Assert((i >= 0) && (i < 4));
			switch (i)
			{
			case 0: return x;
			case 1: return y;
			case 2: return z;
			default: return w;
			}
		}
		[Inline] set mut
		{
			Debug.Assert((i >= 0) && (i < 4));
			switch (i)
			{
			case 0: x = value;
			case 1: y = value;
			case 2: z = value;
			default: w = value;
			}
		}
	}

	[Inline] public Float3 XYZ() => .(x, y, z);

	public static Float4 operator-(Float4 v) => .(-v.x, -v.y, -v.z, -v.w);

	public void operator+=(Float4 r) mut { x += r.x; y += r.y; z += r.z; w += r.w; }
	public void operator-=(Float4 r) mut { x -= r.x; y -= r.y; z -= r.z; w -= r.w; }
	public void operator*=(float s) mut { x *= s; y *= s; z *= s; w *= s; }

	public static Float4 operator+(Float4 a, Float4 b) =>
		.(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w);
	public static Float4 operator-(Float4 a, Float4 b) =>
		.(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w);
	public static Float4 operator*(Float4 v, float s) => .(v.x * s, v.y * s, v.z * s, v.w * s);
	public static Float4 operator*(float s, Float4 v) => .(v.x * s, v.y * s, v.z * s, v.w * s);
	public static bool operator==(Float4 a, Float4 b) =>
		(a.x == b.x) && (a.y == b.y) && (a.z == b.z) && (a.w == b.w);
}

static
{
	[Inline]
	public static float Dot(Float4 a, Float4 b) =>
		a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;

	[Inline] public static float LengthSquared(Float4 v) => Dot(v, v);
	[Inline] public static float Length(Float4 v) => Sqrt(LengthSquared(v));

	/// A unit vector, or Zero when the input is near-zero length.
	public static Float4 Normalized(Float4 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return Float4.Zero;
		return v * (1.0f / Sqrt(lengthSq));
	}

	[Inline]
	public static Float4 Lerp(Float4 a, Float4 b, float t) => a + (b - a) * t;

	public static bool NearlyEqual(Float4 a, Float4 b, float epsilon = Epsilon) =>
		NearlyEqual(a.x, b.x, epsilon) &&
		NearlyEqual(a.y, b.y, epsilon) &&
		NearlyEqual(a.z, b.z, epsilon) &&
		NearlyEqual(a.w, b.w, epsilon);
}
