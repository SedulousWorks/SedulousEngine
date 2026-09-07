using System;
using System.Collections;
using stb_truetype;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// An IFont over a parsed TrueType, OpenType or collection file.
///
/// OWNS the font bytes for its whole life: stb_truetype does not copy them, it points into
/// them, so every metric read afterwards reads that buffer. Freeing it early is a
/// use after free that only shows up on the next glyph asked for.
class TrueTypeFont : IFont
{
	private String mFamilyName = new .() ~ delete _;
	private FontMetrics mMetrics = .Default();
	private float mPixelHeight;
	private List<uint8> mFontData = new .() ~ delete _;
	private stbtt_fontinfo mFontInfo;
	/// Font units to pixels at this size.
	private float mScale;
	/// Glyph lookup walks the font's tables, so a measured string would pay for it once per
	/// character per frame.
	private Dictionary<int32, GlyphInfo> mGlyphCache = new .() ~ delete _;

	/// TAKES the bytes. The caller must not free or touch them afterwards.
	public FontLoadResult Initialize(List<uint8> fontData, float pixelHeight)
	{
		delete mFontData;
		mFontData = fontData;
		mPixelHeight = pixelHeight;

		if (mFontData.IsEmpty)
			return .InvalidFormat;

		// A collection holds several fonts; the first is the one meant.
		let offset = stb_truetype.stbtt_GetFontOffsetForIndex(mFontData.Ptr, 0);
		if (offset < 0)
			return .InvalidFormat;

		if (stb_truetype.stbtt_InitFont(&mFontInfo, mFontData.Ptr, offset) == 0)
			return .CorruptedData;

		mScale = stb_truetype.stbtt_ScaleForPixelHeight(&mFontInfo, pixelHeight);

		int32 ascent = 0, descent = 0, lineGap = 0;
		stb_truetype.stbtt_GetFontVMetrics(&mFontInfo, &ascent, &descent, &lineGap);
		mMetrics = .(ascent * mScale, descent * mScale, lineGap * mScale, pixelHeight, mScale);

		ExtractFamilyName();
		return .Success;
	}

	/// The raw bytes, for a baker that drives stb's packer or reads the outlines itself.
	/// BORROWED: this font still owns them.
	public uint8* RawData => mFontData.IsEmpty ? null : mFontData.Ptr;
	public int RawDataSize => mFontData.Count;

	/// The parsed font, for a baker that needs to walk glyph outlines.
	public stbtt_fontinfo* FontInfo => &mFontInfo;
	public float Scale => mScale;

	// ---- IFont ----

	public override uint32 BackendTypeId => TrueTypeCommon.BackendTypeId;
	public override void GetFamilyName(String outName) => outName.Append(mFamilyName);
	public override FontMetrics Metrics => mMetrics;
	public override float PixelHeight => mPixelHeight;

	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		if (mGlyphCache.TryGetValue(codepoint, let cached))
			return cached;

		var info = GlyphInfo();
		info.Codepoint = codepoint;
		info.GlyphIndex = stb_truetype.stbtt_FindGlyphIndex(&mFontInfo, codepoint);

		// Index zero is the missing glyph, which has no metrics worth reading.
		if (info.GlyphIndex > 0)
		{
			int32 advanceWidth = 0, leftSideBearing = 0;
			stb_truetype.stbtt_GetGlyphHMetrics(&mFontInfo, info.GlyphIndex, &advanceWidth,
				&leftSideBearing);
			info.AdvanceWidth = advanceWidth * mScale;
			info.LeftSideBearing = leftSideBearing * mScale;

			int32 x0 = 0, y0 = 0, x1 = 0, y1 = 0;
			stb_truetype.stbtt_GetGlyphBitmapBox(&mFontInfo, info.GlyphIndex, mScale, mScale,
				&x0, &y0, &x1, &y1);
			info.BoundingBox = .((float)x0, (float)y0, (float)(x1 - x0), (float)(y1 - y0));
			// A space has an advance and an empty box, which is not the same as a glyph
			// that failed to load.
			info.HasBitmap = ((x1 - x0) > 0) && ((y1 - y0) > 0);
		}

