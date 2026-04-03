using System;
using System.Collections;
using Sedulous.Fonts;
using stb_truetype;

namespace Sedulous.Fonts.TTF;

/// TrueType font implementation using stb_truetype
public class TrueTypeFont : IFont
{
	private String mFamilyName ~ delete _;
	private FontMetrics mMetrics;
	private float mPixelHeight;
	private uint8[] mFontData ~ delete _;
	private stbtt_fontinfo mFontInfo;
	private float mScale;
	private Dictionary<int32, GlyphInfo> mGlyphCache ~ delete _;

	public String FamilyName => mFamilyName;
	public FontMetrics Metrics => mMetrics;
	public float PixelHeight => mPixelHeight;

	public this()
	{
		mFamilyName = new .();
		mGlyphCache = new .();
	}

	/// Initialize from font data (takes ownership of fontData)
	public Result<void, FontLoadResult> Initialize(uint8[] fontData, float pixelHeight)
	{
		mFontData = fontData;
		mPixelHeight = pixelHeight;

		// Get font offset (for TTC collections, use first font)
		let offset = stbtt_GetFontOffsetForIndex(mFontData.Ptr, 0);
		if (offset < 0)
			return .Err(.InvalidFormat);

		// Initialize stb_truetype
		if (stbtt_InitFont(&mFontInfo, mFontData.Ptr, offset) == 0)
			return .Err(.CorruptedData);

		// Calculate scale factor
		mScale = stbtt_ScaleForPixelHeight(&mFontInfo, pixelHeight);

		// Get vertical metrics
		int32 ascent = 0, descent = 0, lineGap = 0;
		stbtt_GetFontVMetrics(&mFontInfo, &ascent, &descent, &lineGap);

		mMetrics = .(
			ascent * mScale,
			descent * mScale,
			lineGap * mScale,
			pixelHeight,
			mScale
		);

		// Set font name (simplified - could extract from font tables)
		mFamilyName.Set("TrueType Font");

		return .Ok;
	}

	public GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		// Check cache first
		if (mGlyphCache.TryGetValue(codepoint, let cached))
			return cached;

		GlyphInfo info = .();
		info.Codepoint = codepoint;
		info.GlyphIndex = stbtt_FindGlyphIndex(&mFontInfo, codepoint);

		if (info.GlyphIndex > 0)
		{
			// Get horizontal metrics
			int32 advanceWidth = 0, leftSideBearing = 0;
			stbtt_GetGlyphHMetrics(&mFontInfo, info.GlyphIndex, &advanceWidth, &leftSideBearing);
			info.AdvanceWidth = advanceWidth * mScale;
			info.LeftSideBearing = leftSideBearing * mScale;

			// Get glyph bitmap bounding box
			int32 x0 = 0, y0 = 0, x1 = 0, y1 = 0;
			stbtt_GetGlyphBitmapBox(&mFontInfo, info.GlyphIndex, mScale, mScale, &x0, &y0, &x1, &y1);

			info.BoundingBox = .((float)x0, (float)y0, (float)(x1 - x0), (float)(y1 - y0));
			info.HasBitmap = (x1 - x0) > 0 && (y1 - y0) > 0;
		}

		// Cache the result
		mGlyphCache[codepoint] = info;

		return info;
	}

	public float GetKerning(int32 firstCodepoint, int32 secondCodepoint)
	{
		let kern = stbtt_GetCodepointKernAdvance(&mFontInfo, firstCodepoint, secondCodepoint);
		return kern * mScale;
	}

	public bool HasGlyph(int32 codepoint)
	{
		return stbtt_FindGlyphIndex(&mFontInfo, codepoint) > 0;
	}

	public float MeasureString(StringView text)
	{
		float width = 0;
		int32 prevCodepoint = 0;

		for (let c in text.DecodedChars)
		{
			let codepoint = (int32)c;
			let glyphInfo = GetGlyphInfo(codepoint);

			// Add kerning
			if (prevCodepoint != 0)
				width += GetKerning(prevCodepoint, codepoint);

			width += glyphInfo.AdvanceWidth;
			prevCodepoint = codepoint;
		}

		return width;
	}

	public float MeasureString(StringView text, List<GlyphPosition> outPositions)
	{
		float x = 0;
		int32 prevCodepoint = 0;
		int32 index = 0;

		outPositions.Clear();

		for (let c in text.DecodedChars)
		{
			let codepoint = (int32)c;
			let glyphInfo = GetGlyphInfo(codepoint);

			// Add kerning
			if (prevCodepoint != 0)
				x += GetKerning(prevCodepoint, codepoint);

			GlyphPosition pos = .(index, codepoint, x, 0, glyphInfo.AdvanceWidth, glyphInfo);
			outPositions.Add(pos);

			x += glyphInfo.AdvanceWidth;
			prevCodepoint = codepoint;
			index++;
		}

		return x;
	}
}
