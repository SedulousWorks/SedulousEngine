namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class AbsoluteLayoutTests
{
	[Test]
	public static void ChildAtExplicitPosition()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		let child = new TestView(50, 30);
		abs.AddView(child, new AbsoluteLayout.LayoutParams() { X = 100, Y = 50 });
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 100) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y - 50) < 0.01f);
	}

	[Test]
	public static void DefaultPosition_AtOrigin()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		let child = new TestView(50, 30);
		abs.AddView(child);
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y) < 0.01f);
	}

	[Test]
	public static void Padding_OffsetsAll()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		abs.Padding = .(10, 20, 10, 20);
		let child = new TestView(50, 30);
		abs.AddView(child, new AbsoluteLayout.LayoutParams() { X = 5, Y = 5 });
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 15) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y - 25) < 0.01f);
	}

	[Test]
	public static void MultipleChildren_IndependentPositions()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		let a = new TestView(50, 30);
		let b = new TestView(60, 40);
		abs.AddView(a, new AbsoluteLayout.LayoutParams() { X = 10, Y = 10 });
		abs.AddView(b, new AbsoluteLayout.LayoutParams() { X = 200, Y = 150 });
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - 10) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X - 200) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.Y - 150) < 0.01f);
	}

	[Test]
	public static void ChildRetainsMeasuredSize()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		let child = new TestView(80, 45);
		abs.AddView(child, new AbsoluteLayout.LayoutParams() { X = 50, Y = 50 });
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Width - 80) < 0.01f);
		Test.Assert(Math.Abs(child.Height - 45) < 0.01f);
	}
}
