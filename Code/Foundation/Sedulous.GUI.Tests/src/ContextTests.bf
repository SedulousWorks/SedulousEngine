using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// GUIContext: one GUI of several roots (windows, render targets). Its roots share the clock, the
/// deferred edits, one bindings flush a frame, the data, the commands and keymap, and the element
/// table; the active root (the one last given input) takes keystrokes and decides command
/// availability; every root is made in one.
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

	[Test]
	public static void ARootsAnimationsPauseOrSlowOnTheSharedClock()
	{
		let gui = new GUIContext();
		defer gui.ReleaseRef();
		let hud = new SceneRoot(gui);
		defer hud.ReleaseRef();
		let menu = new SceneRoot(gui);
		defer menu.ReleaseRef();
		hud.Size = .(200.0f, 200.0f);
		menu.Size = .(200.0f, 200.0f);
		let a = new Node();
		defer a.ReleaseRef();
		let b = new Node();
		defer b.ReleaseRef();
		hud.AddChild(a);
		menu.AddChild(b);
		let aMoves = a.Animate("x", "100", 1.0f, "linear");
		defer aMoves.ReleaseRef();
		let bMoves = b.Animate("x", "100", 1.0f, "linear");
		defer bMoves.ReleaseRef();
		menu.Paused = true; // the game paused under its menu: the menu's own root keeps going
		gui.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(NodeFixtures.Near(a.Position.X, 50.0f));
		Test.Assert(NodeFixtures.Near(b.Position.X, 0.0f));
		menu.Paused = false;
		menu.TimeScale = 0.5f;
		gui.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(NodeFixtures.Near(b.Position.X, 25.0f)); // half speed
	}

	[Test]
	public static void TheActiveRootFollowsInputAndTakesCommandsAndKeystrokes()
	{
		let gui = new GUIContext();
		defer gui.ReleaseRef();
		var hud = new SceneRoot(gui);
		defer { hud?.ReleaseRef(); }
		let menu = new SceneRoot(gui);
		defer menu.ReleaseRef();
		hud.Size = .(200.0f, 200.0f);
		menu.Size = .(200.0f, 200.0f);
		let inHud = new Button();
		defer inHud.ReleaseRef();
		let inMenu = new Button();
		defer inMenu.ReleaseRef();
		inHud.Size = .(40.0f, 20.0f);
		inMenu.Size = .(40.0f, 20.0f);
		hud.AddChild(inHud);
		menu.AddChild(inMenu);
		hud.EventDispatcher.FocusNode = inHud;
		menu.EventDispatcher.FocusNode = inMenu;
		int menuBacks = 0;
		int hudBacks = 0;
		inMenu.OnCommand("back", new [&] (command) => { menuBacks++; });
		inHud.OnCommand("back", new [&] (command) => { hudBacks++; });
		Test.Assert(gui.Keymap.Bind("escape", "back"));

		// A toolbar button in the HUD bound to "back" follows the active root's focus path.
		let toolbar = new Button();
		defer toolbar.ReleaseRef();
		hud.AddChild(toolbar);
		toolbar.Command = "back";
		menu.EventDispatcher.InjectKeyDown((uint32)KeyCode.Escape); // input in the menu
		Test.Assert(gui.ActiveRoot == menu);
		Test.Assert(menuBacks == 1);
		Test.Assert(hudBacks == 0);
		Test.Assert(gui.RunCommand("back"));
		Test.Assert(menuBacks == 2);

		hud.EventDispatcher.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(gui.ActiveRoot == hud);
		Test.Assert(hudBacks == 1);

		// A root going away leaves the context; the active root falls back to the first.
		hud.ReleaseRef();
		hud = null;
		Test.Assert(gui.RootCount == 1);
		Test.Assert(gui.ActiveRoot == menu);
	}
}
