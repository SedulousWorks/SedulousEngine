using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.TrueType.Tests;

/// Parsing a real typeface: metrics, glyphs, kerning and measurement.
class TrueTypeFontTests
{
	private static int32 Cp(char8 c) => (int32)c;

	/// The asset has to be findable, or every case below is skipping silently and the suite
	/// would look healthy while testing nothing.
	[Test]
	public static void TheTestFontIsPresent()
	{
		let path = scope String();
		Test.Assert(TestFont.FindPath(path),
			"Roboto-Regular.ttf was not found; the rest of this suite would skip");
	}

	[Test]
	public static void LoadingReadsTheMetrics()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		Test.Assert(font.PixelHeight == 32.0f);
		Test.Assert(font.BackendTypeId == TrueTypeCommon.BackendTypeId);

		let metrics = font.Metrics;
		// Relations, not numbers: the numbers are Roboto's.
		Test.Assert(metrics.Ascent > 0, "the ascent is above the baseline");
		Test.Assert(metrics.Descent < 0, "and the descent below it, as the font formats have it");
		Test.Assert(metrics.LineHeight > metrics.Ascent, "a line box is taller than its ascent");
		Test.Assert(metrics.Scale > 0, "a zero scale would collapse every glyph");

		// Derived from the ascent and the pixel height, so a real font gets real
		// decorations without carrying them.
		Test.Assert(metrics.Decorations.UnderlinePosition > 0);
		Test.Assert(metrics.Decorations.UnderlineThickness >= 1.0f);
	}

	[Test]
	public static void TheFamilyNameIsReadFromTheNameTable()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let name = scope String();
		font.GetFamilyName(name);
		Test.Assert(!name.IsEmpty);
		Test.Assert(name != "TrueType Font", "the placeholder means no name record was read");
		Test.Assert(name.Contains("Roboto"), scope $"got '{name}'");
	}

	[Test]
	public static void GlyphInfoIsReadAndCached()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let a = font.GetGlyphInfo(Cp('A'));
		Test.Assert(a.Codepoint == Cp('A'));
		Test.Assert(a.GlyphIndex > 0, "a real glyph, not the missing one");
		Test.Assert(a.AdvanceWidth > 0);
		Test.Assert(a.HasBitmap, "a letter has something to draw");
		Test.Assert(a.BoundingBox.Width > 0 && a.BoundingBox.Height > 0);

		// Asked again, the cache must answer the same thing.
		let again = font.GetGlyphInfo(Cp('A'));
		Test.Assert(again.GlyphIndex == a.GlyphIndex);
		Test.Assert(again.AdvanceWidth == a.AdvanceWidth);
	}

	/// A space advances and draws nothing, which is NOT the same as a glyph that failed.
	[Test]
	public static void ASpaceAdvancesWithoutABitmap()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let space = font.GetGlyphInfo(Cp(' '));
		Test.Assert(space.GlyphIndex > 0, "the font has a space");
		Test.Assert(space.AdvanceWidth > 0, "and it takes up room");
		Test.Assert(!space.HasBitmap, "with nothing to draw");
	}

	[Test]
	public static void PrintableAsciiIsPresentAndOddCodepointsAreNot()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		for (int32 codepoint = 32; codepoint <= 126; codepoint++)
			Test.Assert(font.HasGlyph(codepoint), scope $"missing printable ASCII {codepoint}");

		// Far outside anything Roboto covers.
		Test.Assert(!font.HasGlyph(0x10FFFD), "a private use codepoint is not in this font");

		let missing = font.GetGlyphInfo(0x10FFFD);
		Test.Assert(missing.GlyphIndex == 0, "and it resolves to the missing glyph");
		Test.Assert(missing.AdvanceWidth == 0);
	}

	[Test]
	public static void MeasuringGrowsWithTheText()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		Test.Assert(font.MeasureString("") == 0.0f);

		let one = font.MeasureString("A");
		let two = font.MeasureString("AA");
		Test.Assert(one > 0);
		Test.Assert(two > one, "two characters are wider than one");

		// Wider text is wider, which is the only relation that holds for any typeface.
		Test.Assert(font.MeasureString("Hello, world") > font.MeasureString("Hello"));
	}

	[Test]
	public static void MeasuringAlsoLaysOutInOrder()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let positions = scope List<GlyphPosition>();
		let width = font.MeasureString("Hi", positions);

		Test.Assert(positions.Count == 2);
		Test.Assert(positions[0].Codepoint == Cp('H'));
		Test.Assert(positions[1].Codepoint == Cp('i'));
		Test.Assert(positions[0].X == 0.0f, "the first sits at the origin");
		Test.Assert(positions[1].X > positions[0].X, "and the second after it");
		Test.Assert(width > positions[1].X, "the total reaches past the last glyph's start");
	}

	/// Two sizes of the same file scale together: the metrics are the font's units times a
	/// scale, so doubling the size roughly doubles them.
	[Test]
	public static void ADifferentSizeScalesTheMetrics()
	{
		let small = TestFont.Load(16.0f);
		let large = TestFont.Load(32.0f);
		Test.Assert((small != null) && (large != null));
		defer { delete small; delete large; }

		Test.Assert(large.Metrics.Ascent > small.Metrics.Ascent);
		Test.Assert(large.MeasureString("Hello") > small.MeasureString("Hello"));

		// Roughly, not exactly: hinting and rounding move the last fraction.
		let ratio = large.MeasureString("Hello") / small.MeasureString("Hello");
		Test.Assert((ratio > 1.8f) && (ratio < 2.2f), scope $"ratio {ratio}");
	}

	/// Nonsense bytes are refused rather than parsed into a font that answers rubbish.
	[Test]
	public static void GarbageIsRefused()
	{
		let parser = scope TrueTypeFontParser();

		uint8[16] garbage = default;
		for (int i < 16)
			garbage[i] = (uint8)(i * 7);

		let result = parser.ParseFromMemory(.(&garbage[0], 16), .Default());
		Test.Assert(!(result case .Ok), "sixteen arbitrary bytes are not a font");

		Test.Assert(parser.ParseFromMemory(.(), .Default()) case .Err(.InvalidFormat));
		Test.Assert(parser.ParseFromFile("no-such-font.ttf", .Default()) case .Err(.FileNotFound));
	}

	/// Kerning is READ from the font and APPLIED when measuring. Without it text is measured
	/// as if every pair sat at its plain advance, and every laid out run comes out too wide.
	[Test]
	public static void KerningIsReadAndAppliedWhenMeasuring()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		// Roboto kerns these; a font that did not would make this test vacuous, so the
		// non-zero check comes first.
		let kern = font.GetKerning(Cp('L'), Cp('T'));
		Test.Assert(kern < 0, scope $"L/T should tuck together, got {kern}");
		Test.Assert(font.GetKerning(Cp('P'), Cp(',')) < 0);

		// A pair that does not kern still reports zero rather than something invented.
		Test.Assert(font.GetKerning(Cp('r'), Cp('n')) == 0);
		Test.Assert(font.GetKerning(Cp('L'), 0x1F600) == 0, "and an absent glyph does not");

		// And the measurement uses it: "LT" is NARROWER than its two advances laid end to end,
		// by exactly the kerning.
		let apart = font.GetGlyphInfo(Cp('L')).AdvanceWidth + font.GetGlyphInfo(Cp('T')).AdvanceWidth;
		let together = font.MeasureString("LT");
		Test.Assert(together < apart, "the pair tucks in");
		Test.Assert(Abs((apart + kern) - together) < 0.001f, "by exactly the kerning");

		// The laying-out overload has to apply it too, and it is a SEPARATE walk over the
		// text from the one above: the T is placed at the L's advance plus the kerning, not
		// simply at the L's advance.
		let positions = scope List<GlyphPosition>();
		let laidOutWidth = font.MeasureString("LT", positions);
		Test.Assert(positions.Count == 2);
		Test.Assert(positions[0].X == 0);
		Test.Assert(Abs(positions[1].X - (font.GetGlyphInfo(Cp('L')).AdvanceWidth + kern)) < 0.001f,
			scope $"the T sits at {positions[1].X}");
		Test.Assert(Abs(laidOutWidth - together) < 0.001f, "and both overloads agree");
	}
}
