namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class HitTestTests
{
	[Test]
	public static void ReverseOrder_TopmostWins()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		// Two overlapping children at the same position.
		let bottom = new ColorView();
		frame.AddView(bottom, new FrameLayout.LayoutParams() { Width = 100, Height = 100, Gravity = .None });

		let top = new ColorView();
		frame.AddView(top, new FrameLayout.LayoutParams() { Width = 100, Height = 100, Gravity = .None });

		ctx.UpdateRootView(root);

		// Hit-test at (50, 50) should return the topmost (last added).
		let hit = root.HitTest(.(50, 50));
		Test.Assert(hit === top);
	}

	[Test]
	public static void HitTest_MissReturnsParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 50;
		child.PreferredHeight = 50;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 50, Height = 50, Gravity = .None });

		ctx.UpdateRootView(root);

		// Hit outside the child but inside the frame -> returns frame.
		let hit = root.HitTest(.(200, 200));
		Test.Assert(hit === frame);
	}

	[Test]
	public static void HitTest_InvisibleSkipped()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.Visibility = .Invisible;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 400, Height = 300 });

		ctx.UpdateRootView(root);

		// Invisible child should not be hit - returns the frame instead.
		let hit = root.HitTest(.(50, 50));
		Test.Assert(hit === frame);
	}

	[Test]
	public static void HitTest_NotHitTestVisible_Skipped()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.IsHitTestVisible = false;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 400, Height = 300 });

		ctx.UpdateRootView(root);

		let hit = root.HitTest(.(50, 50));
		Test.Assert(hit === frame);
	}
}
