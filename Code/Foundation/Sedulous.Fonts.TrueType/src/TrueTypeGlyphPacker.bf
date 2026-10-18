using System;
using stb_truetype;

namespace Sedulous.Fonts.TrueType;

/// Packing by glyph index.
///
/// stb_truetype's pack API names glyphs by codepoint only, and a shaper's output (ligatures,
/// joined forms) has glyphs no codepoint reaches, so the atlas packs glyph indices through
/// this instead. It gathers, packs, oversamples and prefilters as stbtt_PackFontRanges does,
/// so a glyph packs the same whichever way it is named, with one difference: a blank glyph (a
/// space) packs as a zero-area record that still advances, not as a texel of empty atlas.
static class TrueTypeGlyphPacker
{
	/// Packs `glyphs` of `info` at `pixelHeight` into `context`, writing `outPacked[i]` for
	/// `glyphs[i]`. False when a glyph did not fit: the atlas ran out of room.
	public static bool Pack(stbtt_pack_context* context, stbtt_fontinfo* info, float pixelHeight,
		Span<int32> glyphs, stbtt_packedchar* outPacked)
	{
		if (glyphs.IsEmpty)
			return true;

		let scale = stb_truetype.stbtt_ScaleForPixelHeight(info, pixelHeight);
		let hOver = (int32)context.h_oversample;
		let vOver = (int32)context.v_oversample;
		let scaleX = scale * (float)hOver;
		let scaleY = scale * (float)vOver;
		let padding = context.padding;

		let rects = new stbrp_rect[glyphs.Length];
		defer delete rects;

		// Gather, as stbtt_PackFontRangesGatherRects does by codepoint.
		for (int k < glyphs.Length)
		{
			int32 x0 = 0, y0 = 0, x1 = 0, y1 = 0;
			stb_truetype.stbtt_GetGlyphBitmapBoxSubpixel(info, glyphs[k], scaleX, scaleY, 0, 0,
				&x0, &y0, &x1, &y1);
			rects[k].id = (int32)k;
			rects[k].was_packed = 0;
			if ((x1 <= x0) || (y1 <= y0))
			{
				// Nothing to pack, only an advance.
				rects[k].w = 0;
				rects[k].h = 0;
				continue;
			}
			rects[k].w = x1 - x0 + padding + hOver - 1;
			rects[k].h = y1 - y0 + padding + vOver - 1;
		}
		stb_truetype.stbtt_PackFontRangesPackRects(context, rects.Ptr, (int32)glyphs.Length);

		// Render, as stbtt_PackFontRangesRenderIntoRects does.
		bool allPacked = true;
		let recipH = 1.0f / (float)hOver;
		let recipV = 1.0f / (float)vOver;
		for (int k < glyphs.Length)
		{
			var rect = ref rects[k];
			let packed = &outPacked[k];
			let glyph = glyphs[k];
			*packed = default;

			int32 advance = 0, leftSideBearing = 0;
			stb_truetype.stbtt_GetGlyphHMetrics(info, glyph, &advance, &leftSideBearing);
			if ((rect.w == 0) || (rect.h == 0))
			{
				packed.xadvance = scale * (float)advance;
				continue;
			}
			if (rect.was_packed == 0)
			{
				allPacked = false;
				continue;
			}

			rect.x += padding;
			rect.y += padding;
			rect.w -= padding;
			rect.h -= padding;
			int32 x0 = 0, y0 = 0, x1 = 0, y1 = 0;
			stb_truetype.stbtt_GetGlyphBitmapBox(info, glyph, scaleX, scaleY, &x0, &y0, &x1, &y1);

			// The bitmap, then both prefilters and the shift they leave, in one call.
			float subX = 0.0f, subY = 0.0f;
			let target = context.pixels + rect.x + rect.y * context.stride_in_bytes;
			stb_truetype.stbtt_MakeGlyphBitmapSubpixelPrefilter(info, target, rect.w, rect.h,
				context.stride_in_bytes, scaleX, scaleY, 0, 0, hOver, vOver, &subX, &subY, glyph);

			packed.x0 = (uint16)rect.x;
			packed.y0 = (uint16)rect.y;
			packed.x1 = (uint16)(rect.x + rect.w);
			packed.y1 = (uint16)(rect.y + rect.h);
			packed.xadvance = scale * (float)advance;
			packed.xoff = (float)x0 * recipH + subX;
			packed.yoff = (float)y0 * recipV + subY;
			packed.xoff2 = (float)(x0 + rect.w) * recipH + subX;
			packed.yoff2 = (float)(y0 + rect.h) * recipV + subY;
		}
		return allPacked;
	}
}
