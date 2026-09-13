using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;
using Sedulous.Fonts.Coverage.Baker;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.Resource;
using Sedulous.Fonts.TrueType;
using Sedulous.Pipeline.Core;

namespace Sedulous.Fonts.Pipeline;

/// Bakes a font file into the cooked record and its concatenated atlas pixels.
///
/// The cooked record is FLAT PARALLEL ARRAYS, one run per entry, so the builder appends to each
/// table in step rather than pushing entry objects. The counts per entry are what let a reader
/// walk the runs back apart.
class FontAssetBuilder : IAssetBuilder
{
	/// The stream the concatenated atlas pixels travel in.
	public const String cPixelStreamName = "data";

	public Type AssetType => typeof(FontAsset);
	public Type ProductType => typeof(FontResource);

	/// Four, after a run of record changes: the oversample fields, which a baked screen quad
	/// has to divide back out; the distance field range's key; and full names for the glyph
	/// bounds. A product schema change bumps this in the SAME commit, because the bump IS the
	/// migration: it forces every stale cooked font to re-cook.
	public int32 Version => 4;

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let authored = (FontAsset)asset;
		if ((context.Output == null) || authored.FileName.IsEmpty)
			return .Err(.InvalidArgument);

		let fontBytes = scope List<uint8>();
		if (AssetSource.ReadBytes(context, authored.FileName.Value, fontBytes)
			case .Err(let readError))
		{
			return .Err(readError);
		}

		let record = scope FontResource();
		record.Family.Set(authored.Family); // an explicit family wins; a bake fills an empty one
		record.Pixels = (uint32)((authored.Mode == .DistanceField)
			? FontResourcePixels.DistanceField : FontResourcePixels.Coverage);

		let pixels = scope List<uint8>();

		if (authored.Mode == .DistanceField)
		{
			if (BakeDistanceField(authored, fontBytes, record, pixels) case .Err(let bakeError))
				return .Err(bakeError);
		}
		else
		{
			for (let size in authored.Sizes)
			{
				if (BakeCoverage(authored, fontBytes, size, record, pixels)
					case .Err(let bakeError))
				{
					return .Err(bakeError);
				}
			}
		}

		if (record.EntryPixelHeight.IsEmpty)
			return .Err(.InvalidArgument); // no size produced an atlas

