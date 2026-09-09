using System;

namespace Sedulous.Render;

/// The draw list's sort keys.
///
/// A sixty four bit key with its fields ordered by SIGNIFICANCE, so one ascending sort puts
/// the draws in the order the frame wants: the category groups draws by the renderer that
/// draws them, the state bits cluster identical pipelines together so the state changes
/// between them are few, and the depth orders within that, front to back for opaque work and
/// back to front for blended, which the producer inverts before packing.
static class SortKeys
{
	public const uint32 DepthBits = 24;
	public const uint32 StateBits = 24;

	/// Folds two borrowed resource identities into the clustering key.
	///
	/// Pointer derived, which is fine for a key that lives one frame: the renderer checks
	/// exact equality again before it fuses two draws, so a collision costs a fusion that
	/// did not happen rather than a draw that was wrong.
	public static uint32 BatchKey(void* first, void* second)
	{
		let a = (uint64)(int)first;
		let b = (uint64)(int)second;
		let mixed = (a >> 4) &* 1099511628211UL &+ (b >> 4);
		return (uint32)(mixed & ((1UL << StateBits) - 1));
	}

	public static uint64 MakeSortKey(uint16 category, uint32 stateBits, uint32 depthBits)
	{
		let categoryPart = (uint64)category;
		let statePart = (uint64)stateBits & ((1UL << StateBits) - 1);
		let depthPart = (uint64)depthBits & ((1UL << DepthBits) - 1);
		return (categoryPart << (StateBits + DepthBits)) | (statePart << DepthBits) | depthPart;
	}

	/// Quantises a normalised depth into the key's depth field, inverting it for the back to
	/// front categories.
	public static uint32 QuantizeDepth(float depth01, bool invert)
	{
		var depth = Math.Clamp(depth01, 0.0f, 1.0f);
		if (invert)
			depth = 1.0f - depth;

		const uint32 cMax = (1U << DepthBits) - 1;
		return (uint32)(depth * (float)cMax);
	}
}
