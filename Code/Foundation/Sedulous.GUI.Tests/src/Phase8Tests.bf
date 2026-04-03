using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI.Tests;

/// Phase 8 tests: scrolling and range controls.
class Phase8Tests
{
	/// Test panel for container tests.
	class TestPanel : Panel
	{
	}

	// ========== Slider Tests ==========

	[Test]
	public static void Slider_DefaultProperties()
	{
		let slider = scope Slider();

		Test.Assert(slider.Minimum == 0, "Default Minimum should be 0");
		Test.Assert(slider.Maximum == 100, "Default Maximum should be 100");
		Test.Assert(slider.Value == 0, "Default Value should be 0");
		Test.Assert(slider.Step == 0, "Default Step should be 0 (continuous)");
		Test.Assert(slider.Orientation == .Horizontal, "Default Orientation should be Horizontal");
		Test.Assert(slider.TickPlacement == .None, "Default TickPlacement should be None");
	}

	[Test]
	public static void Slider_ValueClamping()
	{
		let slider = scope Slider();
		slider.Minimum = 0;
		slider.Maximum = 100;

		slider.Value = 150;
		Test.Assert(slider.Value == 100, "Value should be clamped to Maximum");

		slider.Value = -50;
		Test.Assert(slider.Value == 0, "Value should be clamped to Minimum");

		slider.Value = 50;
		Test.Assert(slider.Value == 50, "Value within range should be unchanged");
	}

	[Test]
	public static void Slider_StepSnapping()
	{
		let slider = scope Slider();
		slider.Minimum = 0;
		slider.Maximum = 100;
		slider.Step = 10;

		slider.Value = 23;
		Test.Assert(slider.Value == 20, "Value should snap to nearest step (23 -> 20)");

		slider.Value = 27;
		Test.Assert(slider.Value == 30, "Value should snap to nearest step (27 -> 30)");

		slider.Value = 25;
		Test.Assert(slider.Value == 30, "Value at midpoint should snap up (25 -> 30)");
	}

	[Test]
	public static void Slider_ValueChangedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let slider = new Slider();
		slider.Width = 200;
		slider.Height = 30;
		slider.Minimum = 0;
		slider.Maximum = 100;
		panel.AddChild(slider);

