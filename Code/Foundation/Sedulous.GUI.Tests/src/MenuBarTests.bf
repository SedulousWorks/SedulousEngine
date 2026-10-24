using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A menu bar (2 menus) under a scene root, ready to receive input. No font is set, so each button
/// is 2 * padding (24px) wide and the bar is its bar height tall - a deterministic layout. The root
/// and the bar go with it.
class MenuBarBed
{
	public SceneRoot Root = SceneFixtures.NewScene(600.0f, 400.0f) ~ _.ReleaseRef();
	public MenuBar Bar = new .() ~ _.ReleaseRef();
	public Menu FileMenu;
	public Menu EditMenu;

	public this()
	{
		Bar.SetBarHeight(28.0f);
		Bar.SetItemPadding(12.0f); // each button is 24px wide with no font
		Root.AddChild(Bar);
		FileMenu = Bar.AddMenu("File");
		FileMenu.AddItem("Open", new () => { });
		EditMenu = Bar.AddMenu("Edit");
		EditMenu.AddItem("Copy", new () => { });
	}

	public EventDispatcher D => Root.EventDispatcher;
}

/// The menu bar: a horizontal strip of buttons, each opening a Menu below it. Clicking a button
/// toggles its menu; while one is open, hovering another button switches to it; an outside click
/// dismisses and clears the bar's state.
class MenuBarTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void BuildsAButtonPerMenuAndLaysThemOutHorizontally()
	{
		let bed = scope MenuBarBed();
		Test.Assert(bed.Bar.MenuCount == 2);
		Test.Assert(Near(bed.Bar.ButtonAt(0).Position.X, 0.0f));
		Test.Assert(Near(bed.Bar.ButtonAt(0).Size.X, 24.0f)); // 2 * padding
		Test.Assert(Near(bed.Bar.ButtonAt(1).Position.X, 24.0f));
		Test.Assert(Near(bed.Bar.Size.Y, 28.0f));
	}

	[Test]
	public static void ClickingAButtonOpensItsMenuBelowTheButton()
	{
		let bed = scope MenuBarBed();
		let d = bed.D;

		// Click "File" (button 0, centered at x=12, y=14).
		d.InjectMouseDown(.(12.0f, 14.0f), .Left);
		d.InjectMouseUp(.(12.0f, 14.0f), .Left);

		Test.Assert(bed.Bar.CurrentMenu == bed.FileMenu);
		Test.Assert(bed.FileMenu.IsOpen);
		Test.Assert(bed.FileMenu.Parent == bed.Bar.ButtonAt(0)); // a popup of its button
		Test.Assert(Near(bed.FileMenu.Position.X, 0.0f));
		Test.Assert(Near(bed.FileMenu.Position.Y, 28.0f)); // below the bar
	}

	[Test]
	public static void ClickingTheOpenButtonAgainTogglesTheMenuClosed()
	{
		let bed = scope MenuBarBed();
		let d = bed.D;

		d.InjectMouseDown(.(12.0f, 14.0f), .Left);
		d.InjectMouseUp(.(12.0f, 14.0f), .Left);
		Test.Assert(bed.Bar.CurrentMenu == bed.FileMenu);

		// A second click on the same button closes it (the button is the popup owner, so the
		// press does not dismiss before the toggle runs).
		d.InjectMouseDown(.(12.0f, 14.0f), .Left);
		d.InjectMouseUp(.(12.0f, 14.0f), .Left);
		Test.Assert(bed.Bar.CurrentMenu == null);
		Test.Assert(!bed.FileMenu.IsOpen);
	}

	[Test]
	public static void WithAMenuOpenHoveringAnotherButtonSwitchesToIt()
	{
		let bed = scope MenuBarBed();
		let d = bed.D;

		d.InjectMouseDown(.(12.0f, 14.0f), .Left); // open File
		d.InjectMouseUp(.(12.0f, 14.0f), .Left);
		Test.Assert(bed.Bar.CurrentMenu == bed.FileMenu);

		// Hover "Edit" (button 1, centered at x=36) - switches without a click.
		d.InjectMouseMove(.(36.0f, 14.0f));
		Test.Assert(bed.Bar.CurrentMenu == bed.EditMenu);
		Test.Assert(bed.EditMenu.IsOpen);
		Test.Assert(!bed.FileMenu.IsOpen);
		Test.Assert(bed.FileMenu.Parent == null);
	}

	[Test]
	public static void HoveringAButtonWithNothingOpenDoesNotOpenAMenu()
	{
		let bed = scope MenuBarBed();
		bed.D.InjectMouseMove(.(12.0f, 14.0f)); // bare hover over "File"
		Test.Assert(bed.Bar.CurrentMenu == null);
		Test.Assert(!bed.FileMenu.IsOpen);
	}

	[Test]
	public static void AnOutsideClickDismissesTheOpenMenuAndClearsTheBarState()
	{
		let bed = scope MenuBarBed();
		let d = bed.D;

		d.InjectMouseDown(.(12.0f, 14.0f), .Left);
		d.InjectMouseUp(.(12.0f, 14.0f), .Left);
		Test.Assert(bed.FileMenu.IsOpen);

		d.InjectMouseDown(.(300.0f, 300.0f), .Left); // far outside
		Test.Assert(bed.Bar.CurrentMenu == null);
		Test.Assert(!bed.FileMenu.IsOpen);
		Test.Assert(bed.FileMenu.Parent == null);
	}
}
