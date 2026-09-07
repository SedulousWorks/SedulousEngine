using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// A 128 by 128 distance field atlas with one region, plus an advance only region for the
/// space, so the whitespace path can be told apart from a failure.
class StubAtlas : IFontAtlas
{
	public override uint32 Width => 128;
	public override uint32 Height => 128;
	public override Span<uint8> PixelData => .();
	public override bool Contains(int32 codepoint) => true;
	public override Float2 WhitePixelUV => .(0.5f, 0.5f);
	public override AtlasMode Mode => .DistanceField;
	public override float DistanceFieldRange => 4.0f;

	public override bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		if (codepoint == (int32)' ')
		{
			// Advance only: something to step past, nothing to draw.
			region = .(0, 0, 0, 0, 0.0f, 0.0f, 12.0f);
			return true;
		}
		region = .(10, 20, 30, 40, 3.0f, -24.0f, 20.0f);
		return true;
	}

	public override bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY, out GlyphQuad quad)
	{
		TryGetRegion(codepoint, let region);
		GetGlyphQuadAt(codepoint, cursorX + region.OffsetX, cursorY + region.OffsetY, out quad);
		cursorX += region.AdvanceX;
		return true;
	}

	public override bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		quad = .(x, y, x + 30.0f, y + 40.0f, 0, 0, 1, 1);
		return true;
	}
}
