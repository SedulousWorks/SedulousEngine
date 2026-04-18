namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class GridLayoutTests
{
	[Test]
	public static void Grid_PixelColumns()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Pixel(100));
		grid.ColumnDefs.Add(.Pixel(200));
		grid.RowDefs.Add(.Pixel(50));
		root.AddView(grid);

		let a = new ColorView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView();
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(a.Bounds.Width - 100) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 200) < 1);
		Test.Assert(Math.Abs(a.Bounds.Height - 50) < 1);
	}

	[Test]
	public static void Grid_StarColumns()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 100);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Star(1));
		grid.ColumnDefs.Add(.Star(2));
		grid.RowDefs.Add(.Star(1));
		root.AddView(grid);

		let a = new ColorView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView();
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		ctx.UpdateRootView(root);

		// Star 1:2 in 300px -> 100, 200.
		Test.Assert(Math.Abs(a.Bounds.Width - 100) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 200) < 1);
	}
}
