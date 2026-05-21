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

		// Extract the font's family name from the name table. Tries the
		// most common platform/encoding/language tuples in order and falls
		// back to a generic placeholder if none yield a usable string.
		ExtractFamilyName(&mFontInfo, mFamilyName);

		return .Ok;
	}

	/// Populates `outName` with the font's family name read from the name
	/// table. Tries (in order): Microsoft Unicode English, Microsoft
	/// Unicode any-language, Macintosh Roman English. Each Microsoft
	/// platform string is big-endian UTF-16 - we decode it to UTF-8.
	/// Falls back to "TrueType Font" if no name can be extracted.
	private static void ExtractFamilyName(stbtt_fontinfo* font, String outName)
	{
		outName.Clear();

		// nameID 1 = Font Family. The OpenType "Typographic Family Name"
		// (nameID 16) is sometimes preferred for OT but stb's older fonts
		// use 1 everywhere; ID 1 is the safe default.
		const int32 NAME_ID_FAMILY = 1;

		// Microsoft Unicode BMP, English (US).
		if (TryReadUtf16Name(font, 3, 1, 0x0409, NAME_ID_FAMILY, outName))
			return;
		// Microsoft Unicode BMP, any language.
		if (TryReadUtf16NameAnyLanguage(font, 3, 1, NAME_ID_FAMILY, outName))
			return;
		// Macintosh Roman, English. 8-bit, treat as Latin-1.
		if (TryReadLatin1Name(font, 1, 0, 0, NAME_ID_FAMILY, outName))
			return;

		outName.Set("TrueType Font");
	}

	/// Reads a big-endian UTF-16 name string with the exact platform/
	/// encoding/language/nameID tuple. Returns true if found + non-empty.
	private static bool TryReadUtf16Name(stbtt_fontinfo* font, int32 platformID, int32 encodingID, int32 languageID, int32 nameID, String outName)
	{
		int32 byteLen = 0;
		let bytes = stbtt_GetFontNameString(font, &byteLen, platformID, encodingID, languageID, nameID);
		if (bytes == null || byteLen <= 0)
			return false;
		AppendBigEndianUtf16(bytes, byteLen, outName);
		return !outName.IsEmpty;
	}

	/// Like TryReadUtf16Name but walks common English language codes when
	/// the exact language isn't present (some fonts only ship one
	/// language).
	private static bool TryReadUtf16NameAnyLanguage(stbtt_fontinfo* font, int32 platformID, int32 encodingID, int32 nameID, String outName)
	{
		// Common Microsoft language IDs to try (English variants, then 0).
		int32[?] languages = .(0x0809, 0x0c09, 0x1009, 0x1409, 0);
		for (let lang in languages)
		{
			if (TryReadUtf16Name(font, platformID, encodingID, lang, nameID, outName))
				return true;
		}
		return false;
	}

	/// Reads an 8-bit name string (Macintosh Roman, treat as Latin-1).
	private static bool TryReadLatin1Name(stbtt_fontinfo* font, int32 platformID, int32 encodingID, int32 languageID, int32 nameID, String outName)
	{
		int32 byteLen = 0;
		let bytes = stbtt_GetFontNameString(font, &byteLen, platformID, encodingID, languageID, nameID);
		if (bytes == null || byteLen <= 0)
			return false;
		outName.Clear();
		for (int32 i = 0; i < byteLen; i++)
		{
			let b = (uint8)bytes[i];
			if (b == 0) continue; // skip embedded nulls just in case
			if (b < 0x80)
				outName.Append((char8)b);
			else
			{
				// Latin-1 high bytes -> UTF-8 two-byte sequence.
				outName.Append((char8)(0xC0 | (b >> 6)));
				outName.Append((char8)(0x80 | (b & 0x3F)));
			}
		}
		return !outName.IsEmpty;
	}

	/// Decodes `byteLen` bytes of big-endian UTF-16 starting at `bytes`
	/// into `out` as UTF-8. Surrogate pairs are passed through as-is; for
	/// font family names that's almost never an issue (basic Latin /
	/// non-Latin scripts in the BMP).
	private static void AppendBigEndianUtf16(char8* bytes, int32 byteLen, String @out)
	{
		@out.Clear();
		let p = (uint8*)bytes;
		var i = 0;
		while (i + 1 < byteLen)
		{
			let hi = (uint16)p[i];
			let lo = (uint16)p[i + 1];
			let cp = (hi << 8) | lo;
			i += 2;
			if (cp == 0) continue;
			if (cp < 0x80)
			{
				@out.Append((char8)cp);
			}
			else if (cp < 0x800)
			{
				@out.Append((char8)(0xC0 | (cp >> 6)));
				@out.Append((char8)(0x80 | (cp & 0x3F)));
			}
			else
			{
				@out.Append((char8)(0xE0 | (cp >> 12)));
				@out.Append((char8)(0x80 | ((cp >> 6) & 0x3F)));
				@out.Append((char8)(0x80 | (cp & 0x3F)));
			}
		}
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
