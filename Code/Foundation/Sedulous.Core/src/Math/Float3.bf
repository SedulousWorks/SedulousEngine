using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 3D float vector: arithmetic, Dot/Cross/Length/Normalized, Min/Max, Lerp, component
/// constants. Converts from Float2.
[CRepr]
struct Float3
{
	public float X = 0.0f;
	public float Y = 0.0f;
	public float Z = 0.0f;

	public this() { }
	public this(float x, float y, float z) { this.X = x; this.Y = y; this.Z = z; }
	public this(float s) { this.X = s; this.Y = s; this.Z = s; }
	public this(Float2 xy, float z) { this.X = xy.X; this.Y = xy.Y; this.Z = z; }

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
			return (i == 0) ? X : ((i == 1) ? Y : Z);
		}
		[Inline] set mut
		{
			Debug.Assert((i >= 0) && (i < 3));
			if (i == 0) X = value; else if (i == 1) Y = value; else Z = value;
		}
	}

	public static Float3 operator-(Float3 v) => .(-v.X, -v.Y, -v.Z);

	public void operator+=(Float3 r) mut { X += r.X; Y += r.Y; Z += r.Z; }
	public void operator-=(Float3 r) mut { X -= r.X; Y -= r.Y; Z -= r.Z; }
	public void operator*=(float s) mut { X *= s; Y *= s; Z *= s; }
	public void operator/=(float s) mut { X /= s; Y /= s; Z /= s; }

	public static Float3 operator+(Float3 a, Float3 b) => .(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
	public static Float3 operator-(Float3 a, Float3 b) => .(a.X - b.X, a.Y - b.Y, a.Z - b.Z);
	/// Component-wise, not a dot or a cross.
	public static Float3 operator*(Float3 a, Float3 b) => .(a.X * b.X, a.Y * b.Y, a.Z * b.Z);
	public static Float3 operator*(Float3 v, float s) => .(v.X * s, v.Y * s, v.Z * s);
	public static Float3 operator*(float s, Float3 v) => .(v.X * s, v.Y * s, v.Z * s);
	public static Float3 operator/(Float3 v, float s) => .(v.X / s, v.Y / s, v.Z / s);
	/// Component-wise.
	public static Float3 operator/(Float3 a, Float3 b) => .(a.X / b.X, a.Y / b.Y, a.Z / b.Z);
	/// [Commutable] so Beef can derive != from this one declaration. Without it every use
	/// of != warns, and a warning costs the whole incremental build.
	[Commutable]
	public static bool operator==(Float3 a, Float3 b) =>
		(a.X == b.X) && (a.Y == b.Y) && (a.Z == b.Z);
}

static
{
	// IN, not by value. Beef materialises a by value struct argument in memory even for an
	// inlined call, and these run millions of times a frame: the shadow cascade cull measured
	// 10.8 ns a caster by value against 4.9 with in, where writing the same arithmetic out by
	// hand is 3.2. See Tools/Sedulous.Tools.CullBench.
	[Inline]
	public static float Dot(in Float3 a, in Float3 b) => a.X * b.X + a.Y * b.Y + a.Z * b.Z;

	[Inline]
	public static Float3 Cross(in Float3 a, in Float3 b) => .(
		a.Y * b.Z - a.Z * b.Y,
		a.Z * b.X - a.X * b.Z,
		a.X * b.Y - a.Y * b.X);

	[Inline] public static float LengthSquared(in Float3 v) => Dot(v, v);
	[Inline] public static float Length(in Float3 v) => Sqrt(LengthSquared(v));
	[Inline] public static float Distance(in Float3 a, in Float3 b) => Length(b - a);

	/// A unit vector, or Zero when the input is near-zero length.
	public static Float3 Normalized(in Float3 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return Float3.Zero;
		return v / Sqrt(lengthSq);
	}

	[Inline]
	public static Float3 Lerp(in Float3 a, in Float3 b, float t) => a + (b - a) * t;

	public static Float3 Min(in Float3 a, in Float3 b) => .(
		a.X < b.X ? a.X : b.X,
		a.Y < b.Y ? a.Y : b.Y,
		a.Z < b.Z ? a.Z : b.Z);

	public static Float3 Max(in Float3 a, in Float3 b) => .(
		a.X > b.X ? a.X : b.X,
		a.Y > b.Y ? a.Y : b.Y,
		a.Z > b.Z ? a.Z : b.Z);

	public static bool NearlyEqual(in Float3 a, in Float3 b, float epsilon = Epsilon) =>
		NearlyEqual(a.X, b.X, epsilon) &&
		NearlyEqual(a.Y, b.Y, epsilon) &&
		NearlyEqual(a.Z, b.Z, epsilon);
}