		// Cached whether or not it resolved: a codepoint the font lacks is asked for just
		// as often, and re-walking the tables to fail again costs the same.
		mGlyphCache[codepoint] = info;
		return info;
	}

	public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint)
	{
		let kern = stb_truetype.stbtt_GetCodepointKernAdvance(&mFontInfo, firstCodepoint,
			secondCodepoint);
		return kern * mScale;
	}

	public override bool HasGlyph(int32 codepoint)
		=> stb_truetype.stbtt_FindGlyphIndex(&mFontInfo, codepoint) > 0;

	public override float MeasureString(StringView text)
	{
		float width = 0;
		int32 previous = 0;
		int i = 0;
		while (i < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref i);
			if (previous != 0)
				width += GetKerning(previous, codepoint);
			width += GetGlyphInfo(codepoint).AdvanceWidth;
			previous = codepoint;
		}
		return width;
	}

	public override float MeasureString(StringView text, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();

		float x = 0;
		int32 previous = 0;
		int32 index = 0;
		int i = 0;
		while (i < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref i);
			let info = GetGlyphInfo(codepoint);
			if (previous != 0)
				x += GetKerning(previous, codepoint);

			var position = GlyphPosition();
			position.StringIndex = index;
			position.Codepoint = codepoint;
			position.X = x;
			position.Y = 0;
			position.Advance = info.AdvanceWidth;
			position.GlyphInfo = info;
			outPositions.Add(position);

			x += info.AdvanceWidth;
			previous = codepoint;
			index++;
		}
		return x;
	}

	/// Reads the family name from the font's name table.
	///
	/// Tried in order: Microsoft Unicode in English, then Microsoft Unicode in the other
	/// English locales, then Macintosh Roman. A font may carry any subset of those, and one
	/// that carries none still has to be nameable, so there is a placeholder at the end
	/// rather than an empty name.
	private void ExtractFamilyName()
	{
		mFamilyName.Clear();

		const int32 cNameIdFamily = 1;
		const int32 cPlatformMicrosoft = 3;
		const int32 cEncodingUnicodeBmp = 1;
		const int32 cPlatformMacintosh = 1;
		const int32 cEncodingMacRoman = 0;

		if (TryReadUtf16Name(cPlatformMicrosoft, cEncodingUnicodeBmp, 0x0409, cNameIdFamily))
			return;

		// The other English locales, in the order a font is likely to carry them.
		let languages = scope int32[](0x0809, 0x0c09, 0x1009, 0x1409, 0);
		for (let language in languages)
		{
			if (TryReadUtf16Name(cPlatformMicrosoft, cEncodingUnicodeBmp, language, cNameIdFamily))
				return;
		}

		if (TryReadLatin1Name(cPlatformMacintosh, cEncodingMacRoman, 0, cNameIdFamily))
			return;

		mFamilyName.Set("TrueType Font");
	}

	/// Microsoft name records are BIG ENDIAN UTF-16, whatever the host's byte order.
	private bool TryReadUtf16Name(int32 platformId, int32 encodingId, int32 languageId, int32 nameId)
	{
		int32 byteLength = 0;
		let bytes = stb_truetype.stbtt_GetFontNameString(&mFontInfo, &byteLength, platformId,
			encodingId, languageId, nameId);
		if ((bytes == null) || (byteLength <= 0))
			return false;

		mFamilyName.Clear();
		let raw = (uint8*)bytes;
		int i = 0;
		while ((i + 1) < byteLength)
		{
			let codepoint = (uint32)(((uint32)raw[i] << 8) | raw[i + 1]);
			i += 2;
			// Padding nulls appear inside these records; they are not terminators.
			if (codepoint == 0)
				continue;
			// The basic plane only. A lone surrogate passes through as its own unit value
			// rather than being dropped, which keeps a malformed name readable.
			AppendUtf8(mFamilyName, codepoint);
		}
		return !mFamilyName.IsEmpty;
	}

	/// A Macintosh Roman record. Latin-1 and Unicode agree on the first 256 codepoints, so
	/// each byte is its own character.
	private bool TryReadLatin1Name(int32 platformId, int32 encodingId, int32 languageId, int32 nameId)
	{
		int32 byteLength = 0;
		let bytes = stb_truetype.stbtt_GetFontNameString(&mFontInfo, &byteLength, platformId,
			encodingId, languageId, nameId);
		if ((bytes == null) || (byteLength <= 0))
			return false;

		mFamilyName.Clear();
		for (int i < byteLength)
		{
			let b = (uint8)bytes[i];
			if (b == 0)
				continue;
			AppendUtf8(mFamilyName, (uint32)b);
		}
		return !mFamilyName.IsEmpty;
	}

	/// Encodes one basic-plane codepoint as UTF-8.
	private static void AppendUtf8(String output, uint32 codepoint)
	{
		if (codepoint < 0x80)
		{
			output.Append((char8)codepoint);
		}
		else if (codepoint < 0x800)
		{
			output.Append((char8)(0xC0 | (codepoint >> 6)));
			output.Append((char8)(0x80 | (codepoint & 0x3F)));
		}
		else
		{
			output.Append((char8)(0xE0 | (codepoint >> 12)));
			output.Append((char8)(0x80 | ((codepoint >> 6) & 0x3F)));
			output.Append((char8)(0x80 | (codepoint & 0x3F)));
		}
	}
}
