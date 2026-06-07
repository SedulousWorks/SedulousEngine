namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class ShortcutManagerTests
{
	[Test]
	public static void Global_Fires()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		bool fired = false;
		ctx.Shortcuts.AddGlobal(.S, .Ctrl, new [&fired] () => { fired = true; });

		let result = ctx.Shortcuts.TryDispatch(.S, .LeftCtrl);
		Test.Assert(fired);
		Test.Assert(result);
	}

	[Test]
	public static void Global_WrongKey_DoesNotFire()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		bool fired = false;
		ctx.Shortcuts.AddGlobal(.S, .Ctrl, new [&fired] () => { fired = true; });

		let result = ctx.Shortcuts.TryDispatch(.D, .LeftCtrl);
		Test.Assert(!fired);
		Test.Assert(!result);
	}

	[Test]
	public static void Global_WrongModifiers_DoesNotFire()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		bool fired = false;
		ctx.Shortcuts.AddGlobal(.S, .Ctrl, new [&fired] () => { fired = true; });

		let result = ctx.Shortcuts.TryDispatch(.S, .None);
		Test.Assert(!fired);
		Test.Assert(!result);
	}

	[Test]
	public static void Scoped_FiresWhenInScope()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let panel = new TestGroup();
		let child = new TestView();
		child.IsFocusable = true;
		root.AddView(panel);
		panel.AddView(child);

		bool fired = false;
		ctx.Shortcuts.AddScoped(.Delete, .None, new [&fired] () => { fired = true; }, panel);

		ctx.FocusManager.SetFocus(child); // child is in scope of panel
		let result = ctx.Shortcuts.TryDispatch(.Delete, .None);
		Test.Assert(fired);
		Test.Assert(result);
	}

	[Test]
	public static void Scoped_DoesNotFireWhenOutOfScope()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let panelA = new TestGroup();
		let panelB = new TestGroup();
		let child = new TestView();
		child.IsFocusable = true;
		root.AddView(panelA);
		root.AddView(panelB);
		panelB.AddView(child);

		bool fired = false;
		ctx.Shortcuts.AddScoped(.Delete, .None, new [&fired] () => { fired = true; }, panelA);

		ctx.FocusManager.SetFocus(child); // child is in panelB, not panelA
		let result = ctx.Shortcuts.TryDispatch(.Delete, .None);
		Test.Assert(!fired);
		Test.Assert(!result);
	}

	[Test]
	public static void Remove_StopsShortcut()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		bool fired = false;
		let shortcut = ctx.Shortcuts.AddGlobal(.Z, .Ctrl, new [&fired] () => { fired = true; });
		ctx.Shortcuts.Remove(shortcut);

		let result = ctx.Shortcuts.TryDispatch(.Z, .LeftCtrl);
		Test.Assert(!fired);
		Test.Assert(!result);
	}

	[Test]
	public static void ScopedRemoved_OnViewDelete()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let panel = new TestGroup();
		root.AddView(panel);

		bool fired = false;
		ctx.Shortcuts.AddScoped(.F2, .None, new [&fired] () => { fired = true; }, panel);

		// Delete panel - should auto-remove scoped shortcuts
		root.RemoveView(panel, true);

		let result = ctx.Shortcuts.TryDispatch(.F2, .None);
		Test.Assert(!fired);
		Test.Assert(!result);
	}

	[Test]
	public static void Scoped_PriorityOverGlobal()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let panel = new TestGroup();
		let child = new TestView();
		child.IsFocusable = true;
		root.AddView(panel);
		panel.AddView(child);

		bool globalFired = false;
		bool scopedFired = false;
		ctx.Shortcuts.AddGlobal(.S, .Ctrl, new [&globalFired] () => { globalFired = true; });
		ctx.Shortcuts.AddScoped(.S, .Ctrl, new [&scopedFired] () => { scopedFired = true; }, panel);

		ctx.FocusManager.SetFocus(child);
		ctx.Shortcuts.TryDispatch(.S, .LeftCtrl);

		// Scoped should win
		Test.Assert(scopedFired);
		Test.Assert(!globalFired);
	}
}
