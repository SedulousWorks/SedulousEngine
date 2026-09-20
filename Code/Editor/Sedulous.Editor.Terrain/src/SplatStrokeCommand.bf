using System;
using System.Collections;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// One splat stroke as one undo step: the touched region of BOTH rasters, weights and
/// slot indices, before and after, written back with a version bump so the GPU splat
/// textures re-upload. Restoring one raster without the other would land every weight on
/// the wrong layer.
///
/// The rasters are held through the terrain's reference, retained while this lives, so a
/// re-cook that drops the handle leaves a no-op behind; a region the current rasters
/// cannot hold is skipped the same way.
class SplatStrokeCommand : EditorCommand
{
	private Ref<SplatWeights> mWeights;
	private SplatRegion mRegion;
	private List<uint8> mBeforeWeights = new .() ~ delete _;
	private List<uint8> mAfterWeights = new .() ~ delete _;
	private List<uint8> mBeforeIndices = new .() ~ delete _;
	private List<uint8> mAfterIndices = new .() ~ delete _;

	public this(Ref<SplatWeights> weights, SplatRegion region, Span<uint8> beforeWeights, Span<uint8> afterWeights,
		Span<uint8> beforeIndices, Span<uint8> afterIndices)
	{
		mWeights = weights;
		mWeights.Retain();
		mRegion = region;
		mBeforeWeights.AddRange(beforeWeights);
		mAfterWeights.AddRange(afterWeights);
		mBeforeIndices.AddRange(beforeIndices);
		mAfterIndices.AddRange(afterIndices);
	}

	public ~this()
	{
		mWeights.Forget();
	}

	public override bool Execute()
	{
		Write(mAfterWeights, mAfterIndices);
		return !mRegion.IsEmpty;
	}

	public override void Undo() => Write(mBeforeWeights, mBeforeIndices);
	public override StringView TypeId => "terrain.splat.stroke";

	private void Write(List<uint8> weightBlock, List<uint8> indexBlock)
	{
		let weights = mWeights.Get;
		if ((weights == null) || weights.IsEmpty || mRegion.IsEmpty)
			return;
		if ((mRegion.MaxX >= weights.Width) || (mRegion.MaxY >= weights.Height))
			return;
		let w = mRegion.Width;
		let slots = (int)SplatWeights.SlotCount;
		let dstW = weights.Weights;
		let dstI = weights.Indices;
		for (int32 y < mRegion.Height)
		{
			for (int32 x < w)
			{
				let src = ((int)y * (int)w + (int)x) * slots;
				let dst = weights.TexelOffset(mRegion.MinX + x, mRegion.MinY + y);
				for (int k < slots)
				{
					dstW[dst + k] = weightBlock[src + k];
					dstI[dst + k] = indexBlock[src + k];
				}
			}
		}
		weights.BumpVersion();
	}

	/// The region's texels out of a whole raster, row major over the region, four bytes a
	/// texel.
	public static void SliceRegion(Span<uint8> full, int32 rasterWidth, SplatRegion region, List<uint8> outBlock)
	{
		outBlock.Clear();
		if (region.IsEmpty)
			return;
		let w = region.Width;
		let h = region.Height;
		let slots = (int)SplatWeights.SlotCount;
		outBlock.Resize((int)w * (int)h * slots);
		for (int32 y < h)
		{
			for (int32 x < w)
			{
				let src = ((int)(region.MinY + y) * (int)rasterWidth + (int)(region.MinX + x)) * slots;
				let dst = ((int)y * (int)w + (int)x) * slots;
				for (int k < slots)
					outBlock[dst + k] = full[src + k];
			}
		}
	}
}
