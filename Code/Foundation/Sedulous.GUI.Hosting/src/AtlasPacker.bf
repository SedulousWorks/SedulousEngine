using System;
using System.Collections;

namespace Sedulous.GUI;

// ShelfPacker: where the picture baker's atlas puts each picture on a page. Rows (shelves) across
// the page, each as tall as the first picture it took; a picture goes on the lowest shelf it fits
// that wastes the least height (at most a third more than it needs), else on a new shelf under the
// last. A page only fills: what goes leaves its place empty until the atlas packs its page anew
// (Reset), as a font atlas does. Pure arithmetic, no device.

/// A place on a page: its top-left corner in pixels.
struct PackedPlace
{
	public uint32 X = 0;
	public uint32 Y = 0;

	public this() {}

	public this(uint32 x, uint32 y)
	{
		X = x;
		Y = y;
	}
}

class ShelfPacker
{
	private struct Shelf
	{
		public uint32 Top = 0;
		public uint32 Height = 0;
		public uint32 Used = 0; // across, from the left

		public this() {}

		public this(uint32 top, uint32 height)
		{
			Top = top;
			Height = height;
		}
	}

	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	private List<Shelf> mShelves = new .() ~ delete _;
	private uint32 mTop = 0; // under the last shelf
	private uint64 mArea = 0;

	public this(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;
	}

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;

	/// A place for `width` by `height` pixels (the caller's gutter included): its top-left corner,
	/// or null when the page has no room left for it.
	public PackedPlace? Place(uint32 width, uint32 height)
	{
		if ((width == 0) || (height == 0) || (width > mWidth) || (height > mHeight))
			return null;
		int best = -1;
		for (int i < mShelves.Count)
		{
			let shelf = mShelves[i];
			// Widened, so a tall picture's four thirds do not wrap.
			if ((shelf.Height >= height) && ((uint64)shelf.Height * 3 <= (uint64)height * 4)
				&& ((uint64)shelf.Used + width <= mWidth) && ((best < 0) || (shelf.Height < mShelves[best].Height)))
				best = i;
		}
		if (best < 0)
		{
			if ((uint64)mTop + height > mHeight)
				return null;
			mShelves.Add(Shelf(mTop, height));
			mTop += height;
			best = mShelves.Count - 1;
		}
		var shelf = ref mShelves[best];
		let at = PackedPlace(shelf.Used, shelf.Top);
		shelf.Used += width;
		mArea += (uint64)width * height;
		return at;
	}

	/// Empties the page: every place free again.
	public void Reset()
	{
		mShelves.Clear();
		mTop = 0;
		mArea = 0;
	}

	/// The pixels placed since the page was last emptied.
	public uint64 AreaUsed => mArea;
}
