using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 2D float vector: arithmetic, Dot/Length/Normalized, Lerp, component constants.
///
/// CRepr because these reach GPU buffers and file formats, where the layout is part of
/// the contract rather than an implementation detail.
[CRepr]
[Scriptable(.AllPublic)]
struct Float2
{
	public float X = 0.0f;
	public float Y = 0.0f;

	[Inline]
	[Scriptable]
	public this() { }
	[Inline]
	[Scriptable]
	public this(float x, float y) { this.X = x; this.Y = y; }
	[Inline]
	[Scriptable]
	public this(float s) { this.X = s; this.Y = s; }

	public const Float2 Zero = .(0.0f, 0.0f);
	public const Float2 One = .(1.0f, 1.0f);
	public const Float2 UnitX = .(1.0f, 0.0f);
	public const Float2 UnitY = .(0.0f, 1.0f);

	public float this[int i]
	{
		[Inline] get
		{
			Debug.Assert((i >= 0) && (i < 2));
			return (i == 0) ? X : Y;
		}
		[Inline] set mut
		{
			Debug.Assert((i >= 0) && (i < 2));
			if (i == 0) X = value; else Y = value;
		}
	}

	[Inline]
	public static Float2 operator-(Float2 v) => .(-v.X, -v.Y);

	[Inline]
	public void operator+=(Float2 r) mut { X += r.X; Y += r.Y; }
	[Inline]
	public void operator-=(Float2 r) mut { X -= r.X; Y -= r.Y; }
	[Inline]
	public void operator*=(float s) mut { X *= s; Y *= s; }
	[Inline]
	public void operator/=(float s) mut { X /= s; Y /= s; }

	[Inline]
	public static Float2 operator+(Float2 a, Float2 b) => .(a.X + b.X, a.Y + b.Y);
	[Inline]
	public static Float2 operator-(Float2 a, Float2 b) => .(a.X - b.X, a.Y - b.Y);
	/// Component-wise, not a dot or a scale.
	[Inline]
	public static Float2 operator*(Float2 a, Float2 b) => .(a.X * b.X, a.Y * b.Y);
	[Inline]
	public static Float2 operator*(Float2 v, float s) => .(v.X * s, v.Y * s);
	[Inline]
	public static Float2 operator*(float s, Float2 v) => .(v.X * s, v.Y * s);
	[Inline]
	public static Float2 operator/(Float2 v, float s) => .(v.X / s, v.Y / s);
	/// [Commutable] so Beef can derive != from this one declaration. Without it every use
	/// of != warns, and a warning costs the whole incremental build.
	[Commutable]
	[Inline]
	public static bool operator==(Float2 a, Float2 b) => (a.X == b.X) && (a.Y == b.Y);
}

static
{
	[Scriptable]
	[Inline] public static float Dot(Float2 a, Float2 b) => a.X * b.X + a.Y * b.Y;

	[Scriptable]
	[Inline] public static float LengthSquared(Float2 v) => Dot(v, v);
	[Scriptable]
	[Inline] public static float Length(Float2 v) => Sqrt(LengthSquared(v));
	[Scriptable]
	[Inline] public static float DistanceSquared(Float2 a, Float2 b) => LengthSquared(b - a);
	[Scriptable]
	[Inline] public static float Distance(Float2 a, Float2 b) => Length(b - a);

	/// A unit vector, or Zero when the input is near-zero length.
	[Scriptable]
	public static Float2 Normalized(Float2 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return Float2.Zero;
		return v / Sqrt(lengthSq);
	}

	[Scriptable]
	[Inline]
	public static Float2 Lerp(Float2 a, Float2 b, float t) => a + (b - a) * t;

	[Scriptable]
	public static bool NearlyEqual(Float2 a, Float2 b, float epsilon = Epsilon) =>
		NearlyEqual(a.X, b.X, epsilon) && NearlyEqual(a.Y, b.Y, epsilon);
}
