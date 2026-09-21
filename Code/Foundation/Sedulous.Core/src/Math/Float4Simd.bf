using System;

namespace System.Numerics;

/// The two float4 operations a matrix transform wants and corlib's float4 does not have.
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

	/// One lane broadcast to all four: SplatX through SplatW.
	///
	/// A shuffle with four equal indices, which is what the hardware broadcast is anyway. Named
	/// because a matrix transform does twelve of them and `ShuffleVector(v, 1, 1, 1, 1)` reads
	/// as an arbitrary permutation rather than as "take y".
	[Inline] public static float4 SplatX(float4 v) => ShuffleVector(v, 0, 0, 0, 0);
	[Inline] public static float4 SplatY(float4 v) => ShuffleVector(v, 1, 1, 1, 1);
	[Inline] public static float4 SplatZ(float4 v) => ShuffleVector(v, 2, 2, 2, 2);
	[Inline] public static float4 SplatW(float4 v) => ShuffleVector(v, 3, 3, 3, 3);

	/// Horizontal sum: every lane added together.
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
