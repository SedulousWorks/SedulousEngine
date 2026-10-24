using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Bidi;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Caret places that run against the bytes, as a right-to-left line's do.
class ReversedCaretPlaces : ITextCaretPlaces
{
	public int Size = 0;
	public bool RightToLeft = true;

	public bool OffsetVisually(int offset, bool upstream, int32 step, out int outOffset, out bool outUpstream)
	{
		outOffset = offset;
		outUpstream = false;
		if ((step > 0) ? (offset == 0) : (offset >= Size))
			return false;
		outOffset = (step > 0) ? offset - 1 : offset + 1;
		return true;
	}

	public bool IsRightToLeftAt(int offset) => RightToLeft;
}

/// Bidirectional text: the formatter resolves each paragraph's levels through Foundation's
/// resolver (SheenBidi installed here, as a host does), wraps in logical order, then lays each line
/// out in visual order, each piece shaped the way it reads; start and end alignment follow the
/// paragraph; a caret's x is a glyph's leading edge and a point's offset the nearest edge, both the
/// right way round in right-to-left text, with an affinity where the directions meet; Left and
/// Right step through a line's caret places in visual order; a range is a box per stretch of glyphs
/// side by side. Over DejaVu Sans Mono, which draws Arabic.
class BidiTextTests
{
	/// Salaam (four letters, eight bytes).
	private const String cWord = "\u{0633}\u{0644}\u{0627}\u{0645}";

	private static bool Near(float a, float b) => TextFixtures.Near(a, b);

	private static TrueTypeFontService DejaVu(TrueTypeFontService service)
	{
		TextFixtures.Load(service, "DejaVu", TextFixtures.cDejaVuMono);
		return service;
	}

	private static TextLayoutStyle Style(TrueTypeFontService font, TextDirection direction, TextLayoutStyle outStyle, float maxWidth = 0.0f)
	{
		outStyle.Font = font.GetFont("DejaVu", 16.0f);
		outStyle.Family.Set("DejaVu");
		outStyle.Size = 16.0f;
		outStyle.MaxWidth = maxWidth;
		outStyle.Direction = direction;
		return outStyle;
	}

	private static TextLayout Lay(StringView markup, TextLayoutStyle style, TextLayout outLayout)
	{
		let document = scope TextDocument();
		ParseTextMarkup(markup, document);
		return LayOutText(document, style, outLayout);
	}

	// The left edge of the glyphs drawing bytes [start, end) of the plain text.
	private static float LeftOf(TextLayout layout, int start, int end)
	{
		float left = 1e9f;
		for (let run in layout.GlyphRuns)
			for (int g = 0; g < run.Glyphs.Count; g++)
				if ((run.GlyphStart[g] >= start) && (run.GlyphEnd[g] <= end))
					left = Math.Min(left, run.Glyphs[g].X);
		return left;
	}

