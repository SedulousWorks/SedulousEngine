namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class DockLayoutTests
{
	[Test]
	public static void Top_TakesFullWidthMeasuredHeight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let top = new TestView(400, 50);
		dock.AddView(top, new DockLayout.LayoutParams(.Top));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(top.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(top.Bounds.Y) < 0.01f);
		Test.Assert(Math.Abs(top.Width - 400) < 1.0f);
		Test.Assert(Math.Abs(top.Height - 50) < 1.0f);
	}

	[Test]
	public static void Bottom_DocksToBottom()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let bottom = new TestView(400, 40);
		dock.AddView(bottom, new DockLayout.LayoutParams(.Bottom));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(bottom.Bounds.Y - 260) < 1.0f);
		Test.Assert(Math.Abs(bottom.Width - 400) < 1.0f);
	}

	[Test]
	public static void Left_TakesFullHeightMeasuredWidth()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let left = new TestView(80, 300);
		dock.AddView(left, new DockLayout.LayoutParams(.Left));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(left.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(left.Width - 80) < 1.0f);
		Test.Assert(Math.Abs(left.Height - 300) < 1.0f);
	}

	[Test]
	public static void Right_DocksToRight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let right = new TestView(60, 300);
		dock.AddView(right, new DockLayout.LayoutParams(.Right));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(right.Bounds.X - 340) < 1.0f);
		Test.Assert(Math.Abs(right.Width - 60) < 1.0f);
	}

	[Test]
	public static void Fill_TakesRemainingSpace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let top = new TestView(400, 50);
		let fill = new TestView();
		dock.AddView(top, new DockLayout.LayoutParams(.Top));
		dock.AddView(fill, new DockLayout.LayoutParams(.Fill));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(fill.Bounds.Y - 50) < 1.0f);
		Test.Assert(Math.Abs(fill.Width - 400) < 1.0f);
		Test.Assert(Math.Abs(fill.Height - 250) < 1.0f);
	}

	[Test]
	public static void LastChildFill_False_DoesNotFill()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout() { LastChildFill = false };
		let top = new TestView(400, 50);
		let last = new TestView(100, 40);
		dock.AddView(top, new DockLayout.LayoutParams(.Top));
		dock.AddView(last, new DockLayout.LayoutParams(.Left));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(last.Width - 100) < 1.0f);
	}

	[Test]
	public static void LastChildFill_True_FillsRemaining()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout() { LastChildFill = true };
		let top = new TestView(400, 50);
		let last = new TestView(100, 40);
		dock.AddView(top, new DockLayout.LayoutParams(.Top));
		dock.AddView(last, new DockLayout.LayoutParams(.Left));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(last.Width - 400) < 1.0f);
		Test.Assert(Math.Abs(last.Height - 250) < 1.0f);
	}

	[Test]
	public static void MultipleEdges_ShrinkRemaining()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let top = new TestView(400, 40);
		let left = new TestView(60, 260);
		let fill = new TestView();
		dock.AddView(top, new DockLayout.LayoutParams(.Top));
		dock.AddView(left, new DockLayout.LayoutParams(.Left));
		dock.AddView(fill, new DockLayout.LayoutParams(.Fill));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(fill.Bounds.X - 60) < 1.0f);
		Test.Assert(Math.Abs(fill.Bounds.Y - 40) < 1.0f);
		Test.Assert(Math.Abs(fill.Width - 340) < 1.0f);
		Test.Assert(Math.Abs(fill.Height - 260) < 1.0f);
	}
}
