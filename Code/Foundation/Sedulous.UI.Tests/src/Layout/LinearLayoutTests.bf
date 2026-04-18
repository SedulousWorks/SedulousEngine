namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class LinearLayoutTests
{
	[Test]
	public static void Vertical_WeightDistribution()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new ColorView();
		a.Color = .Red;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		let b = new ColorView();
		b.Color = .Blue;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		ctx.UpdateRootView(root);

		// Two equal-weight children should split the height evenly.
		Test.Assert(Math.Abs(a.Bounds.Height - 150) < 1);
		Test.Assert(Math.Abs(b.Bounds.Height - 150) < 1);
		Test.Assert(a.Bounds.Y < b.Bounds.Y);
	}

	[Test]
	public static void Horizontal_WeightDistribution()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);

		let a = new ColorView();
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 2 });

		let b = new ColorView();
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		ctx.UpdateRootView(root);

		// Weight 2:1 -> widths should be ~267 and ~133.
		let expectedA = 400.0f * 2.0f / 3.0f;
		let expectedB = 400.0f * 1.0f / 3.0f;
		Test.Assert(Math.Abs(a.Bounds.Width - expectedA) < 1);
		Test.Assert(Math.Abs(b.Bounds.Width - expectedB) < 1);
	}

	[Test]
	public static void Spacing_BetweenChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		layout.Spacing = 10;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredHeight = 40;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });

		let b = new ColorView();
		b.PreferredHeight = 40;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });

		ctx.UpdateRootView(root);

		// Second child should start 10px below first child's bottom.
		let gap = b.Bounds.Y - (a.Bounds.Y + a.Bounds.Height);
		Test.Assert(Math.Abs(gap - 10) < 0.5f);
	}

	[Test]
	public static void Gone_ChildSkipped()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredHeight = 50;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		let hidden = new ColorView();
		hidden.Visibility = .Gone;
		hidden.PreferredHeight = 50;
		layout.AddView(hidden, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		let b = new ColorView();
		b.PreferredHeight = 50;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		ctx.UpdateRootView(root);

		// b should be directly below a (no gap for the Gone child).
		Test.Assert(Math.Abs(b.Bounds.Y - (a.Bounds.Y + a.Bounds.Height)) < 1);
	}

	[Test]
	public static void Invisible_TakesSpace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new ColorView();
		a.PreferredHeight = 50;
		layout.AddView(a, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		let hidden = new ColorView();
		hidden.Visibility = .Invisible;
		hidden.PreferredHeight = 50;
		layout.AddView(hidden, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		let b = new ColorView();
		b.PreferredHeight = 50;
		layout.AddView(b, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		ctx.UpdateRootView(root);

		// Invisible child still reserves space. b should be below the hidden's space.
		Test.Assert(Math.Abs(b.Bounds.Y - (hidden.Bounds.Y + hidden.Bounds.Height)) < 1);
	}
}
