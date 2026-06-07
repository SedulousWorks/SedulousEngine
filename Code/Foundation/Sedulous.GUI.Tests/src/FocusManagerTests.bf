namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class FocusManagerTests
{
	[Test]
	public static void SetFocus_ViewBecomesFocused()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		view.IsFocusable = true;
		root.AddView(view);

		ctx.FocusManager.SetFocus(view);
		Test.Assert(view.IsFocused);
		Test.Assert(ctx.FocusManager.FocusedView === view);
	}

	[Test]
	public static void SetFocus_OldViewLosesFocus()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let a = new TestView();
		a.IsFocusable = true;
		let b = new TestView();
		b.IsFocusable = true;
		root.AddView(a);
		root.AddView(b);

		ctx.FocusManager.SetFocus(a);
		Test.Assert(a.IsFocused);

		ctx.FocusManager.SetFocus(b);
		Test.Assert(!a.IsFocused);
		Test.Assert(b.IsFocused);
	}

	[Test]
	public static void ClearFocus_NoViewFocused()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		view.IsFocusable = true;
		root.AddView(view);

		ctx.FocusManager.SetFocus(view);
		ctx.FocusManager.ClearFocus();
		Test.Assert(!view.IsFocused);
		Test.Assert(ctx.FocusManager.FocusedView == null);
	}

	[Test]
	public static void PushPop_RestoresFocus()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		view.IsFocusable = true;
		root.AddView(view);

		ctx.FocusManager.SetFocus(view);
		ctx.FocusManager.PushFocus();
		Test.Assert(ctx.FocusManager.FocusedView == null);

		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusedView === view);
	}

	[Test]
	public static void PushPop_StackDepth()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let a = new TestView(); a.IsFocusable = true;
		let b = new TestView(); b.IsFocusable = true;
		root.AddView(a);
		root.AddView(b);

		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);

		ctx.FocusManager.SetFocus(a);
		ctx.FocusManager.PushFocus();
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);
		Test.Assert(ctx.FocusManager.FocusedView == null);

		ctx.FocusManager.SetFocus(b);
		ctx.FocusManager.PushFocus();
		Test.Assert(ctx.FocusManager.FocusStackDepth == 2);
		Test.Assert(ctx.FocusManager.FocusedView == null);

		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);
		Test.Assert(ctx.FocusManager.FocusedView === b);

		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);
		Test.Assert(ctx.FocusManager.FocusedView === a);
	}

	[Test]
	public static void PushPop_SkipsDeletedView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		view.IsFocusable = true;
		root.AddView(view);

		ctx.FocusManager.SetFocus(view);
		ctx.FocusManager.PushFocus();

		// Delete the view while focus is pushed
		root.RemoveView(view, true);

		// Pop should skip the dead ViewId
		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusedView == null);
	}

	[Test]
	public static void Capture_SetAndRelease()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		ctx.FocusManager.SetCapture(view);
		Test.Assert(ctx.FocusManager.HasCapture);
		Test.Assert(ctx.FocusManager.CapturedView === view);

		ctx.FocusManager.ReleaseCapture();
		Test.Assert(!ctx.FocusManager.HasCapture);
	}

	[Test]
	public static void OnViewDeleted_ClearsFocusAndCapture()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		view.IsFocusable = true;
		root.AddView(view);

		ctx.FocusManager.SetFocus(view);
		ctx.FocusManager.SetCapture(view);

		root.RemoveView(view, true); // triggers Unregister -> OnViewDeleted

		Test.Assert(ctx.FocusManager.FocusedView == null);
		Test.Assert(!ctx.FocusManager.HasCapture);
	}

	[Test]
	public static void FocusNext_CyclesThroughTabStops()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let a = new TestView(); a.IsFocusable = true; a.IsTabStop = true;
		let b = new TestView(); b.IsFocusable = true; b.IsTabStop = true;
		let c = new TestView(); c.IsFocusable = true; c.IsTabStop = true;
		root.AddView(a);
		root.AddView(b);
		root.AddView(c);

		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === a);

		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === b);

		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === c);

		ctx.FocusManager.FocusNext(); // wraps
		Test.Assert(ctx.FocusManager.FocusedView === a);
	}

	[Test]
	public static void FocusPrev_CyclesBackward()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let a = new TestView(); a.IsFocusable = true; a.IsTabStop = true;
		let b = new TestView(); b.IsFocusable = true; b.IsTabStop = true;
		root.AddView(a);
		root.AddView(b);

		ctx.FocusManager.SetFocus(a);
		ctx.FocusManager.FocusPrev(); // wraps to b
		Test.Assert(ctx.FocusManager.FocusedView === b);
	}

	[Test]
	public static void FocusNext_SkipsNonTabStop()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let a = new TestView(); a.IsFocusable = true; a.IsTabStop = true;
		let b = new TestView(); b.IsFocusable = true; b.IsTabStop = false;
		let c = new TestView(); c.IsFocusable = true; c.IsTabStop = true;
		root.AddView(a);
		root.AddView(b);
		root.AddView(c);

		ctx.FocusManager.SetFocus(a);
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedView === c); // skipped b
	}

	[Test]
	public static void IsFocusWithin_AncestorOfFocused()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		child.IsFocusable = true;
		root.AddView(group);
		group.AddView(child);

		ctx.FocusManager.SetFocus(child);
		Test.Assert(group.IsFocusWithin);
		Test.Assert(root.IsFocusWithin);
		Test.Assert(child.IsFocusWithin); // self counts
	}
}
