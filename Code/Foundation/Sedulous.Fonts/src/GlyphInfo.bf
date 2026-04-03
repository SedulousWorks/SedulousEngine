namespace Sedulous.Fonts;

/// Information about a single glyph
public struct GlyphInfo
{
	/// Unicode codepoint this glyph represents
	public int32 Codepoint;
	/// Glyph index in the font (0 = missing glyph)
	public int32 GlyphIndex;
	/// Horizontal advance to next character position
	public float AdvanceWidth;
	/// Left side bearing (offset from current position to glyph left edge)
	public float LeftSideBearing;
	/// Bounding box of the glyph in pixels (relative to baseline)
	public Rect BoundingBox;
	/// Whether this glyph has visible pixels
	public bool HasBitmap;

	public this()
	{
		Codepoint = 0;
		GlyphIndex = 0;
		AdvanceWidth = 0;
		LeftSideBearing = 0;
		BoundingBox = .();
		HasBitmap = false;
	}
}

/// UV coordinates and positioning for rendering a glyph from an atlas
public struct GlyphQuad
{
	/// Screen-space coordinates (x0,y0 = top-left, x1,y1 = bottom-right)
	public float X0, Y0, X1, Y1;
	/// Texture coordinates (u0,v0 = top-left, u1,v1 = bottom-right)
	public float U0, V0, U1, V1;

	public float Width => X1 - X0;
	public float Height => Y1 - Y0;

	public this()
	{
		X0 = Y0 = X1 = Y1 = 0;
		U0 = V0 = U1 = V1 = 0;
	}

	public this(float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1)
	{
		X0 = x0;
		Y0 = y0;
		X1 = x1;
		Y1 = y1;
		U0 = u0;
		V0 = v0;
		U1 = u1;
		V1 = v1;
	}
}
