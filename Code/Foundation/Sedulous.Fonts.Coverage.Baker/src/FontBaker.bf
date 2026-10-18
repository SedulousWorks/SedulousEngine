using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.Coverage.Baker;

/// Turns TrueType bytes into a pre-rasterized coverage atlas, at tooling time.
///
/// This is the tooling half of Fonts.Coverage: the rasterizer runs HERE, and the packaged
/// game loads what came out and never links stb_truetype. It lives in Foundation rather
/// than Pipeline because callers with no cook context bake with it, the editor's live font
/// preview among them, so it takes bytes and options and nothing else.
static class FontBaker
{
	/// Bakes from raw TTF, OTF or TTC bytes. The caller owns what comes back.
	///
	/// The bytes are COPIED, because TrueTypeFont points into its buffer for life and the
	/// caller's span is not ours to hold.
	public static Result<BakedFontData, FontLoadResult> Bake(Span<uint8> data, FontLoadOptions options)
	{
		let bytes = new List<uint8>();
		if (!data.IsEmpty)
		{
			bytes.Resize(data.Length);
			Internal.MemCpy(bytes.Ptr, data.Ptr, data.Length);
		}

		let source = new TrueTypeFont();
		// Initialize ADOPTS the list, so a failure past this point is the font's to free.
		let initResult = source.Initialize(bytes, options.PixelHeight);
		if (initResult != .Success)
		{
			delete source;
			return .Err(initResult);
		}
		defer delete source;

		// The range's glyphs, and what the registered shaper's substitutions reach from them.
		let reachable = scope List<int32>();
		TextShaperFactory.ReachableGlyphs(source, options, reachable);
		let rasterized = scope TrueTypeFontAtlas();
		let atlasResult = rasterized.Create(source, options, reachable);
		if (atlasResult != .Success)
			return .Err(atlasResult);

		let baked = new BakedFont();
		{
			let family = scope String();
			source.GetFamilyName(family);
			baked.SetFamilyName(family);
		}
		baked.SetPixelHeight(source.PixelHeight);
		baked.SetMetrics(source.Metrics);

		let bakedAtlas = new BakedFontAtlas();
		CopyPixels(rasterized, bakedAtlas);

		let white = rasterized.WhitePixelUV;
		bakedAtlas.SetWhitePixelUV(white.X, white.Y);
		// The oversampling travels with the atlas: the quad arithmetic divides the span by
		// it, and a baked atlas has no packer left to ask.
		bakedAtlas.SetOversample((float)options.OversampleX, (float)options.OversampleY);

		CopyGlyphs(source, rasterized, baked, bakedAtlas, options);
		CopyKerning(source, rasterized, baked, options);

		return .Ok(new BakedFontData(baked, bakedAtlas));
	}

	private static void CopyPixels(TrueTypeFontAtlas source, BakedFontAtlas target)
	{
		let width = source.Width;
		let height = source.Height;
		let sourcePixels = source.PixelData;

		let copy = new List<uint8>();
		copy.Resize((int)width * (int)height);
		if (!copy.IsEmpty)
		{
			Internal.MemSet(copy.Ptr, 0, copy.Count);
			if (!sourcePixels.IsEmpty)
				Internal.MemCpy(copy.Ptr, sourcePixels.Ptr, Math.Min(sourcePixels.Length, copy.Count));
		}
		target.SetPixels(width, height, copy);
	}

	/// Every codepoint the range maps to keeps its glyph info and its glyph (a space too: it
	/// draws nothing but advances), and every glyph that packed its region, by glyph index; a
	/// mapped glyph with nothing to draw gets an advance-only region. A codepoint the typeface
	/// has no glyph for is absent from both tables rather than present and blank, which is what
	/// lets GlyphFor answer honestly at runtime.
	private static void CopyGlyphs(TrueTypeFont source, TrueTypeFontAtlas rasterized,
		BakedFont baked, BakedFontAtlas bakedAtlas, FontLoadOptions options)
	{
		for (let pair in rasterized.CodepointGlyphs)
		{
			let info = source.GetGlyphInfo(pair.key);
			baked.SetGlyph(pair.key, info);
			bakedAtlas.SetGlyphFor(pair.key, pair.value);
			if (!rasterized.TryGetRegion(pair.value, ?))
				bakedAtlas.SetRegion(pair.value, .(0, 0, 0, 0, 0.0f, 0.0f, info.AdvanceWidth));
		}
		for (let glyph in rasterized.Glyphs)
		{
			if (rasterized.TryGetRegion(glyph, let region))
				bakedAtlas.SetRegion(glyph, region);
		}
	}

	/// Every pair in the range, keeping only the non-zero ones.
	///
	/// Quadratic, but over the baked range and at tooling time: the default ASCII range is
	/// about nine thousand lookups, and storing only what is non-zero is what keeps the
	/// baked table small enough to be worth shipping.
	private static void CopyKerning(TrueTypeFont source, TrueTypeFontAtlas rasterized,
		BakedFont baked, FontLoadOptions options)
	{
		for (int32 first = options.FirstCodepoint; first <= options.LastCodepoint; first++)
		{
			if (!rasterized.Contains(rasterized.GlyphFor(first)))
				continue;
			for (int32 second = options.FirstCodepoint; second <= options.LastCodepoint; second++)
			{
				if (!rasterized.Contains(rasterized.GlyphFor(second)))
					continue;
				let adjustment = source.GetKerning(first, second);
				if (adjustment != 0)
					baked.SetKerning(first, second, adjustment);
			}
		}
	}
}
