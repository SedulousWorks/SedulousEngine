using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Terrain.Resource;

/// The editable terrain splat weights: the TOP FOUR blend model.
///
/// Two equal sized rasters over the terrain's zero to one footprint hold, per texel, up to
/// four (palette index, weight) pairs. A slot is unused exactly when its weight is zero, and
/// the BASE layer implicitly owns whatever the weights do not: an all zero raster is a valid
/// pure base surface by construction, so nothing needs seeding.
///
/// This is the CPU SOURCE OF TRUTH, the way the heightfield is. The GPU textures are derived
/// from it and keyed by identity and version.
class SplatWeights
{
	/// Layers blended per TEXEL.
	///
	/// The palette itself is unbounded up to what an eight bit index holds, which is 256:
	/// exactly the minimum array layer count the graphics API guarantees. Do not widen the
	/// index without checking that limit.
	public const uint32 SlotCount = 4;

	private static int64 sNextUid;

	private int32 mWidth = 0;
	private int32 mHeight = 0;
	private uint64 mVersion = 1;
	/// Four palette indices per texel, row major.
	private List<uint8> mIndices = new .() ~ delete _;
	/// Four weights per texel, row major, summing to at most 255.
	private List<uint8> mWeights = new .() ~ delete _;

	/// Unique per INSTANCE. A GPU cache keys on this and the version, never on the
	/// reference: a freed raster's address can come back as a fresh one at an equal version.
	public readonly uint64 Uid = NextUid();

	public static uint64 NextUid() => (uint64)Interlocked.Increment(ref sNextUid);

	public this() {}

	/// An all zero pair of rasters, which is pure BASE everywhere.
	public this(int32 width, int32 height)
	{
		mWidth = width;
		mHeight = height;

		let bytes = (int)width * (int)height * (int)SlotCount;
		mIndices.Resize(bytes);
		mWeights.Resize(bytes);
	}

	public bool IsEmpty => (mWidth <= 0) || (mHeight <= 0);
	public int32 Width => mWidth;
	public int32 Height => mHeight;

	/// A monotonic edit generation, starting at one. Bumped after a paint so the GPU splat
	/// textures re-upload.
	public uint64 Version => mVersion;
	public void BumpVersion()
	{
		mVersion++;
	}

	public Span<uint8> Indices => .(mIndices.Ptr, mIndices.Count);
	public Span<uint8> Weights => .(mWeights.Ptr, mWeights.Count);

	/// The texel clamped, slot masked accessors. A slot means something only when its weight
	/// is above zero.
	public uint8 SlotIndex(int32 x, int32 y, uint32 slot) => mIndices[TexelOffset(x, y) + (int)(slot & 3)];
	public uint8 SlotWeight(int32 x, int32 y, uint32 slot) => mWeights[TexelOffset(x, y) + (int)(slot & 3)];

	/// What this texel gives a PALETTE layer, or zero when no slot holds it.
	public uint8 WeightOfLayer(int32 x, int32 y, uint32 paletteIndex)
	{
		let at = TexelOffset(x, y);
		for (int k < (int)SlotCount)
		{
			if ((mWeights[at + k] > 0) && (mIndices[at + k] == paletteIndex))
				return mWeights[at + k];
		}
		return 0;
	}

	/// The implicit BASE weight at a texel, which is whatever the slots left over.
	public uint8 BaseWeight(int32 x, int32 y)
	{
		let at = TexelOffset(x, y);
		var sum = 0;
		for (int k < (int)SlotCount)
			sum += mWeights[at + k];

		return (uint8)((sum >= 255) ? 0 : (255 - sum));
	}

	/// Where a texel's four slots begin, with the coordinates clamped into the raster.
	public int TexelOffset(int32 x, int32 y)
	{
		let cx = Clamp(x, 0, mWidth - 1);
		let cy = Clamp(y, 0, mHeight - 1);
		return ((int)cy * (int)mWidth + (int)cx) * (int)SlotCount;
	}
}
