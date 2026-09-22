using System;
using System.Collections;
using Sedulous.Resource;
using Sedulous.Vegetation.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Vegetation;

/// One paint stroke as one undo step: the touched region of ONE mask plane, before and
/// after, written back with a version bump so the scatter regrows.
///
/// The mask is held through the component's reference, retained while this lives, so a
/// re-cook that drops the handle leaves a no op behind; a region the current mask cannot
/// hold is skipped the same way.
///
/// Undo and redo RE-NOTIFY the region, since the chunks that regrew on the way in have to
/// regrow on the way back out.
class VegetationStrokeCommand : EditorCommand
{
	private Ref<VegetationMask> mMask;
	private uint32 mPlane;
	private MaskRegion mRegion;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;
	/// Re-notifies the region so the affected chunks regrow. Owned.
	private delegate void(MaskRegion region) mNotify ~ delete _;

	/// CONSUMES `notify`.
	public this(Ref<VegetationMask> mask, uint32 plane, MaskRegion region, Span<uint8> before,
		Span<uint8> after, delegate void(MaskRegion region) notify)
	{
		mMask = mask;
		mMask.Retain();
		mPlane = plane;
		mRegion = region;
		mBefore.AddRange(before);
		mAfter.AddRange(after);
		mNotify = notify;
	}

	public ~this()
	{
		mMask.Forget();
	}

	public override bool Execute()
	{
		Write(mAfter);
		return !mRegion.IsEmpty;
	}

	public override void Undo() => Write(mBefore);
	public override StringView TypeId => "vegetation.paint.stroke";

	private void Write(List<uint8> block)
	{
		let mask = mMask.Get;
		if ((mask == null) || mask.IsEmpty || mRegion.IsEmpty)
			return;
		if ((mRegion.MaxX >= mask.Width) || (mRegion.MaxY >= mask.Height))
			return;

		let plane = mask.Plane(mPlane);
		if (plane.IsEmpty)
			return;

		let w = mRegion.Width;
		for (int32 y < mRegion.Height)
		{
			for (int32 x < w)
			{
				let src = (int)y * (int)w + (int)x;
				let dst = (int)(mRegion.MinY + y) * (int)mask.Width + (int)(mRegion.MinX + x);
				plane[dst] = block[src];
			}
		}
		mask.BumpVersion();

		if (mNotify != null)
			mNotify(mRegion);
	}

	/// The region's texels out of a whole plane, row major over the region.
	public static void SliceRegion(Span<uint8> plane, int32 rasterWidth, MaskRegion region,
		List<uint8> outBlock)
	{
		outBlock.Clear();
		if (region.IsEmpty)
			return;

		let w = region.Width;
		let h = region.Height;
		outBlock.Resize((int)w * (int)h);
		for (int32 y < h)
		{
			for (int32 x < w)
			{
				let src = (int)(region.MinY + y) * (int)rasterWidth + (int)(region.MinX + x);
				outBlock[(int)y * (int)w + (int)x] = plane[src];
			}
		}
	}
}
