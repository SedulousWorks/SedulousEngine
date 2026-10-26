using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Menus: opening at a position as a popup, activating an item (runs the action and closes), and
/// dismissal (outside click / Escape) through the dispatcher's popups; separators, checkable items
/// and submenus, the safe area toward an open submenu, one row lit at a time, scrolling when taller
/// than the window.
class MenuTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// The centre of `node` on the screen.
	private static Float2 Centre(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	/// Whether `node` or one inside it is a menu item reading `text`.
	private static bool HasItemNamed(Node node, StringView text)
	{
		if (let item = node as MenuItem)
		{
			if (item.Text == text)
				return true;
		}
		for (int i = 0; i < node.ChildCount; ++i)
		{
			let child = node.GetChildAt(i);
			if ((child != null) && HasItemNamed(child, text))
				return true;
		}
		return false;
	}

	[Test]
	public static void SizesToItsItems()
	{
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(140.0f);
		menu.SetItemHeight(25.0f);
		menu.AddItem("Cut", new () => { });
		menu.AddItem("Copy", new () => { });
		menu.AddItem("Paste", new () => { });

		Test.Assert(menu.ItemCount == 3);
		Test.Assert(Near(menu.Size.X, 140.0f));
		Test.Assert(Near(menu.Size.Y, 75.0f)); // 3 * 25
	}

	[Test]
	public static void OpenShowsItAsTheDispatcherPopupAtTheGivenPosition()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		anchor.Size = .(10.0f, 10.0f);
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetItemHeight(26.0f);
		menu.AddItem("One", new () => { });
		menu.AddItem("Two", new () => { });

		menu.Open(anchor, .(100.0f, 80.0f));
		Test.Assert(menu.IsOpen);
		Test.Assert(d.TopPopup == menu);
		Test.Assert(Near(menu.Position.X, 100.0f));
		Test.Assert(Near(menu.Position.Y, 80.0f));
		Test.Assert(menu.Parent == anchor); // a popup of what opened it
	}

	[Test]
	public static void ActivatingAnItemRunsItsActionAndCloses()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		int cut = 0;
		int paste = 0;
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetItemHeight(26.0f);
		menu.AddItem("Cut", new [&] () => { ++cut; });
		menu.AddItem("Paste", new [&] () => { ++paste; });
		menu.Open(anchor, .(50.0f, 50.0f));

		// Item 1 (Paste) spans y in [50 + 26, 50 + 52) = [76, 102); click it.
		d.InjectMouseDown(.(60.0f, 88.0f), .Left);
		d.InjectMouseUp(.(60.0f, 88.0f), .Left);
		Test.Assert(paste == 1);
		Test.Assert(cut == 0);
		Test.Assert(!menu.IsOpen);
		Test.Assert(d.PopupCount == 0);
		Test.Assert(menu.Parent == null); // removed from the tree
	}

	[Test]
	public static void AnItemWhoseActionLetsGoOfItsMenuAndWhatHeldItOutlivesTheAction()
	{
		// The menu's only owner is let go by its item's own action, as a dock float's Move to menu is
		// when the move ends the float.
		var menu = new Menu();
		int ran = 0;
		let item = menu.AddItem("End", new [&] () =>
			{
				++ran;
				menu.ReleaseRef();
				menu = null;
			});
		Test.Assert(item.HandleActivate());
		Test.Assert(ran == 1);
		Test.Assert(menu == null);
	}

	[Test]
	public static void OutsideClickAndEscapeDismissIt()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.AddItem("One", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f));
		Test.Assert(menu.IsOpen);

		d.InjectMouseDown(.(300.0f, 300.0f), .Left); // outside
		Test.Assert(!menu.IsOpen);

		// Reopen and dismiss with Escape.
		menu.Open(anchor, .(50.0f, 50.0f));
		Test.Assert(menu.IsOpen);
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!menu.IsOpen);
	}

	[Test]
	public static void AnOutsideClickDismissesEvenWhenTheOpenerCoversTheClickPoint()
	{
		// Regression: the context menu was opened with the full-window panel as its popup owner,
		// so clicks anywhere on the panel counted as "on the owner" and never dismissed. A menu
		// has no persistent owner - any press outside the menu itself must close it.
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let panel = new UIWidget();
		defer panel.ReleaseRef();
		panel.Size = .(400.0f, 400.0f); // covers the whole area (like the sandbox panel)
		root.AddChild(panel);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetItemHeight(26.0f);
		menu.AddItem("One", new () => { });
		menu.Open(panel, .(50.0f, 50.0f));
		Test.Assert(menu.IsOpen);

		// Left-click on the panel, well away from the menu -> dismissed.
		d.InjectMouseDown(.(300.0f, 300.0f), .Left);
		Test.Assert(!menu.IsOpen);
		Test.Assert(d.PopupCount == 0);
	}

	[Test]
	public static void CanBeReopenedAfterBeingDismissed()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let panel = new UIWidget();
		defer panel.ReleaseRef();
		panel.Size = .(400.0f, 400.0f);
		root.AddChild(panel);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.AddItem("One", new () => { });

		menu.Open(panel, .(40.0f, 40.0f));
		Test.Assert(menu.IsOpen);
		d.InjectMouseDown(.(300.0f, 300.0f), .Left); // dismiss
		Test.Assert(!menu.IsOpen);

		// Reopen at a new position - must work and re-register as the popup.
		menu.Open(panel, .(120.0f, 90.0f));
		Test.Assert(menu.IsOpen);
		Test.Assert(d.TopPopup == menu);
		Test.Assert(menu.Parent == panel); // a popup of what opened it
		Test.Assert(Near(menu.Position.X, 120.0f));
	}

	// ===================== Depth: separators / checkable / submenus =====================

	[Test]
	public static void SeparatorsAreNonSelectableRowsThatAddHeight()
	{
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(140.0f);
		menu.SetItemHeight(26.0f);
		menu.AddItem("Open", new () => { });
		menu.AddSeparator();
		menu.AddItem("Quit", new () => { });

		Test.Assert(menu.RowCount == 3);
		Test.Assert(menu.ItemCount == 2); // the separator is not counted as an item
		Test.Assert(Near(menu.Size.Y, 26.0f + 9.0f + 26.0f)); // item + separator + item
	}

	[Test]
	public static void ACheckableItemTogglesCallsItsCallbackAndClosesTheMenu()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		bool state = false;
		int toggles = 0;
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetItemHeight(26.0f);
		let check = menu.AddCheckItem("Bold", false, new [&] (on) =>
			{
				state = on;
				++toggles;
			});
		menu.Open(anchor, .(50.0f, 50.0f));

		Test.Assert(!check.Checked);
		// Row 0 spans y in [50, 76); click it.
		d.InjectMouseDown(.(60.0f, 60.0f), .Left);
		d.InjectMouseUp(.(60.0f, 60.0f), .Left);
		Test.Assert(check.Checked);
		Test.Assert(state == true);
		Test.Assert(toggles == 1);
		Test.Assert(!menu.IsOpen); // menus close on activation
	}

	[Test]
	public static void ASubmenuOpensToTheRightOfItsItemOnHover()
	{
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f);
		menu.SetItemHeight(26.0f);
		menu.AddItem("Top", new () => { });
		let sub = menu.AddSubMenu("More");
		sub.AddItem("Deep", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f));

		Test.Assert(menu.CurrentSubMenu == null);
		// Hover the "More" row (row 1: y in [76, 102)).
		d.InjectMouseMove(.(60.0f, 88.0f));
		Test.Assert(menu.CurrentSubMenu == sub);
		Test.Assert(sub.IsOpen);
		Test.Assert(sub.Parent.Parent == menu); // a popup of its item, in the menu
		Test.Assert(Near(sub.Position.X, 210.0f)); // menu.x(50) + menu.width(160)
		Test.Assert(Near(sub.Position.Y, 76.0f)); // menu.y(50) + item.y(26)
	}

	[Test]
	public static void HoveringADifferentRowClosesTheOpenSubmenu()
	{
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f);
		menu.SetItemHeight(26.0f);
		menu.AddItem("Top", new () => { }); // row 0
		let sub = menu.AddSubMenu("More"); // row 1
		sub.AddItem("Deep", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f));

		d.InjectMouseMove(.(60.0f, 88.0f)); // open submenu (hover "More")
		Test.Assert(menu.CurrentSubMenu == sub);
		d.InjectMouseMove(.(60.0f, 60.0f)); // hover "Top" (row 0)
		Test.Assert(menu.CurrentSubMenu == null);
		Test.Assert(sub.Parent == null); // submenu removed from the tree
	}

	[Test]
	public static void ClickingInsideAnOpenSubmenuDoesNotDismissActivatingClosesTheWholeChain()
	{
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		int deep = 0;
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f);
		menu.SetItemHeight(26.0f);
		menu.AddItem("Top", new () => { });
		let sub = menu.AddSubMenu("More");
		sub.AddItem("Deep", new [&] () => { ++deep; });
		menu.Open(anchor, .(50.0f, 50.0f));

		d.InjectMouseMove(.(60.0f, 88.0f)); // open submenu
		Test.Assert(sub.IsOpen);

		// The submenu sits at x in [210, 370], its "Deep" row at y in [76, 102). A press there is
		// inside the chain -> the root menu must stay open (the popup 'contains' predicate).
		d.InjectMouseDown(.(260.0f, 88.0f), .Left);
		Test.Assert(menu.IsOpen);
		d.InjectMouseUp(.(260.0f, 88.0f), .Left);
		Test.Assert(deep == 1);
		Test.Assert(!menu.IsOpen); // the whole chain closed
		Test.Assert(menu.Parent == null);
		Test.Assert(sub.Parent == null);
		Test.Assert(d.PopupCount == 0);
	}

	[Test]
	public static void AnOutsideClickDismissesTheWholeOpenSubmenuChain()
	{
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f);
		menu.SetItemHeight(26.0f);
		let sub = menu.AddSubMenu("More");
		sub.AddItem("Deep", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f));

		d.InjectMouseMove(.(60.0f, 60.0f)); // "More" is row 0 (y in [50,76)) -> open sub
		Test.Assert(sub.IsOpen);

		d.InjectMouseDown(.(500.0f, 500.0f), .Left); // outside everything
		Test.Assert(!menu.IsOpen);
		Test.Assert(menu.Parent == null);
		Test.Assert(sub.Parent == null);
		Test.Assert(d.PopupCount == 0);
	}

	[Test]
	public static void ASubmenuStaysOpenWhileThePointerHeadsForItAcrossAnotherRowThenGivesWay()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetItemHeight(26.0f);
		let sub = menu.AddSubMenu("More");
		sub.AddItem("A", new () => { });
		sub.AddItem("B", new () => { });
		sub.AddItem("C", new () => { });
		let next = menu.AddItem("Next", new () => { });
		menu.AddItem("Last", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f)); // rows at y 50, 76, 102; 160 wide
		d.InjectMouseMove(.(100.0f, 60.0f)); // on "More": its submenu opens at x 210, y 50
		Test.Assert(sub.IsOpen);
		let more = sub.Parent as MenuItem;
		Test.Assert(more != null);
		d.InjectMouseMove(.(150.0f, 70.0f));
		// Down and right toward the submenu, over "Next": the submenu stays, and only "More" is lit.
		d.InjectMouseMove(.(190.0f, 80.0f));
		Test.Assert(sub.IsOpen);
		Test.Assert(more.IsLit);
		Test.Assert(!next.IsLit);
		// Resting on "Next" a moment: it takes over.
		for (int i = 0; i < 5; ++i)
			root.Context.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(!sub.IsOpen);
		Test.Assert(next.IsLit);
		Test.Assert(!more.IsLit);

		// Straight down, away from it: the submenu closes at once.
		d.InjectMouseMove(.(100.0f, 60.0f));
		Test.Assert(sub.IsOpen);
		d.InjectMouseMove(.(100.0f, 110.0f)); // onto "Last", heading away
		Test.Assert(!sub.IsOpen);
	}

	[Test]
	public static void OneRowIsLitAtATimeThePointerAndTheKeysMoveTheSameHighlight()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetItemHeight(26.0f);
		let a = menu.AddItem("A", new () => { });
		let b = menu.AddItem("B", new () => { });
		let c = menu.AddItem("C", new () => { });
		menu.AddSeparator();
		let off = menu.AddItem("Off", new () => { });
		off.Enabled = false;
		menu.Open(anchor, .(50.0f, 50.0f));
		root.Context.Update(TimeSpan(0)); // a frame: the popup placed
		MenuItem[4] items = .(a, b, c, off);
		int Lit()
		{
			int n = 0;
			for (let item in items)
				n += item.IsLit ? 1 : 0;
			return n;
		}

		d.InjectMouseMove(Centre(b));
		Test.Assert(b.IsLit);
		Test.Assert(Lit() == 1);
		// A key moves on from the pointer's row, the pointer resting where it was: one lit, the keys'.
		d.InjectKeyDown((uint32)KeyCode.Down);
		Test.Assert(c.IsLit);
		Test.Assert(b.Hovered);
		Test.Assert(Lit() == 1);
		// Onto the separator, then the disabled item: neither can be lit, and nothing else stays lit.
		let cb = c.ScreenBounds;
		let ob = off.ScreenBounds;
		Test.Assert(ob.Y > cb.Y + cb.Height + 1.0f);
		d.InjectMouseMove(.(cb.X + cb.Width * 0.5f, (cb.Y + cb.Height + ob.Y) * 0.5f));
		Test.Assert(Lit() == 0);
		d.InjectKeyDown((uint32)KeyCode.Down); // from none, round to the first
		Test.Assert(a.IsLit);
		d.InjectMouseMove(Centre(off));
		Test.Assert(Lit() == 0);
		d.InjectMouseMove(Centre(a));
		Test.Assert(a.IsLit);
		Test.Assert(Lit() == 1);
	}

	[Test]
	public static void ASubmenuAddedBeforeItsTitleIsSetAScriptsAddThenTitleNamesItsRow()
	{
		let menu = new Menu();
		defer menu.ReleaseRef();
		let sub = new Menu();
		defer sub.ReleaseRef();
		menu.ChildHost.AddChild(sub); // taken in at once, with no title yet
		sub.Title = "Recent";
		Test.Assert(menu.RowCount == 1);
		Test.Assert(HasItemNamed(menu, "Recent"));
	}

	[Test]
	public static void TallerThanTheWindowItKeepsToItAndScrollsByWheelArrowAndKey()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		anchor.Size = .(10.0f, 10.0f);
		root.AddChild(anchor);
		let d = root.EventDispatcher;
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetItemHeight(25.0f);
		for (int i = 0; i < 40; ++i)
			menu.AddItem("Item", new () => { });
		menu.Open(anchor, .(20.0f, 20.0f));
		root.Context.Update(TimeSpan(0)); // a frame: the popup placed
		Test.Assert(d.IsPopupOpen(menu));
		Test.Assert(menu.Scrolls);
		Test.Assert(menu.Size.Y <= 300.0f);
		let at = menu.ConvertToWorldSpace(.(0.0f, 0.0f));
		Test.Assert(at.Y >= 0.0f);
		Test.Assert(at.Y + menu.Size.Y <= 300.0f + 0.5f); // kept to the window
		Test.Assert(Near(menu.ItemScroll, 0.0f));

		// The wheel, over its items.
		let middle = menu.ConvertToWorldSpace(.(50.0f, menu.Size.Y * 0.5f));
		d.InjectMouseWheel(middle, .(0.0f, -2.0f));
		Test.Assert(menu.ItemScroll > 0.0f);
		let wheeled = menu.ItemScroll;

		// The pointer resting on the down arrow, half a second.
		let bottom = menu.ConvertToWorldSpace(.(50.0f, menu.Size.Y - 4.0f));
		d.InjectMouseMove(bottom);
		root.Context.Update(SceneFixtures.Seconds(0.25));
		root.Context.Update(SceneFixtures.Seconds(0.25));
		Test.Assert(menu.ItemScroll > wheeled + 100.0f);
		d.InjectMouseMove(.(390.0f, 290.0f)); // off it: it stops
		let rested = menu.ItemScroll;
		root.Context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(menu.ItemScroll, rested));

		// The keys: up from no item goes round to the last, which scrolls into view at the end.
		menu.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Up);
		let end = 40.0f * 25.0f - (menu.Size.Y - 32.0f);
		Test.Assert(Near(menu.ItemScroll, end));
		d.InjectKeyDown((uint32)KeyCode.Down); // round to the first
		Test.Assert(Near(menu.ItemScroll, 0.0f));
	}

	[Test]
	public static void OpeningOneInAScrolledPageLeavesThePageWhereItWas()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		// A page that scrolls, a button half way down it, the button's menu inside it (a script's).
		let page = new UIWidget();
		defer page.ReleaseRef();
		page.Size = .(400.0f, 200.0f); // shorter than the window, as a page under a header is
		page.EditLayoutStyle(scope (s) =>
			{
				s.OverflowY = .Auto;
				s.Direction = .Column;
			});
		root.AddChild(page);
		let spacer = new UIWidget();
		defer spacer.ReleaseRef();
		spacer.EditLayoutStyle(scope (s) =>
			{
				s.Height = LayoutLength.Px(1000.0f);
				s.Shrink = 0.0f;
			});
		page.AddChild(spacer);
		let button = new UIWidget();
		defer button.ReleaseRef();
		button.EditLayoutStyle(scope (s) =>
			{
				s.Height = LayoutLength.Px(30.0f);
				s.Shrink = 0.0f;
			});
		page.AddChild(button);
		let tail = new UIWidget();
		defer tail.ReleaseRef();
		tail.EditLayoutStyle(scope (s) =>
			{
				s.Height = LayoutLength.Px(1000.0f);
				s.Shrink = 0.0f;
			});
		page.AddChild(tail);
		let menu = new Menu();
		defer menu.ReleaseRef();
		button.AddChild(menu);
		for (int i = 0; i < 60; ++i)
			menu.AddItem("Item", new () => { });
		root.UpdateLayout();
		page.ScrollOffset = .(0.0f, 900.0f); // the button in view
		root.UpdateLayout();
		let scrolled = page.ScrollOffset.Y;
		for (int round = 0; round < 3; ++round)
		{
			Test.Assert(menu.OpenAtPoint(10.0f, 140.0f), scope $"round {round}");
			menu.FocusFirstItem(); // focus goes into it, as from the keys
			root.Context.Update(TimeSpan(0));
			Test.Assert(Near(page.ScrollOffset.Y, scrolled), scope $"round {round}"); // a popup is not the page's to scroll to
			d.InjectKeyDown((uint32)KeyCode.Escape);
			root.Context.Update(TimeSpan(0));
		}
	}

	[Test]
	public static void AMenuBarWhoseWidthAtAScaleDoesNotLandOnTheDeviceGridSettlesNoLayoutEveryFrame()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.DisplayScale = 1.3f; // its buttons' widths snap to the grid at a fraction of a unit
		root.ViewportSize = .(520.0f, 390.0f);
		let host = new UIWidget();
		defer host.ReleaseRef();
		host.EditLayoutStyle(scope (s) => { s.Kind = .Stack; });
		host.Size = .(300.0f, 40.0f);
		root.AddChild(host);
		let bar = new MenuBar();
		defer bar.ReleaseRef();
		bar.Size = .(290.0f, 28.0f);
		bar.AddMenu("File");
		bar.AddMenu("Edit");
		host.AddChild(bar);
		for (int i = 0; i < 4; ++i)
			root.UpdateLayout();
		// Laid out again on its own (its text changed, a font came): it settles, rather than sizing
		// itself back to the fraction and asking for another pass, each pass.
		bar.RequestLayout();
		for (int i = 0; i < 4; ++i)
			root.UpdateLayout();
		Test.Assert(!root.IsLayoutDirty);
		Test.Assert(!root.HasLayoutDirtyDescendant);
		Test.Assert(!bar.IsLayoutDirty);
	}

	[Test]
	public static void InMarkupItemsSeparatorsAndNestedMenusAnItemReportsActivate()
	{
		RegisterGuiElements();
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let page = loader.LoadFromString(
			"<Panel width=\"600\" height=\"400\">\n" +
			"    <Label id=\"target\" text=\"Right-click me\" width=\"200\" height=\"40\" context-menu=\"ctx\"/>\n" +
			"    <Menu id=\"ctx\">\n" +
			"        <MenuItem id=\"cut\" text=\"Cut\" shortcut=\"Ctrl+X\"/>\n" +
			"        <MenuItem id=\"grid\" text=\"Show grid\" checkable=\"true\" checked=\"true\"/>\n" +
			"        <MenuSeparator/>\n" +
			"        <Menu text=\"More\">\n" +
			"            <MenuItem id=\"rename\" text=\"Rename\"/>\n" +
			"        </Menu>\n" +
			"    </Menu>\n" +
			"</Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		root.AddChild(page);
		root.UpdateLayout();

		let menu = page.GetChildAt(1) as Menu;
		Test.Assert(menu != null);
		Test.Assert(!menu.Displayed); // waits in the page, unseen
		Test.Assert(menu.RowCount == 4); // cut, grid, the separator, More
		Test.Assert(menu.ItemCount == 3);
		let cut = menu.GetChildAt(0) as MenuItem;
		Test.Assert(cut != null);
		Test.Assert(cut.Text == "Cut");
		Test.Assert(cut.Shortcut == "Ctrl+X");
		let grid = menu.GetChildAt(1) as MenuItem;
		Test.Assert(grid != null);
		Test.Assert(grid.Checkable);
		Test.Assert(grid.Checked);

		// A context menu asked for over the label opens it at the pointer.
		int activations = 0;
		cut.AddEventListener(.ItemActivate, new [&] (e) => { ++activations; });
		// It bubbles through the menu to what opened it, and on up: one listener hears every item.
		Node heardFrom = null;
		page.AddEventListener(.ItemActivate, new [&] (e) => { heardFrom = e.Target; });
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(50.0f, 20.0f), .Right);
		d.InjectMouseUp(.(50.0f, 20.0f), .Right);
		Test.Assert(menu.IsOpen);
		Test.Assert(menu.Displayed);
		root.UpdateLayout();
		let at = cut.ScreenBounds;
		d.InjectMouseMove(.(at.X + 10.0f, at.Y + at.Height * 0.5f));
		d.InjectMouseDown(.(at.X + 10.0f, at.Y + at.Height * 0.5f), .Left);
		d.InjectMouseUp(.(at.X + 10.0f, at.Y + at.Height * 0.5f), .Left);
		Test.Assert(activations == 1);
		Test.Assert(heardFrom == cut);
		Test.Assert(!menu.IsOpen);
		// Closed, it left the page; the label keeps it, and it opens again.
		d.InjectMouseDown(.(50.0f, 20.0f), .Right);
		d.InjectMouseUp(.(50.0f, 20.0f), .Right);
		Test.Assert(menu.IsOpen);
	}

	[Test]
	public static void AMenuBarInMarkupHasItsMenusForChildrenEachAButton()
	{
		let tree = MarkupFixtures.Load(
			"<MenuBar>\n" +
			"    <Menu text=\"File\"><MenuItem text=\"Open\"/><MenuItem text=\"Save\"/></Menu>\n" +
			"    <Menu text=\"Edit\"><MenuItem text=\"Undo\"/></Menu>\n" +
			"</MenuBar>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let bar = tree as MenuBar;
		Test.Assert(bar != null);
		Test.Assert(bar.MenuCount == 2);
		Test.Assert(bar.ButtonAt(0).Text == "File");
		Test.Assert(bar.ButtonAt(1).Text == "Edit");
		Test.Assert(bar.MenuAt(0).ItemCount == 2);
	}

	[Test]
	public static void AMarkupContextMenuOpensAgainAfterAnItemIsPickedAndAfterAPressOutside()
	{
		RegisterGuiElements();
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let page = loader.LoadFromString(
			"<Panel width=\"600\" height=\"400\">\n" +
			"    <Panel width=\"400\" height=\"90\" context-menu=\"ctx\" display=\"stack\"><Label text=\"Right-click\" width=\"400\" height=\"90\"/></Panel>\n" +
			"    <Menu id=\"ctx\"><MenuItem text=\"Copy\"/><MenuItem text=\"Paste\"/></Menu>\n" +
			"</Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		root.AddChild(page);
		root.UpdateLayout();
		let menu = page.GetChildAt(1) as Menu;
		Test.Assert(menu != null);
		// As the sandbox's script does: a listener up the page takes the bubbling activate.
		page.AddEventListener(.ItemActivate, new (e) => { e.Handled = true; });
		let d = root.EventDispatcher;
		void RightClick(Float2 at)
		{
			d.InjectMouseMove(at);
			d.InjectMouseDown(at, .Right);
			d.InjectMouseUp(at, .Right);
			root.Context.Update(SceneFixtures.Frame);
		}
		void Click(Float2 at)
		{
			d.InjectMouseMove(at);
			d.InjectMouseDown(at, .Left);
			d.InjectMouseUp(at, .Left);
			root.Context.Update(SceneFixtures.Frame);
		}
		RightClick(.(100.0f, 40.0f));
		Test.Assert(menu.IsOpen);
		let copy = menu.GetChildAt(0).ScreenBounds;
		Click(.(copy.X + 10.0f, copy.Y + copy.Height * 0.5f));
		Test.Assert(!menu.IsOpen);
		// The style pass writes the attribute again at every restyle (as the sandbox's does).
		(page.GetChildAt(0) as UIWidget).ContextMenuId = "ctx";
		RightClick(.(200.0f, 40.0f));
		Test.Assert(menu.IsOpen);
		root.UpdateLayout();
		Test.Assert(menu.Displayed);
		Test.Assert(menu.Visible);
		Test.Assert(menu.Size.X > 20.0f);
		Test.Assert(menu.Size.Y > 20.0f);
		Test.Assert(menu.ScreenBounds.Contains(Float2(210.0f, 50.0f)));
		Click(.(500.0f, 300.0f)); // a press outside closes it
		Test.Assert(!menu.IsOpen);
		RightClick(.(150.0f, 50.0f));
		Test.Assert(menu.IsOpen);
	}

	[Test]
	public static void ItsPaddingInsetsItsRowsAndItsSizeTakesThePaddingIn()
	{
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(140.0f);
		menu.SetItemHeight(25.0f);
		menu.Padding = .(4.0f, 6.0f, 4.0f, 6.0f);
		let cut = menu.AddItem("Cut", new () => { });
		let copy = menu.AddItem("Copy", new () => { });
		Test.Assert(Near(menu.Size.X, 148.0f));
		Test.Assert(Near(menu.Size.Y, 62.0f)); // 2 * 25 + 12
		Test.Assert(Near(cut.Position.X, 4.0f));
		Test.Assert(Near(cut.Position.Y, 6.0f));
		Test.Assert(Near(cut.Size.X, 140.0f)); // a lit row inset from the edge
		Test.Assert(Near(copy.Position.Y, 31.0f));
	}

	[Test]
	public static void TheBuiltInThemeDimsAnItemThatCannotRun()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let menu = new Menu();
		defer menu.ReleaseRef();
		let undo = menu.AddItem("Undo", new () => { });
		let redo = menu.AddItem("Redo", new () => { });
		root.AddChild(menu);
		redo.Enabled = false;
		let styles = scope StyleManager();
		let theme = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, theme);
		styles.UserAgentSheet = theme;
		styles.ApplyTree(root);
		Test.Assert(Near(undo.Alpha, 1.0f));
		Test.Assert(Near(redo.Alpha, 0.45f));
	}

	[Test]
	public static void APaddedMenusSubmenuOpensJustOutsideItItsFirstRowLevelWithItsItem()
	{
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f);
		menu.SetItemHeight(26.0f);
		menu.Padding = .(5.0f);
		menu.AddItem("Top", new () => { });
		let sub = menu.AddSubMenu("More");
		sub.Padding = .(5.0f);
		sub.AddItem("Deep", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f));
		// The "More" row: inside the padding, at y 50 + 5 + 26.
		d.InjectMouseMove(.(60.0f, 50.0f + 5.0f + 26.0f + 13.0f));
		Test.Assert(sub.IsOpen);
		let at = sub.ConvertToRootSpace(.(0.0f, 0.0f));
		Test.Assert(Near(at.X, 50.0f + 170.0f)); // the menu's outer edge (160 + 5 + 5), not inside it
		Test.Assert(Near(at.Y, 50.0f + 5.0f + 26.0f - 5.0f)); // up by its own padding
		// So its first row is level with the row that opened it.
		Test.Assert(sub.ChildCount > 0);
		Test.Assert(Near(at.Y + 5.0f, 50.0f + 5.0f + 26.0f));
		// Its padding styled only after it opened (a sheet's first pass): placed by it then.
		sub.Padding = .(8.0f);
		root.UpdateLayout();
		Test.Assert(Near(sub.ConvertToRootSpace(.(0.0f, 0.0f)).Y, 50.0f + 5.0f + 26.0f - 8.0f));
		Test.Assert(!sub.Scrolls); // its rows all show: placed at its whole height
		Test.Assert(Near(sub.Size.Y, 26.0f + 16.0f));
	}

	[Test]
	public static void ASubmenuStyledByASheetAfterItOpensShowsAllItsRows()
	{
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "menu { padding: 4px; border: 1px solid #808080; }");

		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f);
		menu.SetItemHeight(26.0f);
		menu.AddItem("Top", new () => { });
		let sub = menu.AddSubMenu("More");
		sub.AddItem("One", new () => { });
		sub.AddItem("Two", new () => { });
		sub.AddItem("Three", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f));
		styles.ApplyTree(root);
		root.UpdateLayout();
		d.InjectMouseMove(.(60.0f, 50.0f + 5.0f + 26.0f + 13.0f));
		Test.Assert(sub.IsOpen);
		for (int pass = 0; pass < 3; ++pass)
		{
			styles.ApplyTree(root);
			root.UpdateLayout();
		}
		Test.Assert(Near(sub.Padding.Top, 4.0f));
		Test.Assert(!sub.Scrolls);
		Test.Assert(Near(sub.Size.Y, 3.0f * 26.0f + 10.0f));
	}

	[Test]
	public static void ASubmenuWithAFractionalPaddingLinedUpByItsContentStillShowsAllItsRows()
	{
		// A compact density's padding (3.4 + a 1 px border) moves it a fraction up; the device grid
		// must not take that fraction off its height.
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;
		let menu = new Menu();
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f);
		menu.SetItemHeight(26.0f);
		menu.Padding = .(4.4f);
		menu.AddItem("Top", new () => { });
		let sub = menu.AddSubMenu("More");
		sub.Padding = .(4.4f);
		StringView[4] names = .("One", "Two", "Three", "Four");
		for (let name in names)
			sub.AddItem(name, new () => { });
		menu.Open(anchor, .(50.0f, 50.0f));
		root.UpdateLayout();
		d.InjectMouseMove(.(60.0f, 50.0f + 4.4f + 26.0f + 13.0f));
		Test.Assert(sub.IsOpen);
		for (int pass = 0; pass < 3; ++pass)
			root.UpdateLayout();
		Test.Assert(!sub.Scrolls);
		Test.Assert(sub.Size.Y >= 4.0f * 26.0f + 8.8f - 0.001f);
	}
}
