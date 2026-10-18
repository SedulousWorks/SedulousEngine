using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// The inline formatter over the bundled Roboto faces: mixed sizes share a baseline, a paragraph
/// of three colours wraps inside its width, an icon sits on the baseline, breaks and alignment,
/// and bold and italic take a face or synthesize one.
class TextLayoutTests
{
	/// Roboto, and Roboto Bold as its own family, as a project loads a bold face. Null where the
	/// checkout's fonts cannot be found.
	private static TrueTypeFontService MakeRoboto()
	{
		let directory = scope String();
		GetCurrentDirectory(directory);
		for (int depth < 8)
		{
			let regular = scope String();
			PathJoin(directory, "Data/Assets/fonts/roboto/Roboto-Regular.ttf", regular);
			if (File.Exists(regular))
			{
				let bold = scope String();
				PathJoin(directory, "Data/Assets/fonts/roboto/Roboto-Bold.ttf", bold);
				let service = new TrueTypeFontService();
				Test.Assert(service.LoadFont("Roboto", regular) == .Success);
				Test.Assert(service.LoadFont("Roboto Bold", bold) == .Success);
				return service;
			}
			let parent = scope String();
			PathParent(directory, parent);
			if (parent.IsEmpty || (parent == directory))
				break;
			directory.Set(parent);
		}
		return null;
	}

	private static TextLayoutStyle Style(float maxWidth = 0.0f)
	{
		var style = TextLayoutStyle();
		style.Family = "Roboto";
		style.Size = 16.0f;
		style.MaxWidth = maxWidth;
		return style;
	}

	private static bool Near(float a, float b, float epsilon = 0.01f) => Math.Abs(a - b) <= epsilon;

	/// Lays markup out with the default style unless one is given; the caller owns the layout.
	private static TextLayout LayOut(StringView markup, IFontService fonts, TextLayoutStyle? style = null)
	{
		let document = TextMarkup.Parse(markup);
		defer delete document;
		return TextLayouter.LayOut(document, style.HasValue ? style.Value : Style(), fonts);
	}

	[Test]
	public static void RunsOfTwoSizesShareOneBaselineTheLineAsTallAsTheLarger()
	{
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let layout = LayOut("small [size=32]BIG[/size] small", fonts);
		defer delete layout;
		Test.Assert(layout.Lines.Count == 1);
		Test.Assert(layout.GlyphRuns.Count >= 3);
		let baseline = layout.Lines[0].Baseline;
		for (let run in layout.GlyphRuns)
		{
			Test.Assert(Near(run.Baseline, baseline));
			for (let glyph in run.Glyphs)
				Test.Assert(Near(glyph.Y, baseline));
		}
		let big = fonts.GetFont("Roboto", 32.0f);
		let small = fonts.GetFont("Roboto", 16.0f);
		Test.Assert((big != null) && (small != null));
		Test.Assert(Near(baseline, big.Font.Metrics.Ascent));
		Test.Assert(layout.Height > small.Font.Metrics.LineHeight * 1.5f);
		// Runs follow on: each starts where the one before it ended.
		for (int r = 1; r < layout.GlyphRuns.Count; r++)
			Test.Assert(layout.GlyphRuns[r].Glyphs[0].X > layout.GlyphRuns[r - 1].Glyphs[0].X);
	}

	[Test]
	public static void AParagraphOfThreeColoursWrapsInsideItsWidthAndKeepsItsColours()
	{
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let layout = LayOut("The [color=#ff0000]guests in red[/color] dance while [color=#00ff00]the ones in green[/color] watch and [color=#0000ff]the band in blue[/color] plays on into the night",
			fonts, Style(160.0f));
		defer delete layout;
		Test.Assert(layout.Lines.Count >= 3);
		var total = 0.0f;
		for (let line in layout.Lines)
		{
			Test.Assert(line.Width <= 160.0f + 0.01f);
			Test.Assert(Near(line.Top, total));
			total += line.Height;
		}
		Test.Assert(Near(layout.Height, total));
		var red = false;
		var green = false;
		var blue = false;
		for (let run in layout.GlyphRuns)
		{
			red = red || (run.Color.R == 1.0f);
			green = green || (run.Color.G == 1.0f);
			blue = blue || (run.Color.B == 1.0f);
			for (let glyph in run.Glyphs)
				Test.Assert(glyph.X + glyph.Advance <= 160.0f + 4.0f, "within the width (a space may hang over)");
		}
		Test.Assert(red && green && blue);
	}

	[Test]
	public static void AnIconSitsOnTheBaselineAsTallAsItsTextIsBig()
	{
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let layout = LayOut("a [size=20][icon=Icons/rose.png][/size] b", fonts);
		defer delete layout;
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
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let two = LayOut("a\nb", fonts);
		defer delete two;
		Test.Assert(two.Lines.Count == 2);
		let trailing = LayOut("a\n", fonts);
		defer delete trailing;
		Test.Assert(trailing.Lines.Count == 2);
		Test.Assert(trailing.Lines[1].Height > 0.0f);

		var centred = Style(200.0f);
		centred.Align = .Center;
		let layout = LayOut("middle", fonts, centred);
		defer delete layout;
		Test.Assert(layout.Lines.Count == 1);
		Test.Assert(Near(layout.Lines[0].Left, (200.0f - layout.Lines[0].Width) * 0.5f));
		Test.Assert(Near(layout.GlyphRuns[0].Glyphs[0].X, layout.Lines[0].Left));
	}

