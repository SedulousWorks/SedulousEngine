namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class ScrollTests
{
	[Test]
	public static void MomentumHelper_DecaysVelocity()
	{
		var m = MomentumHelper();
		m.VelocityY = 1000;
		m.Friction = 6;
		m.StopThreshold = 0.5f;

		let (_, dy1) = m.Update(0.016f);
		Test.Assert(dy1 > 0);
		Test.Assert(m.VelocityY < 1000); // decayed

		// After many frames, should snap to zero.
		for (int i = 0; i < 300; i++)
			m.Update(0.016f);
		Test.Assert(!m.IsActive);
	}

	[Test]
	public static void MomentumHelper_SnapsBelowThreshold()
	{
		var m = MomentumHelper();
		m.VelocityY = 0.3f;
		m.StopThreshold = 0.5f;

		m.Update(0.016f);
		Test.Assert(m.VelocityY == 0);
		Test.Assert(!m.IsActive);
	}

	[Test]
	public static void ScrollView_NegativeOffsetLayout()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		root.AddView(sv);

		// Tall content.
		let content = new ColorView();
		content.PreferredWidth = 200;
		content.PreferredHeight = 500;
		sv.AddView(content, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 500 });

		ctx.UpdateRootView(root);

		// At scroll=0, content starts at (0, 0).
		Test.Assert(content.Bounds.Y == 0);

		// Scroll down 50px.
		sv.ScrollTo(0, 50);
		ctx.UpdateRootView(root);

		// Content should be at y=-50 (negative offset).
		Test.Assert(Math.Abs(content.Bounds.Y - (-50)) < 1);
	}

	[Test]
	public static void ScrollView_ClampsToMaxScroll()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		root.AddView(sv);

		let content = new ColorView();
		content.PreferredHeight = 500;
		sv.AddView(content, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 500 });

		ctx.UpdateRootView(root);

		// Try to scroll past end.
		sv.ScrollTo(0, 99999);
		ctx.UpdateRootView(root);

		// Should clamp to MaxScrollY (500 - viewport ~100 = ~400).
		Test.Assert(sv.ScrollY <= sv.MaxScrollY + 1);
		Test.Assert(sv.ScrollY > 0);
	}

	[Test]
	public static void ScrollBarPolicy_Auto_ShowsWhenNeeded()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		sv.VScrollPolicy = .Auto;
		root.AddView(sv);

		// Content smaller than viewport — no bar.
		let small = new ColorView();
		small.PreferredHeight = 50;
		sv.AddView(small, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

		ctx.UpdateRootView(root);
		Test.Assert(sv.MaxScrollY == 0);

		// Replace with tall content.
		sv.RemoveView(small, true);
		let tall = new ColorView();
		tall.PreferredHeight = 500;
		sv.AddView(tall, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 500 });

		ctx.UpdateRootView(root);
		Test.Assert(sv.MaxScrollY > 0);
	}

	[Test]
	public static void ScrollView_MouseWheel_Scrolls()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		root.AddView(sv);

		let content = new ColorView();
		content.PreferredHeight = 500;
		sv.AddView(content, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 500 });

		ctx.UpdateRootView(root);
		Test.Assert(sv.ScrollY == 0);

		// Simulate wheel event.
		let args = scope MouseWheelEventArgs();
		args.DeltaY = -2; // scroll down
		sv.OnMouseWheel(args);

		Test.Assert(sv.ScrollY > 0);
		Test.Assert(args.Handled);
	}

	[Test]
	public static void ScrollIntoView_AdjustsScroll()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		root.AddView(sv);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		sv.AddView(layout, new LayoutParams() { Width = LayoutParams.MatchParent });

		// Add many items so it overflows.
		for (int i = 0; i < 20; i++)
		{
			let item = new ColorView();
			item.PreferredHeight = 30;
			layout.AddView(item, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });
		}

		ctx.UpdateRootView(root);

		// Last item is at y=19*30=570, well below viewport.
		let lastItem = layout.GetChildAt(19);
		lastItem.ScrollIntoView();

		// ScrollView should have scrolled down.
		Test.Assert(sv.ScrollY > 0);
	}

	[Test]
	public static void CascadingVisibility_BothAxesAuto()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 200);

		let sv = new ScrollView();
		sv.VScrollPolicy = .Auto;
		sv.HScrollPolicy = .Auto;
		sv.ScrollBarThickness = 10;
		root.AddView(sv);

		// Content that overflows vertically but just barely fits horizontally.
		// Without V scrollbar it fits at 200px. With V scrollbar taking 10px,
		// it only has 190px — if content is 195px wide that triggers H bar.
		let content = new ColorView();
		content.PreferredWidth = 195;
		content.PreferredHeight = 400;
		sv.AddView(content, new LayoutParams() { Width = 195, Height = 400 });

		ctx.UpdateRootView(root);

		// V bar should be visible (400 > 200).
		Test.Assert(sv.MaxScrollY > 0);

		// H bar should also be visible via cascade:
		// V bar takes 10px -> viewport = 190px -> 195 > 190 -> H bar needed.
		Test.Assert(sv.MaxScrollX > 0);
	}

	[Test]
	public static void ContentDrag_Scrolls()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		root.AddView(sv);

		let content = new ColorView();
		content.PreferredHeight = 500;
		sv.AddView(content, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 500 });

		ctx.UpdateRootView(root);
		Test.Assert(sv.ScrollY == 0);

		// Simulate drag: mouse down, then move up (scroll content down).
		let downArgs = scope MouseEventArgs();
		downArgs.Set(50, 50);
		sv.OnMouseDown(downArgs);

		let moveArgs = scope MouseEventArgs();
		moveArgs.Set(50, 30); // moved 20px up -> scroll down by 20
		sv.OnMouseMove(moveArgs);

		Test.Assert(sv.ScrollY > 0);
	}
}
