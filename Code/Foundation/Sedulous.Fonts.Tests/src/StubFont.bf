using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// A font with fixed answers, so the views and the utilities can be tested without a
/// rasteriser.
///
/// One glyph shape for every codepoint: advance 20, left side bearing 2, box (1,2,3,4), and
/// a kerning pair of -1.5. Baked at 32 pixels, which is what the scaled views scale from.
class StubFont : IFont
{
	public override void GetFamilyName(String outName) => outName.Append("Stub");
	public override float PixelHeight => 32.0f;
	public override FontMetrics Metrics => .(24.0f, -8.0f, 4.0f, 32.0f, 1.0f);

	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		var info = GlyphInfo();
		info.Codepoint = codepoint;
		info.GlyphIndex = 1;
		info.AdvanceWidth = 20.0f;
		info.LeftSideBearing = 2.0f;
		info.BoundingBox = .(1.0f, 2.0f, 3.0f, 4.0f);
		return info;
	}

	public override float GetKerning(int32 first, int32 second) => -1.5f;
	public override bool HasGlyph(int32 codepoint) => true;

	/// Twenty per BYTE, so a measurement is trivially predictable from the length.
	public override float MeasureString(StringView text) => (float)text.Length * 20.0f;

	public override float MeasureString(StringView text, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();
		return MeasureString(text);
	}
}
