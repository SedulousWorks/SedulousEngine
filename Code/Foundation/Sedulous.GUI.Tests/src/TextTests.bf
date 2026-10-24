using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A font of 6px advance per byte, 12px line height (ascent 10, descent 2), no file and no shaper:
/// its pieces lay out unshaped.
class MockFont : IFont
{
	public override void GetFamilyName(String outName) { outName.Append("mock"); }
	public override Span<uint8> SourceData => default;
	public override FontMetrics Metrics => .(10.0f, -2.0f, 0.0f, 10.0f, 1.0f);
	public override float PixelHeight => 10.0f;

	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		var g = GlyphInfo();
		g.Codepoint = codepoint;
		g.AdvanceWidth = 6.0f;
		return g;
	}

	public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint) => 0.0f;
	public override bool HasGlyph(int32 codepoint) => true;
	public override float MeasureString(StringView text) => (float)text.Length * 6.0f;
	public override float MeasureString(StringView text, List<GlyphPosition> outPositions) => (float)text.Length * 6.0f;
}

/// Text: measurement, alignment, white-space, line height, spacing and clamping against the mock
/// font. The full glyph-render path (atlas and texture) is an integration concern; here Text's own
/// logic and the draw guards.
class TextTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);

	// The text of each laid-out line, in `outLines`.
	private static void LinesOf(Text t, TextLayout layout, List<StringView> outLines)
	{
		for (let line in layout.Lines)
			outLines.Add(t.PlainText.Substring(line.Start, line.End - line.Start));
	}

	[Test]
	public static void MeasurementUsesFontMetrics()
	{
		let cf = scope CachedFont(new MockFont(), null); // owns and deletes the mock
		let t = scope Text("Hello", cf);
		Test.Assert(Near(t.Width, 30.0f)); // 5 * 6
		Test.Assert(Near(t.LineHeight, 12.0f));
		Test.Assert(Near(t.Measure().X, 30.0f));
		Test.Assert(Near(t.Measure().Y, 12.0f));
	}

	[Test]
	public static void NoFontMeasuresToZero()
	{
		let t = scope Text();
		t.SetString("Hello");
		Test.Assert(t.Width == 0.0f);
		Test.Assert(t.LineHeight == 0.0f);
	}

	[Test]
	public static void StringColorAndAlignmentAccessors()
	{
		let t = scope Text();
		t.SetString("abc");
		Test.Assert(t.GetString() == "abc");
		Test.Assert(!t.IsEmpty);
		t.Color = Color.Red;
		Test.Assert(Near(t.Color.R, 1.0f));
		t.SetAlignment(.Center, .Bottom);
		Test.Assert(t.HAlign == .Center);
		Test.Assert(t.VAlign == .Bottom);
	}

	[Test]
	public static void AlignmentWithinBounds()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("Hello", cf); // width 30, height 12
		let bounds = Rect(0.0f, 0.0f, 100.0f, 50.0f);

		t.SetAlignment(.Left, .Top);
		Test.Assert(Near(t.LayoutFor(bounds).Lines[0].Left, 0.0f));
		Test.Assert(Near(t.Origin(bounds).Y, 0.0f));

		t.SetAlignment(.Center, .Middle);
		Test.Assert(Near(t.LayoutFor(bounds).Lines[0].Left, 35.0f)); // (100-30)/2
		Test.Assert(Near(t.Origin(bounds).Y, 19.0f)); // (50-12)/2

		t.SetAlignment(.Right, .Bottom);
		Test.Assert(Near(t.LayoutFor(bounds).Lines[0].Left, 70.0f)); // 100-30
		Test.Assert(Near(t.Origin(bounds).Y, 38.0f)); // 50-12
	}

	[Test]
	public static void DrawGuardsNoFontOrEmptyProducesNoGeometry()
	{
		let ctx = scope VGContext(); // no font service: VG's DrawText returns early anyway
		let dc = scope DrawContext(ctx);

		let noFont = scope Text();
		noFont.SetString("Hello");
		noFont.Draw(dc, Float2(0.0f, 0.0f));
		Test.Assert(ctx.GetBatch().Vertices.Count == 0);

		let cf = scope CachedFont(new MockFont(), null);
		let empty = scope Text("", cf);
		empty.Draw(dc, Float2(0.0f, 0.0f));
		Test.Assert(ctx.GetBatch().Vertices.Count == 0);
	}

	[Test]
	public static void WhiteSpaceNormalBreaksAtSpacesToFitTheWidth()
	{
		let cf = scope CachedFont(new MockFont(), null); // 6px/byte, 12px line height
		let t = scope Text("hello world foo", cf);
		t.WhiteSpace = .Normal;

		let lines = scope List<StringView>();
		LinesOf(t, t.LayoutFor(Rect(0.0f, 0.0f, 60.0f, 100.0f)), lines); // 10 bytes
		Test.Assert(lines.Count == 2);
		Test.Assert(lines[0] == "hello "); // a wrapped line keeps the space it broke at
		Test.Assert(lines[1] == "world foo");

		let wrapped = t.MeasureWrapped(60.0f);
		Test.Assert(Near(wrapped.X, 54.0f)); // widest line "world foo" = 9 * 6
		Test.Assert(Near(wrapped.Y, 24.0f)); // 2 lines * 12
		// Unbounded, and at no width (each word its own line: its min-content).
		Test.Assert(Near(t.MeasureWrapped(cUnbounded).X, 90.0f));
		Test.Assert(Near(t.MeasureWrapped(0.0f).X, 30.0f));
		Test.Assert(Near(t.MeasureWrapped(0.0f).Y, 36.0f));
	}

	[Test]
	public static void PreKeepsLineBreaksAndSpacesNormalAndNowrapCollapseThem()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("a\nbc  \nd", cf);
		t.WhiteSpace = .Pre;
		let lines = scope List<StringView>();
		LinesOf(t, t.LayoutFor(Rect(0.0f, 0.0f, 1000.0f, 100.0f)), lines);
		Test.Assert(lines.Count == 3);
		Test.Assert(lines[0] == "a");
		Test.Assert(lines[1] == "bc  ");
		Test.Assert(lines[2] == "d");

		t.WhiteSpace = .NoWrap;
		Test.Assert(t.PlainText == "a bc d");
		Test.Assert(t.LayoutFor(Rect(0.0f, 0.0f, 10.0f, 100.0f)).Lines.Count == 1); // no wrap
		let padded = scope Text("  x \t y  ", cf);
		Test.Assert(padded.PlainText == "x y");
	}

	[Test]
	public static void AWordLongerThanTheWidthTakesItsOwnLine()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("abcdefghij k", cf); // first word 10 bytes = 60px
		t.WhiteSpace = .Normal;

		let lines = scope List<StringView>();
		LinesOf(t, t.LayoutFor(Rect(0.0f, 0.0f, 30.0f, 100.0f)), lines);
		Test.Assert(lines.Count == 2);
		Test.Assert(lines[0] == "abcdefghij "); // overflows its line
		Test.Assert(lines[1] == "k");
	}

	[Test]
	public static void LineHeightSetsEachLinesHeightAndCentresTheTextInItLetterSpacingWidensIt()
	{
		let cf = scope CachedFont(new MockFont(), null); // ascent 10, descent 2
		let t = scope Text("ab cd", cf);
		t.WhiteSpace = .Normal;
		t.SetLineHeight(20.0f);
		let layout = t.LayoutFor(Rect(0.0f, 0.0f, 20.0f, 100.0f));
		Test.Assert(layout.Lines.Count == 2);
		Test.Assert(Near(layout.Lines[1].Top, 20.0f));
		Test.Assert(Near(layout.Lines[0].Baseline, (20.0f - 12.0f) * 0.5f + 10.0f)); // half-leading
		Test.Assert(Near(t.LineHeight, 20.0f));

		let spaced = scope Text("abc", cf);
		spaced.LetterSpacing = 2.0f;
		Test.Assert(Near(spaced.Width, 18.0f + 6.0f));
	}

	[Test]
	public static void AClampKeepsTheFirstLines()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("one two three four", cf);
		t.WhiteSpace = .Normal;
		t.MaxLines = 2;
		let layout = t.LayoutFor(Rect(0.0f, 0.0f, 30.0f, 100.0f));
		Test.Assert(layout.Lines.Count == 2);
		Test.Assert(layout.Clamped);
		Test.Assert(Near(t.MeasureWrapped(30.0f).Y, 24.0f));
	}

	[Test]
	public static void AWrappedDrawWithoutAFontServiceProducesNoGeometryAndDoesNotCrash()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("hello world foo", cf);
		t.WhiteSpace = .Normal;

		let ctx = scope VGContext(); // no font service: DrawText returns early, but the layout path runs
		let dc = scope DrawContext(ctx);
		t.Draw(dc, Rect(0.0f, 0.0f, 60.0f, 100.0f));
		Test.Assert(ctx.GetBatch().Vertices.Count == 0);
	}
}
