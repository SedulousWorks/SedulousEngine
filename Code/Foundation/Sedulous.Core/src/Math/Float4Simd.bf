using System;

namespace System.Numerics;

/// The two float4 operations Raptor's f32x4 has and corlib's does not.
///
/// Extended rather than wrapped, because everything else in that type is already what the
/// SIMD vectors want, and a wrapper would exist only to carry these two. Both are what LLVM
/// would emit for the same expression written inline; naming them stops the same fold being
/// rewritten at every call site.
extension float4
{
	/// Unary minus. corlib declares operator-(float4, float4) and operator-(float, float4) but
	/// no unary form, so `-v` does not compile without this.
	[Inline]
	public static float4 operator-(float4 v) => 0.0f - v;

	/// Horizontal sum: every lane added together, Raptor's HSum4.
	///
	/// There is no horizontal add in the portable vector set, so the sum FOLDS: add the pair
	/// swapped halves to get x+z and y+w in the low lanes, then add those two. Two shuffles
	/// rather than four extracts.
	[Inline]
	public static float HorizontalSum(float4 v)
	{
		let folded = v + ShuffleVector(v, 2, 3, 0, 1);
		return folded.x + folded.y;
	}
}
