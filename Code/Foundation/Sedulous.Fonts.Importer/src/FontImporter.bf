using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Importer;

/// Holds a pair of (BakedFont, BakedFontAtlas) produced by an import.
/// Caller takes ownership of both objects and is responsible for deleting
/// them (or assigning ownership to a FontResource).
public class BakedFontData
{
	public BakedFont Font;
	public BakedFontAtlas Atlas;

	public this(BakedFont font, BakedFontAtlas atlas)
	{
		Font = font;
		Atlas = atlas;
	}

	public ~this()
	{
		// Default behavior: BakedFontData owns its members unless transferred.
		if (Font != null) delete Font;
		if (Atlas != null) delete Atlas;
	}

	/// Release ownership of the contained objects; caller is responsible for
	/// deleting them afterwards. Used by callers (asset importer, font
	/// editor page builder) that want to hand the objects to a FontResource
	/// without the BakedFontData destructor freeing them.
	public (BakedFont font, BakedFontAtlas atlas) TakeOwnership()
	{
		let f = Font;
		let a = Atlas;
		Font = null;
		Atlas = null;
		return (f, a);
	}
}

/// Bakes a TrueType / OpenType font into pre-rasterized BakedFont +
/// BakedFontAtlas objects. Runs at editor / build time only. The shipped
/// game loads the saved BakedFont/BakedFontAtlas via FontResource and
/// never re-invokes the rasterizer.
public static class FontImporter
{
	/// Bake a font from raw TTF/OTF/TTC bytes with the given options.
	/// Returns null on failure. The caller takes ownership of the returned
	/// BakedFontData and must delete or call TakeOwnership() on it.
	public static Result<BakedFontData, FontLoadResult> Bake(Span<uint8> data, FontLoadOptions options = .Default)
	{
		// Re-use TrueTypeFont as the parser. It owns its font-bytes buffer,
		// so we copy the input bytes into a fresh array.
		let bytesCopy = new uint8[data.Length];
		data.CopyTo(Span<uint8>(bytesCopy));

		let ttFont = new TrueTypeFont();
		if (ttFont.Initialize(bytesCopy, options.PixelHeight) case .Err(let err))
		{
			delete ttFont;
			return .Err(err);
		}

		let ttAtlas = new TrueTypeFontAtlas();
		if (ttAtlas.Create(ttFont, options) case .Err(let atlasErr))
		{
			delete ttAtlas;
			delete ttFont;
			return .Err(atlasErr);
		}

		// Build the baked font from the parsed metrics + per-glyph info.
		let baked = new BakedFont();
		baked.SetFamilyName(ttFont.FamilyName);
		baked.SetPixelHeight(ttFont.PixelHeight);
		baked.SetMetrics(ttFont.Metrics);

		// Populate the baked atlas with the pre-rasterized pixel data + the
		// per-glyph regions for every codepoint that actually packed.
		let bakedAtlas = new BakedFontAtlas();
		let atlasW = ttAtlas.Width;
		let atlasH = ttAtlas.Height;
		let srcPixels = ttAtlas.PixelData;
		let pixelCopy = new uint8[(int)atlasW * (int)atlasH];
		if (srcPixels.Length > 0)
			srcPixels.CopyTo(Span<uint8>(pixelCopy));
		bakedAtlas.SetPixels(atlasW, atlasH, pixelCopy);

		let (whiteU, whiteV) = ttAtlas.WhitePixelUV;
		bakedAtlas.SetWhitePixelUV(whiteU, whiteV);

		// Walk the codepoint range. For each glyph that has a non-empty
		// atlas region, copy the GlyphInfo + AtlasRegion into the baked
		// tables. Kerning is captured for every pair within the same range
		// (most pairs return 0 - we filter zeros to keep the cache small).
		for (int32 cp = options.FirstCodepoint; cp <= options.LastCodepoint; cp++)
		{
			if (!ttAtlas.TryGetRegion(cp, let region))
				continue;
			let info = ttFont.GetGlyphInfo(cp);
			baked.SetGlyph(cp, info);
			bakedAtlas.SetRegion(cp, region);
		}

		// Kerning pairs. Quadratic in the codepoint count but trivial work
		// per pair (a hash table lookup inside stb_truetype). For the
		// default ASCII range (95 codepoints) this is ~9k pair lookups -
		// fine at import time.
		for (int32 a = options.FirstCodepoint; a <= options.LastCodepoint; a++)
		{
			if (!ttAtlas.Contains(a)) continue;
			for (int32 b = options.FirstCodepoint; b <= options.LastCodepoint; b++)
			{
				if (!ttAtlas.Contains(b)) continue;
				let adj = ttFont.GetKerning(a, b);
				if (adj != 0)
					baked.SetKerning(a, b, adj);
			}
		}

		delete ttAtlas;
		delete ttFont;

		return .Ok(new BakedFontData(baked, bakedAtlas));
	}
}