		float eventValue = -1;
		slider.ValueChanged.Subscribe(new [&](s, v) => { eventValue = v; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		slider.Value = 75;
		Test.Assert(eventValue == 75, "ValueChanged event should fire with new value");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Slider_VerticalOrientation()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let slider = new Slider();
		slider.Orientation = .Vertical;
		slider.Width = 30;
		slider.Height = 200;
		panel.AddChild(slider);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(slider.Orientation == .Vertical, "Orientation should be Vertical");
		Test.Assert(slider.DesiredSize.Height >= slider.DesiredSize.Width, "Vertical slider should be taller than wide");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Slider_TickFrequency()
	{
		let slider = scope Slider();
		slider.Minimum = 0;
		slider.Maximum = 100;
		slider.TickFrequency = 25;
		slider.TickPlacement = .BottomRight;

		Test.Assert(slider.TickFrequency == 25, "TickFrequency should be set");
		Test.Assert(slider.TickPlacement == .BottomRight, "TickPlacement should be set");
	}

	[Test]
	public static void Slider_KeyboardNavigation()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let slider = new Slider();
		slider.Width = 200;
		slider.Height = 30;
		slider.Minimum = 0;
		slider.Maximum = 100;
		slider.Value = 50;
		panel.AddChild(slider);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Focus the slider
		ctx.FocusManager.SetFocus(slider);

		float initialValue = slider.Value;

		// Press Right arrow
		ctx.InputManager.ProcessKeyDown(.Right, .None);
		Test.Assert(slider.Value > initialValue, "Right arrow should increase value");

		float valueAfterRight = slider.Value;

		// Press Left arrow
		ctx.InputManager.ProcessKeyDown(.Left, .None);
		Test.Assert(slider.Value < valueAfterRight, "Left arrow should decrease value");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== ScrollBar Tests ==========

	[Test]
	public static void ScrollBar_DefaultProperties()
	{
		let scrollBar = scope ScrollBar(.Vertical);

		Test.Assert(scrollBar.Minimum == 0, "Default Minimum should be 0");
		Test.Assert(scrollBar.Maximum == 100, "Default Maximum should be 100");
		Test.Assert(scrollBar.Value == 0, "Default Value should be 0");
		Test.Assert(scrollBar.ViewportSize == 10, "Default ViewportSize should be 10");
		Test.Assert(scrollBar.Orientation == .Vertical, "Orientation should match constructor");
	}

	[Test]
	public static void ScrollBar_ValueClamping()
	{
		let scrollBar = scope ScrollBar(.Vertical);
		scrollBar.Minimum = 0;
		scrollBar.Maximum = 100;
		scrollBar.ViewportSize = 20;

		// With viewport 20, max scrollable is 100 - 20 = 80
		scrollBar.Value = 90;
		Test.Assert(scrollBar.Value == 80, "Value should be clamped to Maximum - ViewportSize");

		scrollBar.Value = -10;
		Test.Assert(scrollBar.Value == 0, "Value should be clamped to Minimum");
	}

	[Test]
	public static void ScrollBar_ScrollEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let scrollBar = new ScrollBar(.Vertical);
		scrollBar.Width = 20;
		scrollBar.Height = 200;
		scrollBar.Minimum = 0;
		scrollBar.Maximum = 100;
		scrollBar.ViewportSize = 20;
		panel.AddChild(scrollBar);

		float eventValue = -1;
		scrollBar.Scroll.Subscribe(new [&](sb, v) => { eventValue = v; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		scrollBar.Value = 50;
		Test.Assert(eventValue == 50, "Scroll event should fire with new value");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ScrollBar_IsScrollNeeded()
	{
		let scrollBar = scope ScrollBar(.Vertical);
		scrollBar.Minimum = 0;
		scrollBar.Maximum = 100;
		scrollBar.ViewportSize = 100;

		Test.Assert(!scrollBar.IsScrollNeeded, "Scroll should not be needed when viewport covers content");

		scrollBar.ViewportSize = 50;
		Test.Assert(scrollBar.IsScrollNeeded, "Scroll should be needed when viewport is smaller than content");
	}

	[Test]
	public static void ScrollBar_PageUpDown()
	{
		let scrollBar = scope ScrollBar(.Vertical);
		scrollBar.Minimum = 0;
		scrollBar.Maximum = 100;
		scrollBar.ViewportSize = 20;
		scrollBar.LargeChange = 20;
		scrollBar.Value = 50;

		scrollBar.PageUp();
		Test.Assert(scrollBar.Value == 30, "PageUp should decrease value by LargeChange");

		scrollBar.PageDown();
		Test.Assert(scrollBar.Value == 50, "PageDown should increase value by LargeChange");
	}

	[Test]
	public static void ScrollBar_ScrollUpDown()
	{
		let scrollBar = scope ScrollBar(.Vertical);
		scrollBar.Minimum = 0;
		scrollBar.Maximum = 100;
		scrollBar.ViewportSize = 20;
		scrollBar.SmallChange = 5;
		scrollBar.Value = 50;

		scrollBar.ScrollUp();
		Test.Assert(scrollBar.Value == 45, "ScrollUp should decrease value by SmallChange");

		scrollBar.ScrollDown();
		Test.Assert(scrollBar.Value == 50, "ScrollDown should increase value by SmallChange");
	}

	// ========== ScrollViewer Tests ==========

	[Test]
	public static void ScrollViewer_DefaultProperties()
	{
		let scrollViewer = scope ScrollViewer();

		Test.Assert(scrollViewer.HorizontalOffset == 0, "Default HorizontalOffset should be 0");
		Test.Assert(scrollViewer.VerticalOffset == 0, "Default VerticalOffset should be 0");
		Test.Assert(scrollViewer.HorizontalScrollBarVisibility == .Auto, "Default HorizontalScrollBarVisibility should be Auto");
		Test.Assert(scrollViewer.VerticalScrollBarVisibility == .Auto, "Default VerticalScrollBarVisibility should be Auto");
	}

	[Test]
	public static void ScrollViewer_ContentExtent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let scrollViewer = new ScrollViewer();
		scrollViewer.Width = 200;
		scrollViewer.Height = 100;
		panel.AddChild(scrollViewer);

		let content = new Panel();
		content.Width = 400;
		content.Height = 300;
		scrollViewer.Content = content;

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(scrollViewer.ExtentWidth == 400, "ExtentWidth should match content width");
		Test.Assert(scrollViewer.ExtentHeight == 300, "ExtentHeight should match content height");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ScrollViewer_CanScroll()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let scrollViewer = new ScrollViewer();
		scrollViewer.Width = 200;
		scrollViewer.Height = 100;
		panel.AddChild(scrollViewer);

		let content = new Panel();
		content.Width = 400;
		content.Height = 300;
		scrollViewer.Content = content;

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(scrollViewer.CanScrollHorizontally, "Should be able to scroll horizontally");
		Test.Assert(scrollViewer.CanScrollVertically, "Should be able to scroll vertically");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ScrollViewer_ScrollToMethods()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let scrollViewer = new ScrollViewer();
		scrollViewer.Width = 200;
		scrollViewer.Height = 100;
		panel.AddChild(scrollViewer);

		let content = new Panel();
		content.Width = 400;
		content.Height = 300;
		scrollViewer.Content = content;

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		scrollViewer.ScrollToBottom();
		Test.Assert(scrollViewer.VerticalOffset > 0, "ScrollToBottom should scroll down");

		scrollViewer.ScrollToTop();
		Test.Assert(scrollViewer.VerticalOffset == 0, "ScrollToTop should scroll to top");

		scrollViewer.ScrollToRight();
		Test.Assert(scrollViewer.HorizontalOffset > 0, "ScrollToRight should scroll right");

		scrollViewer.ScrollToLeft();
		Test.Assert(scrollViewer.HorizontalOffset == 0, "ScrollToLeft should scroll to left");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ScrollViewer_ScrollChangedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let scrollViewer = new ScrollViewer();
		scrollViewer.Width = 200;
		scrollViewer.Height = 100;
		panel.AddChild(scrollViewer);

		let content = new Panel();
		content.Width = 400;
		content.Height = 300;
		scrollViewer.Content = content;

		bool eventFired = false;
		scrollViewer.ScrollChanged.Subscribe(new [&](sv) => { eventFired = true; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		scrollViewer.VerticalOffset = 50;
		Test.Assert(eventFired, "ScrollChanged event should fire when offset changes");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ScrollViewer_OffsetClamping()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let scrollViewer = new ScrollViewer();
		scrollViewer.Width = 200;
		scrollViewer.Height = 100;
		panel.AddChild(scrollViewer);

		let content = new Panel();
		content.Width = 400;
		content.Height = 300;
		scrollViewer.Content = content;

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		scrollViewer.VerticalOffset = -100;
		Test.Assert(scrollViewer.VerticalOffset == 0, "Negative offset should be clamped to 0");

		scrollViewer.VerticalOffset = 1000;
		Test.Assert(scrollViewer.VerticalOffset <= 300 - scrollViewer.ViewportHeight, "Offset should be clamped to max scrollable");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ScrollViewer_ScrollBarVisibility()
	{
		let scrollViewer = scope ScrollViewer();

		scrollViewer.HorizontalScrollBarVisibility = .Visible;
		Test.Assert(scrollViewer.HorizontalScrollBarVisibility == .Visible, "HorizontalScrollBarVisibility should be settable");

		scrollViewer.VerticalScrollBarVisibility = .Hidden;
		Test.Assert(scrollViewer.VerticalScrollBarVisibility == .Hidden, "VerticalScrollBarVisibility should be settable");

		scrollViewer.HorizontalScrollBarVisibility = .Disabled;
		Test.Assert(scrollViewer.HorizontalScrollBarVisibility == .Disabled, "HorizontalScrollBarVisibility should accept Disabled");
	}

	// ========== Splitter Tests ==========

	[Test]
	public static void Splitter_DefaultProperties()
	{
		let splitter = scope Splitter(.Vertical);

		Test.Assert(splitter.Orientation == .Vertical, "Orientation should match constructor");
		Test.Assert(splitter.Thickness > 0, "Default Thickness should be positive");
		Test.Assert(splitter.Thickness == 6, "Default Thickness should be 6");
	}

	[Test]
	public static void Splitter_OrientationAffectsCursor()
	{
		let vertSplitter = scope Splitter(.Vertical);
		Test.Assert(vertSplitter.Orientation == .Vertical, "Vertical splitter orientation");

		let horzSplitter = scope Splitter(.Horizontal);
		Test.Assert(horzSplitter.Orientation == .Horizontal, "Horizontal splitter orientation");
	}

	[Test]
	public static void Splitter_ThicknessProperty()
	{
		let splitter = scope Splitter(.Vertical);

		splitter.Thickness = 10;
		Test.Assert(splitter.Thickness == 10, "Thickness should be settable");

		splitter.Thickness = 1;
		Test.Assert(splitter.Thickness == 2, "Thickness should have minimum value of 2");
	}

	[Test]
	public static void Splitter_MeasuresCorrectly()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let vertSplitter = new Splitter(.Vertical);
		vertSplitter.Thickness = 8;
		vertSplitter.Height = 100;
		panel.AddChild(vertSplitter);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(vertSplitter.DesiredSize.Width == 8, "Vertical splitter width should equal thickness");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Splitter_SplitterMovedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let splitter = new Splitter(.Vertical);
		splitter.Width = 8;
		splitter.Height = 100;
		panel.AddChild(splitter);

		float movedDelta = 0;
		splitter.SplitterMoved.Subscribe(new [&](s, delta) => { movedDelta = delta; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Simulate drag - mouse down
		ctx.InputManager.ProcessMouseMove(4, 50);
		ctx.ProcessMouseDown(4, 50, .Left);

		// Move mouse to simulate drag
		ctx.InputManager.ProcessMouseMove(24, 50);

		Test.Assert(movedDelta != 0, "SplitterMoved should fire during drag");

		ctx.ProcessMouseUp(24, 50, .Left);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Splitter_DragEvents()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let splitter = new Splitter(.Vertical);
		splitter.Width = 8;
		splitter.Height = 100;
		panel.AddChild(splitter);

		bool dragStarted = false;
		bool dragCompleted = false;
		splitter.DragStarted.Subscribe(new [&](s) => { dragStarted = true; });
		splitter.DragCompleted.Subscribe(new [&](s) => { dragCompleted = true; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Mouse down starts drag
		ctx.InputManager.ProcessMouseMove(4, 50);
		ctx.ProcessMouseDown(4, 50, .Left);
		Test.Assert(dragStarted, "DragStarted should fire on mouse down");

		// Mouse up ends drag
		ctx.ProcessMouseUp(4, 50, .Left);
		Test.Assert(dragCompleted, "DragCompleted should fire on mouse up");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== ScrollBarVisibility Enum Tests ==========

	[Test]
	public static void ScrollBarVisibility_AllValuesExist()
	{
		ScrollBarVisibility vis;

		vis = .Disabled;
		Test.Assert(vis == .Disabled, "Disabled should exist");

		vis = .Auto;
		Test.Assert(vis == .Auto, "Auto should exist");

		vis = .Hidden;
		Test.Assert(vis == .Hidden, "Hidden should exist");

		vis = .Visible;
		Test.Assert(vis == .Visible, "Visible should exist");
	}

	// ========== TickPlacement Enum Tests ==========

	[Test]
	public static void TickPlacement_AllValuesExist()
	{
		TickPlacement placement;

		placement = .None;
		Test.Assert(placement == .None, "None should exist");

		placement = .TopLeft;
		Test.Assert(placement == .TopLeft, "TopLeft should exist");

		placement = .BottomRight;
		Test.Assert(placement == .BottomRight, "BottomRight should exist");

		placement = .Both;
		Test.Assert(placement == .Both, "Both should exist");
	}
}
