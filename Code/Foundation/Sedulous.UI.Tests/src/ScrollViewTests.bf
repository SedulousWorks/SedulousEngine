namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class ScrollViewTests
{
	[Test]
	public static void ScrollView_ContentLargerThanViewport()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 100);

		let scroll = new ScrollView();
		let content = new TestView(200, 500); // taller than viewport
		scroll.AddView(content);
		root.AddView(scroll);
		TestSetup.Layout(ctx, root);

		Test.Assert(scroll.MaxScrollY > 0);
		Test.Assert(scroll.MaxScrollX == 0);
	}

	[Test]
	public static void ScrollView_ScrollClamps()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 100);

		let scroll = new ScrollView();
		let content = new TestView(200, 500);
		scroll.AddView(content);
		root.AddView(scroll);
		TestSetup.Layout(ctx, root);

		scroll.ScrollY = -100;
		Test.Assert(scroll.ScrollY == 0);

		scroll.ScrollY = 9999;
		Test.Assert(scroll.ScrollY == scroll.MaxScrollY);
	}

	[Test]
	public static void ScrollView_ScrollTo()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 100);

		let scroll = new ScrollView();
		let content = new TestView(200, 500);
		scroll.AddView(content);
		root.AddView(scroll);
		TestSetup.Layout(ctx, root);

		scroll.ScrollTo(0, 100);
		Test.Assert(scroll.ScrollY == 100);
	}

	[Test]
	public static void ScrollView_ScrollToTop()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 100);

		let scroll = new ScrollView();
		scroll.AddView(new TestView(200, 500));
		root.AddView(scroll);
		TestSetup.Layout(ctx, root);

		scroll.ScrollY = 200;
		scroll.ScrollToTop();
		Test.Assert(scroll.ScrollY == 0);
	}

	[Test]
	public static void ScrollView_ScrollToBottom()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 100);

		let scroll = new ScrollView();
		scroll.AddView(new TestView(200, 500));
		root.AddView(scroll);
		TestSetup.Layout(ctx, root);

		scroll.ScrollToBottom();
		Test.Assert(scroll.ScrollY == scroll.MaxScrollY);
	}

	[Test]
	public static void ScrollView_NeverPolicy_NoBar()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 100);

		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Never;
		scroll.AddView(new TestView(200, 500));
		root.AddView(scroll);
		TestSetup.Layout(ctx, root);

		// ViewportHeight should be full height (no bar reserved)
		Test.Assert(Math.Abs(scroll.ViewportHeight - 100) < 1.0f);
	}

	// === MomentumHelper ===

	[Test]
	public static void Momentum_Decelerates()
	{
		var m = MomentumHelper();
		m.VelocityY = 500;

		Test.Assert(m.IsActive);

		var totalDy = 0.0f;
		for (int i = 0; i < 100; i++)
		{
			let (dx, dy) = m.Update(0.016f);
			totalDy += dy;
		}

		// Should have moved and then stopped
		Test.Assert(totalDy > 0);
		Test.Assert(!m.IsActive || Math.Abs(m.VelocityY) < 1.0f);
	}

	[Test]
	public static void Momentum_Stop()
	{
		var m = MomentumHelper();
		m.VelocityY = 500;
		m.Stop();
		Test.Assert(!m.IsActive);
	}

	// === ScrollBar ===

	[Test]
	public static void ScrollBar_ValueClamps()
	{
		let bar = scope ScrollBar();
		bar.MaxValue = 100;

		bar.Value = -10;
		Test.Assert(bar.Value == 0);

		bar.Value = 200;
		Test.Assert(bar.Value == 100);
	}

	[Test]
	public static void ScrollBar_ValueChanged()
	{
		let bar = scope ScrollBar();
		bar.MaxValue = 100;

		float lastVal = -1;
		bar.OnValueChanged.Add(new [&lastVal] (b, v) => { lastVal = v; });

		bar.Value = 42;
		Test.Assert(lastVal == 42);
	}
}
