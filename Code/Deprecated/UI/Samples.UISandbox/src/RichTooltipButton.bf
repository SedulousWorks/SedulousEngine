using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// A button whose tooltip is a built VIEW rather than a line of text.
///
/// It is interactive, so the tooltip survives the pointer moving onto it, which is the only way
/// content with its own controls would ever be reachable.
class RichTooltipButton : Button, ITooltipProvider
{
	public this(StringView text) : base(text)
	{
		IsTooltipInteractive = true;
	}

	public override ITooltipProvider AsTooltipProvider() => this;

	public View CreateTooltipContent()
	{
		let layout = new FlexLayout();
		layout.Direction = .Vertical;
		layout.Spacing = 4.0f;

		layout.AddView(MakeLabel("Rich Tooltip", false));
		layout.AddView(new Separator());
		layout.AddView(MakeLabel("This tooltip has multiple lines,", true));
		layout.AddView(MakeLabel("a separator, and custom content.", true));

		let swatches = new FlexLayout();
		swatches.Direction = .Horizontal;
		swatches.Spacing = 4.0f;
		swatches.AddView(new ColorView(Color.Rgb(220, 60, 60), 16.0f, 16.0f));
		swatches.AddView(new ColorView(Color.Rgb(60, 180, 60), 16.0f, 16.0f));
		swatches.AddView(new ColorView(Color.Rgb(60, 60, 220), 16.0f, 16.0f));
		layout.AddView(swatches);

		return layout;
	}

	private static Label MakeLabel(StringView text, bool dim)
	{
		let label = new Label();
		label.SetText(text);
		if (dim)
			label.AddClass("label-dim");

		return label;
	}
}
