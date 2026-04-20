namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class LayoutDetailTests
{
	// =========================================================================
	// LinearLayout - Vertical
	// =========================================================================

	[Test]
	public static void Linear_Vertical_Spacing_ThreeChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		layout.Spacing = 12;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredHeight = 30;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });

		let b = new ColorView();
		b.PreferredHeight = 40;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });

		let c = new ColorView();
		c.PreferredHeight = 20;
		layout.AddView(c, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 20 });

		ctx.UpdateRootView(root);

		// a starts at y=0, b at y=30+12=42, c at y=42+40+12=94
		Test.Assert(Math.Abs(a.Bounds.Y - 0) < 1);
		Test.Assert(Math.Abs(b.Bounds.Y - 42) < 1);
		Test.Assert(Math.Abs(c.Bounds.Y - 94) < 1);
	}

	[Test]
	public static void Linear_Horizontal_Spacing_BetweenChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		layout.Spacing = 8;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredWidth = 50;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = 50, Height = LayoutParams.MatchParent });

		let b = new ColorView();
		b.PreferredWidth = 60;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = 60, Height = LayoutParams.MatchParent });

		ctx.UpdateRootView(root);

		// a at x=0, b at x=50+8=58
		Test.Assert(Math.Abs(a.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(b.Bounds.X - 58) < 1);
		Test.Assert(Math.Abs(a.Bounds.Width - 50) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 60) < 1);
	}

	[Test]
	public static void Linear_Vertical_EqualWeights_SplitEvenly()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new ColorView();
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		let b = new ColorView();
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		let c = new ColorView();
		layout.AddView(c, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		ctx.UpdateRootView(root);

		// Three equal weights -> 100px each.
		Test.Assert(Math.Abs(a.Bounds.Height - 100) < 1);
		Test.Assert(Math.Abs(b.Bounds.Height - 100) < 1);
		Test.Assert(Math.Abs(c.Bounds.Height - 100) < 1);
	}

	[Test]
	public static void Linear_Vertical_WeightWithFixedChild()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		// Fixed child takes 60px.
		let fixedChild = new ColorView();
		fixedChild.PreferredHeight = 60;
		layout.AddView(fixedChild, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 60 });

		// Weighted child gets the remaining 240px.
		let weightedChild = new ColorView();
		layout.AddView(weightedChild, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(fixedChild.Bounds.Height - 60) < 1);
		Test.Assert(Math.Abs(weightedChild.Bounds.Height - 240) < 1);
	}

	[Test]
	public static void Linear_Vertical_CrossAxis_CenterH()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let child = new ColorView();
		child.PreferredWidth = 100;
		child.PreferredHeight = 50;
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = 100, Height = 50, Gravity = .CenterH });

		ctx.UpdateRootView(root);

		// Centered horizontally in 400px: (400 - 100) / 2 = 150
		Test.Assert(Math.Abs(child.Bounds.X - 150) < 1);
		Test.Assert(Math.Abs(child.Bounds.Width - 100) < 1);
	}

	[Test]
	public static void Linear_Vertical_CrossAxis_Right()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let child = new ColorView();
		child.PreferredWidth = 80;
		child.PreferredHeight = 40;
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = 80, Height = 40, Gravity = .Right });

		ctx.UpdateRootView(root);

		// Right-aligned in 400px: 400 - 80 = 320
		Test.Assert(Math.Abs(child.Bounds.X - 320) < 1);
	}

	[Test]
	public static void Linear_Vertical_Padding_ReducesAvailableSpace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		layout.Padding = .(20, 10, 20, 10); // left, top, right, bottom
		root.AddView(layout);

		let child = new ColorView();
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		ctx.UpdateRootView(root);

		// MatchParent width should be 400 - 20 - 20 = 360
		Test.Assert(Math.Abs(child.Bounds.Width - 360) < 1);
		// Child starts at y=10 (padding top)
		Test.Assert(Math.Abs(child.Bounds.Y - 10) < 1);
		// Child starts at x=20 (padding left)
		Test.Assert(Math.Abs(child.Bounds.X - 20) < 1);
	}

	[Test]
	public static void Linear_Vertical_MatchParent_FillsWidth()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let child = new ColorView();
		child.PreferredHeight = 50;
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(child.Bounds.Width - 400) < 1);
	}

	[Test]
	public static void Linear_Vertical_GoneChild_NoSpace_NoSpacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		layout.Spacing = 10;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredHeight = 40;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });

		let gone = new ColorView();
		gone.Visibility = .Gone;
		gone.PreferredHeight = 40;
		layout.AddView(gone, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });

		let b = new ColorView();
		b.PreferredHeight = 40;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });

		ctx.UpdateRootView(root);

		// With gone child, only one spacing gap (between a and b): b.Y = 40 + 10 = 50
		Test.Assert(Math.Abs(b.Bounds.Y - 50) < 1);
	}

	[Test]
	public static void Linear_Vertical_ChildMargins()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredHeight = 30;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = 100, Height = 30, Margin = .(10, 5, 10, 5) });

		let b = new ColorView();
		b.PreferredHeight = 30;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = 100, Height = 30, Margin = .(10, 5, 10, 5) });

		ctx.UpdateRootView(root);

		// a: margin top=5, so y=5. x should be left margin = 10.
		Test.Assert(Math.Abs(a.Bounds.X - 10) < 1);
		Test.Assert(Math.Abs(a.Bounds.Y - 5) < 1);
		// b: y = a.marginTop + a.height + a.marginBottom + b.marginTop = 5 + 30 + 5 + 5 = 45
		Test.Assert(Math.Abs(b.Bounds.Y - 45) < 1);
	}

	[Test]
	public static void Linear_Vertical_MixedWeightedAndFixed()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		// Fixed: 50px
		let f = new ColorView();
		f.PreferredHeight = 50;
		layout.AddView(f, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		// Weighted: weight 1 -> gets (300-50) * 1/3 = ~83.33
		let w1 = new ColorView();
		layout.AddView(w1, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		// Weighted: weight 2 -> gets (300-50) * 2/3 = ~166.67
		let w2 = new ColorView();
		layout.AddView(w2, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 2 });

		ctx.UpdateRootView(root);

		let remaining = 300.0f - 50.0f;
		Test.Assert(Math.Abs(f.Bounds.Height - 50) < 1);
		Test.Assert(Math.Abs(w1.Bounds.Height - remaining * 1.0f / 3.0f) < 1);
		Test.Assert(Math.Abs(w2.Bounds.Height - remaining * 2.0f / 3.0f) < 1);
	}

	[Test]
	public static void Linear_Horizontal_CrossAxis_CenterV()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);

		let child = new ColorView();
		child.PreferredWidth = 60;
		child.PreferredHeight = 40;
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = 60, Height = 40, Gravity = .CenterV });

		ctx.UpdateRootView(root);

		// Centered vertically in 300px: (300 - 40) / 2 = 130
		Test.Assert(Math.Abs(child.Bounds.Y - 130) < 1);
	}

	[Test]
	public static void Linear_Horizontal_CrossAxis_Bottom()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);

		let child = new ColorView();
		child.PreferredWidth = 60;
		child.PreferredHeight = 40;
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = 60, Height = 40, Gravity = .Bottom });

		ctx.UpdateRootView(root);

		// Bottom-aligned in 300px: 300 - 40 = 260
		Test.Assert(Math.Abs(child.Bounds.Y - 260) < 1);
	}

	[Test]
	public static void Linear_Vertical_FillH_Gravity()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let child = new ColorView();
		child.PreferredWidth = 80;
		child.PreferredHeight = 50;
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = 80, Height = 50, Gravity = .FillH });

		ctx.UpdateRootView(root);

		// FillH should stretch width to the full content width.
		Test.Assert(Math.Abs(child.Bounds.Width - 400) < 1);
		Test.Assert(Math.Abs(child.Bounds.X - 0) < 1);
	}

	[Test]
	public static void Linear_Horizontal_FillV_Gravity()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);

		let child = new ColorView();
		child.PreferredWidth = 60;
		child.PreferredHeight = 30;
		layout.AddView(child, new LinearLayout.LayoutParams() { Width = 60, Height = 30, Gravity = .FillV });

		ctx.UpdateRootView(root);

		// FillV should stretch height to the full content height.
		Test.Assert(Math.Abs(child.Bounds.Height - 300) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 0) < 1);
	}

	[Test]
	public static void Linear_Vertical_Padding_And_Spacing_Combined()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		layout.Padding = .(10);
		layout.Spacing = 5;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredHeight = 30;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });

		let b = new ColorView();
		b.PreferredHeight = 30;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });

		ctx.UpdateRootView(root);

		// a starts at padding top: y=10
		Test.Assert(Math.Abs(a.Bounds.Y - 10) < 1);
		// b: y = 10 + 30 + 5 = 45
		Test.Assert(Math.Abs(b.Bounds.Y - 45) < 1);
		// Width = 400 - 10 - 10 = 380
		Test.Assert(Math.Abs(a.Bounds.Width - 380) < 1);
	}

	[Test]
	public static void Linear_Horizontal_WeightDistribution_ThreeWay()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(600, 200);

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);

		let a = new ColorView();
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		let b = new ColorView();
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 2 });

		let c = new ColorView();
		layout.AddView(c, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 3 });

		ctx.UpdateRootView(root);

		// Weights 1:2:3 in 600px -> 100, 200, 300
		Test.Assert(Math.Abs(a.Bounds.Width - 100) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 200) < 1);
		Test.Assert(Math.Abs(c.Bounds.Width - 300) < 1);
	}

	// =========================================================================
	// FrameLayout
	// =========================================================================

	[Test]
	public static void Frame_MultipleChildren_Overlap()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let a = new ColorView();
		a.PreferredWidth = 100;
		a.PreferredHeight = 80;
		frame.AddView(a, new FrameLayout.LayoutParams() { Width = 100, Height = 80 });

		let b = new ColorView();
		b.PreferredWidth = 120;
		b.PreferredHeight = 60;
		frame.AddView(b, new FrameLayout.LayoutParams() { Width = 120, Height = 60 });

		ctx.UpdateRootView(root);

		// Both default to top-left (Gravity.None), so they overlap at (0,0).
		Test.Assert(Math.Abs(a.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(a.Bounds.Y - 0) < 1);
		Test.Assert(Math.Abs(b.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(b.Bounds.Y - 0) < 1);
	}

	[Test]
	public static void Frame_Gravity_TopLeft()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 50;
		child.PreferredHeight = 50;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 50, Height = 50, Gravity = .Left | .Top });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(child.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 0) < 1);
	}

	[Test]
	public static void Frame_Gravity_CenterH_Top()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 100;
		child.PreferredHeight = 40;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 100, Height = 40, Gravity = .CenterH });

		ctx.UpdateRootView(root);

		// Centered horizontally: (400 - 100) / 2 = 150, top stays at 0.
		Test.Assert(Math.Abs(child.Bounds.X - 150) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 0) < 1);
	}

	[Test]
	public static void Frame_MatchParent_FillsFrame()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(child.Bounds.Width - 400) < 1);
		Test.Assert(Math.Abs(child.Bounds.Height - 300) < 1);
	}

	[Test]
	public static void Frame_Padding_OffsetsChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		frame.Padding = .(15, 10, 15, 10);
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 50;
		child.PreferredHeight = 30;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 50, Height = 30 });

		ctx.UpdateRootView(root);

		// Default gravity (None) -> top-left, offset by padding.
		Test.Assert(Math.Abs(child.Bounds.X - 15) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 10) < 1);
	}

	[Test]
	public static void Frame_Padding_CenterGravity()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		frame.Padding = .(20, 10, 20, 10);
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 60;
		child.PreferredHeight = 40;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 60, Height = 40, Gravity = .Center });

		ctx.UpdateRootView(root);

		// Content area: (400 - 40) x (300 - 20) = 360 x 280
		// Center in content: x = 20 + (360 - 60) / 2 = 20 + 150 = 170
		//                    y = 10 + (280 - 40) / 2 = 10 + 120 = 130
		Test.Assert(Math.Abs(child.Bounds.X - 170) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 130) < 1);
	}

	[Test]
	public static void Frame_Gravity_BottomLeft()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 70;
		child.PreferredHeight = 50;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 70, Height = 50, Gravity = .Left | .Bottom });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(child.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 250) < 1);
	}

	// =========================================================================
	// GridLayout
	// =========================================================================

	[Test]
	public static void Grid_2x2_EqualCells_Star()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Star(1));
		grid.ColumnDefs.Add(.Star(1));
		grid.RowDefs.Add(.Star(1));
		grid.RowDefs.Add(.Star(1));
		root.AddView(grid);

		let a = new ColorView(); // row 0, col 0
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView(); // row 0, col 1
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		let c = new ColorView(); // row 1, col 0
		grid.AddView(c, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

		let d = new ColorView(); // row 1, col 1
		grid.AddView(d, new GridLayout.LayoutParams() { Row = 1, Column = 1 });

		ctx.UpdateRootView(root);

		// Equal star 1:1 -> 200px wide, 150px tall each.
		Test.Assert(Math.Abs(a.Bounds.Width - 200) < 1);
		Test.Assert(Math.Abs(a.Bounds.Height - 150) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 200) < 1);
		Test.Assert(Math.Abs(d.Bounds.Width - 200) < 1);

		// Positions.
		Test.Assert(Math.Abs(a.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(b.Bounds.X - 200) < 1);
		Test.Assert(Math.Abs(c.Bounds.Y - 150) < 1);
		Test.Assert(Math.Abs(d.Bounds.X - 200) < 1);
		Test.Assert(Math.Abs(d.Bounds.Y - 150) < 1);
	}

	[Test]
	public static void Grid_StarProportional_2_1()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 100);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Star(2));
		grid.ColumnDefs.Add(.Star(1));
		grid.RowDefs.Add(.Star(1));
		root.AddView(grid);

		let a = new ColorView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView();
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		ctx.UpdateRootView(root);

		// Star 2:1 in 300px -> 200, 100.
		Test.Assert(Math.Abs(a.Bounds.Width - 200) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 100) < 1);
	}

	[Test]
	public static void Grid_HSpacing_VSpacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Star(1));
		grid.ColumnDefs.Add(.Star(1));
		grid.RowDefs.Add(.Star(1));
		grid.RowDefs.Add(.Star(1));
		grid.HSpacing = 10;
		grid.VSpacing = 20;
		root.AddView(grid);

		let a = new ColorView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView();
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		let c = new ColorView();
		grid.AddView(c, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

		let d = new ColorView();
		grid.AddView(d, new GridLayout.LayoutParams() { Row = 1, Column = 1 });

		ctx.UpdateRootView(root);

		// Available width: 400 - 10 (HSpacing) = 390, split 2 ways = 195 each.
		// Available height: 300 - 20 (VSpacing) = 280, split 2 ways = 140 each.
		Test.Assert(Math.Abs(a.Bounds.Width - 195) < 1);
		Test.Assert(Math.Abs(a.Bounds.Height - 140) < 1);

		// b is at x = 195 + 10 = 205
		Test.Assert(Math.Abs(b.Bounds.X - 205) < 1);
		// c is at y = 140 + 20 = 160
		Test.Assert(Math.Abs(c.Bounds.Y - 160) < 1);
	}

	[Test]
	public static void Grid_AutoTrack_SizesToContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Auto());
		grid.ColumnDefs.Add(.Star(1));
		grid.RowDefs.Add(.Auto());
		root.AddView(grid);

		let label = new ColorView();
		label.PreferredWidth = 80;
		label.PreferredHeight = 25;
		grid.AddView(label, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let content = new ColorView();
		grid.AddView(content, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		ctx.UpdateRootView(root);

		// Auto column 0 sizes to its content: 80px.
		Test.Assert(Math.Abs(label.Bounds.Width - 80) < 1);
		// Star column 1 gets the remainder: 400 - 80 = 320.
		Test.Assert(Math.Abs(content.Bounds.Width - 320) < 1);
		// Content starts at x=80.
		Test.Assert(Math.Abs(content.Bounds.X - 80) < 1);
	}

	[Test]
	public static void Grid_MixedPixelAndStar()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(500, 200);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Pixel(100));
		grid.ColumnDefs.Add(.Star(1));
		grid.ColumnDefs.Add(.Pixel(50));
		grid.RowDefs.Add(.Star(1));
		root.AddView(grid);

		let a = new ColorView();
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView();
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		let c = new ColorView();
		grid.AddView(c, new GridLayout.LayoutParams() { Row = 0, Column = 2 });

		ctx.UpdateRootView(root);

		// Pixel 100, Star(remaining), Pixel 50.
		// Star gets: 500 - 100 - 50 = 350.
		Test.Assert(Math.Abs(a.Bounds.Width - 100) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 350) < 1);
		Test.Assert(Math.Abs(c.Bounds.Width - 50) < 1);

		// Positions: a at 0, b at 100, c at 450.
		Test.Assert(Math.Abs(a.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(b.Bounds.X - 100) < 1);
		Test.Assert(Math.Abs(c.Bounds.X - 450) < 1);
	}

	[Test]
	public static void Grid_PixelRows_And_StarRows()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Star(1));
		grid.RowDefs.Add(.Pixel(40));
		grid.RowDefs.Add(.Star(1));
		grid.RowDefs.Add(.Pixel(30));
		root.AddView(grid);

		let header = new ColorView();
		grid.AddView(header, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let body = new ColorView();
		grid.AddView(body, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

		let footer = new ColorView();
		grid.AddView(footer, new GridLayout.LayoutParams() { Row = 2, Column = 0 });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(header.Bounds.Height - 40) < 1);
		Test.Assert(Math.Abs(footer.Bounds.Height - 30) < 1);
		// Body gets: 300 - 40 - 30 = 230.
		Test.Assert(Math.Abs(body.Bounds.Height - 230) < 1);
	}

	[Test]
	public static void Grid_AutoTrack_MultipleChildren_MaxSize()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Auto());
		grid.RowDefs.Add(.Auto());
		grid.RowDefs.Add(.Auto());
		root.AddView(grid);

		let a = new ColorView();
		a.PreferredWidth = 60;
		a.PreferredHeight = 20;
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView();
		b.PreferredWidth = 90;
		b.PreferredHeight = 35;
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

		ctx.UpdateRootView(root);

		// Auto column: max width = max(60, 90) = 90.
		Test.Assert(Math.Abs(a.Bounds.Width - 90) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - 90) < 1);
		// Auto rows: sized to each child.
		Test.Assert(Math.Abs(a.Bounds.Height - 20) < 1);
		Test.Assert(Math.Abs(b.Bounds.Height - 35) < 1);
	}

	[Test]
	public static void Grid_Spacing_WithAutoTracks()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let grid = new GridLayout();
		grid.ColumnDefs.Add(.Auto());
		grid.ColumnDefs.Add(.Auto());
		grid.RowDefs.Add(.Auto());
		grid.HSpacing = 10;
		root.AddView(grid);

		let a = new ColorView();
		a.PreferredWidth = 50;
		a.PreferredHeight = 30;
		grid.AddView(a, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		let b = new ColorView();
		b.PreferredWidth = 70;
		b.PreferredHeight = 30;
		grid.AddView(b, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		ctx.UpdateRootView(root);

		// b starts at: col0_width + HSpacing = 50 + 10 = 60.
		Test.Assert(Math.Abs(b.Bounds.X - 60) < 1);
	}

	// =========================================================================
	// FlowLayout
	// =========================================================================

	[Test]
	public static void Flow_Horizontal_SingleRow_AllFit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		root.AddView(flow);

		// 3 children x 80px = 240px < 400px -> all fit in one row.
		for (int i = 0; i < 3; i++)
		{
			let child = new ColorView();
			child.PreferredWidth = 80;
			child.PreferredHeight = 30;
			flow.AddView(child);
		}

		ctx.UpdateRootView(root);

		let c0 = flow.GetChildAt(0);
		let c1 = flow.GetChildAt(1);
		let c2 = flow.GetChildAt(2);

		// All on same row.
		Test.Assert(c0.Bounds.Y == c1.Bounds.Y);
		Test.Assert(c1.Bounds.Y == c2.Bounds.Y);
	}

	[Test]
	public static void Flow_Horizontal_Spacing_BetweenItems()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		flow.HSpacing = 10;
		root.AddView(flow);

		let a = new ColorView();
		a.PreferredWidth = 50;
		a.PreferredHeight = 30;
		flow.AddView(a);

		let b = new ColorView();
		b.PreferredWidth = 60;
		b.PreferredHeight = 30;
		flow.AddView(b);

		ctx.UpdateRootView(root);

		// b starts at 50 + 10 = 60.
		Test.Assert(Math.Abs(b.Bounds.X - 60) < 1);
	}

	[Test]
	public static void Flow_Horizontal_WrapsAtBoundary()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		root.AddView(flow);

		// 4 children x 60px = 240px > 200px. First 3 fit (180px), 4th wraps.
		for (int i = 0; i < 4; i++)
		{
			let child = new ColorView();
			child.PreferredWidth = 60;
			child.PreferredHeight = 25;
			flow.AddView(child);
		}

		ctx.UpdateRootView(root);

		let c0 = flow.GetChildAt(0);
		let c1 = flow.GetChildAt(1);
		let c2 = flow.GetChildAt(2);
		let c3 = flow.GetChildAt(3);

		// First 3 on row 1.
		Test.Assert(c0.Bounds.Y == c1.Bounds.Y);
		Test.Assert(c1.Bounds.Y == c2.Bounds.Y);
		// 4th wraps to row 2.
		Test.Assert(c3.Bounds.Y > c0.Bounds.Y);
		Test.Assert(Math.Abs(c3.Bounds.X - 0) < 1);
	}

	[Test]
	public static void Flow_Horizontal_VSpacing_BetweenRows()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(100, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		flow.VSpacing = 8;
		root.AddView(flow);

		// Each child is 60px wide; viewport is 100px -> 1 per row.
		let a = new ColorView();
		a.PreferredWidth = 60;
		a.PreferredHeight = 20;
		flow.AddView(a);

		let b = new ColorView();
		b.PreferredWidth = 60;
		b.PreferredHeight = 20;
		flow.AddView(b);

		ctx.UpdateRootView(root);

		// b should be at y = 20 + 8 = 28.
		Test.Assert(Math.Abs(b.Bounds.Y - 28) < 1);
	}

	[Test]
	public static void Flow_Horizontal_LargeItemForcesWrap()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		flow.HSpacing = 5;
		root.AddView(flow);

		let small = new ColorView();
		small.PreferredWidth = 50;
		small.PreferredHeight = 20;
		flow.AddView(small);

		// This item alone doesn't fit alongside the first one (50+5+160=215 > 200).
		let large = new ColorView();
		large.PreferredWidth = 160;
		large.PreferredHeight = 30;
		flow.AddView(large);

		ctx.UpdateRootView(root);

		// Large item wraps to row 2.
		Test.Assert(large.Bounds.Y > small.Bounds.Y);
		Test.Assert(Math.Abs(large.Bounds.X - 0) < 1);
	}

	[Test]
	public static void Flow_Vertical_Wrapping()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 100);

		let flow = new FlowLayout();
		flow.Orientation = .Vertical;
		root.AddView(flow);

		// 3 children x 40px tall = 120px > 100px. 2 fit (80px), 3rd wraps to next column.
		for (int i = 0; i < 3; i++)
		{
			let child = new ColorView();
			child.PreferredWidth = 30;
			child.PreferredHeight = 40;
			flow.AddView(child);
		}

		ctx.UpdateRootView(root);

		let c0 = flow.GetChildAt(0);
		let c1 = flow.GetChildAt(1);
		let c2 = flow.GetChildAt(2);

		// First 2 in column 1.
		Test.Assert(c0.Bounds.X == c1.Bounds.X);
		// 3rd wraps to column 2.
		Test.Assert(c2.Bounds.X > c0.Bounds.X);
		Test.Assert(Math.Abs(c2.Bounds.Y - 0) < 1);
	}

	[Test]
	public static void Flow_Vertical_Spacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Vertical;
		flow.VSpacing = 6;
		flow.HSpacing = 10;
		root.AddView(flow);

		let a = new ColorView();
		a.PreferredWidth = 40;
		a.PreferredHeight = 50;
		flow.AddView(a);

		let b = new ColorView();
		b.PreferredWidth = 40;
		b.PreferredHeight = 50;
		flow.AddView(b);

		ctx.UpdateRootView(root);

		// Both fit in column (50+6+50=106 < 300), b at y = 50 + 6 = 56.
		Test.Assert(Math.Abs(b.Bounds.Y - 56) < 1);
		Test.Assert(b.Bounds.X == a.Bounds.X);
	}

	[Test]
	public static void Flow_Horizontal_GoneChildren_Skipped()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		root.AddView(flow);

		let a = new ColorView();
		a.PreferredWidth = 60;
		a.PreferredHeight = 25;
		flow.AddView(a);

		let gone = new ColorView();
		gone.Visibility = .Gone;
		gone.PreferredWidth = 200;
		gone.PreferredHeight = 100;
		flow.AddView(gone);

		let b = new ColorView();
		b.PreferredWidth = 60;
		b.PreferredHeight = 25;
		flow.AddView(b);

		ctx.UpdateRootView(root);

		// Gone child is skipped, b should be right next to a on same row.
		Test.Assert(a.Bounds.Y == b.Bounds.Y);
		Test.Assert(Math.Abs(b.Bounds.X - 60) < 1);
	}

	[Test]
	public static void Flow_Horizontal_HSpacing_And_VSpacing_Combined()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(150, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		flow.HSpacing = 10;
		flow.VSpacing = 5;
		root.AddView(flow);

		// Each 60px wide. Row capacity: 60 + 10 + 60 = 130 < 150 -> 2 per row.
		for (int i = 0; i < 4; i++)
		{
			let child = new ColorView();
			child.PreferredWidth = 60;
			child.PreferredHeight = 20;
			flow.AddView(child);
		}

		ctx.UpdateRootView(root);

		let c1 = flow.GetChildAt(1);
		let c2 = flow.GetChildAt(2);
		let c3 = flow.GetChildAt(3);

		// Row 1: c0 at x=0, c1 at x=70.
		Test.Assert(Math.Abs(c1.Bounds.X - 70) < 1);
		// Row 2: c2 at x=0, c3 at x=70, y = 20 + 5 = 25.
		Test.Assert(Math.Abs(c2.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(c2.Bounds.Y - 25) < 1);
		Test.Assert(Math.Abs(c3.Bounds.X - 70) < 1);
	}

	[Test]
	public static void Flow_Vertical_HSpacing_BetweenColumns()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 60);

		let flow = new FlowLayout();
		flow.Orientation = .Vertical;
		flow.HSpacing = 12;
		root.AddView(flow);

		// Each child 40px tall. Viewport 60px -> 1 per column.
		let a = new ColorView();
		a.PreferredWidth = 30;
		a.PreferredHeight = 40;
		flow.AddView(a);

		let b = new ColorView();
		b.PreferredWidth = 30;
		b.PreferredHeight = 40;
		flow.AddView(b);

		ctx.UpdateRootView(root);

		// First column fits 1 item (40 < 60), second item doesn't fit (40+0+40=80 > 60).
		// Wait, 40+40=80 > 60, so b wraps. b at x = 30 + 12 = 42.
		// Actually check: firstInCol is true for a, then for b: !firstInCol && 0+0+40>60 is false since 40 <= 60.
		// After a: colH = 40. For b: !firstInCol(false after a) && 40+0+40=80 > 60 -> wraps!
		Test.Assert(b.Bounds.X > a.Bounds.X);
		Test.Assert(Math.Abs(b.Bounds.X - 42) < 1);
	}

	// =========================================================================
	// AbsoluteLayout
	// =========================================================================

	[Test]
	public static void Absolute_ChildAtExplicitPosition()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let abs = new AbsoluteLayout();
		root.AddView(abs);

		let child = new ColorView();
		child.PreferredWidth = 50;
		child.PreferredHeight = 30;
		abs.AddView(child, new AbsoluteLayout.LayoutParams() { X = 100, Y = 75 });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(child.Bounds.X - 100) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 75) < 1);
		Test.Assert(Math.Abs(child.Bounds.Width - 50) < 1);
		Test.Assert(Math.Abs(child.Bounds.Height - 30) < 1);
	}

	[Test]
	public static void Absolute_MultipleChildrenDifferentPositions()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let abs = new AbsoluteLayout();
		root.AddView(abs);

		let a = new ColorView();
		a.PreferredWidth = 40;
		a.PreferredHeight = 40;
		abs.AddView(a, new AbsoluteLayout.LayoutParams() { X = 10, Y = 20 });

		let b = new ColorView();
		b.PreferredWidth = 60;
		b.PreferredHeight = 50;
		abs.AddView(b, new AbsoluteLayout.LayoutParams() { X = 200, Y = 100 });

		let c = new ColorView();
		c.PreferredWidth = 30;
		c.PreferredHeight = 30;
		abs.AddView(c, new AbsoluteLayout.LayoutParams() { X = 350, Y = 250 });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(a.Bounds.X - 10) < 1);
		Test.Assert(Math.Abs(a.Bounds.Y - 20) < 1);
		Test.Assert(Math.Abs(b.Bounds.X - 200) < 1);
		Test.Assert(Math.Abs(b.Bounds.Y - 100) < 1);
		Test.Assert(Math.Abs(c.Bounds.X - 350) < 1);
		Test.Assert(Math.Abs(c.Bounds.Y - 250) < 1);
	}

	[Test]
	public static void Absolute_ChildrenCanOverlap()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let abs = new AbsoluteLayout();
		root.AddView(abs);

		let a = new ColorView();
		a.PreferredWidth = 100;
		a.PreferredHeight = 100;
		abs.AddView(a, new AbsoluteLayout.LayoutParams() { X = 50, Y = 50 });

		let b = new ColorView();
		b.PreferredWidth = 80;
		b.PreferredHeight = 80;
		abs.AddView(b, new AbsoluteLayout.LayoutParams() { X = 70, Y = 70 });

		ctx.UpdateRootView(root);

		// Both placed at overlapping positions; layout should succeed.
		Test.Assert(Math.Abs(a.Bounds.X - 50) < 1);
		Test.Assert(Math.Abs(a.Bounds.Y - 50) < 1);
		Test.Assert(Math.Abs(b.Bounds.X - 70) < 1);
		Test.Assert(Math.Abs(b.Bounds.Y - 70) < 1);
		// Their rectangles overlap in the region (70..150) x (70..150).
		Test.Assert(a.Bounds.X + a.Bounds.Width > b.Bounds.X);
		Test.Assert(a.Bounds.Y + a.Bounds.Height > b.Bounds.Y);
	}

	[Test]
	public static void Absolute_DefaultPosition_IsOrigin()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let abs = new AbsoluteLayout();
		root.AddView(abs);

		// No explicit LayoutParams -> default X=0, Y=0.
		let child = new ColorView();
		child.PreferredWidth = 30;
		child.PreferredHeight = 20;
		abs.AddView(child);

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(child.Bounds.X - 0) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 0) < 1);
	}

	[Test]
	public static void Absolute_Padding_OffsetsChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let abs = new AbsoluteLayout();
		abs.Padding = .(15, 10, 15, 10);
		root.AddView(abs);

		let child = new ColorView();
		child.PreferredWidth = 40;
		child.PreferredHeight = 30;
		abs.AddView(child, new AbsoluteLayout.LayoutParams() { X = 20, Y = 25 });

		ctx.UpdateRootView(root);

		// Position = Padding + X/Y: x = 15 + 20 = 35, y = 10 + 25 = 35.
		Test.Assert(Math.Abs(child.Bounds.X - 35) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - 35) < 1);
	}

	// =========================================================================
	// GravityHelper.Apply
	// =========================================================================

	[Test]
	public static void Gravity_None_DefaultsTopLeft()
	{
		let result = GravityHelper.Apply(.None, 400, 300, 100, 50, Thickness());
		Test.Assert(Math.Abs(result.X - 0) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 0) < 0.01f);
		Test.Assert(Math.Abs(result.Width - 100) < 0.01f);
		Test.Assert(Math.Abs(result.Height - 50) < 0.01f);
	}

	[Test]
	public static void Gravity_Left_Top()
	{
		let result = GravityHelper.Apply(.Left | .Top, 400, 300, 100, 50, Thickness());
		Test.Assert(Math.Abs(result.X - 0) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 0) < 0.01f);
		Test.Assert(Math.Abs(result.Width - 100) < 0.01f);
		Test.Assert(Math.Abs(result.Height - 50) < 0.01f);
	}

	[Test]
	public static void Gravity_Right_Top()
	{
		let result = GravityHelper.Apply(.Right | .Top, 400, 300, 100, 50, Thickness());
		// x = 400 - 0 - 100 = 300
		Test.Assert(Math.Abs(result.X - 300) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 0) < 0.01f);
	}

	[Test]
	public static void Gravity_Left_Bottom()
	{
		let result = GravityHelper.Apply(.Left | .Bottom, 400, 300, 100, 50, Thickness());
		Test.Assert(Math.Abs(result.X - 0) < 0.01f);
		// y = 300 - 0 - 50 = 250
		Test.Assert(Math.Abs(result.Y - 250) < 0.01f);
	}

	[Test]
	public static void Gravity_Right_Bottom()
	{
		let result = GravityHelper.Apply(.Right | .Bottom, 400, 300, 80, 60, Thickness());
		// x = 400 - 80 = 320, y = 300 - 60 = 240
		Test.Assert(Math.Abs(result.X - 320) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 240) < 0.01f);
	}

	[Test]
	public static void Gravity_CenterH_Only()
	{
		let result = GravityHelper.Apply(.CenterH, 400, 300, 100, 50, Thickness());
		// x = (400 - 100) / 2 = 150
		Test.Assert(Math.Abs(result.X - 150) < 0.01f);
		// y defaults to 0 (top)
		Test.Assert(Math.Abs(result.Y - 0) < 0.01f);
	}

	[Test]
	public static void Gravity_CenterV_Only()
	{
		let result = GravityHelper.Apply(.CenterV, 400, 300, 100, 50, Thickness());
		// x defaults to 0 (left)
		Test.Assert(Math.Abs(result.X - 0) < 0.01f);
		// y = (300 - 50) / 2 = 125
		Test.Assert(Math.Abs(result.Y - 125) < 0.01f);
	}

	[Test]
	public static void Gravity_Center_Both()
	{
		let result = GravityHelper.Apply(.Center, 400, 300, 120, 80, Thickness());
		// x = (400 - 120) / 2 = 140
		// y = (300 - 80) / 2 = 110
		Test.Assert(Math.Abs(result.X - 140) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 110) < 0.01f);
	}

	[Test]
	public static void Gravity_FillH_Only()
	{
		let result = GravityHelper.Apply(.FillH, 400, 300, 100, 50, Thickness());
		Test.Assert(Math.Abs(result.X - 0) < 0.01f);
		// Width expands to container.
		Test.Assert(Math.Abs(result.Width - 400) < 0.01f);
		// Height stays at child size.
		Test.Assert(Math.Abs(result.Height - 50) < 0.01f);
	}

	[Test]
	public static void Gravity_FillV_Only()
	{
		let result = GravityHelper.Apply(.FillV, 400, 300, 100, 50, Thickness());
		Test.Assert(Math.Abs(result.Y - 0) < 0.01f);
		// Height expands to container.
		Test.Assert(Math.Abs(result.Height - 300) < 0.01f);
		// Width stays at child size.
		Test.Assert(Math.Abs(result.Width - 100) < 0.01f);
	}

	[Test]
	public static void Gravity_Fill_Both()
	{
		let result = GravityHelper.Apply(.Fill, 400, 300, 50, 30, Thickness());
		Test.Assert(Math.Abs(result.X - 0) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 0) < 0.01f);
		Test.Assert(Math.Abs(result.Width - 400) < 0.01f);
		Test.Assert(Math.Abs(result.Height - 300) < 0.01f);
	}

	[Test]
	public static void Gravity_WithMargin_CenterH()
	{
		let margin = Thickness(10, 0, 20, 0); // left=10, right=20
		let result = GravityHelper.Apply(.CenterH, 400, 300, 100, 50, margin);
		// Available width = 400 - 10 - 20 = 370
		// x = 10 + (370 - 100) / 2 = 10 + 135 = 145
		Test.Assert(Math.Abs(result.X - 145) < 0.01f);
	}

	[Test]
	public static void Gravity_WithMargin_Right()
	{
		let margin = Thickness(0, 0, 15, 0); // right=15
		let result = GravityHelper.Apply(.Right, 400, 300, 100, 50, margin);
		// x = 400 - 15 - 100 = 285
		Test.Assert(Math.Abs(result.X - 285) < 0.01f);
	}

	[Test]
	public static void Gravity_WithMargin_Bottom()
	{
		let margin = Thickness(0, 0, 0, 25); // bottom=25
		let result = GravityHelper.Apply(.Bottom, 400, 300, 100, 50, margin);
		// y = 300 - 25 - 50 = 225
		Test.Assert(Math.Abs(result.Y - 225) < 0.01f);
	}

	[Test]
	public static void Gravity_WithMargin_Fill()
	{
		let margin = Thickness(10, 20, 30, 40);
		let result = GravityHelper.Apply(.Fill, 400, 300, 50, 30, margin);
		// FillH: x=10, w = 400 - 10 - 30 = 360
		// FillV: y=20, h = 300 - 20 - 40 = 240
		Test.Assert(Math.Abs(result.X - 10) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 20) < 0.01f);
		Test.Assert(Math.Abs(result.Width - 360) < 0.01f);
		Test.Assert(Math.Abs(result.Height - 240) < 0.01f);
	}
}
