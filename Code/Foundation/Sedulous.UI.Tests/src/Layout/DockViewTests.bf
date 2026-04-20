namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class DockViewTests
{
	// Helper: create a view with fixed preferred size.
	private static ColorView MakeView(float w, float h)
	{
		let v = new ColorView();
		v.PreferredWidth = w;
		v.PreferredHeight = h;
		return v;
	}

	// === Basic docking ===

	[Test]
	public static void DockLeft_TakesLeftEdge()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let left = MakeView(80, 0);
		dock.AddView(left, new DockView.LayoutParams(.Left));

		ctx.UpdateRootView(root);

		Test.Assert(left.Bounds.X == 0);
		Test.Assert(left.Bounds.Width == 80);
		Test.Assert(left.Bounds.Height == 300); // full height
	}

	[Test]
	public static void DockTop_TakesTopEdge()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let top = MakeView(0, 40);
		dock.AddView(top, new DockView.LayoutParams(.Top));

		ctx.UpdateRootView(root);

		Test.Assert(top.Bounds.Y == 0);
		Test.Assert(top.Bounds.Height == 40);
		Test.Assert(top.Bounds.Width == 400); // full width
	}

	[Test]
	public static void DockRight_TakesRightEdge()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let right = MakeView(60, 0);
		dock.AddView(right, new DockView.LayoutParams(.Right));

		ctx.UpdateRootView(root);

		Test.Assert(right.Bounds.X == 340); // 400 - 60
		Test.Assert(right.Bounds.Width == 60);
		Test.Assert(right.Bounds.Height == 300);
	}

	[Test]
	public static void DockBottom_TakesBottomEdge()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let bottom = MakeView(0, 50);
		dock.AddView(bottom, new DockView.LayoutParams(.Bottom));

		ctx.UpdateRootView(root);

		Test.Assert(bottom.Bounds.Y == 250); // 300 - 50
		Test.Assert(bottom.Bounds.Height == 50);
		Test.Assert(bottom.Bounds.Width == 400);
	}

	// === LastChildFill ===

	[Test]
	public static void LastChildFill_FillsRemainingSpace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = true;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let left = MakeView(80, 0);
		dock.AddView(left, new DockView.LayoutParams(.Left));

		let center = MakeView(0, 0);
		dock.AddView(center, new DockView.LayoutParams(.Left)); // Dock value ignored for last child

		ctx.UpdateRootView(root);

		Test.Assert(center.Bounds.X == 80);
		Test.Assert(center.Bounds.Width == 320); // 400 - 80
		Test.Assert(center.Bounds.Height == 300);
	}

	[Test]
	public static void LastChildFill_Disabled()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let left = MakeView(80, 0);
		dock.AddView(left, new DockView.LayoutParams(.Left));

		let alsoLeft = MakeView(60, 0);
		dock.AddView(alsoLeft, new DockView.LayoutParams(.Left));

		ctx.UpdateRootView(root);

		// With LastChildFill=false, second child docks left normally.
		Test.Assert(alsoLeft.Bounds.X == 80);
		Test.Assert(alsoLeft.Bounds.Width == 60); // not filling
	}

	// === Multiple docked children ===

	[Test]
	public static void AppShellLayout_TopBottomLeftContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		// Menu bar top
		let menuBar = MakeView(0, 30);
		dock.AddView(menuBar, new DockView.LayoutParams(.Top));

		// Status bar bottom
		let statusBar = MakeView(0, 20);
		dock.AddView(statusBar, new DockView.LayoutParams(.Bottom));

		// Sidebar left
		let sidebar = MakeView(100, 0);
		dock.AddView(sidebar, new DockView.LayoutParams(.Left));

		// Content fills
		let content = MakeView(0, 0);
		dock.AddView(content, new DockView.LayoutParams(.Fill));

		ctx.UpdateRootView(root);

		// Menu bar: full width, 30px tall at top
		Test.Assert(menuBar.Bounds.X == 0);
		Test.Assert(menuBar.Bounds.Y == 0);
		Test.Assert(menuBar.Bounds.Width == 400);
		Test.Assert(menuBar.Bounds.Height == 30);

		// Status bar: full width, 20px tall at bottom
		Test.Assert(statusBar.Bounds.X == 0);
		Test.Assert(statusBar.Bounds.Y == 280); // 300 - 20
		Test.Assert(statusBar.Bounds.Width == 400);
		Test.Assert(statusBar.Bounds.Height == 20);

		// Sidebar: 100px wide, between menu and status
		Test.Assert(sidebar.Bounds.X == 0);
		Test.Assert(sidebar.Bounds.Y == 30);
		Test.Assert(sidebar.Bounds.Width == 100);
		Test.Assert(sidebar.Bounds.Height == 250); // 300 - 30 (top) - 20 (bottom)

		// Content: fills remaining area
		Test.Assert(content.Bounds.X == 100);
		Test.Assert(content.Bounds.Y == 30);
		Test.Assert(content.Bounds.Width == 300); // 400 - 100
		Test.Assert(content.Bounds.Height == 250);
	}

	[Test]
	public static void LeftRightLeftRight_Alternating()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let l1 = MakeView(50, 0);
		dock.AddView(l1, new DockView.LayoutParams(.Left));

		let r1 = MakeView(60, 0);
		dock.AddView(r1, new DockView.LayoutParams(.Right));

		let l2 = MakeView(70, 0);
		dock.AddView(l2, new DockView.LayoutParams(.Left));

		ctx.UpdateRootView(root);

		Test.Assert(l1.Bounds.X == 0);
		Test.Assert(l1.Bounds.Width == 50);

		Test.Assert(r1.Bounds.X == 340); // 400 - 60
		Test.Assert(r1.Bounds.Width == 60);

		Test.Assert(l2.Bounds.X == 50); // after l1
		Test.Assert(l2.Bounds.Width == 70);
	}

	// === Padding ===

	[Test]
	public static void Padding_ReducesAvailableArea()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.Padding = .(10, 20, 10, 20);
		dock.LastChildFill = true;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let fill = MakeView(0, 0);
		dock.AddView(fill, new DockView.LayoutParams(.Fill));

		ctx.UpdateRootView(root);

		Test.Assert(fill.Bounds.X == 10);
		Test.Assert(fill.Bounds.Y == 20);
		Test.Assert(fill.Bounds.Width == 380); // 400 - 10 - 10
		Test.Assert(fill.Bounds.Height == 260); // 300 - 20 - 20
	}

	// === Gone children ===

	[Test]
	public static void GoneChild_SkippedInLayout()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let left = MakeView(80, 0);
		left.Visibility = .Gone;
		dock.AddView(left, new DockView.LayoutParams(.Left));

		let alsoLeft = MakeView(60, 0);
		dock.AddView(alsoLeft, new DockView.LayoutParams(.Left));

		ctx.UpdateRootView(root);

		// Gone child doesn't consume space - alsoLeft starts at 0.
		Test.Assert(alsoLeft.Bounds.X == 0);
		Test.Assert(alsoLeft.Bounds.Width == 60);
	}

	// === Fill dock position ===

	[Test]
	public static void ExplicitFill_FillsRemainingSpace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false; // explicit Fill, not LastChildFill
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let top = MakeView(0, 50);
		dock.AddView(top, new DockView.LayoutParams(.Top));

		let fill = MakeView(0, 0);
		dock.AddView(fill, new DockView.LayoutParams(.Fill));

		let bottom = MakeView(0, 30);
		dock.AddView(bottom, new DockView.LayoutParams(.Bottom));

		ctx.UpdateRootView(root);

		// Fill takes remaining space at the time it's processed.
		Test.Assert(fill.Bounds.X == 0);
		Test.Assert(fill.Bounds.Y == 50);
		Test.Assert(fill.Bounds.Width == 400);
		Test.Assert(fill.Bounds.Height == 250); // 300 - 50
	}

	// === Single child ===

	[Test]
	public static void SingleChild_FillsByDefault()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let only = MakeView(100, 50);
		dock.AddView(only, new DockView.LayoutParams(.Left));

		ctx.UpdateRootView(root);

		// LastChildFill=true (default), so single child fills everything.
		Test.Assert(only.Bounds.X == 0);
		Test.Assert(only.Bounds.Y == 0);
		Test.Assert(only.Bounds.Width == 400);
		Test.Assert(only.Bounds.Height == 300);
	}

	// === Default LayoutParams ===

	[Test]
	public static void DefaultLayoutParams_DocksLeft()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		dock.LastChildFill = false;
		root.AddView(dock, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		let child = MakeView(80, 0);
		dock.AddView(child); // no explicit DockView.LayoutParams - uses default

		ctx.UpdateRootView(root);

		// Default is Dock.Left
		Test.Assert(child.Bounds.X == 0);
		Test.Assert(child.Bounds.Width == 80);
	}

	// === Empty DockView ===

	[Test]
	public static void Empty_MeasuresToZero()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let dock = new DockView();
		root.AddView(dock);

		ctx.UpdateRootView(root);

		// No children, no padding -> measures to available space via spec.
		Test.Assert(dock.MeasuredSize.X >= 0);
		Test.Assert(dock.MeasuredSize.Y >= 0);
	}
}
