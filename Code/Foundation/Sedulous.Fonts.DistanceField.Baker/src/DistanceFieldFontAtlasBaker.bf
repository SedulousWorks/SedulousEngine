using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using stb_truetype;
using msdfgen_Beef;

namespace Sedulous.Fonts.DistanceField.Baker;

/// Bakes a multi-channel distance field atlas from a TrueType font, through msdfgen.
///
/// This is the tooling half: it links msdfgen and stb_truetype, and what it produces is a
/// DistanceFieldFontAtlas that a packaged game loads without either. The result is
/// resolution independent, which is the whole reason to pay for it: one bake renders
/// crisply at any size, where a coverage atlas is sharp only near the size it was baked at.
class DistanceFieldFontAtlasBaker : IFontAtlasBaker
{
	/// The spread, in pixels of the baked cell. Four is msdfgen's usual working value: wide
	/// enough for the shader to antialias and to carry a small outline or glow, narrow
	/// enough that neighbouring strokes do not overwrite each other's field.
	private const double cDefaultPixelRange = 4.0;

	private static StringView[3] sExtensions = .(".ttf", ".otf", ".ttc");

	public override Span<StringView> SupportedExtensions => .(&sExtensions[0], 3);

	public override bool SupportsExtension(StringView fileExtension)
		=> TrueTypeCommon.IsSupportedExtension(fileExtension);

	/// Always false in the one-argument form: without the options there is no atlas mode to
	/// check, and claiming a font here would take every coverage bake as well.
	public override bool CanBake(IFont font) => false;

	public override bool CanBake(IFont font, FontLoadOptions options)
	{
		return (font != null)
			&& (font.BackendTypeId == TrueTypeCommon.BackendTypeId)
			&& (options.AtlasMode == .DistanceField);
	}

