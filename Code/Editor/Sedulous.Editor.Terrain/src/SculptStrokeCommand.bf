using System;
using System.Collections;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// One sculpt stroke as one undo step: the touched region's samples before and after,
/// written back with a version bump so the GPU height texture re-uploads.
///
/// The grid is held through the terrain's reference, retained while this lives, so a
/// re-cook that drops the handle leaves a no-op behind rather than a dangling write. A
/// region the current grid cannot hold, the size changed under it, is skipped the same way.
class SculptStrokeCommand : EditorCommand
{
	private Ref<Heightfield> mGrid;
	private HeightfieldRegion mRegion;
	private List<uint16> mBefore = new .() ~ delete _;
	private List<uint16> mAfter = new .() ~ delete _;

	public this(Ref<Heightfield> grid, HeightfieldRegion region, Span<uint16> before, Span<uint16> after)
	{
		mGrid = grid;
		mGrid.Retain();
		mRegion = region;
		mBefore.AddRange(before);
		mAfter.AddRange(after);
	}

	public ~this()
	{
		mGrid.Forget();
	}

	public override bool Execute()
	{
		Write(mAfter);
		return !mRegion.IsEmpty;
	}

	public override void Undo() => Write(mBefore);
	public override StringView TypeId => "terrain.sculpt.stroke";

	private void Write(List<uint16> block)
	{
		let grid = mGrid.Get;
		if ((grid == null) || mRegion.IsEmpty)
			return;
		if ((mRegion.MaxX >= grid.Size) || (mRegion.MaxZ >= grid.Size))
			return;
		let w = mRegion.Width;
		for (int32 z < mRegion.Height)
		{
			for (int32 x < w)
				grid.SetSample(mRegion.MinX + x, mRegion.MinZ + z, block[(int)z * (int)w + (int)x]);
		}
		grid.BumpVersion();
	}

	/// The region's samples out of the whole grid, row major over the region.
	public static void SliceRegion(Span<uint16> full, int32 gridSize, HeightfieldRegion region, List<uint16> outBlock)
	{
		outBlock.Clear();
		if (region.IsEmpty)
			return;
		let w = region.Width;
		let h = region.Height;
		outBlock.Resize((int)w * (int)h);
		for (int32 z < h)
		{
			for (int32 x < w)
			{
				let src = (int)(region.MinZ + z) * (int)gridSize + (int)(region.MinX + x);
				outBlock[(int)z * (int)w + (int)x] = full[src];
			}
		}
	}
}
