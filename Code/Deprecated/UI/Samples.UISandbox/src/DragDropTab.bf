using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// Drag and drop end to end: a source that makes a payload and a drag visual, one target that
/// reorders within itself and another that accepts a copy.
static class DragDropTab
{
	public static void Build(TabView tabView)
	{
		let demo = SandboxViews.VFlex(8.0f);
		demo.Padding = .(12, 8);
		tabView.AddTab("Drag & Drop", demo);

		let caption = new Label();
		caption.SetText("Drag chips to reorder, or drop onto the box");
		demo.AddView(caption);
		demo.AddView(new Separator());

		let row = SandboxViews.HFlex(8.0f);

		let chips = new ChipReorderContainer();
		chips.Direction = .Horizontal;
		chips.Spacing = 4.0f;

		Color[5] colors = .(
			Color.Rgb(220, 60, 60), Color.Rgb(60, 180, 60), Color.Rgb(60, 100, 220),
			Color.Rgb(220, 180, 40), Color.Rgb(180, 60, 220));

		for (let color in colors)
		{
			chips.AddView(new DragChip(color),
				SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(30)), SizeSpec.Fixed(Unit.Px(30))));
		}

		row.AddView(chips);

		var boxStyle = SandboxViews.Grow(1);
		boxStyle.Height = SizeSpec.Fixed(Unit.Px(30));
		row.AddView(new ColorDropBox(), boxStyle);

		demo.AddView(row);
	}
}
