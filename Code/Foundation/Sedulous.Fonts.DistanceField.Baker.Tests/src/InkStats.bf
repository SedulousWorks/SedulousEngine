using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.DistanceField.Baker.Tests;

/// Where the ink sits inside one glyph's cell.
///
/// A distance field cannot be checked texel against texel like a coverage bitmap, because
/// what it stores is a distance rather than an opacity. What CAN be checked is where the
/// inside of the glyph falls, and that is enough to catch the two mistakes that matter:
/// a vertical flip, and a reversed winding that turns the glyph into its own cutout.
struct InkStats
{
	public int32 CellWidth;
	public int32 CellHeight;
	/// Texels reading as inside the glyph.
	public int32 Total;
	public int32 TopHalf;
	public int32 BottomHalf;
	public int32 MinRow;
	public int32 MaxRow;
	public int32 MinColumn;
	public int32 MaxColumn;

	/// A texel is inside when the median of the three channels is past the midpoint. The
	/// MEDIAN, not any one channel: that is how a multi-channel field is decoded, and
	/// reading a single channel would report the sharp-corner data as ink.
	public static InkStats Analyze(IFontAtlas atlas, int32 codepoint)
	{
		var stats = InkStats();
		if (!atlas.TryGetRegion(codepoint, let region))
			return stats;
		if (region.IsEmpty)
			return stats;

		stats.CellWidth = (int32)region.Width;
		stats.CellHeight = (int32)region.Height;
		stats.MinRow = stats.CellHeight;
		stats.MaxRow = -1;
		stats.MinColumn = stats.CellWidth;
		stats.MaxColumn = -1;

		let pixels = atlas.PixelData;
		let atlasWidth = (int)atlas.Width;

		for (int32 row < stats.CellHeight)
		{
			for (int32 column < stats.CellWidth)
			{
				let index = (((int)region.Y + row) * atlasWidth + (int)region.X + column) * 4;
				let r = (int32)pixels[index + 0];
				let g = (int32)pixels[index + 1];
				let b = (int32)pixels[index + 2];
				if (Median(r, g, b) <= 127)
					continue;

				stats.Total++;
				if (row < (stats.CellHeight / 2))
					stats.TopHalf++;
				else
					stats.BottomHalf++;
				if (row < stats.MinRow)
					stats.MinRow = row;
				if (row > stats.MaxRow)
					stats.MaxRow = row;
				if (column < stats.MinColumn)
					stats.MinColumn = column;
				if (column > stats.MaxColumn)
					stats.MaxColumn = column;
			}
		}
		return stats;
	}

	/// Texels in the SOFT band, neither clearly inside nor clearly outside.
	///
	/// This is what the range controls: the field falls from outside to inside over roughly
	/// `pxRange` texels, and that ramp is what the shader antialiases with. A field whose
	/// range is wrong still has the right interior, so only the width of this band shows it.
	public static int32 CountTransitionTexels(IFontAtlas atlas, int32 codepoint)
	{
		if (!atlas.TryGetRegion(codepoint, let region))
			return 0;
		if (region.IsEmpty)
			return 0;

		let pixels = atlas.PixelData;
		let atlasWidth = (int)atlas.Width;
		int32 band = 0;

		for (int32 row < (int32)region.Height)
		{
			for (int32 column < (int32)region.Width)
			{
				let index = (((int)region.Y + row) * atlasWidth + (int)region.X + column) * 4;
				let median = Median((int32)pixels[index + 0], (int32)pixels[index + 1],
					(int32)pixels[index + 2]);
				if ((median > 64) && (median < 192))
					band++;
			}
		}
		return band;
	}

	private static int32 Median(int32 a, int32 b, int32 c)
		=> Math.Max(Math.Min(a, b), Math.Min(Math.Max(a, b), c));
}
