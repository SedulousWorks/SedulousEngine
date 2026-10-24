using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Rich text runs and their markup: what each tag sets, how runs merge and nest, and that nothing
/// malformed is ever dropped. Copied with the runs from foundation.ui.
class TextRunsTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);

	private static void Plain(TextDocument doc, String outText)
	{
		doc.PlainText(outText);
	}

	[Test]
	public static void PlainTextIsOneUnstyledRun()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("Your mark wears a gown", doc);
		Test.Assert(doc.Runs.Count == 1);
		Test.Assert(doc.Runs[0].Text == "Your mark wears a gown");
		Test.Assert(!doc.Runs[0].TextColor.HasValue);
		Test.Assert(!doc.Runs[0].Bold);
		Test.Assert(doc.Diagnostics.IsEmpty);
	}

	[Test]
	public static void TagsStyleTheirSpanAndNest()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("Your mark wears [color=#d04060][b]a rose[/b] gown[/color] [size=24][i]now[/]", doc);
		Test.Assert(doc.Runs.Count == 5);
		Test.Assert(doc.Runs[0].Text == "Your mark wears ");
		Test.Assert(doc.Runs[1].Text == "a rose");
		Test.Assert(doc.Runs[1].Bold);
		Test.Assert(doc.Runs[1].TextColor.HasValue);
		Test.Assert(Near(doc.Runs[1].TextColor.Value.R, 0xd0 / 255.0f));
		Test.Assert(doc.Runs[2].Text == " gown");
		Test.Assert(!doc.Runs[2].Bold);
		Test.Assert(doc.Runs[2].TextColor.HasValue); // still inside the colour
		Test.Assert(doc.Runs[3].Text == " ");
		Test.Assert(!doc.Runs[3].TextColor.HasValue);
		Test.Assert(doc.Runs[4].Text == "now");
		Test.Assert(doc.Runs[4].Italic);
		Test.Assert(doc.Runs[4].Size.HasValue);
		Test.Assert(Near(doc.Runs[4].Size.Value, 24.0f));
		Test.Assert(doc.Diagnostics.IsEmpty);
		Test.Assert(Plain(doc, .. scope .()) == "Your mark wears a rose gown now");
	}

	[Test]
	public static void FontsUnderlineLinksAndIcons()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("[font=Chewy][u]Hi[/u][/font] [icon=Icons/rose.png] [link=hint]what?[/link]", doc);
		Test.Assert(doc.Runs.Count == 5);
		Test.Assert(doc.Runs[0].Family != null);
		Test.Assert(doc.Runs[0].Family == "Chewy");
		Test.Assert(doc.Runs[0].Underline);
		Test.Assert(doc.Runs[2].IsIcon);
		Test.Assert(doc.Runs[2].Icon == "Icons/rose.png");
		Test.Assert(doc.Runs[2].Text.IsEmpty);
		Test.Assert(doc.Runs[4].Link == "hint");
		Test.Assert(doc.Runs[4].Text == "what?");
		Test.Assert(Plain(doc, .. scope .()) == "Hi \u{FFFC} what?");
	}

	[Test]
	public static void ADoubledBracketIsALiteralOneAndALoneCloseIsText()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("[[b]] is not bold ]", doc);
		Test.Assert(doc.Runs.Count == 1);
		Test.Assert(doc.Runs[0].Text == "[b]] is not bold ]");
		Test.Assert(!doc.Runs[0].Bold);
		Test.Assert(doc.Diagnostics.IsEmpty);
	}

	[Test]
	public static void MalformedTagsStayAsTextAndAreReported()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("a [blink]b[/blink] [size=big]c [color=nope]d [/i] [b=1]e [ f", doc);
		// Every character of the source is still there.
		Test.Assert(Plain(doc, .. scope .()) == "a [blink]b[/blink] [size=big]c [color=nope]d [/i] [b=1]e [ f");
		for (let run in doc.Runs)
		{
			Test.Assert(!run.Bold);
			Test.Assert(!run.Size.HasValue);
			Test.Assert(!run.TextColor.HasValue);
		}
		// blink, /blink, size, color, /i, b=1, and the unclosed bracket.
		Test.Assert(doc.Diagnostics.Count == 7);
		Test.Assert(doc.Diagnostics[0].Offset == 2);
	}

	[Test]
	public static void AClosePastInnerTagsClosesThemTooAndColourNamesResolve()
	{
		TextMarkupColorResolver palette = scope (name) =>
			{
				if (name == "gold")
					return Color(1.0f, 0.8f, 0.2f, 1.0f);
				return null;
			};
		let doc = scope TextDocument();
		ParseTextMarkup("[color=$gold][b]x[/color]y [color=red]z", palette, doc);
		Test.Assert(doc.Runs.Count == 3);
		Test.Assert(doc.Runs[0].Bold);
		Test.Assert(doc.Runs[0].TextColor.HasValue);
		Test.Assert(Near(doc.Runs[0].TextColor.Value.G, 0.8f));
		Test.Assert(!doc.Runs[1].Bold); // closed with the colour
		Test.Assert(!doc.Runs[1].TextColor.HasValue);
		Test.Assert(doc.Runs[2].TextColor.HasValue); // a named CSS colour without the resolver's help
		Test.Assert(Near(doc.Runs[2].TextColor.Value.R, 1.0f));
		Test.Assert(doc.Diagnostics.Count == 1); // [/color] closing the [b] inside it
	}

	[Test]
	public static void OutlineShadowAndGlowTagsSetTheirPartOfARunsEffects()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("[outline=2 #102030]Hunt[shadow=1 2 3 red] the[/shadow][/outline] [glow=6]mask[/glow] [shadow=4 5]free[/]", doc);
		Test.Assert(doc.Diagnostics.IsEmpty);
		Test.Assert(doc.Runs.Count == 6);
		// An outline alone, its colour as written.
		Test.Assert(doc.Runs[0].EffectParts == (uint8)TextEffectPart.TextEffectOutline);
		Test.Assert(Near(doc.Runs[0].Effects.OutlineWidth, 2.0f));
		Test.Assert(Near(doc.Runs[0].Effects.OutlineColor.G, 0x20 / 255.0f));
		// A shadow inside it: both parts.
		Test.Assert(doc.Runs[1].EffectParts == ((uint8)TextEffectPart.TextEffectOutline | (uint8)TextEffectPart.TextEffectShadow));
		Test.Assert(Near(doc.Runs[1].Effects.ShadowOffset.X, 1.0f));
		Test.Assert(Near(doc.Runs[1].Effects.ShadowOffset.Y, 2.0f));
		Test.Assert(Near(doc.Runs[1].Effects.ShadowBlur, 3.0f));
		Test.Assert(Near(doc.Runs[1].Effects.ShadowColor.R, 1.0f));
		Test.Assert(doc.Runs[2].EffectParts == 0); // the space after both closed
		// A glow takes white without a colour, a shadow half black and no blur.
		Test.Assert(doc.Runs[3].EffectParts == (uint8)TextEffectPart.TextEffectGlow);
		Test.Assert(Near(doc.Runs[3].Effects.GlowRadius, 6.0f));
		Test.Assert(Near(doc.Runs[3].Effects.GlowColor.R, 1.0f));
		Test.Assert(Near(doc.Runs[5].Effects.ShadowBlur, 0.0f));
		Test.Assert(Near(doc.Runs[5].Effects.ShadowColor.A, 0.5f));
	}

	[Test]
	public static void ARunsEffectsTakeTheControlsForThePartsItLeavesOut()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("[outline=0]plain[/] [glow=3 yellow]bright", doc);
		Test.Assert(doc.Runs.Count == 3);
		var control = TextEffects();
		control.OutlineWidth = 1.0f;
		control.ShadowColor = Color(0.0f, 0.0f, 0.0f, 1.0f);
		control.ShadowOffset = Float2(2.0f, 2.0f);
		// [outline=0] turns the control's outline off and keeps its shadow.
		let plain = doc.Runs[0].EffectsOver(control);
		Test.Assert(!plain.HasOutline);
		Test.Assert(plain.HasShadow);
		// An unmarked run is the control's.
		Test.Assert(doc.Runs[1].EffectsOver(control) == control);
		let bright = doc.Runs[2].EffectsOver(control);
		Test.Assert(bright.HasOutline);
		Test.Assert(bright.HasGlow);
		Test.Assert(Near(bright.GlowRadius, 3.0f));
	}

	[Test]
	public static void MalformedEffectTagsAreReportedAndKeptAsText()
	{
		// A width without a number, a shadow with one offset, a glow with two radii, a colour not last.
		let doc = scope TextDocument();
		ParseTextMarkup("[outline=red]a [shadow=2]b [glow=1 2]c [outline=#fff 1]d", doc);
		Test.Assert(Plain(doc, .. scope .()) == "[outline=red]a [shadow=2]b [glow=1 2]c [outline=#fff 1]d");
		Test.Assert(doc.Diagnostics.Count == 4);
		for (let run in doc.Runs)
			Test.Assert(run.EffectParts == 0);
	}
}
