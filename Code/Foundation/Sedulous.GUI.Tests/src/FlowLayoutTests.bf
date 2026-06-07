namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class FlowLayoutTests
{
	[Test]
	public static void Horizontal_ChildrenFlowLeftToRight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation.Value = .Horizontal;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X - 50) < 0.01f);
		Test.Assert(Math.Abs(a.Bounds.Y - b.Bounds.Y) < 0.01f); // same row
	}

	[Test]
	public static void Horizontal_WrapsToNextLine()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 300);

		let flow = new FlowLayout();
		flow.Orientation.Value = .Horizontal;
		let a = new TestView(120, 30);
		let b = new TestView(120, 40);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		// b should wrap to next line
		Test.Assert(Math.Abs(b.Bounds.X) < 0.01f);
		Test.Assert(b.Bounds.Y >= 30); // below first line
	}

	[Test]
	public static void Horizontal_Spacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation.Value = .Horizontal;
		flow.HSpacing.Value = 10;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(b.Bounds.X - 60) < 0.01f); // 50 + 10
	}

	[Test]
	public static void Vertical_ChildrenFlowTopToBottom()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation.Value = .Vertical;
		let a = new TestView(50, 30);
		let b = new TestView(60, 40);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.Y) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.Y - 30) < 0.01f);
		Test.Assert(Math.Abs(a.Bounds.X - b.Bounds.X) < 0.01f); // same column
	}

	[Test]
	public static void Vertical_WrapsToNextColumn()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 100);

		let flow = new FlowLayout();
		flow.Orientation.Value = .Vertical;
		let a = new TestView(50, 60);
		let b = new TestView(60, 60);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		TestSetup.Layout(ctx, root);

		// b should wrap to next column
		Test.Assert(Math.Abs(b.Bounds.Y) < 0.01f);
		Test.Assert(b.Bounds.X >= 50);
	}
}
