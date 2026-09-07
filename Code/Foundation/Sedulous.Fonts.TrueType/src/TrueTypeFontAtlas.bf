using System;
using System.Collections;
using stb_truetype;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// An atlas rasterised by stb_truetype's packer.
///
/// Holds stb's own packed-character table rather than converting it to AtlasRegions,
/// because stb computes the quad itself and its correction for oversampling is the one
/// thing here that is easy to get subtly wrong.
class TrueTypeFontAtlas : IFontAtlas
{
	private uint32 mWidth;
	private uint32 mHeight;
	private List<uint8> mPixels = new .() ~ delete _;
	private List<stbtt_packedchar> mPacked = new .() ~ delete _;
	private int32 mFirstCodepoint;
	private int32 mLastCodepoint;
	private float mWhitePixelU;
	private float mWhitePixelV;

	/// Rasterises the requested codepoint range into a new atlas.
	///
	/// The whole range is packed in ONE call: stb's packer places glyphs by shelf, and
	/// feeding it everything at once is what lets it choose a tight arrangement. A range
	/// too large for the atlas fails rather than silently dropping the glyphs that did not
	/// fit, because a page of missing boxes is much harder to diagnose than a refusal.
	public FontLoadResult Create(TrueTypeFont font, FontLoadOptions options)
	{
		if (font.RawData == null)
			return .InvalidFormat;

		mWidth = options.AtlasWidth;
		mHeight = options.AtlasHeight;
		mFirstCodepoint = options.FirstCodepoint;
		mLastCodepoint = options.LastCodepoint;
		let characterCount = options.CharacterCount;
		if ((mWidth == 0) || (mHeight == 0) || (characterCount <= 0))
			return .AtlasPackingFailed;

		mPixels.Clear();
		mPixels.Resize((int)mWidth * (int)mHeight);
		mPacked.Clear();
		mPacked.Resize(characterCount);

		stbtt_pack_context packContext = default;
		if (stb_truetype.stbtt_PackBegin(&packContext, mPixels.Ptr, (int32)mWidth, (int32)mHeight,
			0, (int32)options.Padding, null) == 0)
			return .AtlasPackingFailed;

		stb_truetype.stbtt_PackSetOversampling(&packContext, options.OversampleX, options.OversampleY);

		let packed = stb_truetype.stbtt_PackFontRange(&packContext, font.RawData, 0,
			options.PixelHeight, mFirstCodepoint, characterCount, mPacked.Ptr);

		// PackEnd on BOTH paths: it frees the packer's own nodes, and skipping it on the
		// failure path leaks them exactly when something has already gone wrong.
		stb_truetype.stbtt_PackEnd(&packContext);
		if (packed == 0)
			return .AtlasPackingFailed;

		WriteWhiteTexel();
		return .Success;
	}

	/// A solid two by two block in the bottom right corner.
	///
	/// Two by two rather than one, and sampled at its centre, so a linear filter lands
	/// fully inside it: a single texel would blend with its blank neighbours and the
	/// "white" would come out grey. This is what lets a caret, an underline or a selection
	/// fill be drawn from the same texture, and so the same draw call, as the text.
	private void WriteWhiteTexel()
	{
		if ((mWidth < 2) || (mHeight < 2))
			return;

		let x = mWidth - 2;
		let y = mHeight - 2;
		mPixels[(int)(y * mWidth + x)] = 255;
		mPixels[(int)(y * mWidth + x + 1)] = 255;
		mPixels[(int)((y + 1) * mWidth + x)] = 255;
		mPixels[(int)((y + 1) * mWidth + x + 1)] = 255;

		mWhitePixelU = (x + 0.5f) / (float)mWidth;
		mWhitePixelV = (y + 0.5f) / (float)mHeight;
	}

	public void SetWhitePixelUV(float u, float v)
	{
		mWhitePixelU = u;
		mWhitePixelV = v;
	}

	public int32 FirstCodepoint => mFirstCodepoint;
	public int32 LastCodepoint => mLastCodepoint;

	// ---- IFontAtlas ----

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override Span<uint8> PixelData => mPixels.IsEmpty ? .() : .(mPixels.Ptr, mPixels.Count);
	public override Float2 WhitePixelUV => .(mWhitePixelU, mWhitePixelV);

	/// The atlas holds the RANGE it was baked for and nothing else. A codepoint outside it
	/// was never rasterised, whatever the font itself has.
	public override bool Contains(int32 codepoint)
		=> (codepoint >= mFirstCodepoint) && (codepoint <= mLastCodepoint)
			&& (IndexOf(codepoint) < mPacked.Count);

	public override bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		region = .();
		if (!Contains(codepoint))
			return false;

		let packed = mPacked[IndexOf(codepoint)];
		region = .((uint16)packed.x0, (uint16)packed.y0,
			(uint16)(packed.x1 - packed.x0), (uint16)(packed.y1 - packed.y0),
			packed.xoff, packed.yoff, packed.xadvance);
		return true;
	}

	public override bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY,
		out GlyphQuad quad)
	{
		quad = .();
		if (!Contains(codepoint))
			return false;

		// stb steps the cursor and applies the oversampling correction itself, which is
		// why the packed table is kept rather than flattened into regions.
		float y = cursorY;
		stbtt_aligned_quad aligned = default;
		stb_truetype.stbtt_GetPackedQuad(mPacked.Ptr, (int32)mWidth, (int32)mHeight,
			IndexOf(codepoint), &cursorX, &y, &aligned, 0);

		// A degenerate box has nothing to draw. Note this does NOT catch a space: stb packs
		// one as a one by one texel of blank atlas rather than as nothing, so a space
		// returns a quad here, unlike a baked atlas where an advance-only region reports
		// false. Drawing it is harmless, being blank, and matching stb is what keeps the
		// cursor arithmetic identical to stbtt_GetPackedQuad's.
		if ((aligned.x1 <= aligned.x0) || (aligned.y1 <= aligned.y0))
			return false;

		quad = .(aligned.x0, aligned.y0, aligned.x1, aligned.y1,
			aligned.s0, aligned.t0, aligned.s1, aligned.t1);
		return true;
	}

	public override bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		// Its own cursor, discarded: this placement is absolute.
		var cursorX = x;
		return GetGlyphQuad(codepoint, ref cursorX, y, out quad);
	}

	private int32 IndexOf(int32 codepoint) => codepoint - mFirstCodepoint;
}