		if (context.Output.WriteObject(record) case .Err(let writeError))
			return .Err(writeError);
		return context.Output.WriteData(cPixelStreamName, pixels);
	}

	private static FontLoadOptions OptionsFor(FontAsset asset, float pixelHeight,
		bool distanceField)
	{
		var options = distanceField ? FontLoadOptions.DistanceField() : FontLoadOptions.Default();
		options.PixelHeight = pixelHeight;
		options.FirstCodepoint = asset.FirstCodepoint;
		options.LastCodepoint = asset.LastCodepoint;
		options.AtlasWidth = asset.AtlasWidth;
		options.AtlasHeight = asset.AtlasHeight;
		return options;
	}

	/// The per entry header, whose metrics come from the parsed font.
	private static void AppendEntryHeader(IFont font, float pixelHeight, FontResource record)
	{
		let metrics = font.Metrics;
		record.EntryPixelHeight.Add(pixelHeight);
		record.EntryAscent.Add(metrics.Ascent);
		record.EntryDescent.Add(metrics.Descent);
		record.EntryLineGap.Add(metrics.LineGap);
		record.EntryScale.Add(metrics.Scale);
	}

	private static void AppendGlyph(FontResource record, int32 codepoint, GlyphInfo info)
	{
		record.GlyphCodepoint.Add(codepoint);
		record.GlyphIndex.Add(info.GlyphIndex);
		record.GlyphAdvanceWidth.Add(info.AdvanceWidth);
		record.GlyphLeftSideBearing.Add(info.LeftSideBearing);
		record.GlyphBoundsX.Add(info.BoundingBox.X);
		record.GlyphBoundsY.Add(info.BoundingBox.Y);
		record.GlyphBoundsWidth.Add(info.BoundingBox.Width);
		record.GlyphBoundsHeight.Add(info.BoundingBox.Height);
		record.GlyphHasBitmap.Add(info.HasBitmap);
	}

	private static void AppendRegion(FontResource record, int32 codepoint, AtlasRegion region)
	{
		record.RegionCodepoint.Add(codepoint);
		record.RegionX.Add(region.X);
		record.RegionY.Add(region.Y);
		record.RegionWidth.Add(region.Width);
		record.RegionHeight.Add(region.Height);
		record.RegionOffsetX.Add(region.OffsetX);
		record.RegionOffsetY.Add(region.OffsetY);
		record.RegionAdvanceX.Add(region.AdvanceX);
	}

	private static void AppendPixels(Span<uint8> source, FontResource record, List<uint8> pixels)
	{
		record.EntryPixelOffset.Add((uint64)pixels.Count);
		record.EntryPixelBytes.Add((uint64)source.Length);
		if (!source.IsEmpty)
			pixels.AddRange(source);
	}

	/// One coverage size, through the baker the runtime importer already uses.
	private static Result<void, ErrorCode> BakeCoverage(FontAsset asset, List<uint8> fontBytes,
		float size, FontResource record, List<uint8> pixels)
	{
		let baked = FontBaker.Bake(fontBytes, OptionsFor(asset, size, false));
		if (baked case .Err)
			return .Err(.InvalidArgument);
		let data = baked.Value;
		defer delete data;

		let font = data.Font;
		let atlas = data.Atlas;

		AppendEntryHeader(font, size, record);
		if (record.Family.IsEmpty)
			font.GetFamilyName(record.Family);

		for (let pair in font.Glyphs)
			AppendGlyph(record, pair.key, pair.value);
		record.EntryGlyphCount.Add((uint32)font.Glyphs.Count);

		for (let pair in font.Kerning)
		{
			record.KerningFirst.Add((int32)(pair.key >> 32));
			record.KerningSecond.Add((int32)(uint32)pair.key);
			record.KerningAmount.Add(pair.value);
		}
		record.EntryKerningCount.Add((uint32)font.Kerning.Count);

		for (let pair in atlas.Regions)
			AppendRegion(record, pair.key, pair.value);
		record.EntryRegionCount.Add((uint32)atlas.Regions.Count);

		record.EntryAtlasWidth.Add(atlas.Width);
		record.EntryAtlasHeight.Add(atlas.Height);
		let white = atlas.WhitePixelUV;
		record.EntryWhitePixelU.Add(white.X);
		record.EntryWhitePixelV.Add(white.Y);
		record.EntryOversampleX.Add(atlas.OversampleX);
		record.EntryOversampleY.Add(atlas.OversampleY);
		record.EntryDistanceFieldRange.Add(0.0f);

		AppendPixels(atlas.PixelData, record, pixels);
		return .Ok;
	}

	/// The single distance field bake.
	private static Result<void, ErrorCode> BakeDistanceField(FontAsset asset,
		List<uint8> fontBytes, FontResource record, List<uint8> pixels)
	{
		DistanceFieldFonts.Initialize(); // idempotent baker registration

		// The font TAKES the byte list, so it gets its own copy.
		let owned = new List<uint8>();
		owned.AddRange(fontBytes);

		let options = OptionsFor(asset, asset.DistanceFieldSize, true);
		let font = scope TrueTypeFont();
		if (font.Initialize(owned, options.PixelHeight) != .Success)
			return .Err(.InvalidArgument);

		let baked = FontAtlasBakerFactory.Bake(font, options);
		if (baked case .Err)
			return .Err(.NotSupported); // no distance field baker registered
		let atlas = baked.Value;
		defer delete atlas;

		AppendEntryHeader(font, asset.DistanceFieldSize, record);
		if (record.Family.IsEmpty)
			font.GetFamilyName(record.Family);

		uint32 glyphCount = 0;
		uint32 regionCount = 0;
		for (int32 codepoint = asset.FirstCodepoint; codepoint <= asset.LastCodepoint; ++codepoint)
		{
			if (!atlas.TryGetRegion(codepoint, let region))
				continue;
			AppendGlyph(record, codepoint, font.GetGlyphInfo(codepoint));
			glyphCount++;
			AppendRegion(record, codepoint, region);
			regionCount++;
		}
		record.EntryGlyphCount.Add(glyphCount);
		record.EntryRegionCount.Add(regionCount);

		uint32 kerningCount = 0;
		for (int32 first = asset.FirstCodepoint; first <= asset.LastCodepoint; ++first)
		{
			if (!atlas.Contains(first))
				continue;
			for (int32 second = asset.FirstCodepoint; second <= asset.LastCodepoint; ++second)
			{
				if (!atlas.Contains(second))
					continue;
				let adjustment = font.GetKerning(first, second);
				if (adjustment == 0.0f)
					continue;
				record.KerningFirst.Add(first);
				record.KerningSecond.Add(second);
				record.KerningAmount.Add(adjustment);
				kerningCount++;
			}
		}
		record.EntryKerningCount.Add(kerningCount);

		record.EntryAtlasWidth.Add(atlas.Width);
		record.EntryAtlasHeight.Add(atlas.Height);
		let white = atlas.WhitePixelUV;
		record.EntryWhitePixelU.Add(white.X);
		record.EntryWhitePixelV.Add(white.Y);
		record.EntryOversampleX.Add(1.0f);
		record.EntryOversampleY.Add(1.0f);
		record.EntryDistanceFieldRange.Add(atlas.DistanceFieldRange);

		AppendPixels(atlas.PixelData, record, pixels);
		return .Ok;
	}
}
