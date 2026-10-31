using System;
using Sedulous.UI;

namespace Samples.UISandbox;

/// The three virtualized item views side by side.
///
/// The counts are the point: a thousand list rows and two hundred grid cells build only what
/// fits on screen, so the cost tracks the VIEWPORT rather than the data.
static class DataControlsTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		let body = SandboxViews.HFlex(8.0f);
		body.Padding = .(8);
		tabView.AddTab("Data Controls", body);

		{
			let column = AddColumn(body, "ListView (1000 items)");
			let list = new ListView();
			list.SetAdapter(app.ListAdapter);
			column.AddView(list, SandboxViews.Grow(1));
		}

		{
			let column = AddColumn(body, "TreeView");
			let tree = new TreeView();
			// The adapter's rows take their indent from the tree, so it needs to know which.
			app.TreeAdapter.SetTree(tree);
			tree.SetAdapter(app.TreeAdapter);
			column.AddView(tree, SandboxViews.Grow(1));
		}

		{
			let column = AddColumn(body, "GridView (200 cells)");
			let grid = new GridView();
			grid.SetAdapter(app.GridAdapter);
			column.AddView(grid, SandboxViews.Grow(1));
		}
	}

	private static FlexLayout AddColumn(FlexLayout body, StringView title)
	{
		let column = SandboxViews.VFlex(4.0f);

		let caption = new Label();
		caption.SetText(title);
		column.AddView(caption);

		body.AddView(column, SandboxViews.Grow(1));
		return column;
	}
}
