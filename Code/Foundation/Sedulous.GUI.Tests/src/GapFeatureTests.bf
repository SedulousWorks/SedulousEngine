using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Tests for gap-filling features: Vector2Animation, RectangleAnimation, Double-click detection, Popup control

// === Vector2Animation Tests ===

class Vector2AnimationTests
{
	[Test]
	public static void Vector2AnimationDefaultProperties()
	{
		let anim = scope Vector2Animation();
		Test.Assert(anim.From == Vector2(0, 0));
		Test.Assert(anim.To == Vector2(0, 0));
		Test.Assert(anim.State == .Pending);
	}

	[Test]
	public static void Vector2AnimationSetFromTo()
	{
		let anim = scope Vector2Animation();
		anim.From = Vector2(10, 20);
		anim.To = Vector2(100, 200);
		Test.Assert(anim.From.X == 10 && anim.From.Y == 20);
		Test.Assert(anim.To.X == 100 && anim.To.Y == 200);
	}

	[Test]
	public static void Vector2AnimationWithGetterSetter()
	{
		let context = scope GUIContext();
		let panel = new Panel();
		context.RootElement = panel;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		Vector2 capturedValue = Vector2(0, 0);
		let anim = scope Vector2Animation(
			new (e) => Vector2(0, 0),
			new [&] (e, v) => { capturedValue = v; }
		);
		anim.From = Vector2(0, 0);
		anim.To = Vector2(100, 100);
		anim.Duration = 0.1f;
		anim.SetTarget(panel);
		anim.Start();

		// Update to 50% progress
		anim.Update(0.05f);
		Test.Assert(capturedValue.X >= 40 && capturedValue.X <= 60);
		Test.Assert(capturedValue.Y >= 40 && capturedValue.Y <= 60);

		context.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Vector2AnimationRenderTransformOriginFactory()
	{
		let anim = Vector2Animation.RenderTransformOrigin(Vector2(0, 0), Vector2(1, 1));
		defer delete anim;
		Test.Assert(anim.From == Vector2(0, 0));
		Test.Assert(anim.To == Vector2(1, 1));
	}

	[Test]
	public static void Vector2AnimationCreateFactory()
	{
		let anim = Vector2Animation.Create(
			new (e) => Vector2(0, 0),
			new (e, v) => { },
			Vector2(10, 20),
			Vector2(30, 40)
		);
		defer delete anim;
		Test.Assert(anim.From == Vector2(10, 20));
		Test.Assert(anim.To == Vector2(30, 40));
	}
}

// === RectangleAnimation Tests ===

class RectangleAnimationTests
{
	[Test]
	public static void RectangleAnimationDefaultProperties()
	{
		let anim = scope RectangleAnimation();
		Test.Assert(anim.From == RectangleF(0, 0, 0, 0));
		Test.Assert(anim.To == RectangleF(0, 0, 0, 0));
		Test.Assert(anim.State == .Pending);
	}

	[Test]
	public static void RectangleAnimationSetFromTo()
	{
		let anim = scope RectangleAnimation();
		anim.From = RectangleF(10, 20, 30, 40);
		anim.To = RectangleF(100, 200, 300, 400);
		Test.Assert(anim.From.X == 10 && anim.From.Y == 20);
		Test.Assert(anim.From.Width == 30 && anim.From.Height == 40);
		Test.Assert(anim.To.X == 100 && anim.To.Y == 200);
		Test.Assert(anim.To.Width == 300 && anim.To.Height == 400);
	}

	[Test]
	public static void RectangleAnimationWithGetterSetter()
	{
		let context = scope GUIContext();
		let panel = new Panel();
		context.RootElement = panel;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		RectangleF capturedValue = RectangleF(0, 0, 0, 0);
		let anim = scope RectangleAnimation(
			new (e) => RectangleF(0, 0, 0, 0),
			new [&] (e, v) => { capturedValue = v; }
		);
		anim.From = RectangleF(0, 0, 100, 100);
		anim.To = RectangleF(100, 100, 200, 200);
		anim.Duration = 0.1f;
		anim.SetTarget(panel);
		anim.Start();

		// Update to 50% progress
		anim.Update(0.05f);
		Test.Assert(capturedValue.X >= 40 && capturedValue.X <= 60);
		Test.Assert(capturedValue.Width >= 140 && capturedValue.Width <= 160);

		context.RootElement = null;
		delete panel;
	}

	[Test]
	public static void RectangleAnimationCreateFactory()
	{
		let anim = RectangleAnimation.Create(
			new (e) => RectangleF(0, 0, 0, 0),
			new (e, v) => { },
			RectangleF(10, 20, 30, 40),
			RectangleF(100, 200, 300, 400)
		);
		defer delete anim;
		Test.Assert(anim.From == RectangleF(10, 20, 30, 40));
		Test.Assert(anim.To == RectangleF(100, 200, 300, 400));
	}
}

// === Double-Click Detection Tests ===

/// Test control that tracks mouse down events for click count testing.
class ClickTestControl : Control
{
	public int32 LastClickCount = 0;

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);
		LastClickCount = e.ClickCount;
	}
}

