using System;
using System.Diagnostics;

namespace Sedulous.Core;

/// 3D float vector: arithmetic, Dot/Cross/Length/Normalized, Min/Max, Lerp, component
/// constants. Converts from Float2.
[CRepr]
[Scriptable(.AllPublic)]
struct Float3
{
	public float X = 0.0f;
	public float Y = 0.0f;
	public float Z = 0.0f;

	[Inline]
	[Scriptable]
	public this() { }
	[Inline]
	[Scriptable]
	public this(float x, float y, float z) { this.X = x; this.Y = y; this.Z = z; }
	[Inline]
	[Scriptable]
	public this(float s) { this.X = s; this.Y = s; this.Z = s; }
	[Inline]
	[Scriptable]
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

	[Inline]
	public static Float3 operator-(Float3 v) => .(-v.X, -v.Y, -v.Z);

	[Inline]
	public void operator+=(Float3 r) mut { X += r.X; Y += r.Y; Z += r.Z; }
	[Inline]
	public void operator-=(Float3 r) mut { X -= r.X; Y -= r.Y; Z -= r.Z; }
	[Inline]
	public void operator*=(float s) mut { X *= s; Y *= s; Z *= s; }
	[Inline]
	public void operator/=(float s) mut { X /= s; Y /= s; Z /= s; }

	[Inline]
	public static Float3 operator+(Float3 a, Float3 b) => .(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
	[Inline]
	public static Float3 operator-(Float3 a, Float3 b) => .(a.X - b.X, a.Y - b.Y, a.Z - b.Z);
	/// Component-wise, not a dot or a cross.
	[Inline]
	public static Float3 operator*(Float3 a, Float3 b) => .(a.X * b.X, a.Y * b.Y, a.Z * b.Z);
	[Inline]
	public static Float3 operator*(Float3 v, float s) => .(v.X * s, v.Y * s, v.Z * s);
	[Inline]
	public static Float3 operator*(float s, Float3 v) => .(v.X * s, v.Y * s, v.Z * s);
	[Inline]
	public static Float3 operator/(Float3 v, float s) => .(v.X / s, v.Y / s, v.Z / s);
	/// Component-wise.
	[Inline]
	public static Float3 operator/(Float3 a, Float3 b) => .(a.X / b.X, a.Y / b.Y, a.Z / b.Z);
	/// [Commutable] so Beef can derive != from this one declaration. Without it every use
	/// of != warns, and a warning costs the whole incremental build.
	[Commutable]
	[Inline]
	public static bool operator==(Float3 a, Float3 b) =>
		(a.X == b.X) && (a.Y == b.Y) && (a.Z == b.Z);
}

static
{
	[Scriptable]
	[Inline]
	public static float Dot(Float3 a, Float3 b) => a.X * b.X + a.Y * b.Y + a.Z * b.Z;

	[Scriptable]
	[Inline]
	public static Float3 Cross(Float3 a, Float3 b) => .(
		a.Y * b.Z - a.Z * b.Y,
		a.Z * b.X - a.X * b.Z,
		a.X * b.Y - a.Y * b.X);

	[Scriptable]
	[Inline] public static float LengthSquared(Float3 v) => Dot(v, v);
	[Scriptable]
	[Inline] public static float Length(Float3 v) => Sqrt(LengthSquared(v));
	[Scriptable]
	[Inline] public static float Distance(Float3 a, Float3 b) => Length(b - a);

	/// A unit vector, or Zero when the input is near-zero length.
	[Scriptable]
	public static Float3 Normalized(Float3 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return Float3.Zero;
		return v / Sqrt(lengthSq);
	}

	[Scriptable]
	[Inline]
	public static Float3 Lerp(Float3 a, Float3 b, float t) => a + (b - a) * t;

	[Scriptable]
	public static Float3 Min(Float3 a, Float3 b) => .(
		a.X < b.X ? a.X : b.X,
		a.Y < b.Y ? a.Y : b.Y,
		a.Z < b.Z ? a.Z : b.Z);

	[Scriptable]
	public static Float3 Max(Float3 a, Float3 b) => .(
		a.X > b.X ? a.X : b.X,
		a.Y > b.Y ? a.Y : b.Y,
		a.Z > b.Z ? a.Z : b.Z);

	[Scriptable]
	public static bool NearlyEqual(Float3 a, Float3 b, float epsilon = Epsilon) =>
		NearlyEqual(a.X, b.X, epsilon) &&
		NearlyEqual(a.Y, b.Y, epsilon) &&
		NearlyEqual(a.Z, b.Z, epsilon);
}
