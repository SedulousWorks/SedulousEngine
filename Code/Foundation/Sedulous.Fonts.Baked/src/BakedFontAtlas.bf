using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Baked;

/// Pre-rasterized font atlas. Holds an owned 8-bit alpha pixel buffer plus
/// a dictionary mapping codepoint -> AtlasRegion. No runtime dependency on
/// stb_truetype or any other glyph rasterizer: shipped games get all the
/// glyph data from `FontResource` deserialization and never re-rasterize.
public class BakedFontAtlas : IFontAtlas
{
	private uint32 mWidth;
	private uint32 mHeight;
	private uint8[] mPixelData ~ delete _;
	private Dictionary<int32, AtlasRegion> mRegions = new .() ~ delete _;
	private float mWhitePixelU;
	private float mWhitePixelV;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public Span<uint8> PixelData => mPixelData != null ? Span<uint8>(mPixelData) : .();
	public (float U, float V) WhitePixelUV => (mWhitePixelU, mWhitePixelV);

	/// Codepoint -> AtlasRegion table. Exposed read-only for callers that
	/// want to iterate all glyph regions (e.g. the font editor page).
	public Dictionary<int32, AtlasRegion> Regions => mRegions;

	public this() { }

	/// Hand the atlas its dimensions + pixel buffer ownership. The buffer
	/// must be `width * height` bytes (single-channel alpha). Replaces any
	/// previously held buffer.
	public void SetPixels(uint32 width, uint32 height, uint8[] takenPixels)
	{
		if (mPixelData != null) delete mPixelData;
		mWidth = width;
		mHeight = height;
		mPixelData = takenPixels;
	}

	/// Add a glyph region to the lookup table. Importer calls this once per
	/// baked glyph; deserialization replays the same calls. Replaces any
	/// existing entry for the same codepoint.
	public void SetRegion(int32 codepoint, AtlasRegion region)
	{
		mRegions[codepoint] = region;
	}

	/// Set the UV coords of the white-pixel cell used to draw solid lines /
	/// rects through the same texture.
	public void SetWhitePixelUV(float u, float v)
	{
		mWhitePixelU = u;
		mWhitePixelV = v;
	}

	public bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		return mRegions.TryGetValue(codepoint, out region);
	}

	public bool Contains(int32 codepoint)
	{
		return mRegions.ContainsKey(codepoint);
	}

	public bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY, out GlyphQuad quad)
	{
		quad = .();
		if (!mRegions.TryGetValue(codepoint, let region))
			return false;
		return BuildQuad(region, cursorX, cursorY, true, ref cursorX, out quad);
	}

	public bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		quad = .();
		if (!mRegions.TryGetValue(codepoint, let region))
			return false;
		var dummy = x;
		return BuildQuad(region, x, y, false, ref dummy, out quad);
	}

	private bool BuildQuad(AtlasRegion region, float x, float y, bool advance,
		ref float cursorX, out GlyphQuad quad)
	{
		let invW = 1.0f / (float)mWidth;
		let invH = 1.0f / (float)mHeight;

		// Screen-space quad: position + offsets + dimensions.
		let qx0 = x + region.OffsetX;
		let qy0 = y + region.OffsetY;
		let qx1 = qx0 + (float)region.Width;
		let qy1 = qy0 + (float)region.Height;

		// Texture-space quad: region's bounds normalized into the atlas.
		let u0 = (float)region.X * invW;
		let v0 = (float)region.Y * invH;
		let u1 = (float)(region.X + region.Width) * invW;
		let v1 = (float)(region.Y + region.Height) * invH;

		quad = .(qx0, qy0, qx1, qy1, u0, v0, u1, v1);

		if (advance)
			cursorX = x + region.AdvanceX;
		return true;
	}
}
