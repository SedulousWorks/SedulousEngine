using System;

namespace Sedulous.Core;

/// Scalar math foundation: constants and float functions.
///
/// Packed vector and matrix types live in Float2/Float3/Float4/Float3x3/Float4x4; the
/// aligned SIMD types are separate. Conventions throughout: row major matrices, row
/// vectors, XNA style.
///
/// These are free functions in an anonymous static block, which is how namespace-scope
/// functions are spelled in Beef. Comptime reflects the block directly, so no empty
/// `struct Math` is needed for scripts to hang the statics on.
///
/// Abs is overloaded for the integer widths as well as the floats. Beef has no implicit
/// narrowing, so the overloads buy no safety; they are kept because index and pixel code
/// reads better calling Abs than writing the conditional.
static
{
	public const float Pi = 3.14159265358979323846f;
	public const float TwoPi = 2.0f * Pi;
	public const float HalfPi = 0.5f * Pi;
	public const float InvPi = 1.0f / Pi;
	public const float DegToRad = Pi / 180.0f;
	public const float RadToDeg = 180.0f / Pi;
	public const float Epsilon = 1.0e-6f;
	public const float FloatMax = 3.402823466e38f;

	// A script has one float and one integer, so only one Abs of each crosses; the double
	// and int64 overloads are the same callable at the boundary.
	[Scriptable]
	[Inline] public static float Abs(float x) => x < 0.0f ? -x : x;
	[Inline] public static double Abs(double x) => x < 0.0 ? -x : x;
	[Scriptable]
	[Inline] public static int32 Abs(int32 x) => x < 0 ? -x : x;
	[Inline] public static int64 Abs(int64 x) => x < 0 ? -x : x;

	[Scriptable]
	[Inline] public static float Sqrt(float x) => (float)System.Math.Sqrt(x);
	[Scriptable]
	[Inline] public static float Sin(float x) => (float)System.Math.Sin(x);
	[Scriptable]
	[Inline] public static float Cos(float x) => (float)System.Math.Cos(x);
	[Scriptable]
	[Inline] public static float Tan(float x) => (float)System.Math.Tan(x);
	[Scriptable]
	[Inline] public static float Asin(float x) => (float)System.Math.Asin(x);
	[Scriptable]
	[Inline] public static float Acos(float x) => (float)System.Math.Acos(x);
	[Scriptable]
	[Inline] public static float Atan2(float y, float x) => (float)System.Math.Atan2(y, x);
	[Scriptable]
	[Inline] public static float Floor(float x) => (float)System.Math.Floor(x);
	[Scriptable]
	[Inline] public static float Ceil(float x) => (float)System.Math.Ceiling(x);
	[Scriptable]
	[Inline] public static float Pow(float b, float exp) => (float)System.Math.Pow(b, exp);
	/// Natural log.
	[Scriptable]
	[Inline] public static float Log(float x) => (float)System.Math.Log(x);
	/// Base ten log. Delegated rather than written as Log(x) / Log(10), which loses the exactness
	/// at powers of ten that anything picking a decade depends on.
	[Scriptable]
	[Inline] public static float Log10(float x) => (float)System.Math.Log10(x);
	[Scriptable]
	[Inline] public static float Exp(float x) => (float)System.Math.Exp(x);

	/// Rounds half away from zero, matching C's round rather than banker's rounding.
	///
	/// Delegated rather than written as Floor(x + 0.5f), which is wrong: for the largest
	/// float below 0.5 the addition rounds up to exactly 1.0f and the result comes back
	/// as 1 instead of 0. corlib's Round is extern and lands on roundf, which has the
	/// tie rule this wants.
	[Scriptable]
	[Inline]
	public static float Round(float x) => System.Math.Round(x);

	[Scriptable]
	[Inline] public static float DegreesToRadians(float degrees) => degrees * DegToRad;
	[Scriptable]
	[Inline] public static float RadiansToDegrees(float radians) => radians * RadToDeg;

	[Scriptable]
	[Inline] public static float Lerp(float a, float b, float t) => a + (b - a) * t;

	[Scriptable]
	[Inline]
	public static bool NearlyEqual(float a, float b, float epsilon = Epsilon) =>
		Abs(a - b) <= epsilon;

	[Scriptable]
	[Inline]
	public static bool NearlyZero(float x, float epsilon = Epsilon) => Abs(x) <= epsilon;
}
