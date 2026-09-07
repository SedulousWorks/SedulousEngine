using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Fonts.Resource;

/// The cooked font record: a family, a pixel encoding, and one ENTRY per baked size.
///
/// The tables are FLATTENED into parallel lists of primitives rather than stored as lists
/// of structs, which is what the counted array path can describe. Each entry names how many
/// glyph, kerning and region rows are its own, and those rows sit in entry order, so entry
/// `i` reads the slice that follows the sum of the counts before it.
///
/// The atlas pixels are NOT here. They live concatenated in the resource's "data" stream
/// and each entry records its offset and length, so loading one size does not deserialize
/// every other size's texture.
[Serializable(1)]
class FontResource
{
	public String Family = new .() ~ delete _;
	/// A FontResourcePixels. Stored as its underlying type because that is what a cooked
	/// record should carry: a value it does not recognise must not become a valid enum.
	public uint32 Pixels = 0;

	// ---- one row per entry, which is one baked pixel size ----

	public List<float> EntryPixelHeight = new .() ~ delete _;
	public List<float> EntryAscent = new .() ~ delete _;
	public List<float> EntryDescent = new .() ~ delete _;
	public List<float> EntryLineGap = new .() ~ delete _;
	public List<float> EntryScale = new .() ~ delete _;

	public List<uint32> EntryAtlasWidth = new .() ~ delete _;
	public List<uint32> EntryAtlasHeight = new .() ~ delete _;
	public List<float> EntryWhitePixelU = new .() ~ delete _;
	public List<float> EntryWhitePixelV = new .() ~ delete _;
	/// DistanceField only, and ignored for coverage.
	public List<float> EntryDistanceFieldRange = new .() ~ delete _;

	/// The oversampling the atlas was PACKED at. Region spans are raw atlas texels at this
	/// multiple of the logical glyph size, and the runtime atlas divides screen quads back
	/// down by it. A record that lost this draws every glyph oversized.
	public List<float> EntryOversampleX = new .() ~ delete _;
	public List<float> EntryOversampleY = new .() ~ delete _;

	/// Where this entry's atlas sits in the "data" stream.
	public List<uint64> EntryPixelOffset = new .() ~ delete _;
	public List<uint64> EntryPixelBytes = new .() ~ delete _;

	/// How many rows of each flattened table below belong to this entry.
	public List<uint32> EntryGlyphCount = new .() ~ delete _;
	public List<uint32> EntryKerningCount = new .() ~ delete _;
	public List<uint32> EntryRegionCount = new .() ~ delete _;

	// ---- the flattened glyph table ----

	public List<int32> GlyphCodepoint = new .() ~ delete _;
	public List<int32> GlyphIndex = new .() ~ delete _;
	public List<float> GlyphAdvanceWidth = new .() ~ delete _;
	public List<float> GlyphLeftSideBearing = new .() ~ delete _;
	public List<float> GlyphBoundsX = new .() ~ delete _;
	public List<float> GlyphBoundsY = new .() ~ delete _;
	public List<float> GlyphBoundsWidth = new .() ~ delete _;
	public List<float> GlyphBoundsHeight = new .() ~ delete _;
	public List<bool> GlyphHasBitmap = new .() ~ delete _;

	// ---- the flattened kerning table ----

	public List<int32> KerningFirst = new .() ~ delete _;
	public List<int32> KerningSecond = new .() ~ delete _;
	public List<float> KerningAmount = new .() ~ delete _;

	// ---- the flattened region table ----

	public List<int32> RegionCodepoint = new .() ~ delete _;
	public List<uint16> RegionX = new .() ~ delete _;
	public List<uint16> RegionY = new .() ~ delete _;
	public List<uint16> RegionWidth = new .() ~ delete _;
	public List<uint16> RegionHeight = new .() ~ delete _;
	public List<float> RegionOffsetX = new .() ~ delete _;
	public List<float> RegionOffsetY = new .() ~ delete _;
	public List<float> RegionAdvanceX = new .() ~ delete _;

	public int EntryCount => EntryPixelHeight.Count;

	public FontResourcePixels PixelEncoding => (Pixels == 1) ? .DistanceField : .Coverage;

	/// Where entry `index`'s slice of a flattened table starts, being the sum of every
	/// earlier entry's count.
	public static int SliceStart(List<uint32> counts, int index)
	{
		int start = 0;
		for (int i < index)
		{
			if (i >= counts.Count)
				break;
			start += (int)counts[i];
		}
		return start;
	}

	/// Whether every table is long enough for the counts the entries claim.
	///
	/// A cooked record is data from disk, so a truncated or hand edited one must be
	/// REFUSED rather than read past the end of a list.
	public bool IsWellFormed()
	{
		let count = EntryCount;
		if ((EntryAscent.Count != count) || (EntryDescent.Count != count)
			|| (EntryLineGap.Count != count) || (EntryScale.Count != count)
			|| (EntryAtlasWidth.Count != count) || (EntryAtlasHeight.Count != count)
			|| (EntryWhitePixelU.Count != count) || (EntryWhitePixelV.Count != count)
			|| (EntryDistanceFieldRange.Count != count)
			|| (EntryOversampleX.Count != count) || (EntryOversampleY.Count != count)
			|| (EntryPixelOffset.Count != count) || (EntryPixelBytes.Count != count)
			|| (EntryGlyphCount.Count != count) || (EntryKerningCount.Count != count)
			|| (EntryRegionCount.Count != count))
			return false;

		int glyphs = 0, kerning = 0, regions = 0;
		for (int i < count)
		{
			glyphs += (int)EntryGlyphCount[i];
			kerning += (int)EntryKerningCount[i];
			regions += (int)EntryRegionCount[i];
		}

		if ((GlyphCodepoint.Count != glyphs) || (GlyphIndex.Count != glyphs)
			|| (GlyphAdvanceWidth.Count != glyphs) || (GlyphLeftSideBearing.Count != glyphs)
			|| (GlyphBoundsX.Count != glyphs) || (GlyphBoundsY.Count != glyphs)
			|| (GlyphBoundsWidth.Count != glyphs) || (GlyphBoundsHeight.Count != glyphs)
			|| (GlyphHasBitmap.Count != glyphs))
			return false;

		if ((KerningFirst.Count != kerning) || (KerningSecond.Count != kerning)
			|| (KerningAmount.Count != kerning))
			return false;

		if ((RegionCodepoint.Count != regions) || (RegionX.Count != regions)
			|| (RegionY.Count != regions) || (RegionWidth.Count != regions)
			|| (RegionHeight.Count != regions) || (RegionOffsetX.Count != regions)
			|| (RegionOffsetY.Count != regions) || (RegionAdvanceX.Count != regions))
			return false;

		return true;
	}
}
