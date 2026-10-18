using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Rich text runs and their markup: what each tag sets, how runs merge and nest, and that nothing
/// malformed is ever dropped.
class TextRunsTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) <= 0.001f;

	private static void Plain(TextDocument document, String outText) => document.PlainText(outText);

	[Test]
	public static void PlainTextIsOneUnstyledRun()
	{
		let document = TextMarkup.Parse("Your mark wears a gown");
		defer delete document;
		Test.Assert(document.Runs.Count == 1);
		Test.Assert(document.Runs[0].Text == "Your mark wears a gown");
		Test.Assert(!document.Runs[0].Color.HasValue);
		Test.Assert(!document.Runs[0].Bold);
		Test.Assert(document.Diagnostics.IsEmpty);
	}

	[Test]
	public static void TagsStyleTheirSpanAndNest()
	{
		let document = TextMarkup.Parse("Your mark wears [color=#d04060][b]a rose[/b] gown[/color] [size=24][i]now[/]");
		defer delete document;
		Test.Assert(document.Runs.Count == 5);
		Test.Assert(document.Runs[0].Text == "Your mark wears ");
		Test.Assert(document.Runs[1].Text == "a rose");
		Test.Assert(document.Runs[1].Bold);
		Test.Assert(document.Runs[1].Color.HasValue);
		Test.Assert(Near(document.Runs[1].Color.Value.R, 0xd0 / 255.0f));
		Test.Assert(document.Runs[2].Text == " gown");
		Test.Assert(!document.Runs[2].Bold);
		Test.Assert(document.Runs[2].Color.HasValue, "still inside the colour");
		Test.Assert(document.Runs[3].Text == " ");
		Test.Assert(!document.Runs[3].Color.HasValue);
		Test.Assert(document.Runs[4].Text == "now");
		Test.Assert(document.Runs[4].Italic);
		Test.Assert(document.Runs[4].Size.HasValue);
		Test.Assert(Near(document.Runs[4].Size.Value, 24.0f));
		Test.Assert(document.Diagnostics.IsEmpty);
		Test.Assert(Plain(document, .. scope .()) == "Your mark wears a rose gown now");
	}

	/// Adjacent runs of one style merge: an empty span between them, or the same tag closed and
	/// opened again, leaves one run.
	[Test]
	public static void AdjacentRunsOfOneStyleMerge()
	{
		let document = TextMarkup.Parse("a[b][/b]b [color=red]x[/color][color=red]y[/color]");
		defer delete document;
		Test.Assert(document.Runs.Count == 2, scope $"{document.Runs.Count} runs");
		Test.Assert(document.Runs[0].Text == "ab ");
		Test.Assert(document.Runs[1].Text == "xy");
		Test.Assert(document.Runs[1].Color.HasValue);
	}

	[Test]
	public static void FontsUnderlineLinksAndIcons()
	{
		let document = TextMarkup.Parse("[font=Chewy][u]Hi[/u][/font] [icon=Icons/rose.png] [link=hint]what?[/link]");
		defer delete document;
		Test.Assert(document.Runs.Count == 5);
		Test.Assert(document.Runs[0].Family != null);
		Test.Assert(document.Runs[0].Family == "Chewy");
		Test.Assert(document.Runs[0].Underline);
		Test.Assert(document.Runs[2].IsIcon);
		Test.Assert(document.Runs[2].Icon == "Icons/rose.png");
		Test.Assert(document.Runs[2].Text.IsEmpty);
		Test.Assert(document.Runs[4].Link == "hint");
		Test.Assert(document.Runs[4].Text == "what?");
		Test.Assert(Plain(document, .. scope .()) == "Hi \u{FFFC} what?");
	}

	[Test]
	public static void ADoubledBracketIsALiteralOneAndALoneCloseIsText()
	{
		let document = TextMarkup.Parse("[[b]] is not bold ]");
		defer delete document;
		Test.Assert(document.Runs.Count == 1);
		Test.Assert(document.Runs[0].Text == "[b]] is not bold ]");
		Test.Assert(!document.Runs[0].Bold);
		Test.Assert(document.Diagnostics.IsEmpty);
	}

	[Test]
	public static void MalformedTagsStayAsTextAndAreReported()
	{
		let source = "a [blink]b[/blink] [size=big]c [color=nope]d [/i] [b=1]e [ f";
		let document = TextMarkup.Parse(source);
		defer delete document;
		// Every character of the source is still there.
		Test.Assert(Plain(document, .. scope .()) == source);
		for (let run in document.Runs)
		{
			Test.Assert(!run.Bold);
			Test.Assert(!run.Size.HasValue);
			Test.Assert(!run.Color.HasValue);
		}
		// blink, /blink, size, color, /i, b=1, and the unclosed bracket.
		Test.Assert(document.Diagnostics.Count == 7, scope $"{document.Diagnostics.Count} diagnostics");
		Test.Assert(document.Diagnostics[0].Offset == 2);
	}

	[Test]
	public static void ACloseRunsPastInnerTagsAndColourNamesResolve()
	{
		let document = TextMarkup.Parse("[color=$gold][b]x[/color]y [color=red]z", scope (name) =>
			{
				if (name == "gold")
					return Color(1.0f, 0.8f, 0.2f, 1.0f);
				return null;
			});
		defer delete document;
		Test.Assert(document.Runs.Count == 3);
		Test.Assert(document.Runs[0].Bold);
		Test.Assert(document.Runs[0].Color.HasValue);
		Test.Assert(Near(document.Runs[0].Color.Value.G, 0.8f));
		Test.Assert(!document.Runs[1].Bold, "closed with the colour");
		Test.Assert(!document.Runs[1].Color.HasValue);
		Test.Assert(document.Runs[2].Color.HasValue, "a named CSS colour without the resolver's help");
		Test.Assert(Near(document.Runs[2].Color.Value.R, 1.0f));
		Test.Assert(document.Diagnostics.Count == 1, "[/color] closing the [b] inside it");
	}
}
