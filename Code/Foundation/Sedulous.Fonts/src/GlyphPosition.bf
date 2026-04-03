namespace Sedulous.Fonts;

/// Position information for a glyph in laid-out text
public struct GlyphPosition
{
	/// Index of this character in the source string
	public int32 StringIndex;
	/// Unicode codepoint
	public int32 Codepoint;
	/// X position (left edge of glyph)
	public float X;
	/// Y position (baseline)
	public float Y;
	/// Advance to next character
	public float Advance;
	/// Glyph info for this character
	public GlyphInfo GlyphInfo;

	public this()
	{
		StringIndex = 0;
		Codepoint = 0;
		X = 0;
		Y = 0;
		Advance = 0;
		GlyphInfo = .();
	}

	public this(int32 stringIndex, int32 codepoint, float x, float y, float advance, GlyphInfo glyphInfo)
	{
		StringIndex = stringIndex;
		Codepoint = codepoint;
		X = x;
		Y = y;
		Advance = advance;
		GlyphInfo = glyphInfo;
	}
}
