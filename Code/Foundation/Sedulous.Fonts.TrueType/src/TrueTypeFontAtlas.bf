using System;
using System.Collections;
using stb_truetype;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// An atlas rasterised by stb_truetype's packer, keyed by glyph index: the glyphs a codepoint
/// range maps to, and any further glyphs asked for (what a shaper's substitutions reach), packed
/// through TrueTypeGlyphPacker, with the range's codepoint to glyph map for unshaped text.
///
/// Holds stb's own packed-character table rather than converting it to AtlasRegions,
/// because stb computes the quad itself and its correction for oversampling is the one
/// thing here that is easy to get subtly wrong.
class TrueTypeFontAtlas : IFontAtlas
{
	private uint32 mWidth;
	private uint32 mHeight;
	private List<uint8> mPixels = new .() ~ delete _;
	/// Glyph indices, in packing order.
	private List<int32> mGlyphs = new .() ~ delete _;
	/// Parallel to mGlyphs.
	private List<stbtt_packedchar> mPacked = new .() ~ delete _;
	/// Glyph index to its slot in mGlyphs.
	private Dictionary<int32, int32> mGlyphSlots = new .() ~ delete _;
	/// Codepoint to glyph index, the range's.
	private Dictionary<int32, int32> mCodepointGlyphs = new .() ~ delete _;
	private int32 mFirstCodepoint;
	private int32 mLastCodepoint;
	private float mWhitePixelU;
	private float mWhitePixelV;

	/// Rasterises the glyphs of the requested codepoint range, plus `extraGlyphs` (glyph
	/// indices no codepoint reaches), into a new atlas.
	///
	/// Every glyph is packed in ONE call: stb's packer places glyphs by shelf, and feeding it
	/// everything at once is what lets it choose a tight arrangement. A set too large for the
	/// atlas fails rather than silently dropping the glyphs that did not fit, because a page
	/// of missing boxes is much harder to diagnose than a refusal.
	public FontLoadResult Create(TrueTypeFont font, FontLoadOptions options, Span<int32> extraGlyphs = default)
	{
		if (font.RawData == null)
			return .InvalidFormat;

		mWidth = options.AtlasWidth;
		mHeight = options.AtlasHeight;
		mFirstCodepoint = options.FirstCodepoint;
		mLastCodepoint = options.LastCodepoint;
		if ((mWidth == 0) || (mHeight == 0) || (options.CharacterCount <= 0))
			return .AtlasPackingFailed;

		mPixels.Clear();
		mPixels.Resize((int)mWidth * (int)mHeight);
		mGlyphs.Clear();
		mGlyphSlots.Clear();
		mCodepointGlyphs.Clear();

		// The range's glyphs (a codepoint the font lacks maps to none), then the extras, each once.
		let info = font.FontInfo;
		for (int32 codepoint = mFirstCodepoint; codepoint <= mLastCodepoint; codepoint++)
		{
			let glyph = stb_truetype.stbtt_FindGlyphIndex(info, codepoint);
			if (glyph <= 0)
				continue;
			mCodepointGlyphs[codepoint] = glyph;
			AddGlyph(glyph);
		}
		for (let glyph in extraGlyphs)
		{
			if ((glyph > 0) && (glyph < info.numGlyphs))
				AddGlyph(glyph);
		}
		mPacked.Clear();
		mPacked.Resize(mGlyphs.Count);

		stbtt_pack_context packContext = default;
		if (stb_truetype.stbtt_PackBegin(&packContext, mPixels.Ptr, (int32)mWidth, (int32)mHeight,
			0, (int32)options.Padding, null) == 0)
			return .AtlasPackingFailed;

		stb_truetype.stbtt_PackSetOversampling(&packContext, options.OversampleX, options.OversampleY);

		let packed = TrueTypeGlyphPacker.Pack(&packContext, info, options.PixelHeight,
			.(mGlyphs.Ptr, mGlyphs.Count), mPacked.Ptr);

		// PackEnd on BOTH paths: it frees the packer's own nodes, and skipping it on the
		// failure path leaks them exactly when something has already gone wrong.
		stb_truetype.stbtt_PackEnd(&packContext);
		if (!packed)
			return .AtlasPackingFailed;

		WriteWhiteTexel();
		return .Success;
	}

	private void AddGlyph(int32 glyph)
	{
		if (mGlyphSlots.ContainsKey(glyph))
			return;
		mGlyphSlots[glyph] = (int32)mGlyphs.Count;
		mGlyphs.Add(glyph);
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

	/// The glyphs packed, in packing order, and the codepoint to glyph map, for bakers that
	/// copy this atlas into their own.
	public Span<int32> Glyphs => .(mGlyphs.Ptr, mGlyphs.Count);
	public Dictionary<int32, int32> CodepointGlyphs => mCodepointGlyphs;

	// ---- IFontAtlas ----

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override Span<uint8> PixelData => mPixels.IsEmpty ? .() : .(mPixels.Ptr, mPixels.Count);
	public override Float2 WhitePixelUV => .(mWhitePixelU, mWhitePixelV);

	public override int32 GlyphFor(int32 codepoint)
		=> mCodepointGlyphs.TryGetValue(codepoint, let glyph) ? glyph : -1;

	/// A glyph with pixels. A blank one (a space) packed only its advance, so it is not here.
	public override bool Contains(int32 glyphId)
	{
		if (!mGlyphSlots.TryGetValue(glyphId, let slot))
			return false;
		let packed = mPacked[slot];
		return (packed.x1 > packed.x0) && (packed.y1 > packed.y0);
	}

	public override bool TryGetRegion(int32 glyphId, out AtlasRegion region)
	{
		region = .();
		if (!Contains(glyphId))
			return false;

		let packed = mPacked[mGlyphSlots[glyphId]];
		region = .((uint16)packed.x0, (uint16)packed.y0,
			(uint16)(packed.x1 - packed.x0), (uint16)(packed.y1 - packed.y0),
			packed.xoff, packed.yoff, packed.xadvance);
		return true;
	}

	public override bool GetGlyphQuad(int32 glyphId, ref float cursorX, float cursorY,
		out GlyphQuad quad)
	{
		quad = .();
		if (!mGlyphSlots.TryGetValue(glyphId, let slot))
			return false;

		// stb steps the cursor and applies the oversampling correction itself, which is
		// why the packed table is kept rather than flattened into regions.
		float y = cursorY;
		stbtt_aligned_quad aligned = default;
		stb_truetype.stbtt_GetPackedQuad(mPacked.Ptr, (int32)mWidth, (int32)mHeight,
			slot, &cursorX, &y, &aligned, 0);

		// A blank glyph (a space) packed as a zero-area record: the cursor has stepped past
		// its advance and there is nothing to draw.
		if ((aligned.x1 <= aligned.x0) || (aligned.y1 <= aligned.y0))
			return false;

		quad = .(aligned.x0, aligned.y0, aligned.x1, aligned.y1,
			aligned.s0, aligned.t0, aligned.s1, aligned.t1);
		return true;
	}

	public override bool GetGlyphQuadAt(int32 glyphId, float x, float y, out GlyphQuad quad)
	{
		// Its own cursor, discarded: this placement is absolute.
		var cursorX = x;
		return GetGlyphQuad(glyphId, ref cursorX, y, out quad);
	}
}
