using System;

namespace Sedulous.Core;

/// The pieces of Raptor's Core :base partition that have a Beef counterpart.
///
/// The integer and float aliases (i32, f32, usize) are not ported: they exist because
/// C++ spells its fixed-width types awkwardly, and Beef's int32/float/int already say
/// exactly what they mean.
static
{
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
