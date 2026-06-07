namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class FrameLayoutTests
{
	[Test]
	public static void Children_StackOnTopOfEachOther()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		let a = new TestView(100, 50);
		let b = new TestView(80, 40);
		frame.AddView(a);
		frame.AddView(b);
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		// Both at top-left by default
		Test.Assert(Math.Abs(a.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(a.Bounds.Y) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.Y) < 0.01f);
	}

	[Test]
	public static void Gravity_Center()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(100, 50);
		frame.AddView(child, new FrameLayout.LayoutParams() { Gravity = .Center });
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 150) < 1.0f);
		Test.Assert(Math.Abs(child.Bounds.Y - 125) < 1.0f);
	}

	[Test]
	public static void Gravity_BottomRight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(100, 50);
		frame.AddView(child, new FrameLayout.LayoutParams() { Gravity = .BottomRight });
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 300) < 1.0f);
		Test.Assert(Math.Abs(child.Bounds.Y - 250) < 1.0f);
	}

	[Test]
	public static void Gravity_Fill()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(100, 50);
		frame.AddView(child, new FrameLayout.LayoutParams() { Gravity = .Fill });
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Width - 400) < 1.0f);
		Test.Assert(Math.Abs(child.Height - 300) < 1.0f);
	}
}
