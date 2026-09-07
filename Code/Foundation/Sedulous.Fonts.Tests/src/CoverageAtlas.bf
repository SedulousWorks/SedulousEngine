using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// An atlas that is nothing but a coverage buffer, for testing the expansion to RGBA.
class CoverageAtlas : IFontAtlas
{
	private uint32 mWidth;
	private uint32 mHeight;
	private uint8[] mPixels;

	public this(uint32 width, uint32 height, uint8[] pixels)
	{
		mWidth = width; mHeight = height; mPixels = pixels;
	}

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override Span<uint8> PixelData => .(mPixels.CArray(), mPixels.Count);
	public override bool Contains(int32 codepoint) => false;
	public override Float2 WhitePixelUV => .(0, 0);

	public override bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		region = .();
		return false;
	}

	public override bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY, out GlyphQuad quad)
	{
		quad = .();
		return false;
	}

	public override bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		quad = .();
		return false;
	}
}
