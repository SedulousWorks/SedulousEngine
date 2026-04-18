namespace UISandbox;

using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Demo page: Drag-and-drop with reorderable chips and drop target.
class DragDropPage : DemoPage
{
	public this(DemoContext demo) : base(demo)
	{
		AddSection("Drag & Drop");
		AddLabel("Drag color chips to swap. Drop on the box to change its color.");

		let row = new LinearLayout();
		row.Orientation = .Horizontal;
		row.Spacing = 8;
		mLayout.AddView(row, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height = 36 });

		let container = new ChipReorderContainer();
		container.Orientation = .Horizontal;
		container.Spacing = 4;
		row.AddView(container, new LinearLayout.LayoutParams() { Height =  Sedulous.UI.LayoutParams.MatchParent });

		Color[?] chipColors = .(
			.(220, 60, 60, 255), .(60, 180, 60, 255), .(60, 100, 220, 255),
			.(220, 180, 40, 255), .(180, 60, 220, 255));

		for (int i = 0; i < chipColors.Count; i++)
		{
			let chip = new DragChip();
			chip.Color = chipColors[i];
			chip.PreferredWidth = 30;
			chip.PreferredHeight = 30;
			container.AddView(chip, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
		}

		let dropBox = new ColorDropBox();
		row.AddView(dropBox, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent, Weight = 1 });
	}
}
