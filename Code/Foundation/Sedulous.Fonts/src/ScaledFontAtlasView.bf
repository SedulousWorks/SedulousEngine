using System;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// A base atlas whose glyph geometry is scaled, while the texture it names is not.
///
/// The texel rectangle of a region indexes the real atlas and must not move; only the
/// offsets and the advance, which are screen space, scale. BORROWS the base.
class ScaledFontAtlasView : IFontAtlas
{
	private IFontAtlas mBase;
	private float mScale;

	public this(IFontAtlas baseAtlas, float scale)
	{
		mBase = baseAtlas;
		mScale = scale;
	}

	public override uint32 Width => mBase.Width;
	public override uint32 Height => mBase.Height;
	public override Span<uint8> PixelData => mBase.PixelData;
	public override Float2 WhitePixelUV => mBase.WhitePixelUV;
	public override AtlasMode Mode => mBase.Mode;
	public override float DistanceFieldRange => mBase.DistanceFieldRange;
	public override bool Contains(int32 codepoint) => mBase.Contains(codepoint);

	public override bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		if (!mBase.TryGetRegion(codepoint, out region))
			return false;
		region.OffsetX *= mScale;
		region.OffsetY *= mScale;
		region.AdvanceX *= mScale;
		return true;
	}

	public override bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY, out GlyphQuad quad)
	{
		// Straight from the base, because BuildQuad applies the scale itself and a region
		// through this view's TryGetRegion would have it applied twice.
		if (!mBase.TryGetRegion(codepoint, let region))
		{
			quad = .();
			return false;
		}
		// Advance only, which is whitespace: step the cursor, draw nothing.
		if (region.IsEmpty)
		{
			quad = .();
			cursorX += region.AdvanceX * mScale;
			return false;
		}
		BuildQuad(region, cursorX, cursorY, out quad);
		cursorX += region.AdvanceX * mScale;
		return true;
	}

	public override bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		if (!mBase.TryGetRegion(codepoint, let region) || region.IsEmpty)
		{
			quad = .();
			return false;
		}
		BuildQuad(region, x, y, out quad);
		return true;
	}

	private void BuildQuad(AtlasRegion region, float x, float y, out GlyphQuad quad)
	{
		let x0 = x + region.OffsetX * mScale;
		let y0 = y + region.OffsetY * mScale;
		let x1 = x0 + (float)region.Width * mScale;
		let y1 = y0 + (float)region.Height * mScale;
		// The UVs come from the BASE dimensions: the texture is the base atlas.
		region.GetUVs(mBase.Width, mBase.Height, let u0, let v0, let u1, let v1);
		quad = .(x0, y0, x1, y1, u0, v0, u1, v1);
	}
}
