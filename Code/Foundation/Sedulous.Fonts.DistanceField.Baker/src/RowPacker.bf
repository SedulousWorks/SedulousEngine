using System;
using System.Collections;

namespace Sedulous.Fonts.DistanceField.Baker;

/// A shelf packer: cells go left to right along a row, and a new row starts below the
/// tallest cell of the last one.
///
/// A GUTTER is left between cells. The atlas starts zeroed, which reads as fully outside
/// the glyph, so the gutter guarantees that bilinear sampling at a cell's UV edge blends
/// into empty space rather than into the neighbour. Without it, magnified text shows
/// flickering seams where one glyph's field bleeds into the next.
struct RowPacker
{
	public const uint32 CellGutter = 2;

	public uint32 AtlasWidth;
	public uint32 AtlasHeight;

	private uint32 mCursorX;
	private uint32 mCursorY;
	private uint32 mRowHeight;

	/// The extent the packed cells reach, which is the atlas the cells actually need.
	public uint32 UsedWidth { get; private set mut; }
	public uint32 UsedHeight { get; private set mut; }

	public this(uint32 atlasWidth, uint32 atlasHeight)
	{
		AtlasWidth = atlasWidth;
		AtlasHeight = atlasHeight;
		mCursorX = 0;
		mCursorY = 0;
		mRowHeight = 0;
		UsedWidth = 0;
		UsedHeight = 0;
	}

	/// Places a cell, or returns false when the atlas is full or the cell is wider than it. Deterministic: the same
	/// sequence of sizes always lands in the same places, which is what lets the expensive
	/// field generation run out of order afterwards without moving anything.
	public bool TryPack(uint32 width, uint32 height, out uint32 x, out uint32 y) mut
	{
		x = 0;
		y = 0;

		if ((mCursorX + width) > AtlasWidth)
		{
			mCursorX = 0;
			mCursorY += mRowHeight + CellGutter;
			mRowHeight = 0;
		}
		if ((width > AtlasWidth) || ((mCursorY + height) > AtlasHeight))
			return false;

		x = mCursorX;
		y = mCursorY;
		mCursorX += width + CellGutter;
		if (height > mRowHeight)
			mRowHeight = height;
		UsedWidth = Math.Max(UsedWidth, x + width);
		UsedHeight = Math.Max(UsedHeight, y + height);
		return true;
	}
}

/// Sizing an atlas to its cells: the asset's atlas size is a maximum, and a Latin set at 48 px
/// needs a fraction of 1024 x 1024, every texel of which ships.
static class AtlasSizing
{
	/// Atlas sides are rounded up to this, so the atlas stays block compressible (4x4 blocks).
	public const uint32 SideMultiple = 4;
	/// The narrowest width tried.
	public const uint32 SmallestTriedWidth = 64;

	public static uint32 RoundUp(uint32 value, uint32 multiple) => (value + multiple - 1) / multiple * multiple;

	/// Packs every cell, in order, into an atlas `width` wide and at most `maxHeight` tall:
	/// each cell's place (when `outPositions` is given, one per cell) and the atlas size the
	/// cells need, rounded up to SideMultiple. False if they do not all fit.
	public static bool PackAll(Span<(uint32 Width, uint32 Height)> cells, uint32 width, uint32 maxHeight,
		List<(uint32 X, uint32 Y)> outPositions, out uint32 outWidth, out uint32 outHeight)
	{
		outWidth = 0;
		outHeight = 0;
		var packer = RowPacker(width, maxHeight);
		for (let cell in cells)
		{
			if (!packer.TryPack(cell.Width, cell.Height, let x, let y))
				return false;
			outPositions?.Add((x, y));
		}
		outWidth = RoundUp(packer.UsedWidth, SideMultiple);
		outHeight = RoundUp(packer.UsedHeight, SideMultiple);
		return (outWidth <= width) && (outHeight <= maxHeight);
	}

	/// The width (at most `maxWidth`) whose packing needs the smallest atlas, the squarer one
	/// on a tie: powers of two from SmallestTriedWidth, then the maximum itself. The packing is
	/// metrics only, so trying several widths costs nothing beside the field generation. False
	/// if the cells do not fit at all.
	public static bool ChooseWidth(Span<(uint32 Width, uint32 Height)> cells, uint32 maxWidth, uint32 maxHeight,
		out uint32 outWidth)
	{
		outWidth = 0;
		uint64 bestArea = 0;
		uint32 bestSkew = 0;
		bool found = false;
		for (uint32 width = SmallestTriedWidth; ; width *= 2)
		{
			let tried = Math.Min(width, maxWidth);
			if (PackAll(cells, tried, maxHeight, null, let w, let h))
			{
				let area = (uint64)w * h;
				let skew = (uint32)((w > h) ? (w - h) : (h - w));
				if (!found || (area < bestArea) || ((area == bestArea) && (skew < bestSkew)))
				{
					found = true;
					bestArea = area;
					bestSkew = skew;
					outWidth = tried;
				}
			}
			if (tried >= maxWidth)
				break;
		}
		return found;
	}
}