	[Test]
	public static void BoldTakesTheBoldFaceItalicWithoutOneIsSynthesized()
	{
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let bold = scope TextRun();
		bold.Bold = true;
		let b = TextLayouter.ResolveRunFont(bold, Style(), fonts);
		Test.Assert(b.Font != null);
		Test.Assert(!b.SyntheticBold);
		Test.Assert(b.Font != fonts.GetFont("Roboto", 16.0f));
		let italic = scope TextRun();
		italic.Italic = true;
		let i = TextLayouter.ResolveRunFont(italic, Style(), fonts);
		Test.Assert(i.SyntheticItalic);
		Test.Assert(!i.SyntheticBold);
		let both = scope TextRun();
		both.Bold = true;
		both.Italic = true;
		let bi = TextLayouter.ResolveRunFont(both, Style(), fonts);
		Test.Assert(!bi.SyntheticBold, "the bold face, slanted");
		Test.Assert(bi.SyntheticItalic);
	}

	[Test]
	public static void UnderlinesAndLinksCoverTheirRuns()
	{
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let layout = LayOut("see [u][link=hint]the hint[/link][/u] here", fonts);
		defer delete layout;
		Test.Assert(layout.Links.Count == 2, "\"the \" and \"hint\"");
		Test.Assert(layout.Underlines.Count == 2);
		let first = layout.Links[0].Rect;
		Test.Assert(layout.LinkAt(.(first.X + 1.0f, first.Y + first.Height * 0.5f)) == 1);
		Test.Assert(layout.LinkAt(.(0.5f, first.Y + first.Height * 0.5f)) == -1, "\"see\"");
		Test.Assert(layout.Underlines[0].Rect.Y > layout.Lines[0].Baseline, "below the baseline");
		// The underline runs on under the space between the words, and stops at the last letter.
		Test.Assert(Near(layout.Underlines[0].Rect.X + layout.Underlines[0].Rect.Width, layout.Underlines[1].Rect.X));
	}

	// ---- The RichText control over the formatter ----

	[Test]
	public static void ARichTextMeasuresWrappedAtItsWidthAndDrawsEveryRun()
	{
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let context = scope UIContext();
		context.SetFontService(fonts);
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);
		let text = new RichText("The [color=#ff0000]guests in red[/color] dance while [b]the band[/b] plays on into the night and the masks turn");
		text.FontFamily.Value.Set("Roboto");
		root.AddView(text);
		UITest.LayoutPass(context, root);
		// Measured loosely at a width: wrapped there, as tall as its lines.
		text.Measure(BoxConstraints.Loose(160.0f, 1000.0f));
		Test.Assert(text.Layout.Lines.Count >= 3);
		Test.Assert(text.MeasuredSize.X <= 160.0f + 0.01f);
		Test.Assert(Near(text.MeasuredSize.Y, text.Layout.Height));

		let canvas = scope VGContext();
		context.DrawRootView(root, canvas);
		Test.Assert(canvas.GetBatch().Commands.Count > 0);
	}

	[Test]
	public static void AClickOnALinkRaisesOnLinkWithItsIdAndAClickElsewhereDoesNot()
	{
		let fonts = MakeRoboto();
		if (fonts == null)
			return;
		defer delete fonts;
		let context = scope UIContext();
		context.SetFontService(fonts);
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);
		let text = new RichText("go [link=door]open the door[/link] now");
		text.FontFamily.Value.Set("Roboto");
		root.AddView(text);
		UITest.LayoutPass(context, root);
		let heard = scope String();
		text.OnLink.Add(new [&](sender, id) => { heard.Set(id); });

		Test.Assert(!text.Layout.Links.IsEmpty);
		let link = text.Layout.Links[0].Rect;
		let at = text.LocalToScreen(.(link.X + link.Width * 0.5f, link.Y + link.Height * 0.5f));
		Test.Assert(text.CursorAt(.(link.X + 1.0f, link.Y + 1.0f)) == .Hand);
		context.GetInputManager().ProcessMouseDown(.Left, at.X, at.Y, 0);
		context.GetInputManager().ProcessMouseUp(.Left, at.X, at.Y);
		Test.Assert(heard == "door");

		heard.Clear();
		// On "go".
		let before = text.LocalToScreen(.(2.0f, link.Y + link.Height * 0.5f));
		context.GetInputManager().ProcessMouseDown(.Left, before.X, before.Y, 0);
		context.GetInputManager().ProcessMouseUp(.Left, before.X, before.Y);
		Test.Assert(heard.IsEmpty);
	}

	[Test]
	public static void MalformedMarkupIsDrawnAsWrittenAndRunsSetDirectlyReplaceIt()
	{
		let text = new RichText("a [blink]b");
		defer text.ReleaseRef();
		Test.Assert(text.Document.PlainText(.. scope .()) == "a [blink]b");
		Test.Assert(text.Document.Diagnostics.Count == 1);

		let runs = scope List<TextRun>();
		let run = new TextRun();
		run.Text.Set("set");
		run.Bold = true;
		runs.Add(run);
		text.SetRuns(runs);
		Test.Assert(runs.IsEmpty, "the control took them");
		Test.Assert(text.Document.Runs.Count == 1);
		Test.Assert(text.Document.Runs[0].Bold);
		text.SetMarkup("[i]again[/i]");
		Test.Assert(text.Document.Runs.Count == 1);
		Test.Assert(text.Document.Runs[0].Italic);
	}
}