	public override Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options)
	{
		if (!CanBake(font, options))
			return .Err(.UnsupportedFormat);

		let source = (TrueTypeFont)font;
		let rawData = source.RawData;
		if (rawData == null)
			return .Err(.InvalidFormat);

		// Its OWN stbtt_fontinfo rather than the font's: this reads metrics at the bake's
		// pixel height, which need not be the height the font was parsed at.
		stbtt_fontinfo info = default;
		if (stbtt_InitFont(&info, rawData, stbtt_GetFontOffsetForIndex(rawData, 0)) == 0)
			return .Err(.InvalidFormat);

		let atlasWidth = options.AtlasWidth;
		let atlasHeight = options.AtlasHeight;
		let scale = stbtt_ScaleForPixelHeight(&info, options.PixelHeight);

		let atlas = new DistanceFieldFontAtlas();
		atlas.SetPixelRange((float)cDefaultPixelRange);

		let work = scope List<GlyphWork>();
		PackGlyphs(&info, scale, options, atlas, work);

		let pixels = new List<uint8>();
		pixels.Resize((int)atlasWidth * (int)atlasHeight * 4);
		if (!pixels.IsEmpty)
			Internal.MemSet(pixels.Ptr, 0, pixels.Count);

		GenerateFields(rawData, source.RawDataSize, scale, atlasWidth, work, pixels);

		// Sequential again: only the cells that actually generated get a region, because a
		// region pointing at a cell whose field failed would draw blank texels rather than
		// fall back to nothing. No glyph in a well formed font reaches this, so it is
		// defensive: the tests cannot reach it either, and it is kept for malformed input.
		bool anyGlyphs = false;
		for (let item in work)
		{
			if (!item.Generated)
				continue;
			atlas.SetRegion(item.Codepoint, item.Region);
			anyGlyphs = true;
		}

		if (!anyGlyphs)
		{
			delete atlas;
			delete pixels;
			return .Err(.NoGlyphsFound);
		}

		WriteWhiteBlock(atlasWidth, atlasHeight, pixels, atlas);
		atlas.SetPixels(atlasWidth, atlasHeight, pixels);
		return .Ok(atlas);
	}

	/// Sequential: measures every glyph and decides where its cell goes.
	private void PackGlyphs(stbtt_fontinfo* info, float scale, FontLoadOptions options,
		DistanceFieldFontAtlas atlas, List<GlyphWork> outWork)
	{
		var packer = RowPacker(options.AtlasWidth, options.AtlasHeight);
		let padding = (int32)options.Padding;

		for (int32 codepoint = options.FirstCodepoint; codepoint <= options.LastCodepoint; codepoint++)
		{
			let glyphIndex = stbtt_FindGlyphIndex(info, codepoint);
			if (glyphIndex <= 0)
				continue;

			int32 boxX0 = 0, boxY0 = 0, boxX1 = 0, boxY1 = 0;
			if (stbtt_GetGlyphBox(info, glyphIndex, &boxX0, &boxY0, &boxX1, &boxY1) == 0)
			{
				AddAdvanceOnly(info, scale, codepoint, glyphIndex, atlas);
				continue;
			}

			int32 pixelX0 = 0, pixelY0 = 0, pixelX1 = 0, pixelY1 = 0;
			stbtt_GetGlyphBitmapBox(info, glyphIndex, scale, scale,
				&pixelX0, &pixelY0, &pixelX1, &pixelY1);

			let glyphWidth = pixelX1 - pixelX0;
			let glyphHeight = pixelY1 - pixelY0;
			if ((glyphWidth <= 0) || (glyphHeight <= 0))
			{
				AddAdvanceOnly(info, scale, codepoint, glyphIndex, atlas);
				continue;
			}

			// The cell is the glyph plus the padding on each side, plus one texel of safety
			// so the field has somewhere to fall off before the cell edge.
			let cellWidth = glyphWidth + padding * 2 + 2;
			let cellHeight = glyphHeight + padding * 2 + 2;

			if (!packer.TryPack((uint32)cellWidth, (uint32)cellHeight, let packX, let packY))
				continue; // the atlas is full; the rest simply do not get baked

			int32 advanceWidth = 0, leftSideBearing = 0;
			stbtt_GetGlyphHMetrics(info, glyphIndex, &advanceWidth, &leftSideBearing);

			let scaleAsDouble = (double)scale;

			var item = GlyphWork();
			item.Codepoint = codepoint;
			item.CellWidth = cellWidth;
			item.CellHeight = cellHeight;
			item.PackX = packX;
			item.PackY = packY;
			// Map the glyph's bounding box corner onto the cell's inner corner. msdfgen
			// projects as scale * (coord + translate), so the translate is in font units and
			// is applied BEFORE the scale, hence the division.
			item.TranslateX = (double)(padding + 1) / scaleAsDouble - (double)boxX0;
			item.TranslateY = (double)(padding + 1) / scaleAsDouble - (double)boxY0;
			// The offsets are the cell's top left relative to the cursor on the baseline, in
			// the Y-down space the draw path works in.
			item.Region = .((uint16)packX, (uint16)packY, (uint16)cellWidth, (uint16)cellHeight,
				(float)(pixelX0 - padding - 1), (float)(pixelY0 - padding - 1),
				(float)advanceWidth * scale);
			outWork.Add(item);
		}
	}

	/// A glyph with no outline, a space above all, still carries an advance.
	///
	/// Recording an advance-only region is what keeps the cursor-walking draw paths from
	/// rendering "hello world" as "helloworld". The coverage baker gets this for free from
	/// stb's packer; here it has to be done by hand, because a shape with no contours simply
	/// produces no cell.
	private void AddAdvanceOnly(stbtt_fontinfo* info, float scale, int32 codepoint,
		int32 glyphIndex, DistanceFieldFontAtlas atlas)
	{
		int32 advanceWidth = 0, leftSideBearing = 0;
		stbtt_GetGlyphHMetrics(info, glyphIndex, &advanceWidth, &leftSideBearing);
		atlas.SetRegion(codepoint, .(0, 0, 0, 0, 0, 0, (float)advanceWidth * scale));
	}

	/// Parallel: every glyph's field, blitted into its own cell.
	///
	/// Safe to fan out because the packing already happened: the cells were placed with a
	/// gutter between them, so no two workers write the same byte, and each worker parses
	/// the font itself rather than sharing one stbtt_fontinfo.
	private void GenerateFields(uint8* rawData, int rawDataSize, float scale, uint32 atlasWidth,
		List<GlyphWork> work, List<uint8> pixels)
	{
		if (work.IsEmpty)
			return;

		let jobs = scope JobSystem();
		jobs.ParallelFor((int32)work.Count, scope [&] (index) =>
		{
			var item = work[index];
			let cellPixels = scope List<uint8>();
			cellPixels.Resize(item.CellWidth * item.CellHeight * 4);
			Internal.MemSet(cellPixels.Ptr, 0, cellPixels.Count);

			if (GenerateGlyph(rawData, item.Codepoint, item.CellWidth, item.CellHeight,
				(double)scale, item.TranslateX, item.TranslateY, cellPixels))
			{
				for (int row < item.CellHeight)
				{
					let sourceOffset = row * item.CellWidth * 4;
					let targetOffset = ((int)(item.PackY + (uint32)row) * (int)atlasWidth
						+ (int)item.PackX) * 4;
					Internal.MemCpy(pixels.Ptr + targetOffset, cellPixels.Ptr + sourceOffset,
						item.CellWidth * 4);
				}
				item.Generated = true;
				work[index] = item;
			}
		}, 1);
	}

	/// One glyph's field, written as RGBA8 into `outPixels`.
	private static bool GenerateGlyph(uint8* rawData, int32 codepoint, int32 width, int32 height,
		double scale, double translateX, double translateY, List<uint8> outPixels)
	{
		// Its own parse per call, so this is stateless and safe to run on any worker.
		stbtt_fontinfo info = default;
		if (stbtt_InitFont(&info, rawData, stbtt_GetFontOffsetForIndex(rawData, 0)) == 0)
			return false;

		let glyphIndex = stbtt_FindGlyphIndex(&info, codepoint);
		if (glyphIndex <= 0)
			return false;

		let shape = msdf_shape_create();
		defer msdf_shape_destroy(shape);

		if (!GlyphShape.Build(&info, glyphIndex, shape))
			return false;

		// The outline is Y-up in its native winding, which is what msdfgen expects: setting
		// the inverse flag here would swap inside for outside and fill the whole cell.
		msdf_shape_set_inverse_y_axis(shape, 0);
		msdf_shape_normalize(shape);
		msdf_edge_coloring_by_distance(shape, 3.0, 0);

		let bitmap = msdf_bitmap_create(width, height, 3);
		defer msdf_bitmap_destroy(bitmap);

		// The range is in SHAPE units, not pixels, so the pixel spread is divided by the
		// scale that takes shape units to pixels.
		let shapeRange = cDefaultPixelRange / scale;
		var transform = msdf_Transform(scale, scale, translateX, translateY, shapeRange);
		var config = msdf_Config.Default;
		if (msdf_generate_msdf(bitmap, shape, &transform, &config) == 0)
			return false;

		let data = msdf_bitmap_data(bitmap);
		if (data == null)
			return false;

		// msdfgen's bitmap is Y-up, with row zero at the BOTTOM. The atlas and the draw path
		// are top-down, so the rows are flipped on the way out. This is also what lands a
		// descender near the bottom of its cell instead of clipping it off the top.
		for (int32 y < height)
		{
			let sourceRow = height - 1 - y;
			for (int32 x < width)
			{
				let source = (sourceRow * width + x) * 3;
				let target = (y * width + x) * 4;
				outPixels[target + 0] = ToByte(data[source + 0]);
				outPixels[target + 1] = ToByte(data[source + 1]);
				outPixels[target + 2] = ToByte(data[source + 2]);
				outPixels[target + 3] = 255;
			}
		}
		return true;
	}

	/// msdfgen works in floats around 0.5 for the edge, and can run outside zero to one.
	private static uint8 ToByte(float value)
	{
		let scaled = value * 255.0f + 0.5f;
		if (scaled <= 0)
			return 0;
		if (scaled >= 255.0f)
			return 255;
		return (uint8)scaled;
	}

	/// A two by two solid block in the bottom right corner, for solid fills.
	///
	/// The vector renderer draws untextured geometry by sampling this rather than binding a
	/// second texture, so it has to survive into every atlas. Two by two, sampled at the
	/// centre, so bilinear filtering cannot pull in a neighbouring texel.
	private void WriteWhiteBlock(uint32 atlasWidth, uint32 atlasHeight, List<uint8> pixels,
		DistanceFieldFontAtlas atlas)
	{
		if ((atlasWidth < 2) || (atlasHeight < 2))
			return;

		let blockX = atlasWidth - 2;
		let blockY = atlasHeight - 2;
		for (uint32 dy < 2)
		{
			for (uint32 dx < 2)
			{
				let index = ((int)(blockY + dy) * (int)atlasWidth + (int)(blockX + dx)) * 4;
				pixels[index + 0] = 255;
				pixels[index + 1] = 255;
				pixels[index + 2] = 255;
				pixels[index + 3] = 255;
			}
		}

		atlas.SetWhitePixelUV(((float)blockX + 0.5f) / (float)atlasWidth,
			((float)blockY + 0.5f) / (float)atlasHeight);
	}
}
