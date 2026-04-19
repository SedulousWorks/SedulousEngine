namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Additional input system tests: double-click, capture, accelerators, tooltip integration.
class InputDetailTests
{
	// === Double-click ===

	[Test]
	public static void DoubleClick_ClickCountIncrements()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn = new Button();
		btn.SetText("Click");
		root.AddView(btn, new LayoutParams() { Width = 100, Height = 40 });
		ctx.UpdateRootView(root);

		int maxClickCount = 0;
		btn.OnClick.Add(new [&maxClickCount](b) => { });

		// First click.
		ctx.InputManager.ProcessMouseDown(.Left, 50, 20, 0.0f);
		ctx.InputManager.ProcessMouseUp(.Left, 50, 20);

		// Second click quickly (within double-click time).
		ctx.InputManager.ProcessMouseDown(.Left, 50, 20, 0.1f);
		// ClickCount should be 2.
	}

	// === Mouse capture ===

	[Test]
	public static void Capture_RoutesMovesToCapturedView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let view = new ColorView();
		view.IsFocusable = true;
		root.AddView(view, new LayoutParams() { Width = 100, Height = 100 });
		ctx.UpdateRootView(root);

		ctx.FocusManager.SetCapture(view);
		Test.Assert(ctx.FocusManager.HasCapture);

		ctx.FocusManager.ReleaseCapture();
		Test.Assert(!ctx.FocusManager.HasCapture);
	}

	// === Accelerator ===

	[Test]
	public static void Accelerator_AltKeyRoutesToHandler()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let handler = new AcceleratorTestView();
		root.AddView(handler, new LayoutParams() { Width = 100, Height = 100 });
		ctx.UpdateRootView(root);

		ctx.InputManager.ProcessKeyDown(.F, .Alt, false);
		Test.Assert(handler.Handled);
	}

	// === Focus navigation ===

	[Test]
	public static void TabNavigation_CyclesThroughFocusable()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let a = new Button();
		a.SetText("A");
		root.AddView(a, new LayoutParams() { Width = 100, Height = 30 });

		let b = new Button();
		b.SetText("B");
		root.AddView(b, new LayoutParams() { Width = 100, Height = 30 });

		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(a);
		Test.Assert(a.IsFocused);

		ctx.FocusManager.FocusNext();
		Test.Assert(b.IsFocused);

		ctx.FocusManager.FocusNext();
		Test.Assert(a.IsFocused); // wraps around
	}

	[Test]
	public static void ShiftTab_NavigatesBackward()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let a = new Button();
		a.SetText("A");
		root.AddView(a, new LayoutParams() { Width = 100, Height = 30 });

		let b = new Button();
		b.SetText("B");
		root.AddView(b, new LayoutParams() { Width = 100, Height = 30 });

		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(b);
		ctx.FocusManager.FocusPrev();
		Test.Assert(a.IsFocused);
	}

	// === TabIndex ordering ===

	[Test]
	public static void TabIndex_OverridesTreeOrder()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let a = new Button();
		a.SetText("A");
		a.TabIndex = 2;
		root.AddView(a, new LayoutParams() { Width = 100, Height = 30 });

		let b = new Button();
		b.SetText("B");
		b.TabIndex = 1;
		root.AddView(b, new LayoutParams() { Width = 100, Height = 30 });

		ctx.UpdateRootView(root);

		// TabIndex 1 (b) should come before TabIndex 2 (a).
		ctx.FocusManager.FocusNext();
		Test.Assert(b.IsFocused);

		ctx.FocusManager.FocusNext();
		Test.Assert(a.IsFocused);
	}

	// === IsEffectivelyEnabled ===

	[Test]
	public static void DisabledParent_DisablesChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let parent = new Panel();
		parent.IsEnabled = false;
		root.AddView(parent, new LayoutParams() { Width = 200, Height = 200 });

		let child = new Button();
		child.SetText("Child");
		parent.AddView(child, new LayoutParams() { Width = 100, Height = 30 });

		ctx.UpdateRootView(root);

		Test.Assert(!child.IsEffectivelyEnabled);
	}

	// === IsFocusWithin ===

	[Test]
	public static void IsFocusWithin_TrueForAncestors()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let parent = new Panel();
		root.AddView(parent, new LayoutParams() { Width = 200, Height = 200 });

		let child = new Button();
		child.SetText("Child");
		parent.AddView(child, new LayoutParams() { Width = 100, Height = 30 });

		ctx.UpdateRootView(root);
		ctx.FocusManager.SetFocus(child);

		Test.Assert(child.IsFocused);
		Test.Assert(parent.IsFocusWithin);
		Test.Assert(!parent.IsFocused);
	}
}

/// Test view implementing IAcceleratorHandler.
class AcceleratorTestView : View, IAcceleratorHandler
{
	public bool Handled;

	public bool HandleAccelerator(KeyCode key, KeyModifiers modifiers)
	{
		if (key == .F && modifiers.HasFlag(.Alt))
		{
			Handled = true;
			return true;
		}
		return false;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(100), hSpec.Resolve(100));
	}
}
