using System;
using Sedulous.UI;

namespace Samples.UISandbox;

/// Four nested tab views in a two by two grid, one per placement.
///
/// Each is packed with far more tabs than its cell can show, which is the point: a top or bottom
/// strip overflows HORIZONTALLY and a left or right strip VERTICALLY. The wheel scrolls a strip,
/// and arrowing or clicking to a tab that is off screen scrolls it into view.
static class TabPlacementTab
{
	public static void Build(TabView tabView)
	{
		let demo = new GridLayout();
		demo.Columns.Add(TrackSize.Flex(1));
		demo.Columns.Add(TrackSize.Flex(1));
		demo.Rows.Add(TrackSize.Flex(1));
		demo.Rows.Add(TrackSize.Flex(1));
		demo.ColumnSpacing = 4;
		demo.RowSpacing = 4;
		tabView.AddTab("Tab Placement", demo, true);

		AddPlaced(demo, .Top, "Top", 24, 0, 0);
		AddPlaced(demo, .Bottom, "Bot", 24, 0, 1);
		AddPlaced(demo, .Left, "Left", 24, 1, 0);
		AddPlaced(demo, .Right, "Right", 24, 1, 1);
	}

	private static void AddPlaced(GridLayout demo, TabPlacement placement, StringView prefix,
		int32 count, int32 row, int32 column)
	{
		let tabs = new TabView();
		tabs.Placement.Value = placement;

		for (int32 i = 1; i <= count; i++)
		{
			let title = scope $"{prefix} {i}";
			let label = new Label();
			label.SetText(title);
			tabs.AddTab(title, label);
		}

		LayoutStyle style = .();
		style.GridRow = row;
		style.GridColumn = column;
		demo.AddView(tabs, style);
	}
}
