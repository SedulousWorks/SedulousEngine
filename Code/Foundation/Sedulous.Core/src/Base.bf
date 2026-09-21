using System;

namespace Sedulous.Core;

/// The small generic helpers everything else leans on.
///
/// No integer or float aliases (i32, f32, usize): they exist where a language spells its
/// fixed-width types awkwardly, and Beef's int32/float/int already say exactly what they
/// mean.
static
{
	/// Generic ordering helpers. The Float3 overloads in Float3.bf are component-wise
	/// and sit in the same overload set.
	public static T Min<T>(T a, T b)
		where bool : operator T < T
	{
		return a < b ? a : b;
	}

	public static T Max<T>(T a, T b)
		where bool : operator T > T
	{
		return a > b ? a : b;
	}

	/// Constrained on the comparisons rather than on a named interface, so it works for
	/// any type that orders, including the vector types when they grow comparisons.
	public static T Clamp<T>(T v, T lo, T hi)
		where bool : operator T < T
		where bool : operator T > T
	{
		if (v < lo)
			return lo;
		if (v > hi)
			return hi;
		return v;
	}
}
