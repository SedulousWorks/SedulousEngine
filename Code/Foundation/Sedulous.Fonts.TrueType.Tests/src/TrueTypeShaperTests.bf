using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.TrueType.Tests;

/// Laying text out, and the questions an editable control asks of a laid out line.
class TrueTypeShaperTests
{
	private static int32 Cp(char8 c) => (int32)c;

	[Test]
	public static void ShapingPlacesEveryGlyphInOrder()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();

		Test.Assert(shaper.ShapeText(font, "Hello", positions) case .Ok(let width));
		Test.Assert(positions.Count == 5);
		Test.Assert(positions[0].X == 0.0f);
		for (int i = 1; i < positions.Count; i++)
			Test.Assert(positions[i].X > positions[i - 1].X, "each sits after the one before");
		Test.Assert(width > 0);

		// The width is the ADVANCE, so it agrees with measuring the same text.
		Test.Assert(Abs(width - font.MeasureString("Hello")) < 0.01f);
	}

	/// Shaping applies kerning when PLACING each glyph, not only when totalling the width.
	/// A shaper that kerned the cursor but placed glyphs at the unkerned position would
	/// still report the right width, and draw the text wrong.
	[Test]
	public static void ShapingPlacesGlyphsWithTheKerningApplied()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let kern = font.GetKerning(Cp('L'), Cp('T'));
		Test.Assert(kern < 0, "Roboto kerns this pair, so the check below means something");

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(font, "LT", positions) case .Ok);

		Test.Assert(positions.Count == 2);
		Test.Assert(positions[0].X == 0);
		Test.Assert(Abs(positions[1].X - (font.GetGlyphInfo(Cp('L')).AdvanceWidth + kern)) < 0.001f,
			scope $"the T was placed at {positions[1].X}");

		// And the wrapped path places them the same way, since it walks the text separately.
		let wrapped = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeTextWrapped(font, "LT", 10000.0f, wrapped, let height) case .Ok);
		Test.Assert(Abs(wrapped[1].X - positions[1].X) < 0.001f, "both paths agree");
	}

	/// Shaping from an origin reports the same WIDTH, because a caller measuring a run
	/// wants how wide it is whatever it started from.
	[Test]
	public static void AStartPositionOffsetsWithoutChangingTheWidth()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let atOrigin = scope List<GlyphPosition>();
		let offset = scope List<GlyphPosition>();

		Test.Assert(shaper.ShapeText(font, "Hi", atOrigin) case .Ok(let originWidth));
		Test.Assert(shaper.ShapeText(font, "Hi", 100.0f, 50.0f, offset) case .Ok(let offsetWidth));

		Test.Assert(Abs(originWidth - offsetWidth) < 0.001f, "the width did not move with it");
		Test.Assert(Abs(offset[0].X - 100.0f) < 0.001f);
		Test.Assert(Abs(offset[0].Y - 50.0f) < 0.001f);
		Test.Assert(Abs((offset[1].X - offset[0].X) - (atOrigin[1].X - atOrigin[0].X)) < 0.001f);
	}

	[Test]
	public static void WrappingBreaksOnWidth()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();

		let oneLine = font.MeasureString("word word word word");
		Test.Assert(shaper.ShapeTextWrapped(font, "word word word word", oneLine * 0.4f,
			positions, let height) case .Ok);

		Test.Assert(!positions.IsEmpty);
		Test.Assert(height > font.Metrics.LineHeight, "it took more than one line");

		// Something is on a second line, which is the whole point.
		bool wrapped = false;
		for (let position in positions)
		{
			if (position.Y > 0.001f)
				wrapped = true;
		}
		Test.Assert(wrapped);

		// And nothing on any line reaches past the width it was given.
		for (let position in positions)
			Test.Assert((position.X + position.Advance) <= (oneLine * 0.4f) + 0.5f,
				scope $"a glyph at {position.X} overruns the wrap width");
	}

	/// Wrapping breaks between WORDS, not through them. This is what separates word wrap
	/// from the character wrap that falls out of simply cutting at the width, and nothing
	/// above distinguishes the two: both put something on a second line.
	[Test]
	public static void WrappingBreaksBetweenWordsNotThroughThem()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();

		// Room for "aaaa bbbb" but not for the "cccc" after it, so the break has to land on
		// the second space rather than partway through a word.
		const String cText = "aaaa bbbb cccc";
		let width = font.MeasureString("aaaa bbbb ") + font.MeasureString("cc");
		Test.Assert(shaper.ShapeTextWrapped(font, cText, width, positions, let height) case .Ok);
		Test.Assert(positions.Count == cText.Length);

		// Reading the codepoints back per line says where the break actually fell.
		let firstLine = scope String();
		let secondLine = scope String();
		let firstY = positions[0].Y;
		for (let position in positions)
		{
			if (position.Y == firstY)
				firstLine.Append((char8)position.GlyphInfo.Codepoint);
			else
				secondLine.Append((char8)position.GlyphInfo.Codepoint);
		}

		Test.Assert(firstLine == "aaaa bbbb ", scope $"first line was '{firstLine}'");
		Test.Assert(secondLine == "cccc", scope $"second line was '{secondLine}'");
	}

	/// A newline ends the line wherever it is, whether or not the width was reached.
	[Test]
	public static void WrappingHonoursExplicitNewlines()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();

		Test.Assert(shaper.ShapeTextWrapped(font, "a\nb", 10000.0f, positions, let height) case .Ok);

		Test.Assert(positions.Count == 2, "the newline is a break, not a glyph");
		Test.Assert(positions[0].Y == 0.0f);
		Test.Assert(positions[1].Y > positions[0].Y, "the second is on the next line");
		Test.Assert(Abs(positions[1].X) < 0.001f, "and back at the left margin");
		Test.Assert(height > font.Metrics.LineHeight);
	}

	/// A carriage return is consumed silently, so CRLF is one break rather than two.
	[Test]
	public static void ACarriageReturnDoesNotDoubleTheBreak()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let unix = scope List<GlyphPosition>();
		let windows = scope List<GlyphPosition>();

		Test.Assert(shaper.ShapeTextWrapped(font, "a\nb", 10000.0f, unix, let unixHeight) case .Ok);
		Test.Assert(shaper.ShapeTextWrapped(font, "a\r\nb", 10000.0f, windows, let windowsHeight) case .Ok);

		Test.Assert(unix.Count == windows.Count);
		Test.Assert(Abs(unixHeight - windowsHeight) < 0.001f, "the same number of lines");
		Test.Assert(Abs(unix[1].Y - windows[1].Y) < 0.001f);
	}

	/// A single word wider than the whole line still has to be placed, or wrapping would
	/// loop forever emitting nothing.
	[Test]
	public static void AWordWiderThanTheLineIsStillPlaced()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();

		Test.Assert(shaper.ShapeTextWrapped(font, "wwwwwwww", 1.0f, positions, let height) case .Ok);
		Test.Assert(positions.Count == 8, "every glyph was placed somewhere");

		// And the FIRST one is still on the first line. The guard that stops the endless wrap
		// is `x > 0`: relaxing it to `x >= 0` wraps before placing anything, which opens the
		// text with a blank line and pushes every glyph down one.
		Test.Assert(positions[0].Y == 0.0f, scope $"the first glyph sits at y={positions[0].Y}");
		Test.Assert(positions[0].X == 0.0f);
	}

	[Test]
	public static void HitTestingFindsTheCharacterAndItsHalf()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();
		shaper.ShapeText(font, "Hello", positions).IgnoreError();
		let span = Span<GlyphPosition>(positions.Ptr, positions.Count);

		// The leading half of the second character.
		let second = positions[1];
		let leading = shaper.HitTest(font, span, second.X + second.Advance * 0.25f, 0);
		Test.Assert(leading.CharacterIndex == 1);
		Test.Assert(leading.IsInside);
		Test.Assert(!leading.IsTrailingHit);
		Test.Assert(leading.InsertionIndex == 1, "the caret goes before it");

		// And the trailing half.
		let trailing = shaper.HitTest(font, span, second.X + second.Advance * 0.75f, 0);
		Test.Assert(trailing.CharacterIndex == 1);
		Test.Assert(trailing.IsTrailingHit);
		Test.Assert(trailing.InsertionIndex == 2, "the caret goes after it");
	}

	/// Outside the text the hit is CLAMPED and reported as not inside, so a caller can tell
	/// a click on a character from a click past the end.
	[Test]
	public static void HitTestingClampsOutsideTheText()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();
		shaper.ShapeText(font, "Hello", positions).IgnoreError();
		let span = Span<GlyphPosition>(positions.Ptr, positions.Count);

		let before = shaper.HitTest(font, span, -50.0f, 0);
		Test.Assert(before.CharacterIndex == 0);
		Test.Assert(!before.IsInside);
		Test.Assert(before.InsertionIndex == 0);

		let after = shaper.HitTest(font, span, 100000.0f, 0);
		Test.Assert(after.CharacterIndex == 4);
		Test.Assert(!after.IsInside);
		Test.Assert(after.InsertionIndex == 5, "the caret goes at the very end");
	}

	[Test]
	public static void HitTestingEmptyTextIsHarmless()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let result = shaper.HitTest(font, .(), 10.0f, 0);
		Test.Assert(result.CharacterIndex == 0);
		Test.Assert(!result.IsInside);
	}

	/// An index past the end answers the far side of the last character, which is where the
	/// caret goes at the end of a line.
	[Test]
	public static void TheCursorSitsAtTheStartTheEndAndBetween()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();
		shaper.ShapeText(font, "Hello", positions).IgnoreError();
		let span = Span<GlyphPosition>(positions.Ptr, positions.Count);

		Test.Assert(shaper.GetCursorPosition(font, span, 0) == positions[0].X);
		Test.Assert(shaper.GetCursorPosition(font, span, -5) == positions[0].X, "clamped");
		Test.Assert(shaper.GetCursorPosition(font, span, 2) == positions[2].X);

		let last = positions[positions.Count - 1];
		Test.Assert(shaper.GetCursorPosition(font, span, 5) == last.X + last.Advance);
		Test.Assert(shaper.GetCursorPosition(font, span, 99) == last.X + last.Advance, "clamped");

		Test.Assert(shaper.GetCursorPosition(font, .(), 0) == 0.0f, "no text, no offset");
	}

	[Test]
	public static void SelectionRectsCoverExactlyWhatIsSelected()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();
		shaper.ShapeText(font, "Hello", positions).IgnoreError();
		let span = Span<GlyphPosition>(positions.Ptr, positions.Count);

		let rects = scope List<FontRect>();
		shaper.GetSelectionRects(font, span, .(1, 3), 20.0f, rects);

		Test.Assert(rects.Count == 1, "one line, one rectangle");
		Test.Assert(Abs(rects[0].X - positions[1].X) < 0.001f, "starting at the first selected");
		let lastSelected = positions[2];
		Test.Assert(Abs(rects[0].Right - (lastSelected.X + lastSelected.Advance)) < 0.001f,
			"and ending past the last, which is half open");
		Test.Assert(Abs(rects[0].Height - 20.0f) < 0.001f);

		// An empty selection has nothing to fill.
		rects.Clear();
		shaper.GetSelectionRects(font, span, .(2, 2), 20.0f, rects);
		Test.Assert(rects.IsEmpty);

		// A selection reaching past the text is clamped rather than reading past the end.
		rects.Clear();
		shaper.GetSelectionRects(font, span, .(0, 999), 20.0f, rects);
		Test.Assert(rects.Count == 1);
		Test.Assert(Abs(rects[0].Right - (positions[4].X + positions[4].Advance)) < 0.001f);
	}

	/// A wrapped selection is one rectangle per line: the middle of a three line selection
	/// is not one box from the first character to the last.
	[Test]
	public static void AWrappedSelectionIsOneRectPerLine()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();
		let width = font.MeasureString("word word word") * 0.4f;
		shaper.ShapeTextWrapped(font, "word word word", width, positions, let height).IgnoreError();

		let rects = scope List<FontRect>();
		shaper.GetSelectionRects(font, .(positions.Ptr, positions.Count),
			.(0, (int32)positions.Count), font.Metrics.LineHeight, rects);

		Test.Assert(rects.Count >= 2, scope $"got {rects.Count} rects for wrapped text");
		for (int i = 1; i < rects.Count; i++)
			Test.Assert(rects[i].Y > rects[i - 1].Y, "each rectangle is on a later line");
	}

	// ---- Clusters: the UI helpers work in characters through GlyphPosition.Cluster, written
	// down here under the one to one stb shaper before a shaper can map characters to glyphs any
	// other way.

	/// Clusters count characters, not bytes, and a line break has no glyph.
	[Test]
	public static void ClustersCountCharactersNotBytesAndALineBreakHasNoGlyph()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;
		let shaper = scope TrueTypeTextShaper();

		// a, e acute (2 bytes), the euro sign (3 bytes), b.
		let positions = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(font, "a\u{E9}\u{20AC}b", positions) case .Ok);
		Test.Assert(positions.Count == 4);
		for (int32 i < 4)
		{
			Test.Assert(positions[i].Cluster == i);
			Test.Assert(positions[i].ClusterLength == 1);
			Test.Assert(positions[i].XOffset == 0.0f);
		}
		Test.Assert(positions[1].GlyphId == font.GetGlyphInfo(0xE9).GlyphIndex);
		Test.Assert(positions[2].GlyphId == font.GetGlyphInfo(0x20AC).GlyphIndex);

		// "ab\ncd" wrapped: the break is character 2 and draws nothing.
		let lines = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeTextWrapped(font, "ab\ncd", 1000.0f, lines, let height) case .Ok);
		Test.Assert(lines.Count == 4);
		Test.Assert(lines[1].Cluster == 1);
		Test.Assert(lines[2].Cluster == 3);
		Test.Assert(lines[2].Y > lines[1].Y);
	}

	/// Hit tests, carets and selections across a line break go by cluster.
	[Test]
	public static void HitTestsCaretsAndSelectionsAcrossALineBreakGoByCluster()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;
		let shaper = scope TrueTypeTextShaper();
		let lines = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeTextWrapped(font, "ab\ncd", 1000.0f, lines, let height) case .Ok);
		let lineHeight = font.Metrics.LineHeight;
		let b = lines[1];
		let c = lines[2];

		// The trailing half of b puts the caret before the break; the leading half of c after it.
		Test.Assert(shaper.HitTestWrapped(font, lines, b.X + b.Advance * 0.9f, 0.1f * lineHeight, lineHeight).InsertionIndex == 2);
		Test.Assert(shaper.HitTestWrapped(font, lines, c.X + c.Advance * 0.1f, 1.1f * lineHeight, lineHeight).InsertionIndex == 3);
		// Past the end of the first line: before the break.
		Test.Assert(shaper.HitTestWrapped(font, lines, 900.0f, 0.1f * lineHeight, lineHeight).InsertionIndex == 2);

		// The caret before the break sits at b's end; after it, at c's start.
		Test.Assert(Abs(shaper.GetCursorPosition(font, lines, 2) - (b.X + b.Advance)) < 0.001f);
		Test.Assert(Abs(shaper.GetCursorPosition(font, lines, 3) - c.X) < 0.001f);

		// Characters 1 to 4 (b, the break, c): one rectangle on each line.
		let rects = scope List<FontRect>();
		shaper.GetSelectionRects(font, lines, .(1, 4), lineHeight, rects);
		Test.Assert(rects.Count == 2);
		Test.Assert(Abs(rects[0].X - b.X) < 0.001f);
		Test.Assert(Abs(rects[0].Width - b.Advance) < 0.001f);
		Test.Assert(Abs(rects[1].X - c.X) < 0.001f);
	}

	/// A cluster of several characters, or of several glyphs, is one caret stop: what a real
	/// shaper may produce for "x", a two character ligature, and a base with its mark.
	[Test]
	public static void AClusterOfSeveralCharactersOrGlyphsIsOneCaretStop()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;
		let shaper = scope TrueTypeTextShaper();

		// Glyph 0 is character 0; glyph 1 covers characters 1 and 2; glyphs 2 and 3 share
		// characters 3 and 4.
		let positions = scope List<GlyphPosition>();
		void Glyph(int32 cluster, int32 length, float x, float advance)
		{
			var glyph = GlyphPosition();
			glyph.Cluster = cluster;
			glyph.ClusterLength = length;
			glyph.X = x;
			glyph.Advance = advance;
			positions.Add(glyph);
		}
		Glyph(0, 1, 0.0f, 10.0f);
		Glyph(1, 2, 10.0f, 20.0f);
		Glyph(3, 2, 30.0f, 10.0f);
		Glyph(3, 2, 40.0f, 0.0f); // the mark: placed by its offsets, no advance

		// The trailing half of the ligature puts the caret after both its characters.
		Test.Assert(shaper.HitTest(font, positions, 25.0f, 0.0f).InsertionIndex == 3);
		Test.Assert(shaper.HitTest(font, positions, 12.0f, 0.0f).InsertionIndex == 1);
		// Past the end: after the last cluster, both its characters.
		Test.Assert(shaper.HitTest(font, positions, 500.0f, 0.0f).InsertionIndex == 5);
		// A caret inside a cluster stands at the cluster's start; after the last one, at the end.
		Test.Assert(shaper.GetCursorPosition(font, positions, 2) == 10.0f);
		Test.Assert(shaper.GetCursorPosition(font, positions, 3) == 30.0f);
		Test.Assert(shaper.GetCursorPosition(font, positions, 4) == 30.0f, "the base's, not the mark's");
		Test.Assert(shaper.GetCursorPosition(font, positions, 5) == 40.0f);
		// Selecting the ligature's first character selects its glyph.
		let rects = scope List<FontRect>();
		shaper.GetSelectionRects(font, positions, .(1, 2), 10.0f, rects);
		Test.Assert(rects.Count == 1);
		Test.Assert(rects[0].X == 10.0f);
		Test.Assert(rects[0].Width == 20.0f);
	}
}
