using System;
using System.Numerics;

namespace Sedulous.Core;

/// A three lane SIMD compute vector, holding its W LANE AT ZERO by invariant.
///
/// That invariant is what lets Dot and Length ignore the fourth lane without masking: the lane
/// contributes zero to every sum. Every constructor establishes it, and the one that wraps a
/// raw float4 re establishes it, because a register arriving from a shuffle or a matrix row
/// carries whatever was in lane three.
///
/// NOT a storage type; see [[Vector4]] for why, and store as Float3.
[Align(16)]
struct Vector3
{
	public float4 R = .(0, 0, 0, 0);

	[Inline] public this() {}
	[Inline] public this(float x, float y, float z) { R = .(x, y, z, 0.0f); }
	[Inline] public this(float s) { R = .(s, s, s, 0.0f); }
	/// Wraps a register directly, forcing w to zero to keep the invariant.
	[Inline] public this(float4 v) { R = .(v.x, v.y, v.z, 0.0f); }
	[Inline] public this(Float3 f) { R = .(f.X, f.Y, f.Z, 0.0f); }

	[Inline] public Float3 ToFloat3() => .(R.x, R.y, R.z);

	[Inline] public float X => R.x;
	[Inline] public float Y => R.y;
	[Inline] public float Z => R.z;

	[Inline] public static Vector3 operator-(Vector3 v) => .(-v.R);
	[Inline] public static Vector3 operator+(Vector3 a, Vector3 b) => .(a.R + b.R);
	[Inline] public static Vector3 operator-(Vector3 a, Vector3 b) => .(a.R - b.R);
	/// COMPONENT WISE, as in Raptor. Dot is the dot product.
	[Inline] public static Vector3 operator*(Vector3 a, Vector3 b) => .(a.R * b.R);
	[Inline, Commutable] public static Vector3 operator*(Vector3 v, float s) => .(v.R * s);
	[Inline] public static Vector3 operator/(Vector3 v, float s) => .(v.R / s);

	[Inline] public void operator+=(Vector3 o) mut { R += o.R; }
	[Inline] public void operator-=(Vector3 o) mut { R -= o.R; }
	[Inline] public void operator*=(float s) mut { R *= s; }
}

static
{
	/// The w lane is zero on both sides, so the four lane fold is the three lane dot product.
	[Inline]
	public static float Dot(Vector3 a, Vector3 b)
	{
		return float4.HorizontalSum(a.R * b.R);
	}

	/// The shuffle form: (a.yzx * b.zxy) - (a.zxy * b.yzx), with lane three left alone because
	/// the constructor zeroes it anyway.
	[Inline]
	public static Vector3 Cross(Vector3 a, Vector3 b)
	{
		let aYzx = float4.ShuffleVector(a.R, 1, 2, 0, 3);
		let aZxy = float4.ShuffleVector(a.R, 2, 0, 1, 3);
		let bYzx = float4.ShuffleVector(b.R, 1, 2, 0, 3);
		let bZxy = float4.ShuffleVector(b.R, 2, 0, 1, 3);
		return .(aYzx * bZxy - aZxy * bYzx);
	}

	[Inline] public static float LengthSquared(Vector3 v) => Dot(v, v);
	[Inline] public static float Length(Vector3 v) => Sqrt(LengthSquared(v));
	[Inline] public static float Distance(Vector3 a, Vector3 b) => Length(b - a);

	public static Vector3 Normalized(Vector3 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return .();
		return .(v.R * (1.0f / Sqrt(lengthSq)));
	}

	[Inline] public static Vector3 Lerp(Vector3 a, Vector3 b, float t) => a + (b - a) * t;
	[Inline] public static Vector3 Min(Vector3 a, Vector3 b) => .(float4.Min(a.R, b.R));
	[Inline] public static Vector3 Max(Vector3 a, Vector3 b) => .(float4.Max(a.R, b.R));
}
