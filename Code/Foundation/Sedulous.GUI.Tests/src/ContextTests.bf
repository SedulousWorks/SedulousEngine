using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// GUIContext: one GUI of several roots (windows, render targets). Its roots share the clock, the
/// deferred edits, one bindings flush a frame, the data, the commands and keymap, and the element
/// table; every root is made in one.
class ContextTests
{
	[Test]
	public static void AGUIOfOneRootIsAContextWithOne()
	{
		let gui = new GUIContext();
		defer gui.ReleaseRef();
		Test.Assert(gui.RootCount == 0);
		Test.Assert(gui.ActiveRoot == null);
		let root = new SceneRoot(gui);
		defer root.ReleaseRef();
		Test.Assert(gui.RootCount == 1);
		Test.Assert(gui.ActiveRoot == root); // the first, until input picks another
		Test.Assert(root.Context == gui);
	}

	[Test]
	public static void OneUpdateAdvancesEveryRootAndDrainsTheirDeferredEdits()
	{
		let gui = new GUIContext();
		defer gui.ReleaseRef();
		let a = new CountingScene(gui);
		defer a.ReleaseRef();
		let b = new CountingScene(gui);
		defer b.ReleaseRef();
		let doomed = new Node();
		defer doomed.ReleaseRef();
		b.AddChild(doomed);
		doomed.Close();
		gui.Update(SceneFixtures.Frame); // the GUI's one update
		Test.Assert(a.Ticks == 1);
		Test.Assert(b.Ticks == 1);
		Test.Assert(b.ChildCount == 0);
	}

	[Test]
	public static void AHandleSurvivesItsNodeMovingBetweenRoots()
	{
		let gui = new GUIContext();
		defer gui.ReleaseRef();
		let hud = new SceneRoot(gui);
		defer hud.ReleaseRef();
		let menu = new SceneRoot(gui);
		defer menu.ReleaseRef();
		hud.Size = .(200.0f, 200.0f);
		menu.Size = .(200.0f, 200.0f);
		let panel = new UIWidget();
		defer panel.ReleaseRef();
		hud.AddChild(panel);
		let before = panel.TakeElementRef();
		hud.RemoveChild(panel);
		menu.AddChild(panel); // docked into the other window
		let after = panel.TakeElementRef();
		Test.Assert(before.Table == after.Table);
		Test.Assert(before.Slot == after.Slot);
		Test.Assert(after.Table.Resolve(after.Slot, after.Generation) == panel);
	}
}
