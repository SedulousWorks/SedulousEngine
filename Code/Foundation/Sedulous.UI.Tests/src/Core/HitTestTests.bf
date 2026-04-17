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
		ctx.SetViewportSize(400, 300);

		let frame = new FrameLayout();
		ctx.Root.AddView(frame);

		// Two overlapping children at the same position.
		let bottom = new ColorView();
		frame.AddView(bottom, new FrameLayout.LayoutParams() { Width = 100, Height = 100, Gravity = .None });

		let top = new ColorView();
		frame.AddView(top, new FrameLayout.LayoutParams() { Width = 100, Height = 100, Gravity = .None });

		ctx.DoLayout();

		// Hit-test at (50, 50) should return the topmost (last added).
		let hit = ctx.Root.HitTest(.(50, 50));
		Test.Assert(hit === top);
	}

	[Test]
	public static void HitTest_MissReturnsParent()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(400, 300);

		let frame = new FrameLayout();
		ctx.Root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 50;
		child.PreferredHeight = 50;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 50, Height = 50, Gravity = .None });

		ctx.DoLayout();

		// Hit outside the child but inside the frame → returns frame.
		let hit = ctx.Root.HitTest(.(200, 200));
		Test.Assert(hit === frame);
	}

	[Test]
	public static void HitTest_InvisibleSkipped()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(400, 300);

		let frame = new FrameLayout();
		ctx.Root.AddView(frame);

		let child = new ColorView();
		child.Visibility = .Invisible;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 400, Height = 300 });

		ctx.DoLayout();

		// Invisible child should not be hit — returns the frame instead.
		let hit = ctx.Root.HitTest(.(50, 50));
		Test.Assert(hit === frame);
	}

	[Test]
	public static void HitTest_NotHitTestVisible_Skipped()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(400, 300);

		let frame = new FrameLayout();
		ctx.Root.AddView(frame);

		let child = new ColorView();
		child.IsHitTestVisible = false;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 400, Height = 300 });

		ctx.DoLayout();

		let hit = ctx.Root.HitTest(.(50, 50));
		Test.Assert(hit === frame);
	}
}
