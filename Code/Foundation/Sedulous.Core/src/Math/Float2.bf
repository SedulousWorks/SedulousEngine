using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 2D float vector: arithmetic, Dot/Length/Normalized, Lerp, component constants.
///
/// CRepr because these reach GPU buffers and file formats, where the layout is part of
/// the contract rather than an implementation detail.
[CRepr]
struct Float2
{
	public float x = 0.0f;
	public float y = 0.0f;

	public this() { }
	public this(float x, float y) { this.x = x; this.y = y; }
	public this(float s) { this.x = s; this.y = s; }

	public const Float2 Zero = .(0.0f, 0.0f);
	public const Float2 One = .(1.0f, 1.0f);
	public const Float2 UnitX = .(1.0f, 0.0f);
	public const Float2 UnitY = .(0.0f, 1.0f);

	public float this[int i]
	{
		[Inline] get
		{
			Debug.Assert((i >= 0) && (i < 2));
			return (i == 0) ? x : y;
		}
		[Inline] set mut
		{
			Debug.Assert((i >= 0) && (i < 2));
			if (i == 0) x = value; else y = value;
		}
	}

	public static Float2 operator-(Float2 v) => .(-v.x, -v.y);

	public void operator+=(Float2 r) mut { x += r.x; y += r.y; }
	public void operator-=(Float2 r) mut { x -= r.x; y -= r.y; }
	public void operator*=(float s) mut { x *= s; y *= s; }
	public void operator/=(float s) mut { x /= s; y /= s; }

	public static Float2 operator+(Float2 a, Float2 b) => .(a.x + b.x, a.y + b.y);
	public static Float2 operator-(Float2 a, Float2 b) => .(a.x - b.x, a.y - b.y);
	/// Component-wise, not a dot or a scale.
	public static Float2 operator*(Float2 a, Float2 b) => .(a.x * b.x, a.y * b.y);
	public static Float2 operator*(Float2 v, float s) => .(v.x * s, v.y * s);
	public static Float2 operator*(float s, Float2 v) => .(v.x * s, v.y * s);
	public static Float2 operator/(Float2 v, float s) => .(v.x / s, v.y / s);
	public static bool operator==(Float2 a, Float2 b) => (a.x == b.x) && (a.y == b.y);
}

static
{
	[Inline] public static float Dot(Float2 a, Float2 b) => a.x * b.x + a.y * b.y;

	[Inline] public static float LengthSquared(Float2 v) => Dot(v, v);
	[Inline] public static float Length(Float2 v) => Sqrt(LengthSquared(v));
	[Inline] public static float DistanceSquared(Float2 a, Float2 b) => LengthSquared(b - a);
	[Inline] public static float Distance(Float2 a, Float2 b) => Length(b - a);

	/// A unit vector, or Zero when the input is near-zero length.
	public static Float2 Normalized(Float2 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return Float2.Zero;
		return v / Sqrt(lengthSq);
	}

	[Inline]
	public static Float2 Lerp(Float2 a, Float2 b, float t) => a + (b - a) * t;

	public static bool NearlyEqual(Float2 a, Float2 b, float epsilon = Epsilon) =>
		NearlyEqual(a.x, b.x, epsilon) && NearlyEqual(a.y, b.y, epsilon);
}
