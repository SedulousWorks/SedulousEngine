namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class AbsoluteLayoutTests
{
	[Test]
	public static void ExplicitPosition()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		let child = new TestView(80, 40);
		abs.AddView(child, new AbsoluteLayout.LayoutParams() { X = 50, Y = 100 });
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X - 50) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y - 100) < 0.01f);
		Test.Assert(Math.Abs(child.Width - 80) < 0.01f);
		Test.Assert(Math.Abs(child.Height - 40) < 0.01f);
	}

	[Test]
	public static void DefaultPosition_IsOrigin()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		let child = new TestView(80, 40);
		abs.AddView(child);
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(child.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y) < 0.01f);
	}

	[Test]
	public static void MultipleChildren_Independent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let abs = new AbsoluteLayout();
		let a = new TestView(50, 30);
		let b = new TestView(60, 40);
		abs.AddView(a, new AbsoluteLayout.LayoutParams() { X = 10, Y = 20 });
		abs.AddView(b, new AbsoluteLayout.LayoutParams() { X = 200, Y = 150 });
		root.AddView(abs);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - 10) < 0.01f);
		Test.Assert(Math.Abs(a.Bounds.Y - 20) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X - 200) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.Y - 150) < 0.01f);
	}
}
