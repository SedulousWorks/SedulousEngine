using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;
using Sedulous.Fonts.DistanceField;
using Sedulous.Image;
using Sedulous.Resource;

namespace Sedulous.Fonts.Resource;

/// Builds a cooked FontResource into a runtime Font.
///
/// DEVICE FREE on purpose: the atlases stay CPU side as images, and whichever layer draws
/// text uploads them itself. That is what lets a font bind with no graphics device at all,
/// which the headless tests and the cooking tools both depend on.
class FontFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<Font>();
	public Type CookedType => typeof(FontResource);

	/// The whole build is a pure function of the stored bytes: glyph tables and CPU atlas
	/// images, with no upload and nothing global touched. So it runs entirely on a worker
	/// and finalize has nothing left to do.
	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFont(instance);

	public Object DecodeStage(Instance instance) => BuildFont(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFont(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;

		let record = stored as FontResource;
		if (record == null)
			return null;

		// A record from disk is not trusted: a truncated one would otherwise be read past
		// the end of its own tables.
		if (!record.IsWellFormed())
			return null;

		let pixels = scope List<uint8>();
		ReadStream(instance, "data", pixels);

		let product = new Font();
		product.SetFamily(record.Family);
		// The font file, for a shaper; absent in a font cooked before it was kept.
		let sourceData = new List<uint8>();
		ReadStream(instance, "font", sourceData);
		product.SetSourceData(sourceData);

		let distanceField = record.PixelEncoding == .DistanceField;

		for (int index < record.EntryCount)
		{
			let entry = BuildEntry(record, index, pixels, product.SourceData, distanceField);
			// A corrupt entry is DROPPED rather than added half built: a font size that
			// exists but has no atlas would draw nothing and look like a missing glyph.
			if (entry != null)
				product.AddEntry(entry);
		}

		if (product.EntryCount == 0)
		{
			delete product;
			return null;
		}
		return product;
	}

	/// A data stream whole: "data", the concatenated atlas payloads, or "font", the font file.
	/// An absent stream is not fatal here: the entry builder rejects an atlas slice it cannot
	/// satisfy, so a record with no pixels simply produces no entries, and a font without its
	/// file draws unshaped.
	private void ReadStream(Instance instance, StringView name, List<uint8> outBytes)
	{
		let stream = instance.ReadData(name);
		if (stream == null)
			return;
		defer delete stream;

		let size = stream.Size();
		if (size <= 0)
			return;

		outBytes.Resize((int)size);
		if (stream.Read(.(outBytes.Ptr, (int)size)) != (int)size)
			outBytes.Clear();
	}

	private FontEntry BuildEntry(FontResource record, int index, List<uint8> pixels, Span<uint8> sourceData,
		bool distanceField)
	{
		let pixelHeight = record.EntryPixelHeight[index];

		let font = new BakedFont();
		font.SetFamilyName(record.Family);
		font.SetSourceData(sourceData);
		font.SetPixelHeight(pixelHeight);
		font.SetMetrics(.(record.EntryAscent[index], record.EntryDescent[index],
			record.EntryLineGap[index], pixelHeight, record.EntryScale[index]));

		let glyphStart = FontResource.SliceStart(record.EntryGlyphCount, index);
		for (int i = glyphStart; i < (glyphStart + (int)record.EntryGlyphCount[index]); i++)
		{
			var info = GlyphInfo();
			info.Codepoint = record.GlyphCodepoint[i];
			info.GlyphIndex = record.GlyphIndex[i];
			info.AdvanceWidth = record.GlyphAdvanceWidth[i];
			info.LeftSideBearing = record.GlyphLeftSideBearing[i];
			info.BoundingBox = .(record.GlyphBoundsX[i], record.GlyphBoundsY[i],
				record.GlyphBoundsWidth[i], record.GlyphBoundsHeight[i]);
			info.HasBitmap = record.GlyphHasBitmap[i];
			font.SetGlyph(info.Codepoint, info);
		}

		let kerningStart = FontResource.SliceStart(record.EntryKerningCount, index);
		for (int i = kerningStart; i < (kerningStart + (int)record.EntryKerningCount[index]); i++)
			font.SetKerning(record.KerningFirst[i], record.KerningSecond[i], record.KerningAmount[i]);

		// This entry's slice of the shared pixel stream.
		let offset = record.EntryPixelOffset[index];
		let bytes = record.EntryPixelBytes[index];
		let slice = new List<uint8>();
		if ((bytes > 0) && ((offset + bytes) <= (uint64)pixels.Count))
		{
			slice.Resize((int)bytes);
			Internal.MemCpy(slice.Ptr, pixels.Ptr + (int)offset, (int)bytes);
		}

		let result = new FontEntry();
		result.PixelHeight = pixelHeight;
		result.Font = font;

		let width = record.EntryAtlasWidth[index];
		let height = record.EntryAtlasHeight[index];
		let regionStart = FontResource.SliceStart(record.EntryRegionCount, index);
		let regionEnd = regionStart + (int)record.EntryRegionCount[index];

		if (distanceField)
		{
			let atlas = new DistanceFieldFontAtlas();
			atlas.SetPixelRange(record.EntryDistanceFieldRange[index]);
			atlas.SetWhitePixelUV(record.EntryWhitePixelU[index], record.EntryWhitePixelV[index]);
			for (int i = regionStart; i < regionEnd; i++)
				atlas.SetRegion(record.RegionGlyph[i], ReadRegion(record, i));
			MapCodepoints(record, glyphStart, index, scope => atlas.SetGlyphFor);

			// Already RGBA8, and LINEAR: these are distances, and gamma decoding them would
			// bend the field.
			result.AtlasImage = new OwnedImageData(width, height, .RGBA8,
				.(slice.Ptr, slice.Count), .Linear);
			atlas.SetPixels(width, height, slice);
			result.Atlas = atlas;
		}
		else
		{
			let atlas = new BakedFontAtlas();
			atlas.SetWhitePixelUV(record.EntryWhitePixelU[index], record.EntryWhitePixelV[index]);
			atlas.SetOversample(record.EntryOversampleX[index], record.EntryOversampleY[index]);
			for (int i = regionStart; i < regionEnd; i++)
				atlas.SetRegion(record.RegionGlyph[i], ReadRegion(record, i));
			MapCodepoints(record, glyphStart, index, scope => atlas.SetGlyphFor);
			atlas.SetPixels(width, height, slice);
			result.Atlas = atlas;

			// One byte of coverage per texel expands to RGBA8, the same expansion the
			// TrueType service performs, so a renderer sees one format either way.
			result.AtlasImage = FontAtlasTexture.ExpandR8ToRGBA8(atlas);
		}

		if (result.AtlasImage == null)
		{
			delete result;
			return null;
		}
		return result;
	}

	/// The glyph rows map codepoints to the glyphs the regions key by; a codepoint with no
	/// glyph in the font maps to none.
	private static void MapCodepoints(FontResource record, int glyphStart, int index,
		delegate void(int32 codepoint, int32 glyphId) setGlyphFor)
	{
		for (int i = glyphStart; i < (glyphStart + (int)record.EntryGlyphCount[index]); i++)
		{
			if (record.GlyphIndex[i] > 0)
				setGlyphFor(record.GlyphCodepoint[i], record.GlyphIndex[i]);
		}
	}

	private static AtlasRegion ReadRegion(FontResource record, int i)
	{
		return .(record.RegionX[i], record.RegionY[i], record.RegionWidth[i],
			record.RegionHeight[i], record.RegionOffsetX[i], record.RegionOffsetY[i],
			record.RegionAdvanceX[i]);
	}
}
