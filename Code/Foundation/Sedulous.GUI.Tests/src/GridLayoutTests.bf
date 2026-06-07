namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class GridLayoutTests
{
	[Test]
	public static void FixedColumns_CorrectWidths()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(100));
		grid.Columns.Add(.Fixed(200));
		grid.Rows.Add(.Fixed(50));
		let a = new TestView();
		let b = new TestView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 100) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 200) < 1.0f);
		Test.Assert(Math.Abs(b.Bounds.X - 100) < 1.0f);
	}

	[Test]
	public static void FlexColumns_ProportionalWidths()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Flex(1));
		grid.Columns.Add(.Flex(3));
		grid.Rows.Add(.Flex(1));
		let a = new TestView();
		let b = new TestView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 100) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 300) < 1.0f);
	}

	[Test]
	public static void AutoColumns_SizeToContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Auto());
		grid.Columns.Add(.Auto());
		grid.Rows.Add(.Auto());
		let a = new TestView(80, 30);
		let b = new TestView(120, 40);
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 80) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 120) < 1.0f);
	}

	[Test]
	public static void Spacing_BetweenCells()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(100));
		grid.Columns.Add(.Fixed(100));
		grid.Rows.Add(.Fixed(50));
		grid.ColumnSpacing = 10;
		let a = new TestView();
		let b = new TestView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(b.Bounds.X - 110) < 1.0f);
	}

	[Test]
	public static void AutoFlow_PlacesSequentially()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout() { AutoFlow = true };
		grid.Columns.Add(.Flex(1));
		grid.Columns.Add(.Flex(1));
		grid.Rows.Add(.Flex(1));
		grid.Rows.Add(.Flex(1));
		let a = new TestView();
		let b = new TestView();
		let c = new TestView();
		let d = new TestView();
		grid.AddView(a);
		grid.AddView(b);
		grid.AddView(c);
		grid.AddView(d);
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X) < 1.0f);
		Test.Assert(Math.Abs(b.Bounds.X - 200) < 1.0f);
		Test.Assert(Math.Abs(c.Bounds.Y - 150) < 1.0f);
		Test.Assert(Math.Abs(d.Bounds.X - 200) < 1.0f);
		Test.Assert(Math.Abs(d.Bounds.Y - 150) < 1.0f);
	}

	[Test]
	public static void ColumnSpan_MergesCells()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(100));
		grid.Columns.Add(.Fixed(100));
		grid.Columns.Add(.Fixed(100));
		grid.Rows.Add(.Fixed(50));
		grid.ColumnSpacing = 5;
		let a = new TestView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0, ColumnSpan = 2 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 205) < 1.0f);
	}

	[Test]
	public static void RowSpan_MergesCells()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(100));
		grid.Rows.Add(.Fixed(50));
		grid.Rows.Add(.Fixed(60));
		grid.RowSpacing = 4;
		let a = new TestView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0, RowSpan = 2 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Height - 114) < 1.0f);
	}

	[Test]
	public static void MixedTracks_FixedAutoFlex()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(80));
		grid.Columns.Add(.Auto());
		grid.Columns.Add(.Flex(1));
		grid.Rows.Add(.Flex(1));
		let a = new TestView(80, 30);
		let b = new TestView(60, 30);
		let c = new TestView(50, 30);
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });
		grid.AddView(c, new GridLayout.LayoutParams() { Row = 0, Column = 2 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 80) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 60) < 1.0f);
		Test.Assert(Math.Abs(c.Width - 260) < 1.0f);
	}
}
