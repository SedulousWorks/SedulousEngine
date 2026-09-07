namespace Sedulous.Fonts;

/// A glyph placed by layout.
///
/// StringIndex is the BYTE offset in the original text, not a glyph counter: hit testing
/// and cursor placement answer in terms of the caller's string, and one codepoint can be
/// several bytes.
struct GlyphPosition
{
	public int32 StringIndex;
	public int32 Codepoint;
	public float X;
	public float Y;
	public float Advance;
	public GlyphInfo GlyphInfo;

	public this()
	{
		StringIndex = 0; Codepoint = 0; X = 0; Y = 0; Advance = 0; GlyphInfo = .();
	}
}
