namespace Sedulous.Fonts;

/// One glyph's metrics.
struct GlyphInfo
{
	public int32 Codepoint;
	/// The font's own index for the glyph. Zero is the MISSING glyph, which every font
	/// has, so a codepoint the font does not cover still renders as a visible box rather
	/// than as nothing.
	public int32 GlyphIndex;
	public float AdvanceWidth;
	public float LeftSideBearing;
	/// In pixels, relative to the baseline.
	public FontRect BoundingBox;
	public bool HasBitmap;

	public this()
	{
		Codepoint = 0; GlyphIndex = 0; AdvanceWidth = 0; LeftSideBearing = 0;
		BoundingBox = .(); HasBitmap = false;
	}
}
