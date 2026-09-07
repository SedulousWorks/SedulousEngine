using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;

namespace Sedulous.Fonts.Coverage.Tests;

/// A font whose tables were baked ahead of time, with no rasteriser behind it.
class BakedFontTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// Beef does not widen char8 to int32 on its own, and a codepoint is what these tables
	/// are keyed on.
	private static int32 Cp(char8 c) => (int32)c;

	private static GlyphInfo Glyph(int32 codepoint, float advance)
	{
		var info = GlyphInfo();
		info.Codepoint = codepoint;
		info.GlyphIndex = 1;
		info.AdvanceWidth = advance;
		return info;
	}

	[Test]
	public static void MetricsRoundTrip()
	{
		let font = scope BakedFont();
		font.SetFamilyName("Test Family");
		font.SetPixelHeight(24.0f);
		font.SetMetrics(.(20.0f, -5.0f, 2.0f, 24.0f, 0.5f));

		let name = scope String();
		font.GetFamilyName(name);
		Test.Assert(name == "Test Family");
		Test.Assert(Near(font.PixelHeight, 24.0f));

		let metrics = font.Metrics;
		Test.Assert(Near(metrics.Ascent, 20.0f));
		Test.Assert(Near(metrics.Descent, -5.0f));
		Test.Assert(Near(metrics.LineGap, 2.0f));
		Test.Assert(Near(metrics.LineHeight, 27.0f), "derived, not stored");
	}

	/// A codepoint the bake did not cover answers a default glyph rather than failing: it
	/// contributes no advance and nothing to draw, which is what an unbaked character
	/// should do to a line of text.
	[Test]
	public static void TheGlyphTableAnswersForWhatWasBakedAndDefaultsForTheRest()
	{
		let font = scope BakedFont();
		font.SetGlyph(Cp('A'), Glyph(Cp('A'), 12.0f));
		font.SetGlyph(Cp('B'), Glyph(Cp('B'), 10.0f));

		Test.Assert(font.HasGlyph(Cp('A')));
		Test.Assert(font.HasGlyph(Cp('B')));
		Test.Assert(!font.HasGlyph(Cp('Z')));

		Test.Assert(Near(font.GetGlyphInfo(Cp('A')).AdvanceWidth, 12.0f));
		Test.Assert(font.GetGlyphInfo(Cp('A')).Codepoint == Cp('A'));

		let missing = font.GetGlyphInfo(Cp('Z'));
		Test.Assert(Near(missing.AdvanceWidth, 0.0f));
		Test.Assert(missing.GlyphIndex == 0, "the missing glyph");

		Test.Assert(font.Glyphs.Count == 2, "the table is readable for tooling");
	}

	/// Kerning belongs to an ordered PAIR: AV and VA are different adjustments, and neither
	/// is the same as no kerning at all.
	[Test]
	public static void KerningIsPerOrderedPair()
	{
		let font = scope BakedFont();
		font.SetKerning(Cp('A'), Cp('V'), -2.0f);
		font.SetKerning(Cp('V'), Cp('A'), -1.0f);

		Test.Assert(Near(font.GetKerning(Cp('A'), Cp('V')), -2.0f));
		Test.Assert(Near(font.GetKerning(Cp('V'), Cp('A')), -1.0f), "the other order is its own pair");
		Test.Assert(Near(font.GetKerning(Cp('A'), Cp('B')), 0.0f), "an unkerned pair is zero");
		Test.Assert(font.Kerning.Count == 2);
	}

	/// The packed key masks the second codepoint through unsigned. A negative one would
	/// otherwise sign extend across the whole key and collide with an unrelated pair.
	[Test]
	public static void APackedKeyDoesNotCollide()
	{
		let font = scope BakedFont();
		font.SetKerning(1, -1, 5.0f);
		font.SetKerning(0, -1, 7.0f);
		font.SetKerning(1, 0, 9.0f);

		Test.Assert(Near(font.GetKerning(1, -1), 5.0f));
		Test.Assert(Near(font.GetKerning(0, -1), 7.0f));
		Test.Assert(Near(font.GetKerning(1, 0), 9.0f));
		Test.Assert(font.Kerning.Count == 3, "three distinct pairs, three entries");
	}

	[Test]
	public static void MeasuringAppliesKerning()
	{
		let font = scope BakedFont();
		font.SetGlyph(Cp('A'), Glyph(Cp('A'), 10.0f));
		font.SetGlyph(Cp('V'), Glyph(Cp('V'), 10.0f));
		font.SetKerning(Cp('A'), Cp('V'), -3.0f);

		Test.Assert(Near(font.MeasureString("AV"), 17.0f), "two advances less the kerning");
		Test.Assert(Near(font.MeasureString("VA"), 20.0f), "the other order is unkerned here");
		Test.Assert(Near(font.MeasureString("A"), 10.0f), "one glyph has no pair to kern");
		Test.Assert(Near(font.MeasureString(""), 0.0f));
	}

	[Test]
	public static void MeasuringAlsoLaysOut()
	{
		let font = scope BakedFont();
		font.SetGlyph(Cp('A'), Glyph(Cp('A'), 10.0f));
		font.SetGlyph(Cp('V'), Glyph(Cp('V'), 10.0f));
		font.SetKerning(Cp('A'), Cp('V'), -3.0f);

		let positions = scope List<GlyphPosition>();
		let width = font.MeasureString("AV", positions);

		Test.Assert(positions.Count == 2);
		Test.Assert(Near(positions[0].X, 0.0f));
		Test.Assert(Near(positions[1].X, 7.0f), "the second sits after the advance and the kerning");
		Test.Assert(positions[0].Codepoint == Cp('A'));
		Test.Assert(positions[1].Codepoint == Cp('V'));
		Test.Assert(Near(positions[0].Advance, 10.0f));
		Test.Assert(Near(width, 17.0f), "and the total agrees with the measurement");
	}

	/// Multi byte text advances the BYTE index correctly, so the positions report offsets
	/// into the caller's string.
	[Test]
	public static void MeasuringWalksUtf8()
	{
		let font = scope BakedFont();
		font.SetGlyph(0x20AC, Glyph(0x20AC, 8.0f)); // The euro sign, three bytes.
		font.SetGlyph(Cp('A'), Glyph(Cp('A'), 10.0f));

		let positions = scope List<GlyphPosition>();
		let width = font.MeasureString("\u{20AC}A", positions);

		Test.Assert(positions.Count == 2, "two glyphs, not four bytes' worth");
		Test.Assert(positions[0].Codepoint == 0x20AC);
		Test.Assert(positions[1].Codepoint == Cp('A'));
		Test.Assert(Near(width, 18.0f));
	}

	/// A hot reload refills the SAME object, because a CachedFont, a shaper and every
	/// proxy hold it; replacing it would mean finding them all.
	[Test]
	public static void ClearForReloadEmptiesInPlace()
	{
		let font = scope BakedFont();
		font.SetFamilyName("Before");
		font.SetPixelHeight(32.0f);
		font.SetGlyph(Cp('A'), Glyph(Cp('A'), 10.0f));
		font.SetKerning(Cp('A'), Cp('V'), -2.0f);
		font.SetMetrics(.(20.0f, -5.0f, 2.0f, 32.0f, 1.0f));

		font.ClearForReload();

		let name = scope String();
		font.GetFamilyName(name);
		Test.Assert(name.IsEmpty);
		Test.Assert(Near(font.PixelHeight, 0.0f));
		Test.Assert(!font.HasGlyph(Cp('A')));
		Test.Assert(Near(font.GetKerning(Cp('A'), Cp('V')), 0.0f));
		Test.Assert(Near(font.Metrics.Scale, 1.0f), "back to the default metrics, not zeroed");

		// And it takes a fresh bake.
		font.SetFamilyName("After");
		font.SetGlyph(Cp('B'), Glyph(Cp('B'), 5.0f));
		let reloaded = scope String();
		font.GetFamilyName(reloaded);
		Test.Assert(reloaded == "After");
		Test.Assert(font.HasGlyph(Cp('B')));
	}
}
