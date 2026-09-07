using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Coverage;

/// An atlas of pre-rasterised eight bit coverage, with a region per glyph.
class BakedFontAtlas : IFontAtlas
{
	private uint32 mWidth;
	private uint32 mHeight;
	private float mOversampleX = 1.0f;
	private float mOversampleY = 1.0f;
	private List<uint8> mPixels = new .() ~ delete _;
	private Dictionary<int32, AtlasRegion> mRegions = new .() ~ delete _;
	private float mWhitePixelU;
	private float mWhitePixelV;

	/// The oversampling the BAKE used.
	///
	/// A packer rasterises glyph bitmaps at oversample times the logical size, for better
	/// filtering, while the offsets and advances it records stay logical. So a screen quad
	/// has to divide the raw region span back down; not doing so draws every glyph at twice
	/// its size, overlapping its neighbours, while the cursor still steps by the logical
	/// advance. One means no oversampling.
	public void SetOversample(float x, float y)
	{
		mOversampleX = (x > 0.0f) ? x : 1.0f;
		mOversampleY = (y > 0.0f) ? y : 1.0f;
	}

	public float OversampleX => mOversampleX;
	public float OversampleY => mOversampleY;

	/// Empties the regions and the pixels in place, for the same reason BakedFont does.
	public void ClearForReload()
	{
		mRegions.Clear();
		mPixels.Clear();
		mWidth = 0;
		mHeight = 0;
		mWhitePixelU = 0;
		mWhitePixelV = 0;
	}

	/// TAKES the buffer, replacing whatever was held. The caller must not touch it
	/// afterwards: an atlas is a megabyte or two and copying one per bake is worth
	/// avoiding.
	public void SetPixels(uint32 width, uint32 height, List<uint8> takenPixels)
	{
		mWidth = width;
		mHeight = height;
		delete mPixels;
		mPixels = takenPixels;
	}

	public void SetRegion(int32 codepoint, AtlasRegion region) => mRegions[codepoint] = region;

	public void SetWhitePixelUV(float u, float v)
	{
		mWhitePixelU = u;
		mWhitePixelV = v;
	}

	// ---- IFontAtlas ----

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override Span<uint8> PixelData => mPixels.IsEmpty ? .() : .(mPixels.Ptr, mPixels.Count);

	public override bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		if (mRegions.TryGetValue(codepoint, out region))
			return true;
		region = .();
		return false;
	}

	public override bool Contains(int32 codepoint) => mRegions.ContainsKey(codepoint);

	public override Float2 WhitePixelUV => .(mWhitePixelU, mWhitePixelV);

	public override bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY,
		out GlyphQuad quad)
	{
		quad = .();
		if (!mRegions.TryGetValue(codepoint, let region))
			return false;
		return BuildQuad(region, cursorX, cursorY, true, ref cursorX, out quad);
	}

	public override bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		quad = .();
		if (!mRegions.TryGetValue(codepoint, let region))
			return false;
		// Its own cursor, thrown away: this placement is absolute and must not move the
		// caller's.
		var ignored = x;
		return BuildQuad(region, x, y, false, ref ignored, out quad);
	}

	public Dictionary<int32, AtlasRegion> Regions => mRegions;

	private bool BuildQuad(AtlasRegion region, float x, float y, bool advance, ref float cursorX,
		out GlyphQuad quad)
	{
		quad = .();

		// Advance only, which is whitespace: step the cursor, draw nothing.
		if (region.IsEmpty)
		{
			if (advance)
				cursorX = x + region.AdvanceX;
			return false;
		}

		let inverseWidth = 1.0f / (float)mWidth;
		let inverseHeight = 1.0f / (float)mHeight;

		// The offsets and the advance are LOGICAL; the region's width and height are raw
		// atlas pixels, so only the span is divided by the oversampling.
		let x0 = x + region.OffsetX;
		let y0 = y + region.OffsetY;
		let x1 = x0 + (float)region.Width / mOversampleX;
		let y1 = y0 + (float)region.Height / mOversampleY;

		let u0 = (float)region.X * inverseWidth;
		let v0 = (float)region.Y * inverseHeight;
		let u1 = (float)(region.X + region.Width) * inverseWidth;
		let v1 = (float)(region.Y + region.Height) * inverseHeight;

		quad = .(x0, y0, x1, y1, u0, v0, u1, v1);

		if (advance)
			cursorX = x + region.AdvanceX;
		return true;
	}
}
