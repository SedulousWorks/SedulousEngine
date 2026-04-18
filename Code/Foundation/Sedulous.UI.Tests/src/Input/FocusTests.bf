namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class FocusTests
{
	[Test]
	public static void Focus_SetAndClear()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let btn = new Button();
		btn.SetText("A");
		layout.AddView(btn);

		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(btn);
		Test.Assert(btn.IsFocused);

		ctx.FocusManager.ClearFocus();
		Test.Assert(!btn.IsFocused);
	}

	[Test]
	public static void FocusNext_CyclesThroughFocusable()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new Button(); a.SetText("A");
		let b = new Button(); b.SetText("B");
		let c = new Button(); c.SetText("C");
		layout.AddView(a);
		layout.AddView(b);
		layout.AddView(c);

		ctx.UpdateRootView(root);

		// No focus -> FocusNext selects first.
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === a);

		// Next -> B.
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === b);

		// Next -> C.
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === c);

		// Next wraps -> A.
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === a);
	}

	[Test]
	public static void FocusPrev_CyclesBackward()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new Button(); a.SetText("A");
		let b = new Button(); b.SetText("B");
		layout.AddView(a);
		layout.AddView(b);

		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(a);

		// Prev from A wraps to B.
		ctx.FocusManager.FocusPrev();
		Test.Assert(ctx.FocusManager.FocusedView === b);
	}

	[Test]
	public static void IsFocusWithin_TrueForAncestors()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let btn = new Button(); btn.SetText("X");
		layout.AddView(btn);

		ctx.UpdateRootView(root);
		ctx.FocusManager.SetFocus(btn);

		Test.Assert(btn.IsFocusWithin);
		Test.Assert(layout.IsFocusWithin);
		Test.Assert(root.IsFocusWithin);
	}

	[Test]
	public static void Disabled_SkippedInTabOrder()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		root.AddView(layout);

		let a = new Button(); a.SetText("A");
		let b = new Button(); b.SetText("B"); b.IsEnabled = false;
		let c = new Button(); c.SetText("C");
		layout.AddView(a);
		layout.AddView(b);
		layout.AddView(c);

		ctx.UpdateRootView(root);

		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === a);

		// Skip disabled B -> go to C.
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === c);
	}

	[Test]
	public static void HandleSurvivesViewDeletion()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new LinearLayout();
		root.AddView(layout);

		let btn = new Button(); btn.SetText("X");
		layout.AddView(btn);
		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(btn);
		Test.Assert(ctx.FocusManager.FocusedView === btn);

		// Destroy the button.
		layout.RemoveView(btn, true);

		// Focus should be null, not a dangling pointer.
		Test.Assert(ctx.FocusManager.FocusedView == null);
	}
}
