using System;

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

	public this(uint32 atlasWidth, uint32 atlasHeight)
	{
		AtlasWidth = atlasWidth;
		AtlasHeight = atlasHeight;
		mCursorX = 0;
		mCursorY = 0;
		mRowHeight = 0;
	}

	/// Places a cell, or returns false when the atlas is full. Deterministic: the same
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
		if ((mCursorY + height) > AtlasHeight)
			return false;

		x = mCursorX;
		y = mCursorY;
		mCursorX += width + CellGutter;
		if (height > mRowHeight)
			mRowHeight = height;
		return true;
	}
}
