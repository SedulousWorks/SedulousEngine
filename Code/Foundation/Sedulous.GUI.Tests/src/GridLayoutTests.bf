namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class GridLayoutTests
{
	[Test]
	public static void AutoFlow_PlacesLeftToRight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(100));
		grid.Columns.Add(.Fixed(100));
		grid.Rows.Add(.Fixed(50));
		grid.Rows.Add(.Fixed(50));

		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		let c = new TestView(50, 30);
		grid.AddView(a);
		grid.AddView(b);
		grid.AddView(c);
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		// a at (0,0), b at (1,0), c at (0,1)
		Test.Assert(Math.Abs(a.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X - 100) < 1.0f);
		Test.Assert(Math.Abs(c.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(c.Bounds.Y - 50) < 1.0f);
	}

	[Test]
	public static void FixedColumns()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(120));
		grid.Columns.Add(.Fixed(80));
		grid.Rows.Add(.Fixed(50));

		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		grid.AddView(a);
		grid.AddView(b);
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 120) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 80) < 1.0f);
		Test.Assert(Math.Abs(b.Bounds.X - 120) < 1.0f);
	}

	[Test]
	public static void ColumnSpacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(100));
		grid.Columns.Add(.Fixed(100));
		grid.ColumnSpacing.Value = 10;
		grid.Rows.Add(.Fixed(50));

		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		grid.AddView(a);
		grid.AddView(b);
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(b.Bounds.X - 110) < 1.0f); // 100 + 10
	}

	[Test]
	public static void FlexColumns_DistributeSpace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Flex(1));
		grid.Columns.Add(.Flex(1));
		grid.Rows.Add(.Fixed(50));

		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		grid.AddView(a);
		grid.AddView(b);
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 200) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 200) < 1.0f);
	}

	[Test]
	public static void ExplicitPlacement()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(.Fixed(100));
		grid.Columns.Add(.Fixed(100));
		grid.Rows.Add(.Fixed(50));
		grid.Rows.Add(.Fixed(50));

		let child = new TestView(50, 30);
		grid.AddView(child, new GridLayout.LayoutParams() { Row = 1, Column = 1 });
		root.AddView(grid);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 100) < 1.0f);
		Test.Assert(Math.Abs(child.Bounds.Y - 50) < 1.0f);
	}
}