	[Test]
	public static void ARightToLeftParagraphRunsFromTheRightItsFirstWordRightmostEachGlyphReadRightToLeft()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let text = scope String(cWord);
		text.Append(" ");
		text.Append(cWord); // bytes 0 to 8, a space, 9 to 17
		let layout = Lay(text, Style(font, .RightToLeft, scope .()), scope .());
		Test.Assert(layout.Lines.Count == 1);
		Test.Assert(layout.Lines[0].RightToLeft);
		Test.Assert(LeftOf(layout, 0, 8) > LeftOf(layout, 9, 17));
		for (let run in layout.GlyphRuns)
			for (let g in run.Glyphs)
				Test.Assert(g.RightToLeft);
		Test.Assert(LeftOf(layout, 0, 2) > LeftOf(layout, 6, 8)); // its first letter on its right
	}

	[Test]
	public static void LatinInsideARightToLeftParagraphReadsLeftToRightToTheArabicsLeft()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let text = scope String(cWord);
		text.Append(" hello world"); // Arabic 0 to 8; hello 9 to 14; world 15 to 20
		let layout = Lay(text, Style(font, .RightToLeft, scope .()), scope .());
		Test.Assert(LeftOf(layout, 9, 14) < LeftOf(layout, 0, 8));
		Test.Assert(LeftOf(layout, 9, 14) < LeftOf(layout, 15, 20));
		Test.Assert(LeftOf(layout, 15, 20) < LeftOf(layout, 0, 8));
	}

	[Test]
	public static void AnArabicWordInsideALeftToRightParagraphKeepsItsPlaceAndReadsRightToLeft()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let text = scope String("a ");
		text.Append(cWord);
		text.Append(" b"); // a 0; Arabic 2 to 10; b 11
		let layout = Lay(text, Style(font, .LeftToRight, scope .()), scope .());
		Test.Assert(!layout.Lines[0].RightToLeft);
		Test.Assert(LeftOf(layout, 0, 1) < LeftOf(layout, 2, 10));
		Test.Assert(LeftOf(layout, 2, 10) < LeftOf(layout, 11, 12));
		Test.Assert(LeftOf(layout, 2, 4) > LeftOf(layout, 8, 10));
	}

	[Test]
	public static void StartAndEndFollowTheParagraphAWrappedRightToLeftParagraphStartsEachLineOnTheRight()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		// A word and its space, as the layout shapes them (Salaam's lam and alef join in one glyph).
		let two = scope String(cWord);
		two.Append(" ");
		two.Append(cWord);
		let word = Lay(two, Style(font, .LeftToRight, scope .()), scope .()).Lines[0].Width -
			Lay(cWord, Style(font, .LeftToRight, scope .()), scope .()).Lines[0].Width;
		let text = scope String();
		for (int i = 0; i < 3; i++)
		{
			text.Append(cWord);
			if (i < 2)
				text.Append(" ");
		}
		let style = Style(font, .RightToLeft, scope .(), word * 2.5f);
		style.Align = .Start;
		let layout = Lay(text, style, scope .());
		Test.Assert(layout.Lines.Count == 2);
		for (let line in layout.Lines)
			Test.Assert(Near(line.Left + line.Width, word * 2.5f));
		Test.Assert(LeftOf(layout, 0, 8) > LeftOf(layout, 9, 17)); // the first line's first word on its right
		style.Align = .End;
		Test.Assert(Near(Lay(text, style, scope .()).Lines[0].Left, 0.0f));
		let ltr = Style(font, .LeftToRight, scope .(), 300.0f);
		ltr.Align = .Start;
		Test.Assert(Near(Lay("hello", ltr, scope .()).Lines[0].Left, 0.0f));
	}

	[Test]
	public static void ACaretStandsAtAGlyphsLeadingEdgeAndAPointFindsTheNearestEdgeTheRightWayRound()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let layout = Lay(cWord, Style(font, .RightToLeft, scope .()), scope .());
		let line = layout.Lines[0];
		let right = line.Left + line.Width;
		Test.Assert(Near(layout.CaretX(0), right)); // before its first letter: the right edge
		Test.Assert(Near(layout.CaretX(8), line.Left)); // after its last: the left edge
		Test.Assert(layout.CaretX(2) < right);
		Test.Assert(layout.CaretX(2) > layout.CaretX(4));
		let y = line.Top + line.Height * 0.5f;
		Test.Assert(layout.OffsetAt(.(right - 0.5f, y)) == 0);
		Test.Assert(layout.OffsetAt(.(line.Left + 0.5f, y)) == 8);
	}

	[Test]
	public static void WithNoResolverARightToLeftParagraphKeepsItsOrderAndStartsOnTheRight()
	{
		let font = DejaVu(scope .());
		let style = Style(font, .RightToLeft, scope .(), 300.0f);
		style.Align = .Start;
		let layout = Lay("ab cd", style, scope .());
		Test.Assert(layout.Lines[0].RightToLeft);
		Test.Assert(LeftOf(layout, 0, 2) < LeftOf(layout, 3, 5));
		Test.Assert(Near(layout.Lines[0].Left + layout.Lines[0].Width, 300.0f));
	}

	[Test]
	public static void LeftToRightTextLaysOutTheSameWithTheResolverInstalled()
	{
		let font = DejaVu(scope .());
		let before = Lay("hello [b]bold[/b] world", Style(font, .LeftToRight, scope .(), 80.0f), scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let after = Lay("hello [b]bold[/b] world", Style(font, .LeftToRight, scope .(), 80.0f), scope .());
		Test.Assert(before.GlyphRuns.Count == after.GlyphRuns.Count);
		for (int r = 0; r < before.GlyphRuns.Count; r++)
		{
			Test.Assert(before.GlyphRuns[r].Glyphs.Count == after.GlyphRuns[r].Glyphs.Count);
			for (int g = 0; g < before.GlyphRuns[r].Glyphs.Count; g++)
				Test.Assert(before.GlyphRuns[r].Glyphs[g].X == after.GlyphRuns[r].Glyphs[g].X);
		}
	}

	[Test]
	public static void RightStepsThroughEveryCaretPlaceOfAMixedLineOnceLeftToRight()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let text = scope String("ab ");
		text.Append(cWord); // a 0, b 1, a space 2, Arabic 3 to 11
		let layout = Lay(text, Style(font, .LeftToRight, scope .()), scope .());
		int offset = 0;
		bool upstream = false;
		float x = layout.CaretX(offset, upstream);
		int steps = 0;
		int next = 0;
		bool nextUpstream = false;
		while (layout.OffsetVisually(offset, upstream, 1, out next, out nextUpstream))
		{
			let nx = layout.CaretX(next, nextUpstream);
			Test.Assert(nx > x);
			x = nx;
			offset = next;
			upstream = nextUpstream;
			Test.Assert(++steps < 20);
		}
		Test.Assert(steps == 7); // three Latin edges and the space's, three inside the Arabic, its right end
		Test.Assert(Near(x, layout.Lines[0].Width));
		Test.Assert(offset == 3); // the right end is the Arabic's start
		// And back again, the same places.
		int back = 0;
		while (layout.OffsetVisually(offset, upstream, -1, out next, out nextUpstream))
		{
			offset = next;
			upstream = nextUpstream;
			Test.Assert(++back < 20);
		}
		Test.Assert(back == 7);
		Test.Assert(offset == 0);
	}

	[Test]
	public static void APointsCaretDrawsWhereItWasFoundARangeAcrossDirectionsIsInPieces()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let text = scope String("ab ");
		text.Append(cWord);
		let layout = Lay(text, Style(font, .LeftToRight, scope .()), scope .());
		let line = layout.Lines[0];
		for (let run in layout.GlyphRuns)
		{
			for (let g in run.Glyphs)
			{
				float[2] edges = .(g.X, g.X + g.Advance);
				for (let edge in edges)
				{
					let at = layout.OffsetAt(.(edge, line.Top + 1.0f), let upstream);
					Test.Assert(Near(layout.CaretX(at, upstream), edge));
				}
			}
		}
		let boxes = scope List<Float2>();
		layout.RangeOnLine(0, 5, 0, boxes); // "ab ", then the first Arabic letter, at the far right
		Test.Assert(boxes.Count == 2);
		Test.Assert(Near(boxes[0].X, 0.0f));
		Test.Assert(Near(boxes[1].Y, line.Width));
		layout.RangeOnLine(0, 11, 0, boxes);
		Test.Assert(boxes.Count == 1); // all of it: one box
	}

	[Test]
	public static void TheModelMovesLeftAndRightAcrossTheViewsCaretPlacesAndStaysAtTheirEnds()
	{
		let model = scope TextEditModel();
		model.Text = "abcd";
		let places = scope ReversedCaretPlaces();
		places.Size = 4;
		model.SetCaretPlaces(places);
		model.SetCaret(1);
		Test.Assert(model.Run(.MoveLeft));
		Test.Assert(model.Caret == 2); // left goes on through the text
		Test.Assert(model.Run(.SelectRight));
		Test.Assert(model.Caret == 1);
		Test.Assert(model.Anchor == 2);
		model.SetCaret(0);
		Test.Assert(model.Run(.MoveRight));
		Test.Assert(model.Caret == 0); // nowhere further that way
		model.SetCaretPlaces(null);
		Test.Assert(model.Run(.MoveRight));
		Test.Assert(model.Caret == 1); // without, as the bytes go
	}

	[Test]
	public static void AClampedRightToLeftParagraphEndsItsLastLinesEllipsisOnTheLeft()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let text = scope String();
		for (int i = 0; i < 6; i++)
		{
			text.Append(cWord);
			text.Append(" ");
		}
		let style = Style(font, .RightToLeft, scope .(), 120.0f);
		style.MaxLines = 1;
		style.Overflow = .Ellipsis;
		let layout = Lay(text, style, scope .());
		Test.Assert(layout.Clamped);
		LaidOutGlyphs ellipsis = null;
		float textLeft = 1e9f;
		for (let run in layout.GlyphRuns)
		{
			if (run.Run < 0)
				ellipsis = run;
			else
			{
				for (let g in run.Glyphs)
					textLeft = Math.Min(textLeft, g.X);
			}
		}
		Test.Assert(ellipsis != null);
		Test.Assert(ellipsis.X < textLeft); // the end of a right-to-left line is its left
	}

	[Test]
	public static void InARightToLeftParagraphAWordToTheLeftIsTheNextOneAndLeftCollapsesASelectionToItsEnd()
	{
		let model = scope TextEditModel();
		model.Text = "one two three";
		let places = scope ReversedCaretPlaces();
		places.Size = 13;
		model.SetCaretPlaces(places);
		model.SetCaret(4); // before "two"
		Test.Assert(model.Run(.MoveWordLeft));
		Test.Assert(model.Caret > 4); // on through the text: past "two"
		let past = model.Caret;
		Test.Assert(model.Run(.MoveWordRight));
		Test.Assert(model.Caret < past); // back
		model.SetCaret(4);
		Test.Assert(model.Run(.SelectWordLeft));
		Test.Assert(model.Anchor == 4);
		Test.Assert(model.Run(.MoveLeft));
		Test.Assert(model.Caret == model.Anchor);
		Test.Assert(model.Caret > 4); // the selection's left end is its logical end
		// Deletes keep to the text's order: backward is backward.
		model.SetCaret(7); // after "two"
		Test.Assert(model.Run(.DeleteWordBackward));
		Test.Assert(model.Text == "one  three");
		// Left to right, as before.
		places.RightToLeft = false;
		model.Text = "one two";
		model.SetCaret(4);
		Test.Assert(model.Run(.MoveWordLeft));
		Test.Assert(model.Caret == 0);
	}
}
