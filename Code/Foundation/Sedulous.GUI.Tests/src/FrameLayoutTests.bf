namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class FrameLayoutTests
{
	[Test]
	public static void Default_ChildAtTopLeft()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(50, 30);
		frame.AddView(child);
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y) < 0.01f);
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
		let child = new TestView(80, 40);
		frame.AddView(child, new FrameLayout.LayoutParams() { Gravity = .Bottom | .Right });
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 320) < 1.0f);
		Test.Assert(Math.Abs(child.Bounds.Y - 260) < 1.0f);
	}

	[Test]
	public static void Gravity_Fill()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(50, 30);
		frame.AddView(child, new FrameLayout.LayoutParams() { Gravity = .Fill });
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Width - 400) < 1.0f);
		Test.Assert(Math.Abs(child.Height - 300) < 1.0f);
	}

	[Test]
	public static void Padding_OffsetsGravity()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		frame.Padding = .(10, 20, 10, 20);
		let child = new TestView(50, 30);
		frame.AddView(child);
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 10) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y - 20) < 0.01f);
	}

	[Test]
	public static void MultipleChildren_Stacked()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let frame = new FrameLayout();
		let a = new TestView(100, 50);
		let b = new TestView(80, 40);
		frame.AddView(a, new FrameLayout.LayoutParams() { Gravity = .None });
		frame.AddView(b, new FrameLayout.LayoutParams() { Gravity = .Center });
		root.AddView(frame);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X - 160) < 1.0f);
	}
}
