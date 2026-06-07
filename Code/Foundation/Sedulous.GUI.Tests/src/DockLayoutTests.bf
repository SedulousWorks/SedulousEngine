namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class DockLayoutTests
{
	[Test]
	public static void Left_ClaimsLeftEdge()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let left = new TestView(100, 50);
		let rest = new TestView(50, 50);
		dock.AddView(left, new DockLayout.LayoutParams(.Left));
		dock.AddView(rest, new DockLayout.LayoutParams(.Left));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(left.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(left.Width - 100) < 1.0f);
		Test.Assert(Math.Abs(rest.Bounds.X - 100) < 1.0f);
	}

	[Test]
	public static void Top_ClaimsTopEdge()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let top = new TestView(50, 60);
		let rest = new TestView(50, 50);
		dock.AddView(top, new DockLayout.LayoutParams(.Top));
		dock.AddView(rest, new DockLayout.LayoutParams(.Top));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(top.Bounds.Y) < 0.01f);
		Test.Assert(Math.Abs(top.Height - 60) < 1.0f);
		Test.Assert(Math.Abs(rest.Bounds.Y - 60) < 1.0f);
	}

	[Test]
	public static void LastChildFill()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		dock.LastChildFill.Value = true;
		let top = new TestView(50, 60);
		let fill = new TestView(50, 50);
		dock.AddView(top, new DockLayout.LayoutParams(.Top));
		dock.AddView(fill);
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		// Fill child should take remaining space
		Test.Assert(Math.Abs(fill.Bounds.Y - 60) < 1.0f);
		Test.Assert(Math.Abs(fill.Width - 400) < 1.0f);
		Test.Assert(Math.Abs(fill.Height - 240) < 1.0f);
	}

	[Test]
	public static void AllFourEdges()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let dock = new DockLayout();
		let l = new TestView(50, 0);
		let t = new TestView(0, 40);
		let r = new TestView(60, 0);
		let b = new TestView(0, 30);
		dock.AddView(l, new DockLayout.LayoutParams(.Left));
		dock.AddView(t, new DockLayout.LayoutParams(.Top));
		dock.AddView(r, new DockLayout.LayoutParams(.Right));
		dock.AddView(b, new DockLayout.LayoutParams(.Bottom));
		root.AddView(dock);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(l.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(t.Bounds.X - 50) < 1.0f); // after left
		Test.Assert(Math.Abs(r.Bounds.X - (400 - 60)) < 1.0f); // right edge
		Test.Assert(Math.Abs(b.Bounds.Y - (300 - 30)) < 1.0f); // bottom edge
	}
}
