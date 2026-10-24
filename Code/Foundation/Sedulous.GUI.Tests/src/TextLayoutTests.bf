using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The inline formatter over the bundled Roboto faces: mixed sizes share a baseline, a paragraph of
/// three colours wraps inside its width, an icon sits on the baseline, breaks and alignment, and
/// bold and italic take a face or synthesize one. Then the GUI's additions: ellipses, the clamp,
/// line height and spacing on shaped text, carets. Copied with the layout from foundation.ui.
class TextLayoutTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);

	// Roboto, and Roboto Bold as its own family (as a project loads a bold face).
	private static TrueTypeFontService Roboto(TrueTypeFontService service)
	{
		TextFixtures.Load(service, "Roboto", TextFixtures.cRoboto);
		TextFixtures.Load(service, "Roboto Bold", TextFixtures.cRobotoBold);
		return service;
	}

	// The label's font (Roboto 16), the service for runs that set their own.
	private static TextLayoutStyle Style(TrueTypeFontService fonts, TextLayoutStyle outStyle, float maxWidth = 0.0f)
	{
		outStyle.Font = fonts.GetFont("Roboto", 16.0f);
		outStyle.Fonts = fonts;
		outStyle.Family.Set("Roboto");
		outStyle.Size = 16.0f;
		outStyle.MaxWidth = maxWidth;
		return outStyle;
	}

	private static TextDocument Markup(StringView markup, TextDocument outDocument)
	{
		ParseTextMarkup(markup, outDocument);
		return outDocument;
	}

	[Test]
	public static void RunsOfTwoSizesShareOneBaselineTheLineAsTallAsTheLarger()
	{
		let fonts = Roboto(scope .());
		let layout = LayOutText(Markup("small [size=32]BIG[/size] small", scope .()), Style(fonts, scope .()), scope .());
		Test.Assert(layout.Lines.Count == 1);
		Test.Assert(layout.GlyphRuns.Count >= 3);
		let baseline = layout.Lines[0].Baseline;
		for (let run in layout.GlyphRuns)
		{
			Test.Assert(Near(run.Baseline, baseline));
			for (let g in run.Glyphs)
				Test.Assert(Near(g.Y, baseline));
		}
		let big = fonts.GetFont("Roboto", 32.0f);
		let small = fonts.GetFont("Roboto", 16.0f);
		Test.Assert(big != null);
		Test.Assert(small != null);
		Test.Assert(Near(baseline, big.Font.Metrics.Ascent));
		Test.Assert(layout.Height > small.Font.Metrics.LineHeight * 1.5f);
		// Runs follow on: each starts where the one before it ended.
		for (int r = 1; r < layout.GlyphRuns.Count; r++)
			Test.Assert(layout.GlyphRuns[r].Glyphs[0].X > layout.GlyphRuns[r - 1].Glyphs[0].X);
	}

	[Test]
	public static void AParagraphOfThreeColoursWrapsInsideItsWidthAndKeepsItsColours()
	{
		let fonts = Roboto(scope .());
		let doc = Markup(
			"The [color=#ff0000]guests in red[/color] dance while [color=#00ff00]the ones in green[/color] watch and [color=#0000ff]the band in blue[/color] plays on into the night",
			scope .());
		let layout = LayOutText(doc, Style(fonts, scope .(), 160.0f), scope .());
		Test.Assert(layout.Lines.Count >= 3);
		float total = 0.0f;
		for (let line in layout.Lines)
		{
			Test.Assert(line.Width <= 160.0f + 0.01f);
			Test.Assert(Near(line.Top, total));
			total += line.Height;
		}
		Test.Assert(Near(layout.Height, total));
		bool red = false;
		bool green = false;
		bool blue = false;
		for (let run in layout.GlyphRuns)
		{
			red = red || (run.TextColor.R == 1.0f);
			green = green || (run.TextColor.G == 1.0f);
			blue = blue || (run.TextColor.B == 1.0f);
			for (let g in run.Glyphs)
				Test.Assert(g.X + g.Advance <= 160.0f + 4.0f); // within the width (a space may hang over)
		}
		Test.Assert(red && green && blue);
	}

	[Test]
	public static void AnIconSitsOnTheBaselineAsTallAsItsTextIsBig()
	{
		let fonts = Roboto(scope .());
		let layout = LayOutText(Markup("a [size=20][icon=Icons/rose.png][/size] b", scope .()), Style(fonts, scope .()), scope .());
		Test.Assert(layout.Icons.Count == 1);
		let icon = layout.Icons[0].Rect;
		Test.Assert(Near(icon.Width, 20.0f));
		Test.Assert(Near(icon.Y + icon.Height, layout.Lines[0].Baseline));
		Test.Assert(layout.Icons[0].Run == 1);
		// The text after it starts after it.
		Test.Assert(layout.GlyphRuns.Back.Glyphs[0].X >= icon.X + icon.Width);
	}

	[Test]
	public static void LineBreaksAnEmptyLastLineAndCentring()
	{
		let fonts = Roboto(scope .());
		Test.Assert(LayOutText(Markup("a\nb", scope .()), Style(fonts, scope .()), scope .()).Lines.Count == 2);
		let trailing = LayOutText(Markup("a\n", scope .()), Style(fonts, scope .()), scope .());
		Test.Assert(trailing.Lines.Count == 2);
		Test.Assert(trailing.Lines[1].Height > 0.0f);

		let centred = Style(fonts, scope .(), 200.0f);
		centred.Align = .Center;
		let layout = LayOutText(Markup("middle", scope .()), centred, scope .());
		Test.Assert(layout.Lines.Count == 1);
		Test.Assert(Near(layout.Lines[0].Left, (200.0f - layout.Lines[0].Width) * 0.5f));
		Test.Assert(Near(layout.GlyphRuns[0].Glyphs[0].X, layout.Lines[0].Left));
	}

	[Test]
	public static void BoldTakesTheBoldFaceItalicWithoutOneIsSynthesized()
	{
		let fonts = Roboto(scope .());
		let style = Style(fonts, scope .());
		let bold = scope TextRun();
		bold.Bold = true;
		let b = ResolveRunFont(bold, style);
		Test.Assert(b.Font != null);
		Test.Assert(!b.SyntheticBold);
		Test.Assert(b.Font !== fonts.GetFont("Roboto", 16.0f));
		let italic = scope TextRun();
		italic.Italic = true;
		let i = ResolveRunFont(italic, style);
		Test.Assert(i.SyntheticItalic);
		Test.Assert(!i.SyntheticBold);
		let both = scope TextRun();
		both.Bold = true;
		both.Italic = true;
		let bi = ResolveRunFont(both, style);
		Test.Assert(!bi.SyntheticBold); // the bold face, slanted
		Test.Assert(bi.SyntheticItalic);
	}

	[Test]
	public static void UnderlinesAndLinksCoverTheirRuns()
	{
		let fonts = Roboto(scope .());
		let layout = LayOutText(Markup("see [u][link=hint]the hint[/link][/u] here", scope .()), Style(fonts, scope .()), scope .());
		Test.Assert(layout.Links.Count == 2); // "the " and "hint"
		Test.Assert(layout.Underlines.Count == 2);
		let first = layout.Links[0].Rect;
		Test.Assert(layout.LinkAt(.(first.X + 1.0f, first.Y + first.Height * 0.5f)) == 1);
		Test.Assert(layout.LinkAt(.(0.5f, first.Y + first.Height * 0.5f)) == -1); // "see"
		Test.Assert(layout.Underlines[0].Rect.Y > layout.Lines[0].Baseline); // below the baseline
		// The underline runs on under the space between the words, and stops at the last letter.
		Test.Assert(Near(layout.Underlines[0].Rect.X + layout.Underlines[0].Rect.Width, layout.Underlines[1].Rect.X));
	}

	[Test]
	public static void PlainRunsDrawInTheLabelsFontWithNoServiceABoldRunIsSynthesizedInIt()
	{
		let fonts = Roboto(scope .());
		let style = Style(fonts, scope .());
		let plain = LayOutText(TextDocument.Plain("plain", scope .()), style, scope .());
		Test.Assert(plain.GlyphRuns.Count == 1);
		Test.Assert(plain.GlyphRuns[0].Font === style.Font);
		style.Fonts = null;
		let bold = scope TextRun();
		bold.Bold = true;
		let b = ResolveRunFont(bold, style);
		Test.Assert(b.Font === style.Font);
		Test.Assert(b.SyntheticBold);
		// A size of its own needs the service: without one the run keeps the label's.
		let big = scope TextRun();
		big.Size = 32.0f;
		Test.Assert(ResolveRunFont(big, style).Font === style.Font);
		Test.Assert(Near(ResolveRunFont(big, style).Size, 16.0f));
	}

	// === The GUI's additions: ellipses, the clamp, line height and spacing on shaped text, carets ===

	[Test]
	public static void AnOverflowingLineEndsInAnEllipsisAtItsEndStartOrMiddleInsideTheWidth()
	{
		let fonts = Roboto(scope .());
		StringView path = "/home/player/saves/slot-three/profile.dat";
		let doc = TextDocument.Plain(path, scope .());
		let style = Style(fonts, scope .(), 150.0f);
		style.Wrap = false;
		let full = LayOutText(doc, style, scope .());
		Test.Assert(full.Width > 150.0f); // clipped: as wide as the text
		Test.Assert(!full.Lines[0].Ellipsized);

		style.Overflow = .Ellipsis;
		let end = LayOutText(doc, style, scope .());
		Test.Assert(end.Lines[0].Ellipsized);
		Test.Assert(end.Width <= 150.0f + 0.01f);
		let endShown = scope String();
		TextFixtures.ShownInOrder(end, path, 0, endShown);
		Test.Assert(endShown.Substring(0, 6) == "/home/");
		Test.Assert(endShown.Substring(endShown.Length - 1, 1) == "~");

		style.Overflow = .EllipsisStart;
		let start = LayOutText(doc, style, scope .());
		Test.Assert(start.Width <= 150.0f + 0.01f);
		let startShown = scope String();
		TextFixtures.ShownInOrder(start, path, 0, startShown);
		Test.Assert(startShown.Substring(0, 1) == "~");
		Test.Assert(startShown.Substring(startShown.Length - 4, 4) == ".dat");
		for (let run in start.GlyphRuns)
			for (let g in run.Glyphs)
				Test.Assert(g.X >= -0.01f);

		style.Overflow = .EllipsisMiddle;
		let middle = LayOutText(doc, style, scope .());
		Test.Assert(middle.Width <= 150.0f + 0.01f);
		let middleShown = scope String();
		TextFixtures.ShownInOrder(middle, path, 0, middleShown);
		Test.Assert(middleShown.Substring(0, 6) == "/home/");
		Test.Assert(middleShown.Substring(middleShown.Length - 4, 4) == ".dat");
		bool ellipsisInside = false;
		for (int i = 1; i + 1 < middleShown.Length; i++)
			ellipsisInside = ellipsisInside || (middleShown[i] == '~');
		Test.Assert(ellipsisInside);

		// Centred, the shortened line centres.
		style.Overflow = .Ellipsis;
		style.Align = .Center;
		let centred = LayOutText(doc, style, scope .());
		Test.Assert(Near(centred.Lines[0].Left, (150.0f - centred.Lines[0].Width) * 0.5f));
	}

	[Test]
	public static void AClampKeepsItsLinesAndEndsTheLastInAnEllipsis()
	{
		let fonts = Roboto(scope .());
		let style = Style(fonts, scope .(), 120.0f);
		style.MaxLines = 2;
		style.Overflow = .Ellipsis;
		let layout = LayOutText(TextDocument.Plain("The guests dance while the band plays on into the night and the masks turn", scope .()),
			style, scope .());
		Test.Assert(layout.Lines.Count == 2);
		Test.Assert(layout.Clamped);
		Test.Assert(layout.Lines[1].Ellipsized);
		Test.Assert(!layout.Lines[0].Ellipsized);
		Test.Assert(Near(layout.Height, layout.Lines[1].Top + layout.Lines[1].Height));
		for (let run in layout.GlyphRuns)
			Test.Assert(run.Line < 2);
	}

	[Test]
	public static void LineHeightSpacesShapedLinesLetterSpacingWidensEachGlyphsStep()
	{
		let fonts = Roboto(scope .());
		let style = Style(fonts, scope .(), 60.0f);
		style.LineHeight = 40.0f;
		let tall = LayOutText(TextDocument.Plain("one two three", scope .()), style, scope .());
		Test.Assert(tall.Lines.Count >= 2);
		Test.Assert(Near(tall.Lines[1].Top, 40.0f));
		Test.Assert(Near(tall.Lines[1].Baseline - tall.Lines[0].Baseline, 40.0f));

		let plain = Style(fonts, scope .());
		let narrow = LayOutText(TextDocument.Plain("abc", scope .()), plain, scope .());
		plain.LetterSpacing = 3.0f;
		let wide = LayOutText(TextDocument.Plain("abc", scope .()), plain, scope .());
		Test.Assert(Near(wide.Width, narrow.Width + 9.0f));
		Test.Assert(wide.GlyphRuns[0].Glyphs.Count == 3);
		Test.Assert(Near(wide.GlyphRuns[0].Glyphs[2].X - narrow.GlyphRuns[0].Glyphs[2].X, 6.0f));
	}

	[Test]
	public static void ACaretsXFollowsItsOffsetAndAPointFindsTheNearestOffsetOnItsLine()
	{
		let fonts = Roboto(scope .());
		StringView text = "ab cd\nefg";
		let layout = LayOutText(TextDocument.Plain(text, scope .()), Style(fonts, scope .()), scope .());
		Test.Assert(layout.Lines.Count == 2);
		Test.Assert(layout.Lines[0].Start == 0);
		Test.Assert(layout.Lines[0].End == 5);
		Test.Assert(layout.Lines[1].Start == 6);
		Test.Assert(layout.Lines[1].End == 9);
		Test.Assert(layout.LineOf(5) == 0);
		Test.Assert(layout.LineOf(6) == 1);
		float last = -1.0f;
		for (int offset = 0; offset <= 5; offset++)
		{
			let x = layout.CaretX(offset);
			Test.Assert(x > last);
			last = x;
			Test.Assert(layout.OffsetAt(.(x + 0.5f, layout.Lines[0].Baseline)) == offset);
		}
		Test.Assert(Near(layout.CaretX(6), 0.0f));
		Test.Assert(layout.OffsetAt(.(1000.0f, layout.Lines[1].Baseline)) == 9);
		Test.Assert(layout.OffsetAt(.(-5.0f, -5.0f)) == 0);
	}

	[Test]
	public static void AWrappedLinesCaretEndStaysOnIt()
	{
		let fonts = Roboto(scope .());
		let layout = LayOutText(TextDocument.Plain("alpha beta", scope .()), Style(fonts, scope .(), 50.0f), scope .());
		Test.Assert(layout.Lines.Count == 2);
		Test.Assert(layout.Lines[0].End == layout.Lines[1].Start);
		let end = layout.OffsetAt(.(49.0f, layout.Lines[0].Baseline));
		Test.Assert(layout.LineOf(end) == 0);
	}

	[Test]
	public static void AnEllipsisTheFontsAtlasLacksFallsBackToFullStops()
	{
		let fonts = Roboto(scope .()); // baked over Latin-1: no U+2026
		let roboto = fonts.GetFont("Roboto", 16.0f);
		Test.Assert(!FontDraws(roboto, "\u{2026}"));
		Test.Assert(FontDraws(roboto, "abc"));
		Test.Assert(EllipsisFor(roboto) == "...");
		let style = Style(fonts, scope .(), 60.0f);
		style.Wrap = false;
		style.Overflow = .Ellipsis;
		let layout = LayOutText(TextDocument.Plain("a long line of text", scope .()), style, scope .());
		int ellipsisGlyphs = 0;
		for (let run in layout.GlyphRuns)
			if (run.Run < 0)
				ellipsisGlyphs += run.Glyphs.Count;
		Test.Assert(ellipsisGlyphs == 3);
		Test.Assert(layout.Width <= 60.0f + 0.01f);
	}
}
