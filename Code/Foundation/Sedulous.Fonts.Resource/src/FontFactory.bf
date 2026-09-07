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
		ReadPixelStream(instance, pixels);

		let product = new Font();
		product.SetFamily(record.Family);

		let distanceField = record.PixelEncoding == .DistanceField;

		for (int index < record.EntryCount)
		{
			let entry = BuildEntry(record, index, pixels, distanceField);
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

	/// The concatenated atlas payloads. An absent stream is not fatal here: the entry
	/// builder rejects a slice it cannot satisfy, so a record with no pixels simply
	/// produces no entries.
	private void ReadPixelStream(Instance instance, List<uint8> outPixels)
	{
		let stream = instance.ReadData("data");
		if (stream == null)
			return;
		defer delete stream;

		let size = stream.Size();
		if (size <= 0)
			return;

		outPixels.Resize((int)size);
		if (stream.Read(.(outPixels.Ptr, (int)size)) != (int)size)
			outPixels.Clear();
	}

	private FontEntry BuildEntry(FontResource record, int index, List<uint8> pixels,
		bool distanceField)
	{
		let pixelHeight = record.EntryPixelHeight[index];

		let font = new BakedFont();
		font.SetFamilyName(record.Family);
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
				atlas.SetRegion(record.RegionCodepoint[i], ReadRegion(record, i));

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
				atlas.SetRegion(record.RegionCodepoint[i], ReadRegion(record, i));
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

	private static AtlasRegion ReadRegion(FontResource record, int i)
	{
		return .(record.RegionX[i], record.RegionY[i], record.RegionWidth[i],
			record.RegionHeight[i], record.RegionOffsetX[i], record.RegionOffsetY[i],
			record.RegionAdvanceX[i]);
	}
}
