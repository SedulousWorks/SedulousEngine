using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.DistanceField;

/// A multi-channel distance field atlas: RGBA8 linear pixels plus a region per glyph.
///
/// Pure data, with no msdfgen anywhere near it. That is the point of the split: the baker
/// links msdfgen and runs at tooling time, and a packaged game loads THIS from a cooked
/// asset and links nothing. The pixels are linear rather than sRGB because they hold
/// distances, not colour, and gamma would bend them.
class DistanceFieldFontAtlas : IFontAtlas
{
	private uint32 mWidth;
	private uint32 mHeight;
	private float mPixelRange = 4.0f;
	private List<uint8> mPixels = new .() ~ delete _;
	private Dictionary<int32, AtlasRegion> mRegions = new .() ~ delete _;
	private float mWhitePixelU;
	private float mWhitePixelV;

	/// Adopts `takenPixels`, which is RGBA8 and so four bytes per texel.
	public void SetPixels(uint32 width, uint32 height, List<uint8> takenPixels)
	{
		mWidth = width;
		mHeight = height;
		if (takenPixels !== mPixels)
		{
			delete mPixels;
			mPixels = takenPixels;
		}
	}

	public void SetRegion(int32 codepoint, AtlasRegion region) => mRegions[codepoint] = region;

	public void SetWhitePixelUV(float u, float v)
	{
		mWhitePixelU = u;
		mWhitePixelV = v;
	}

	/// The spread, in PIXELS of the atlas the field was rendered at. The shader divides by
	/// it to turn the stored distance back into a screen-space edge, so it has to travel
	/// with the pixels.
	public void SetPixelRange(float pixelRange) => mPixelRange = pixelRange;

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override Span<uint8> PixelData => mPixels.IsEmpty ? .() : .(mPixels.Ptr, mPixels.Count);
	public override Float2 WhitePixelUV => .(mWhitePixelU, mWhitePixelV);
	public override AtlasMode Mode => .DistanceField;
	public override float DistanceFieldRange => mPixelRange;

	public override bool Contains(int32 codepoint) => mRegions.ContainsKey(codepoint);

	public override bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		if (mRegions.TryGetValue(codepoint, out region))
			return true;
		region = default;
		return false;
	}

	public override bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY,
		out GlyphQuad quad)
	{
		quad = default;
		if (!mRegions.TryGetValue(codepoint, let region))
			return false;
		return BuildQuad(region, cursorX, cursorY, true, ref cursorX, out quad);
	}

	public override bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		quad = default;
		if (!mRegions.TryGetValue(codepoint, let region))
			return false;
		var ignored = x;
		return BuildQuad(region, x, y, false, ref ignored, out quad);
	}

	public Dictionary<int32, AtlasRegion> Regions => mRegions;

	/// No oversampling division here, unlike the coverage atlas: a distance field is
	/// rendered at one texel per pixel of the cell and read back through its range, so
	/// there is no supersampled grid to collapse.
	private bool BuildQuad(AtlasRegion region, float x, float y, bool advance, ref float cursorX,
		out GlyphQuad quad)
	{
		quad = default;

		// Whitespace carries an advance and nothing to draw. Stepping the cursor anyway is
		// what keeps "hello world" from rendering as "helloworld".
		if (region.IsEmpty)
		{
			if (advance)
				cursorX = x + region.AdvanceX;
			return false;
		}

		let invW = 1.0f / (float)mWidth;
		let invH = 1.0f / (float)mHeight;

		let x0 = x + region.OffsetX;
		let y0 = y + region.OffsetY;
		let x1 = x0 + (float)region.Width;
		let y1 = y0 + (float)region.Height;

		let u0 = (float)region.X * invW;
		let v0 = (float)region.Y * invH;
		let u1 = (float)(region.X + region.Width) * invW;
		let v1 = (float)(region.Y + region.Height) * invH;

		quad = .(x0, y0, x1, y1, u0, v0, u1, v1);

		if (advance)
			cursorX = x + region.AdvanceX;
		return true;
	}
}
