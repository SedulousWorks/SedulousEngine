using System;
using System.Numerics;

namespace Sedulous.Core;

/// A two lane SIMD compute vector, holding its Z AND W LANES AT ZERO by invariant, for the
/// same reason [[Vector3]] holds one: the fold then ignores them without masking.
///
/// NOT a storage type; store as Float2.
[Align(16)]
struct Vector2
{
	public float4 R = .(0, 0, 0, 0);

	[Inline] public this() {}
	[Inline] public this(float x, float y) { R = .(x, y, 0.0f, 0.0f); }
	[Inline] public this(float s) { R = .(s, s, 0.0f, 0.0f); }
	/// Wraps a register directly, forcing z and w to zero to keep the invariant.
	[Inline] public this(float4 v) { R = .(v.x, v.y, 0.0f, 0.0f); }
	[Inline] public this(Float2 f) { R = .(f.X, f.Y, 0.0f, 0.0f); }

	[Inline] public Float2 ToFloat2() => .(R.x, R.y);

	[Inline] public float X => R.x;
	[Inline] public float Y => R.y;

	[Inline] public static Vector2 operator-(Vector2 v) => .(-v.R);
	[Inline] public static Vector2 operator+(Vector2 a, Vector2 b) => .(a.R + b.R);
	[Inline] public static Vector2 operator-(Vector2 a, Vector2 b) => .(a.R - b.R);
	/// COMPONENT WISE, as in Raptor. Dot is the dot product.
	[Inline] public static Vector2 operator*(Vector2 a, Vector2 b) => .(a.R * b.R);
	[Inline, Commutable] public static Vector2 operator*(Vector2 v, float s) => .(v.R * s);
	[Inline] public static Vector2 operator/(Vector2 v, float s) => .(v.R / s);

	[Inline] public void operator+=(Vector2 o) mut { R += o.R; }
	[Inline] public void operator-=(Vector2 o) mut { R -= o.R; }
	[Inline] public void operator*=(float s) mut { R *= s; }
}

static
{
	[Inline] public static float Dot(Vector2 a, Vector2 b) => a.R.x * b.R.x + a.R.y * b.R.y;

	[Inline] public static float LengthSquared(Vector2 v) => Dot(v, v);
	[Inline] public static float Length(Vector2 v) => Sqrt(LengthSquared(v));
	[Inline] public static float Distance(Vector2 a, Vector2 b) => Length(b - a);

	public static Vector2 Normalized(Vector2 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return .();
		return .(v.R * (1.0f / Sqrt(lengthSq)));
	}

	[Inline] public static Vector2 Lerp(Vector2 a, Vector2 b, float t) => a + (b - a) * t;
	[Inline] public static Vector2 Min(Vector2 a, Vector2 b) => .(float4.Min(a.R, b.R));
	[Inline] public static Vector2 Max(Vector2 a, Vector2 b) => .(float4.Max(a.R, b.R));
}