class DoubleClickTests
{
	[Test]
	public static void MouseButtonEventArgsHasClickCount()
	{
		let args = scope MouseButtonEventArgs(100, 100, .Left);
		Test.Assert(args.ClickCount == 1);  // Default is 1
	}

	[Test]
	public static void InputManagerSingleClick()
	{
		let context = scope GUIContext();
		let control = new ClickTestControl();
		control.Width = .Fixed(100);
		control.Height = .Fixed(50);
		context.RootElement = control;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		// Single click
		context.InputManager.ProcessMouseDown(50, 25, .Left);
		Test.Assert(control.LastClickCount == 1);

		context.RootElement = null;
		delete control;
	}

	[Test]
	public static void InputManagerDoubleClick()
	{
		let context = scope GUIContext();
		let control = new ClickTestControl();
		control.Width = .Fixed(100);
		control.Height = .Fixed(50);
		context.RootElement = control;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		// First click
		context.InputManager.ProcessMouseDown(50, 25, .Left);
		context.InputManager.ProcessMouseUp(50, 25, .Left);
		Test.Assert(control.LastClickCount == 1);

		// Second click (within double-click time and distance)
		// Note: TotalTime doesn't advance automatically, so the second click
		// will be within the time threshold
		context.InputManager.ProcessMouseDown(50, 25, .Left);
		Test.Assert(control.LastClickCount == 2);

		context.RootElement = null;
		delete control;
	}

	[Test]
	public static void InputManagerTripleClick()
	{
		let context = scope GUIContext();
		let control = new ClickTestControl();
		control.Width = .Fixed(100);
		control.Height = .Fixed(50);
		context.RootElement = control;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		// Three rapid clicks
		context.InputManager.ProcessMouseDown(50, 25, .Left);
		context.InputManager.ProcessMouseUp(50, 25, .Left);
		context.InputManager.ProcessMouseDown(50, 25, .Left);
		context.InputManager.ProcessMouseUp(50, 25, .Left);
		context.InputManager.ProcessMouseDown(50, 25, .Left);
		Test.Assert(control.LastClickCount == 3);

		context.RootElement = null;
		delete control;
	}

	[Test]
	public static void InputManagerClickResetOnDifferentButton()
	{
		let context = scope GUIContext();
		let control = new ClickTestControl();
		control.Width = .Fixed(100);
		control.Height = .Fixed(50);
		context.RootElement = control;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		// Left click
		context.InputManager.ProcessMouseDown(50, 25, .Left);
		context.InputManager.ProcessMouseUp(50, 25, .Left);
		Test.Assert(control.LastClickCount == 1);

		// Right click - should reset to 1
		context.InputManager.ProcessMouseDown(50, 25, .Right);
		Test.Assert(control.LastClickCount == 1);

		context.RootElement = null;
		delete control;
	}

	[Test]
	public static void InputManagerClickResetOnDistance()
	{
		let context = scope GUIContext();
		let control = new ClickTestControl();
		control.Width = .Fixed(200);
		control.Height = .Fixed(200);
		context.RootElement = control;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		// First click at (50, 50)
		context.InputManager.ProcessMouseDown(50, 50, .Left);
		context.InputManager.ProcessMouseUp(50, 50, .Left);
		Test.Assert(control.LastClickCount == 1);

		// Second click far away - should reset to 1
		context.InputManager.ProcessMouseDown(150, 150, .Left);
		Test.Assert(control.LastClickCount == 1);

		context.RootElement = null;
		delete control;
	}
}

// === Popup Control Tests ===

class PopupTests
{
	[Test]
	public static void PopupDefaultProperties()
	{
		let popup = scope Popup();
		Test.Assert(popup.IsOpen == false);
		Test.Assert(popup.Placement == .Bottom);
		Test.Assert(popup.Behavior == .Default);
		Test.Assert(popup.HorizontalOffset == 0);
		Test.Assert(popup.VerticalOffset == 0);
		Test.Assert(popup.Visibility == .Collapsed);
	}

	[Test]
	public static void PopupSetPlacement()
	{
		let popup = scope Popup();
		popup.Placement = .TopCenter;
		Test.Assert(popup.Placement == .TopCenter);
	}

	[Test]
	public static void PopupSetBehavior()
	{
		let popup = scope Popup();
		popup.Behavior = .ModalDialog;
		Test.Assert(popup.Behavior == .ModalDialog);
		Test.Assert(popup.IsModal == true);
	}

