namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class FlexLayoutTests
{
	// === Direction ===

	[Test]
	public static void Row_ChildrenArrangedHorizontally()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal };
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(a.Bounds.X < b.Bounds.X);
		Test.Assert(Math.Abs(b.Bounds.X - 50) < 0.01f);
	}

	[Test]
	public static void Column_ChildrenArrangedVertically()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Vertical };
		let a = new TestView(50, 30);
		let b = new TestView(50, 40);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(a.Bounds.Y < b.Bounds.Y);
		Test.Assert(Math.Abs(b.Bounds.Y - 30) < 0.01f);
	}

	// === Spacing ===

	[Test]
	public static void Row_Spacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, Spacing = 10 };
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(b.Bounds.X - 60) < 0.01f); // 50 + 10
	}

	[Test]
	public static void Column_Spacing()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		let a = new TestView(50, 30);
		let b = new TestView(50, 40);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(b.Bounds.Y - 38) < 0.01f); // 30 + 8
	}

	// === Grow ===

	[Test]
	public static void Row_Grow_DistributesExtraSpace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal };
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		flex.AddView(a, new FlexLayout.LayoutParams() { Grow = 1 });
		flex.AddView(b, new FlexLayout.LayoutParams() { Grow = 1 });
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 200) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 200) < 1.0f);
	}

	[Test]
	public static void Row_Grow_WeightedDistribution()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal };
		let a = new TestView(0, 30);
		let b = new TestView(0, 30);
		flex.AddView(a, new FlexLayout.LayoutParams() { Grow = 1 });
		flex.AddView(b, new FlexLayout.LayoutParams() { Grow = 3 });
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Width - 100) < 1.0f);
		Test.Assert(Math.Abs(b.Width - 300) < 1.0f);
	}

	[Test]
	public static void Row_Grow_FixedPlusFlexible()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal };
		let fixedChild = new TestView(100, 30);
		let flexChild = new TestView(0, 30);
		flex.AddView(fixedChild);
		flex.AddView(flexChild, new FlexLayout.LayoutParams() { Grow = 1 });
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(fixedChild.Width - 100) < 1.0f);
		Test.Assert(Math.Abs(flexChild.Width - 300) < 1.0f);
	}

	[Test]
	public static void Column_Grow()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Vertical };
		let a = new TestView(50, 0);
		let b = new TestView(50, 0);
		flex.AddView(a, new FlexLayout.LayoutParams() { Grow = 1 });
		flex.AddView(b, new FlexLayout.LayoutParams() { Grow = 1 });
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Height - 150) < 1.0f);
		Test.Assert(Math.Abs(b.Height - 150) < 1.0f);
	}

	// === JustifyContent ===

	[Test]
	public static void Justify_End()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, JustifyContent = .End };
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - 350) < 1.0f);
	}

	[Test]
	public static void Justify_Center()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, JustifyContent = .Center };
		let a = new TestView(100, 30);
		flex.AddView(a);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - 150) < 1.0f);
	}

	[Test]
	public static void Justify_SpaceBetween()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, JustifyContent = .SpaceBetween };
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X) < 0.01f);
		Test.Assert(Math.Abs(b.Bounds.X - 350) < 1.0f);
	}

	[Test]
	public static void Justify_SpaceEvenly()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, JustifyContent = .SpaceEvenly };
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		// Free space = 300, 3 gaps = 100 each
		Test.Assert(Math.Abs(a.Bounds.X - 100) < 1.0f);
		Test.Assert(Math.Abs(b.Bounds.X - 250) < 1.0f);
	}

	// === AlignItems ===

	[Test]
	public static void AlignItems_Stretch()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, AlignItems = .Stretch };
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Height - 300) < 1.0f);
	}

	[Test]
	public static void AlignItems_Center()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, AlignItems = .Center };
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.Y - 135) < 1.0f);
	}

	[Test]
	public static void AlignItems_End()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal, AlignItems = .End };
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.Y - 270) < 1.0f);
	}

	// === Gone visibility ===

	[Test]
	public static void Gone_ChildSkipped()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal };
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		b.Visibility = .Gone;
		let c = new TestView(70, 30);
		flex.AddView(a);
		flex.AddView(b);
		flex.AddView(c);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(c.Bounds.X - 50) < 0.01f);
	}

	// === Padding ===

	[Test]
	public static void Padding_OffsetsChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let flex = new FlexLayout() { Direction = .Horizontal };
		flex.Padding = .(10, 20, 10, 20);
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		TestSetup.Layout(ctx, root);

		Test.Assert(Math.Abs(a.Bounds.X - 10) < 0.01f);
		Test.Assert(a.Bounds.Y >= 20);
	}
}
