using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Samples.UISandbox;

/// Rich text for a look: colour, a real bold face (the sandbox loads Roboto Bold as its own
/// family), a synthetic italic, underline, a larger run and another family on one baseline, a
/// centred paragraph wrapping at 300 px, and links that report their id to a label, with a
/// malformed tag left as text. Then text effects over bright stripes, from a distance-field face:
/// an outline, a shadow, a glow and all three together, with no panel behind the text.
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

		// Text effects over bright stripes, from a distance-field face: no panel behind the text.
		let stage = new FrameLayout();
		let stripes = SandboxViews.HFlex(0.0f);
		for (int i < 24)
		{
			let color = ((i % 3) == 0) ? Color(0.95f, 0.85f, 0.3f, 1.0f)
				: (((i % 3) == 1) ? Color(0.98f, 0.98f, 0.95f, 1.0f) : Color(0.3f, 0.65f, 0.95f, 1.0f));
			stripes.AddView(new ColorView(color, 24.0f, 120.0f), SandboxViews.Sized(.Fixed(.Px(24)), .Fixed(.Px(120))));
		}
		stage.AddView(stripes);
		let effects = new RichText("Plain, [outline=2 #000000]outlined[/outline], [shadow=3 3 2 #000000c0]shadowed[/shadow], " +
			"[glow=6 #ff9020]glowing[/glow] and [outline=1.5 #301000][glow=5 #ffd040][color=#fff4d0]all at once[/color][/glow][/outline].");
		effects.FontFamily.Value.Set("Roboto Field");
		effects.FontSize.Value = 30.0f;
		effects.Transform.Translation = .(12.0f, 14.0f);
		stage.AddView(effects, SandboxViews.Sized(.Fixed(.Px(540)), .Wrap()));
		demo.AddView(stage, SandboxViews.Sized(.Fixed(.Px(576)), .Fixed(.Px(120))));
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
