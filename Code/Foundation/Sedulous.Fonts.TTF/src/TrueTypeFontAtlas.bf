using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Imaging;
using stb_truetype;

namespace Sedulous.Fonts.TTF;

/// Font atlas implementation using stb_truetype packed font API
public class TrueTypeFontAtlas : IFontAtlas
{
	private uint32 mWidth;
	private uint32 mHeight;
	private uint8[] mPixelData ~ delete _;
	private stbtt_packedchar[] mPackedChars ~ delete _;
	private int32 mFirstCodepoint;
	private int32 mLastCodepoint;
	private int32 mNumChars;
	private float mWhitePixelU;
	private float mWhitePixelV;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public Span<uint8> PixelData => mPixelData;
	public (float U, float V) WhitePixelUV => (mWhitePixelU, mWhitePixelV);

	public this() { }

	/// Create atlas from a TrueType font
	public Result<void, FontLoadResult> Create(TrueTypeFont font, FontLoadOptions options)
	{
		mWidth = options.AtlasWidth;
		mHeight = options.AtlasHeight;
		mFirstCodepoint = options.FirstCodepoint;
		mLastCodepoint = options.LastCodepoint;
		mNumChars = mLastCodepoint - mFirstCodepoint + 1;

		// Allocate pixel data
		mPixelData = new uint8[mWidth * mHeight];

		// Allocate packed char data
		mPackedChars = new stbtt_packedchar[mNumChars];

		// Initialize packing context
		stbtt_pack_context packContext = .();
		if (stbtt_PackBegin(&packContext, mPixelData.Ptr, (int32)mWidth, (int32)mHeight, 0, (int32)options.Padding, null) == 0)
			return .Err(.AtlasPackingFailed);

		// Set oversampling for better quality
		stbtt_PackSetOversampling(&packContext, (uint32)options.OversampleX, (uint32)options.OversampleY);

		// Pack the font range using the simpler API
		if (stbtt_PackFontRange(&packContext, font.[Friend]mFontData.Ptr, 0, options.PixelHeight,
			mFirstCodepoint, mNumChars, mPackedChars.Ptr) == 0)
		{
			stbtt_PackEnd(&packContext);
			return .Err(.AtlasPackingFailed);
		}

		stbtt_PackEnd(&packContext);

		// Add a solid white pixel in the bottom-right corner for drawing lines/rects
		// Place it 1 pixel from edge to avoid filtering artifacts
		uint32 whiteX = mWidth - 2;
		uint32 whiteY = mHeight - 2;
		mPixelData[whiteY * mWidth + whiteX] = 255;
		// Also set neighboring pixels to avoid bilinear filtering artifacts
		mPixelData[whiteY * mWidth + whiteX + 1] = 255;
		mPixelData[(whiteY + 1) * mWidth + whiteX] = 255;
		mPixelData[(whiteY + 1) * mWidth + whiteX + 1] = 255;

		// Store UV coordinates (center of the 2x2 white area)
		mWhitePixelU = (whiteX + 0.5f) / (float)mWidth;
		mWhitePixelV = (whiteY + 0.5f) / (float)mHeight;

		return .Ok;
	}

	public bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		region = .();

		if (codepoint < mFirstCodepoint || codepoint > mLastCodepoint)
			return false;

		let index = codepoint - mFirstCodepoint;
		let pc = ref mPackedChars[index];

		// Check if this character was actually packed
		if (pc.x1 <= pc.x0 || pc.y1 <= pc.y0)
			return false;

		region.X = pc.x0;
		region.Y = pc.y0;
		region.Width = pc.x1 - pc.x0;
		region.Height = pc.y1 - pc.y0;
		region.OffsetX = pc.xoff;
		region.OffsetY = pc.yoff;
		region.AdvanceX = pc.xadvance;

		return true;
	}

	public bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY, out GlyphQuad quad)
	{
		quad = .();

		if (codepoint < mFirstCodepoint || codepoint > mLastCodepoint)
			return false;

		let index = codepoint - mFirstCodepoint;

		stbtt_aligned_quad q = .();
		float xpos = cursorX;
		float ypos = cursorY;
		stbtt_GetPackedQuad(mPackedChars.Ptr, (int32)mWidth, (int32)mHeight,
			index, &xpos, &ypos, &q, 0); // 0 = don't align to integer

		cursorX = xpos;

		quad.X0 = q.x0;
		quad.Y0 = q.y0;
		quad.X1 = q.x1;
		quad.Y1 = q.y1;
		quad.U0 = q.s0;
		quad.V0 = q.t0;
		quad.U1 = q.s1;
		quad.V1 = q.t1;

		return true;
	}

	public bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		quad = .();

		if (codepoint < mFirstCodepoint || codepoint > mLastCodepoint)
			return false;

		let index = codepoint - mFirstCodepoint;

		// Use stbtt_GetPackedQuad but ignore cursor advancement
		stbtt_aligned_quad q = .();
		float xpos = x;
		float ypos = y;
		stbtt_GetPackedQuad(mPackedChars.Ptr, (int32)mWidth, (int32)mHeight,
			index, &xpos, &ypos, &q, 0);

		quad.X0 = q.x0;
		quad.Y0 = q.y0;
		quad.X1 = q.x1;
		quad.Y1 = q.y1;
		quad.U0 = q.s0;
		quad.V0 = q.t0;
		quad.U1 = q.s1;
		quad.V1 = q.t1;

		return true;
	}

	public bool Contains(int32 codepoint)
	{
		if (codepoint < mFirstCodepoint || codepoint > mLastCodepoint)
			return false;

		let index = codepoint - mFirstCodepoint;
		let pc = ref mPackedChars[index];

		return pc.x1 > pc.x0 && pc.y1 > pc.y0;
	}
}
