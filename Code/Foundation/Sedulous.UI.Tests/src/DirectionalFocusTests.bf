namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class DirectionalFocusTests
{
	[Test]
	public static void MoveFocus_Down()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let top = new Button("Top");
		let bottom = new Button("Bottom");
		root.AddView(top);
		root.AddView(bottom);

		top.Layout(100, 50, 100, 30);
		bottom.Layout(100, 150, 100, 30);

		ctx.FocusManager.SetFocus(top);
		Test.Assert(ctx.FocusManager.FocusedView === top);

		let moved = ctx.FocusManager.MoveFocus(.Down);
		Test.Assert(moved);
		Test.Assert(ctx.FocusManager.FocusedView === bottom);
	}

	[Test]
	public static void MoveFocus_Up()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let top = new Button("Top");
		let bottom = new Button("Bottom");
		root.AddView(top);
		root.AddView(bottom);

		top.Layout(100, 50, 100, 30);
		bottom.Layout(100, 150, 100, 30);

		ctx.FocusManager.SetFocus(bottom);
		let moved = ctx.FocusManager.MoveFocus(.Up);
		Test.Assert(moved);
		Test.Assert(ctx.FocusManager.FocusedView === top);
	}

	[Test]
	public static void MoveFocus_LeftRight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let left = new Button("Left");
		let right = new Button("Right");
		root.AddView(left);
		root.AddView(right);

		left.Layout(50, 100, 100, 30);
		right.Layout(250, 100, 100, 30);

		ctx.FocusManager.SetFocus(left);
		let moved = ctx.FocusManager.MoveFocus(.Right);
		Test.Assert(moved);
		Test.Assert(ctx.FocusManager.FocusedView === right);

		let movedBack = ctx.FocusManager.MoveFocus(.Left);
		Test.Assert(movedBack);
		Test.Assert(ctx.FocusManager.FocusedView === left);
	}

	[Test]
	public static void MoveFocus_NoCandidate()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let only = new Button("Only");
		root.AddView(only);
		only.Layout(100, 100, 100, 30);

		ctx.FocusManager.SetFocus(only);
		let moved = ctx.FocusManager.MoveFocus(.Down);
		Test.Assert(!moved);
		Test.Assert(ctx.FocusManager.FocusedView === only); // unchanged
	}

	[Test]
	public static void MoveFocus_PrefersClosest()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let top = new Button("Top");
		let nearBottom = new Button("Near");
		let farBottom = new Button("Far");
		root.AddView(top);
		root.AddView(nearBottom);
		root.AddView(farBottom);

		top.Layout(100, 50, 100, 30);
		nearBottom.Layout(100, 120, 100, 30); // closer
		farBottom.Layout(100, 300, 100, 30); // farther

		ctx.FocusManager.SetFocus(top);
		ctx.FocusManager.MoveFocus(.Down);
		Test.Assert(ctx.FocusManager.FocusedView === nearBottom);
	}

	[Test]
	public static void MoveFocus_ExplicitOverride()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let a = new Button("A");
		let b = new Button("B");
		let c = new Button("C");
		root.AddView(a);
		root.AddView(b);
		root.AddView(c);

		a.Layout(100, 50, 100, 30);
		b.Layout(100, 150, 100, 30); // spatially below A
		c.Layout(300, 300, 100, 30); // far away

		// Explicit override: A's down goes to C, not B
		a.NextFocusDown = c.Id;

		ctx.FocusManager.SetFocus(a);
		ctx.FocusManager.MoveFocus(.Down);
		Test.Assert(ctx.FocusManager.FocusedView === c);
	}

	[Test]
	public static void MoveFocus_NoFocused_ReturnsFalse()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		root.AddView(new Button("A"));
		let moved = ctx.FocusManager.MoveFocus(.Down);
		Test.Assert(!moved);
	}

	// === OnActivate ===

	[Test]
	public static void OnActivate_ButtonFiresClick()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let btn = new Button("Test");
		root.AddView(btn);
		bool clicked = false;
		btn.OnClick.Add(new [&clicked] (b) => { clicked = true; });

		btn.OnActivate();
		Test.Assert(clicked);
	}

	[Test]
	public static void OnActivate_CheckBoxToggles()
	{
		let cb = scope CheckBox("Test");
		Test.Assert(!cb.IsChecked.Value);
		cb.OnActivate();
		Test.Assert(cb.IsChecked.Value);
		cb.OnActivate();
		Test.Assert(!cb.IsChecked.Value);
	}

	[Test]
	public static void OnActivate_ToggleSwitchToggles()
	{
		let ts = scope ToggleSwitch("Test");
		Test.Assert(!ts.IsChecked.Value);
		ts.OnActivate();
		Test.Assert(ts.IsChecked.Value);
	}

	[Test]
	public static void OnActivate_RadioButtonSelects()
	{
		let rb = scope RadioButton("Test");
		Test.Assert(!rb.IsChecked.Value);
		rb.OnActivate();
		Test.Assert(rb.IsChecked.Value);
	}

	// === WantsArrowKeys ===

	[Test]
	public static void WantsArrowKeys_EditTextTrue()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		root.AddView(edit);
		Test.Assert(edit.WantsArrowKeys);
	}

	[Test]
	public static void WantsArrowKeys_NumericFieldTrue()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let nf = new NumericField();
		root.AddView(nf);
		Test.Assert(nf.WantsArrowKeys);
	}

	[Test]
	public static void WantsArrowKeys_ButtonFalse()
	{
		let btn = scope Button("Test");
		Test.Assert(!btn.WantsArrowKeys);
	}

	// === OnCancel ===

	[Test]
	public static void OnCancel_BubblesToParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		bool parentCancelCalled = false;
		let parent = new CancelTrackingGroup();
		parent.OnCancelCalled = new [&parentCancelCalled] () => { parentCancelCalled = true; };
		let child = new Button("Child");
		parent.AddView(child);
		root.AddView(parent);

		child.OnCancel();
		Test.Assert(parentCancelCalled);
	}
}

class CancelTrackingGroup : ViewGroup
{
	public delegate void() OnCancelCalled ~ delete _;

	public override void OnCancel()
	{
		OnCancelCalled?.Invoke();
	}

	protected override void OnLayout(float left, float top, float width, float height) { }
}