	[Test]
	public static void PopupSetOffsets()
	{
		let popup = scope Popup();
		popup.HorizontalOffset = 10;
		popup.VerticalOffset = 20;
		Test.Assert(popup.HorizontalOffset == 10);
		Test.Assert(popup.VerticalOffset == 20);
	}

	[Test]
	public static void PopupOpenClose()
	{
		let context = scope GUIContext();
		let root = new Panel();
		context.RootElement = root;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		let popup = scope Popup();

		bool openedFired = false;
		bool closedFired = false;
		delegate void(Popup) openHandler = new [&] (p) => { openedFired = true; };
		delegate void(Popup) closeHandler = new [&] (p) => { closedFired = true; };
		popup.Opened.Subscribe(openHandler);
		popup.Closed.Subscribe(closeHandler);

		// Use OpenAt with context (all open methods now require context or element)
		popup.OpenAt(context, 0, 0);
		Test.Assert(popup.IsOpen == true);
		Test.Assert(popup.Visibility == .Visible);
		Test.Assert(openedFired == true);

		popup.Close();
		Test.Assert(popup.IsOpen == false);
		Test.Assert(popup.Visibility == .Collapsed);
		Test.Assert(closedFired == true);

		popup.Opened.Unsubscribe(openHandler);
		popup.Closed.Unsubscribe(closeHandler);

		context.RootElement = null;
		delete root;
	}

	[Test]
	public static void PopupOpenAt()
	{
		let context = scope GUIContext();
		let root = new Panel();
		context.RootElement = root;
		context.SetViewportSize(800, 600);
		context.Update(0, 0);

		let popup = scope Popup();

		// Use the context-accepting overload for absolute positioning
		popup.OpenAt(context, 100, 200);
		Test.Assert(popup.IsOpen == true);
		Test.Assert(popup.Placement == .Absolute);
		Test.Assert(popup.HorizontalOffset == 100);
		Test.Assert(popup.VerticalOffset == 200);

		popup.Close();

		context.RootElement = null;
		delete root;
	}

	[Test]
	public static void PopupOpenAtAnchor()
	{
		let context = scope GUIContext();
		let root = new Panel();
		context.RootElement = root;
		context.SetViewportSize(800, 600);

		let anchor = new Button();
		anchor.Width = .Fixed(100);
		anchor.Height = .Fixed(30);
		root.AddChild(anchor);
		context.Update(0, 0);

		let popup = scope Popup();

		// OpenAt(anchor) automatically gets context from anchor - no manual OnAttachedToContext needed
		popup.OpenAt(anchor, .Bottom);
		Test.Assert(popup.IsOpen == true);
		Test.Assert(popup.Anchor == anchor);
		Test.Assert(popup.Placement == .Bottom);

		popup.Close();

		// After close, anchor should be cleared
		Test.Assert(popup.Anchor == null);

		context.RootElement = null;
		delete root;
	}

	[Test]
	public static void PopupWithContent()
	{
		let popup = scope Popup();
		let content = new TextBlock();
		content.Text = "Popup Content";
		popup.Content = content;

		Test.Assert(popup.HasContent == true);
		Test.Assert(popup.Content == content);

		// Note: Setting Content to null deletes the old content, so no manual delete needed
		popup.Content = null;
		Test.Assert(popup.HasContent == false);
	}

	[Test]
	public static void PopupPlacementEnumValues()
	{
		// Verify all placement values exist
		Test.Assert(PopupPlacement.Bottom == .Bottom);
		Test.Assert(PopupPlacement.BottomCenter == .BottomCenter);
		Test.Assert(PopupPlacement.Top == .Top);
		Test.Assert(PopupPlacement.TopCenter == .TopCenter);
		Test.Assert(PopupPlacement.Left == .Left);
		Test.Assert(PopupPlacement.Right == .Right);
		Test.Assert(PopupPlacement.Mouse == .Mouse);
		Test.Assert(PopupPlacement.Absolute == .Absolute);
		Test.Assert(PopupPlacement.Center == .Center);
	}

	[Test]
	public static void PopupBehaviorFlags()
	{
		// Test individual flags
		let behavior = PopupBehavior.CloseOnClickOutside | .CloseOnEscape;
		Test.Assert(behavior.HasFlag(.CloseOnClickOutside));
		Test.Assert(behavior.HasFlag(.CloseOnEscape));
		Test.Assert(!behavior.HasFlag(.Modal));

		// Test preset
		Test.Assert(PopupBehavior.Default.HasFlag(.CloseOnClickOutside));
		Test.Assert(PopupBehavior.Default.HasFlag(.CloseOnEscape));
		Test.Assert(PopupBehavior.ModalDialog.HasFlag(.Modal));
	}
}
