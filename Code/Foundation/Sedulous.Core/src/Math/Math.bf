using System;

namespace Sedulous.Core;

/// Scalar math foundation: constants and float functions.
///
/// Packed vector and matrix types live in Float2/Float3/Float4/Float3x3/Float4x4; the
/// aligned SIMD types are separate. Conventions throughout: row major matrices, row
/// vectors, XNA style.
///
/// These are free functions in an anonymous static block, which is how Raptor's
/// namespace-scope functions are spelled in Beef. Raptor also carries an empty `struct
/// Math` so scripts have something to hang the reflected statics on, because C++ cannot
/// reflect a namespace. Comptime reflects this block directly, so the anchor is not
/// ported.
///
/// Raptor overloads Abs for i32/i64/f64 so integer arguments do not silently narrow
/// through the float version, which MSVC warns about as C4244. Beef has no implicit
/// narrowing, so those overloads carry no safety here; they are kept because index and
/// pixel code reads better calling Abs than writing the conditional.
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

	[Inline] public static float Abs(float x) => x < 0.0f ? -x : x;
	[Inline] public static double Abs(double x) => x < 0.0 ? -x : x;
	[Inline] public static int32 Abs(int32 x) => x < 0 ? -x : x;
	[Inline] public static int64 Abs(int64 x) => x < 0 ? -x : x;

	[Inline] public static float Sqrt(float x) => (float)System.Math.Sqrt(x);
	[Inline] public static float Sin(float x) => (float)System.Math.Sin(x);
	[Inline] public static float Cos(float x) => (float)System.Math.Cos(x);
	[Inline] public static float Tan(float x) => (float)System.Math.Tan(x);
	[Inline] public static float Asin(float x) => (float)System.Math.Asin(x);
	[Inline] public static float Acos(float x) => (float)System.Math.Acos(x);
	[Inline] public static float Atan2(float y, float x) => (float)System.Math.Atan2(y, x);
	[Inline] public static float Floor(float x) => (float)System.Math.Floor(x);
	[Inline] public static float Ceil(float x) => (float)System.Math.Ceiling(x);
	[Inline] public static float Pow(float b, float exp) => (float)System.Math.Pow(b, exp);
	/// Natural log.
	[Inline] public static float Log(float x) => (float)System.Math.Log(x);
	/// Base ten log. Delegated rather than written as Log(x) / Log(10), which loses the exactness
	/// at powers of ten that anything picking a decade depends on.
	[Inline] public static float Log10(float x) => (float)System.Math.Log10(x);
	[Inline] public static float Exp(float x) => (float)System.Math.Exp(x);

	/// Rounds half away from zero, matching C's round rather than banker's rounding.
	///
	/// Delegated rather than written as Floor(x + 0.5f), which is wrong: for the largest
	/// float below 0.5 the addition rounds up to exactly 1.0f and the result comes back
	/// as 1 instead of 0. corlib's Round is extern and lands on roundf, which has the
	/// tie rule this wants.
	[Inline]
	public static float Round(float x) => System.Math.Round(x);

	[Inline] public static float DegreesToRadians(float degrees) => degrees * DegToRad;
	[Inline] public static float RadiansToDegrees(float radians) => radians * RadToDeg;

	[Inline] public static float Lerp(float a, float b, float t) => a + (b - a) * t;

	[Inline]
	public static bool NearlyEqual(float a, float b, float epsilon = Epsilon) =>
		Abs(a - b) <= epsilon;

	[Inline]
	public static bool NearlyZero(float x, float epsilon = Epsilon) => Abs(x) <= epsilon;
}
