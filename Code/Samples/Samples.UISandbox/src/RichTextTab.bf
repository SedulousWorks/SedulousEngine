using System;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Samples.UISandbox;

/// Rich text for a look: colour, a real bold face (the sandbox loads Roboto Bold as its own
/// family), a synthetic italic, underline, a larger run and another family on one baseline, a
/// centred paragraph wrapping at 300 px, and links that report their id to a label, with a
/// malformed tag left as text.
static class RichTextTab
{
	public static void Build(TabView tabView)
	{
		let demo = SandboxViews.VFlex(12.0f);
		demo.Padding = .(12, 8);
		tabView.AddTab("Rich Text", demo);

		Paragraph(demo, "Your mark wears [color=#e05a7a][b]a rose gown[/b][/color], and [i]slanted[/i] words lean " +
			"without an italic face. [u]Underlined[/u], [size=24]bigger[/size] and [font=Chewy]Chewy[/font] " +
			"share one baseline.", 0.0f, .Left);
		Paragraph(demo, "A centred paragraph that wraps at three hundred pixels: [color=#f0c040]gold[/color], " +
			"[color=#60c0f0]sky[/color] and [color=#80e080]leaf[/color] runs flow from line to line as one text.",
			300.0f, .Center);

		let heard = new Label();
		heard.SetText("No link clicked yet.");
		let links = Paragraph(demo, "Links: [link=north][u]go north[/u][/link] or [link=south][u]go south[/u][/link]. " +
			"Malformed tags such as [blink] stay as text.", 0.0f, .Left);
		links.OnLink.Add(new (text, id) =>
			{
				heard.SetText(scope $"Clicked the link \"{id}\".");
			});
		demo.AddView(heard);
	}

	/// A width of nought fills the row.
	private static RichText Paragraph(FlexLayout demo, StringView markup, float width, TextAlignment align)
	{
		let text = new RichText(markup);
		text.HAlign.Value = align;
		demo.AddView(text, SandboxViews.Sized(width > 0.0f ? .Fixed(.Px(width)) : .Match(), .Wrap()));
		return text;
	}
}
