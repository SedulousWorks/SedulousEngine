using System;
using System.Collections;

namespace Sedulous.Fonts;

/// Core font interface providing access to font data and metrics
public interface IFont
{
	/// Get the font family name
	String FamilyName { get; }

	/// Get metrics for this font
	FontMetrics Metrics { get; }

	/// Get the pixel height this font was loaded at
	float PixelHeight { get; }

	/// Get glyph information for a Unicode codepoint
	/// Returns default GlyphInfo if glyph not found (GlyphIndex = 0)
	GlyphInfo GetGlyphInfo(int32 codepoint);

	/// Get kerning adjustment between two characters
	/// Returns horizontal adjustment in pixels
	float GetKerning(int32 firstCodepoint, int32 secondCodepoint);

	/// Check if font contains a specific codepoint
	bool HasGlyph(int32 codepoint);

	/// Measure the width of a string of text
	float MeasureString(StringView text);

	/// Measure text with detailed glyph positions output
	float MeasureString(StringView text, List<GlyphPosition> outPositions);
}
