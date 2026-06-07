namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class FlowLayoutTests
{
	[Test]
	public static void Horizontal_NoWrap_SingleLine()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Horizontal };
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.Y - b.Bounds.Y) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X - 50) < 0.01f);
	}

	[Test]
	public static void Horizontal_Wraps_WhenExceedsWidth()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Horizontal };
		let a = new TestView(150, 30);
		let b = new TestView(150, 30);
		let c = new TestView(150, 30);
		flow.AddView(a);
		flow.AddView(b);
		flow.AddView(c);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.Y - b.Bounds.Y) < 0.01f);
		Test.Assert(c.Bounds.Y > a.Bounds.Y);
	}

	[Test]
	public static void Horizontal_Spacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Horizontal, HSpacing = 10, VSpacing = 5 };
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(b.Bounds.X - 60) < 0.01f);
	}

	[Test]
	public static void Horizontal_VSpacing_BetweenLines()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Horizontal, VSpacing = 8 };
		let a = new TestView(250, 30);
		let b = new TestView(250, 40);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(b.Bounds.Y - 38) < 0.01f);
	}

	[Test]
	public static void Vertical_NoWrap_SingleColumn()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Vertical };
		let a = new TestView(50, 30);
		let b = new TestView(50, 40);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - b.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.Y - 30) < 0.01f);
	}

	[Test]
	public static void Vertical_Wraps_WhenExceedsHeight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Vertical };
		let a = new TestView(50, 150);
		let b = new TestView(50, 150);
		let c = new TestView(50, 150);
		flow.AddView(a);
		flow.AddView(b);
		flow.AddView(c);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - b.Bounds.X) < 0.01f);
		Test.Assert(c.Bounds.X > a.Bounds.X);
	}

	[Test]
	public static void Gone_ChildSkipped()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Horizontal };
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		b.Visibility = .Gone;
		let c = new TestView(70, 30);
		flow.AddView(a);
		flow.AddView(b);
		flow.AddView(c);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(c.Bounds.X - 50) < 0.01f);
	}

	[Test]
	public static void Padding_OffsetsContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout() { Orientation = .Horizontal };
		flow.Padding = .(10, 20, 10, 20);
		let a = new TestView(50, 30);
		flow.AddView(a);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - 10) < 0.01f);
		Test.Assert(Math.Abs(a.Bounds.Y - 20) < 0.01f);
	}
}
