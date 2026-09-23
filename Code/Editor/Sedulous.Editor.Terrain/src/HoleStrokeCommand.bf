using System;
using System.Collections;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// One hole stroke as one undo step: the touched region of the hole PLANE before and after,
/// written back with a version bump so the chunk meshes, the collider and the grass follow.
///
/// The grid is held through the terrain's reference, retained while this lives, so a re-cook
/// that drops the handle leaves a no op behind rather than a dangling write. A region the
/// current grid cannot hold, the size having changed under it, is skipped the same way.
class HoleStrokeCommand : EditorCommand
{
	private Ref<Heightfield> mGrid;
	private HeightfieldRegion mRegion;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(Ref<Heightfield> grid, HeightfieldRegion region, Span<uint8> before,
		Span<uint8> after)
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

	/// A no op on the push, the stroke having already cut it, and the replay on a redo.
	public override bool Execute()
	{
		Write(mAfter);
		return !mRegion.IsEmpty;
	}

	public override void Undo() => Write(mBefore);
	public override StringView TypeId => "terrain.hole.stroke";

	private void Write(List<uint8> block)
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
			{
				grid.SetHole(mRegion.MinX + x, mRegion.MinZ + z,
					block[(int)z * (int)w + (int)x] != 0);
			}
		}
		grid.BumpVersion();
	}

	/// The region's plane bytes out of the whole grid, row major over the region.
	public static void SliceRegion(Span<uint8> full, int32 gridSize, HeightfieldRegion region,
		List<uint8> outBlock)
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
