using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 4D float vector: arithmetic, Dot/Length/Normalized, XYZ, component constants.
/// Converts from Float3.
[CRepr]
struct Float4
{
	public float X = 0.0f;
	public float Y = 0.0f;
	public float Z = 0.0f;
	public float W = 0.0f;

	public this() { }
	public this(float x, float y, float z, float w)
	{
		this.X = x; this.Y = y; this.Z = z; this.W = w;
	}
	public this(float s) { this.X = s; this.Y = s; this.Z = s; this.W = s; }
	public this(Float3 xyz, float w)
	{
		this.X = xyz.X; this.Y = xyz.Y; this.Z = xyz.Z; this.W = w;
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
			case 0: return X;
			case 1: return Y;
			case 2: return Z;
			default: return W;
			}
		}
		[Inline] set mut
		{
			Debug.Assert((i >= 0) && (i < 4));
			switch (i)
			{
			case 0: X = value;
			case 1: Y = value;
			case 2: Z = value;
			default: W = value;
			}
		}
	}

	[Inline] public Float3 XYZ() => .(X, Y, Z);

	public static Float4 operator-(in Float4 v) => .(-v.X, -v.Y, -v.Z, -v.W);

	public void operator+=(Float4 r) mut { X += r.X; Y += r.Y; Z += r.Z; W += r.W; }
	public void operator-=(Float4 r) mut { X -= r.X; Y -= r.Y; Z -= r.Z; W -= r.W; }
	public void operator*=(float s) mut { X *= s; Y *= s; Z *= s; W *= s; }

	public static Float4 operator+(in Float4 a, in Float4 b) =>
		.(a.X + b.X, a.Y + b.Y, a.Z + b.Z, a.W + b.W);
	public static Float4 operator-(in Float4 a, in Float4 b) =>
		.(a.X - b.X, a.Y - b.Y, a.Z - b.Z, a.W - b.W);
	public static Float4 operator*(in Float4 v, float s) => .(v.X * s, v.Y * s, v.Z * s, v.W * s);
	public static Float4 operator*(float s, in Float4 v) => .(v.X * s, v.Y * s, v.Z * s, v.W * s);
	/// [Commutable] so Beef can derive != from this one declaration. Without it every use
	/// of != warns, and a warning costs the whole incremental build.
	[Commutable]
	public static bool operator==(in Float4 a, in Float4 b) =>
		(a.X == b.X) && (a.Y == b.Y) && (a.Z == b.Z) && (a.W == b.W);
}

static
{
	[Inline]
	public static float Dot(in Float4 a, in Float4 b) =>
		a.X * b.X + a.Y * b.Y + a.Z * b.Z + a.W * b.W;

	[Inline] public static float LengthSquared(in Float4 v) => Dot(v, v);
	[Inline] public static float Length(in Float4 v) => Sqrt(LengthSquared(v));

	/// A unit vector, or Zero when the input is near-zero length.
	public static Float4 Normalized(in Float4 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return Float4.Zero;
		return v * (1.0f / Sqrt(lengthSq));
	}

	[Inline]
	public static Float4 Lerp(in Float4 a, in Float4 b, float t) => a + (b - a) * t;

	public static bool NearlyEqual(in Float4 a, in Float4 b, float epsilon = Epsilon) =>
		NearlyEqual(a.X, b.X, epsilon) &&
		NearlyEqual(a.Y, b.Y, epsilon) &&
		NearlyEqual(a.Z, b.Z, epsilon) &&
		NearlyEqual(a.W, b.W, epsilon);
}
