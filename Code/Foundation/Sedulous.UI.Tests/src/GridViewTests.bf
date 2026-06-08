namespace Sedulous.UI.Tests;

using System;

class GridViewTests
{
	[Test]
	public static void GridView_NoAdapter_NoViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 300, 300);

		let gv = new GridView();
		root.AddView(gv);
		TestSetup.Layout(ctx, root);

		// VisualChildCount = active views (0) + scrollbar (1)
		Test.Assert(gv.VisualChildCount == 1);
	}

	[Test]
	public static void GridView_IsFocusable()
	{
		let gv = scope GridView();
		Test.Assert(gv.IsFocusable);
		Test.Assert(gv.IsTabStop);
	}

	[Test]
	public static void GridView_ColumnCalculation()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 300, 300);

		let adapter = new SimpleListAdapter(50);
		defer delete adapter;

		let gv = new GridView();
		gv.CellWidth.Value = 60;
		gv.CellSpacing.Value = 4;
		gv.Adapter = adapter;
		root.AddView(gv);
		TestSetup.Layout(ctx, root);

		// 300 / (60 + 4) = 4.68 -> 4 columns
		// Verify by checking that items at different positions are visible.
		Test.Assert(gv.GetItemAtPoint(0, 0) == 0);
		Test.Assert(gv.GetItemAtPoint(64, 0) == 1);
	}

	[Test]
	public static void GridView_ScrollBy_ClampsBounds()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 300, 300);

		let adapter = new SimpleListAdapter(200);
		defer delete adapter;

		let gv = new GridView();
		gv.CellWidth.Value = 60;
		gv.CellHeight.Value = 60;
		gv.Adapter = adapter;
		root.AddView(gv);
		TestSetup.Layout(ctx, root);

		gv.ScrollBy(-1000);
		Test.Assert(gv.ScrollY == 0);

		gv.ScrollBy(999999);
		Test.Assert(gv.ScrollY == gv.MaxScrollY);
	}

	[Test]
	public static void GridView_Selection()
	{
		let gv = scope GridView();
		let adapter = scope SimpleListAdapter(20);
		gv.Adapter = adapter;

		gv.Selection.Select(5);
		Test.Assert(gv.Selection.IsSelected(5));
		Test.Assert(gv.Selection.SelectedCount == 1);
	}

	[Test]
	public static void GridView_DefaultValues()
	{
		let gv = scope GridView();
		Test.Assert(gv.CellWidth.Value == 60);
		Test.Assert(gv.CellHeight.Value == 60);
		Test.Assert(gv.CellSpacing.Value == 4);
		Test.Assert(gv.ScrollY == 0);
	}
}
