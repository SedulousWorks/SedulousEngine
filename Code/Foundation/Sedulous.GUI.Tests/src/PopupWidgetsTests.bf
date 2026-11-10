using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The popups, windows and tabs beyond the ported tests: each element type built by its tag through
/// its GUI table and its reflected properties set by a sheet's CSS names, and each widget's role; a
/// menu opened from a menu bar by the pointer (none of its items lit) and by the keys (its first
/// lit); a submenu holding through the safe area's grace and no longer; a checkable item following
/// its command; a combo box's choice by its keys and its dropdown, reporting only the user's; a
/// window dragged by its title and resized by its grip, its sheet's `resizable` taking the grip
/// away; a message box's buttons from its `buttons`, its result, and its way back to its page;
/// tabs inserted, removed, reordered by a drag and walked by their keys; a toast's queue, its
/// timeout and its action; a context menu named by a sheet opening on a widget at the pointer.
class PopupWidgetsTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new instance of `info`'s type made by its creator, held by the caller; null when it has
	/// none.
	private static Node Make(GuiTypeInfo info) => info.Create() as Node;

	private static Float2 Centre(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	[Test]
	public static void EachWidgetTypeIsMadeByItsCreatorUnderItsTypesNameItsPartsHaveNone()
	{
		GuiTypeInfo[12] elements = .(Menu.StaticGuiType, MenuItem.StaticGuiType, MenuSeparator.StaticGuiType,
			MenuBar.StaticGuiType, ComboBox.StaticGuiType, Window.StaticGuiType, MessageBox.StaticGuiType,
			Tab.StaticGuiType, TabBar.StaticGuiType, TabPage.StaticGuiType, TabView.StaticGuiType,
			ToastHost.StaticGuiType);
		String[12] tags = .("Menu", "MenuItem", "MenuSeparator", "MenuBar", "ComboBox", "Window", "MessageBox", "Tab",
			"TabBar", "TabPage", "TabView", "ToastHost");
		String[12] cssTags = .("menu", "menuitem", "menuseparator", "menubar", "combobox", "window", "messagebox",
			"tab", "tabbar", "tabpage", "tabview", "toasthost");
		String[12] roles = .("menu", "menuitem", "separator", "menubar", "combobox", "window", "dialog", "tab", "",
			"tabpanel", "", "");
		for (int i = 0; i < elements.Count; i++)
		{
			let info = elements[i];
			Test.Assert(info.Tag == tags[i], scope $"{tags[i]}: tagged {info.Tag}");
			Test.Assert(info.CanCreate);
			let made = Make(info);
			Test.Assert(made != null);
			Test.Assert(made.GetType() == info.Type);
			Test.Assert(made.GuiType == info); // an instance answers for its own type
			let widget = made as UIWidget;
			Test.Assert(widget.Tag == cssTags[i]); // what a sheet selects it by
			Test.Assert(widget.AccessRoleName == roles[i], scope $"{tags[i]}: role {widget.AccessRoleName}");
			made.ReleaseRef();
		}
		// Reflected, but no element: markup builds none of them by a tag.
		Test.Assert(!TabCloseButton.StaticGuiType.CanCreate);
		Test.Assert(!TabListButton.StaticGuiType.CanCreate);
		Test.Assert(!TabCloseAllButton.StaticGuiType.CanCreate);
		Test.Assert(!TabStrip.StaticGuiType.CanCreate);
		Test.Assert(!TabPageHost.StaticGuiType.CanCreate);
		// Each answers for its own type, its base's table after it.
		Test.Assert(MessageBox.StaticGuiType.Is(Window.StaticGuiType));
		Test.Assert(Tab.StaticGuiType.Is(ButtonBase.StaticGuiType));
		Test.Assert(TabPage.StaticGuiType.Is(Panel.StaticGuiType));
		Test.Assert(MenuItem.StaticGuiType.Is(UIWidget.StaticGuiType));
		// The parts a strip is made of take the roles a screen reader reads.
		let bar = new TabBar();
		defer bar.ReleaseRef();
		Test.Assert((bar.Strip as UIWidget).AccessRoleName == "tablist");
	}

	[Test]
	public static void TheReflectedPropertiesCarryTheirFlagsAndAccessNames()
	{
		let text = MenuItem.StaticGuiType.Find("text");
		Test.Assert(text != null);
		Test.Assert(text.IsTranslatable);
		Test.Assert(text.Access == "name");
		Test.Assert(text.Css.IsEmpty); // markup's, not a sheet's
		Test.Assert(ComboBox.StaticGuiType.FindCss("selected").IsTwoWay);
		Test.Assert(ComboBox.StaticGuiType.FindCss("placeholder").IsTranslatable);
		Test.Assert(TabBar.StaticGuiType.FindCss("selected").IsTwoWay);
		Test.Assert(TabView.StaticGuiType.FindCss("selected").IsTwoWay);
		Test.Assert(TabBar.StaticGuiType.FindCss("close-all").Name == "ShowsCloseAll");
		Test.Assert(Window.StaticGuiType.FindCss("title").Access == "name");
		Test.Assert(TabPage.StaticGuiType.FindCss("title").Access == "name");
		Test.Assert(MessageBox.StaticGuiType.FindCss("title") != null); // through its base's table
		let result = MessageBox.StaticGuiType.Find("ResultName");
		Test.Assert(result != null);
		Test.Assert(!result.CanWrite);
		let maxShown = ToastHost.StaticGuiType.Find("maxShown");
		Test.Assert(maxShown != null);
		Test.Assert(maxShown.CanWrite);
		Test.Assert(!ToastHost.StaticGuiType.Find("shownCount").CanWrite);
	}

	[Test]
	public static void ASheetSetsEachWidgetsReflectedPropertiesByTheirCSSNames()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let item = Make(MenuItem.StaticGuiType) as MenuItem;
		defer item.ReleaseRef();
		let combo = Make(ComboBox.StaticGuiType) as ComboBox;
		defer combo.ReleaseRef();
		combo.ItemsText = "Red|Green|Blue";
		let list = Make(ComboBox.StaticGuiType) as ComboBox;
		defer list.ReleaseRef();
		list.Id = "list";
		let window = Make(Window.StaticGuiType) as Window;
		defer window.ReleaseRef();
		let bar = Make(TabBar.StaticGuiType) as TabBar;
		defer bar.ReleaseRef();
		bar.Id = "bar"; // a view's own bar is a tabbar too
		bar.AddTab("A");
		let view = Make(TabView.StaticGuiType) as TabView;
		defer view.ReleaseRef();
		view.AddPage("One");
		view.AddPage("Two");
		let page = Make(TabPage.StaticGuiType) as TabPage;
		defer page.ReleaseRef();
		Node[7] all = .(item, combo, list, window, bar, view, page);
		for (let node in all)
			root.AddChild(node);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles,
			"menuitem { checkable: true; checked: true; } " +
			"combobox { selected: 2; placeholder: Pick; } " +
			"#list { items: Low|High; } " +
			"window { title: Tools; closable: false; resizable: false; } " +
			"#bar { close-display: hover; list-display: always; close-all: true; reorderable: true; group: docs; } " +
			"tabview { close-display: always; reorderable: true; group: views; selected: 1; } " +
			"tabpage { title: General; icon: gear.png; closable: false; }");
		styles.ApplyTree(root);

		Test.Assert(item.Checkable);
		Test.Assert(item.Checked);
		Test.Assert(combo.SelectedIndex == 2);
		Test.Assert(combo.SelectedText == "Blue");
		Test.Assert(combo.Placeholder == "Pick");
		Test.Assert(list.ItemCount == 2);
		Test.Assert(list.ItemsText == "Low|High");
		Test.Assert(window.Title == "Tools");
		Test.Assert(!window.Closable);
		Test.Assert(!window.Resizable);
		Test.Assert(bar.CloseDisplay == .Hover);
		Test.Assert(bar.ListDisplay == .Always);
		Test.Assert(bar.ShowsCloseAll);
		Test.Assert(bar.Reorderable);
		Test.Assert(bar.Group == "docs");
		Test.Assert(view.Bar.CloseDisplay == .Always);
		Test.Assert(view.Reorderable);
		Test.Assert(view.Group == "views");
		Test.Assert(view.SelectedIndex == 1);
		Test.Assert(page.Title == "General");
		Test.Assert(page.Icon == "gear.png");
		Test.Assert(!page.Closable);
	}

	[Test]
	public static void AMenuOpenedFromAMenuBarByThePointerLightsNoneOfItsItemsByTheKeysItsFirst()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let bar = Make(MenuBar.StaticGuiType) as MenuBar;
		defer bar.ReleaseRef();
		root.AddChild(bar);
		let file = bar.AddMenu("File");
		let open = file.AddItem("Open", new () => { });
		file.AddItem("Save", new () => { });
		bar.AddMenu("Edit").AddItem("Undo", new () => { });
		root.UpdateLayout();
		let d = root.EventDispatcher;

		SceneFixtures.Click(d, Centre(bar.ButtonAt(0)));
		Test.Assert(file.IsOpen);
		Test.Assert(d.FocusNode == file); // the menu itself: no item lit until one is picked
		Test.Assert(!open.IsLit);
		Test.Assert(bar.ButtonAt(0).HasClass("selected"));
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!file.IsOpen);
		Test.Assert(!bar.ButtonAt(0).HasClass("selected"));

		d.InjectKeyDown((uint32)KeyCode.F10); // into the bar
		Test.Assert(d.FocusNode == bar.ButtonAt(0));
		d.InjectKeyDown((uint32)KeyCode.Return); // the button opens it, from the keys
		Test.Assert(file.IsOpen);
		Test.Assert(open.IsLit);
		Test.Assert(d.FocusNode == open);
		Test.Assert(file.Parent == bar.ButtonAt(0)); // a popup of its button
		Test.Assert(Near(file.Position.Y, bar.Size.Y)); // below the bar
	}

	[Test]
	public static void ASubmenuHoldsThroughTheSafeAreasGraceAndThenTheRowThePointerRestsOnTakesOver()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let anchor = new UIWidget();
		defer anchor.ReleaseRef();
		root.AddChild(anchor);
		let d = root.EventDispatcher;
		let menu = Make(Menu.StaticGuiType) as Menu;
		defer menu.ReleaseRef();
		menu.SetWidth(160.0f); // widths of their own: with no font here they would measure narrow
		menu.SetItemHeight(26.0f);
		let sub = menu.AddSubMenu("More");
		sub.SetWidth(160.0f);
		sub.AddItem("A", new () => { });
		sub.AddItem("B", new () => { });
		sub.AddItem("C", new () => { });
		let next = menu.AddItem("Next", new () => { });
		menu.Open(anchor, .(50.0f, 50.0f)); // rows at y 50, 76; 160 wide
		d.InjectMouseMove(.(100.0f, 60.0f)); // on "More": its submenu opens at x 210, y 50
		Test.Assert(sub.IsOpen);
		d.InjectMouseMove(.(150.0f, 70.0f));
		d.InjectMouseMove(.(190.0f, 80.0f)); // over "Next", heading for the submenu
		Test.Assert(sub.IsOpen);
		root.Context.Update(SceneFixtures.Seconds(0.2)); // short of the grace (0.3 s)
		Test.Assert(sub.IsOpen);
		Test.Assert(!next.IsLit);
		root.Context.Update(SceneFixtures.Seconds(0.15)); // past it, the pointer still on "Next"
		Test.Assert(!sub.IsOpen);
		Test.Assert(next.IsLit);
	}

	[Test]
	public static void ACheckableItemBoundToACommandFollowsItsCheckedStateAndRunsIt()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let grid = root.Context.DefineCommand("grid");
		grid.Checked = true;
		root.OnCommand("grid", new (command) => { grid.Checked = !grid.Checked; });
		let menu = new Menu();
		defer menu.ReleaseRef();
		int toggled = 0;
		let item = menu.AddCheckItem("Show grid", false, new [&] (on) => { ++toggled; });
		root.AddChild(menu); // in the tree, so its binding runs
		item.Command = "grid";
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(item.Checked); // the command's, not its own
		Test.Assert(item.Enabled);
		Test.Assert(toggled == 0); // a command's state is no toggle of the user's

		Test.Assert(item.HandleActivate()); // runs the command, which decides
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!grid.Checked);
		Test.Assert(!item.Checked);
		Test.Assert(toggled == 0);
		grid.Enabled = false;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!item.Enabled); // greyed with its command

		// Bound to none, it toggles itself and says so.
		let own = menu.AddCheckItem("Snap", false, new [&] (on) => { ++toggled; });
		Test.Assert(own.HandleActivate());
		Test.Assert(own.Checked);
		Test.Assert(toggled == 1);
	}

	[Test]
	public static void AComboBoxsChoiceByItsKeysAndItsDropdownReportsOnlyTheUsers()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let combo = Make(ComboBox.StaticGuiType) as ComboBox;
		defer combo.ReleaseRef();
		combo.Size = .(120.0f, 26.0f);
		combo.ItemsText = "Low|Medium|High";
		root.AddChild(combo);
		int changes = 0;
		combo.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		let d = root.EventDispatcher;
		combo.RequestFocus();

		d.InjectKeyDown((uint32)KeyCode.Down); // from none: the first
		Test.Assert(combo.SelectedIndex == 0);
		d.InjectKeyDown((uint32)KeyCode.Down);
		Test.Assert(combo.SelectedText == "Medium");
		Test.Assert(changes == 2);
		combo.SelectedIndex = 2; // code's: no change event
		Test.Assert(changes == 2);
		d.InjectKeyDown((uint32)KeyCode.Up);
		Test.Assert(combo.SelectedIndex == 1);
		Test.Assert(changes == 3);

		// The dropdown, below the box, its rows the items; a click on one picks it.
		SceneFixtures.Click(d, Centre(combo));
		Test.Assert(combo.IsOpen);
		root.UpdateLayout();
		let list = combo.Dropdown;
		Test.Assert(list.ItemCount == 3);
		Test.Assert(list.SelectedIndex == 1); // the current item lit
		Test.Assert(Near(list.Position.Y, 26.0f));
		Test.Assert(Near(list.Size.Y, 3.0f * 24.0f)); // three rows of the item height
		SceneFixtures.Click(d, .(20.0f, 26.0f + 2.5f * 24.0f)); // the third row
		Test.Assert(!combo.IsOpen);
		Test.Assert(combo.SelectedText == "High");
		Test.Assert(changes == 4);

		// New items: the old choice goes with them.
		combo.ItemsText = "A|B";
		Test.Assert(combo.SelectedIndex == -1);
		Test.Assert(combo.SelectedText.Length == 0);
		Test.Assert(combo.Dropdown.ItemCount == 2); // the list follows
		Test.Assert(changes == 4);
	}

	[Test]
	public static void AWindowIsDraggedByItsTitleAndResizedByItsGripItsSheetsResizableTakesTheGripAway()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let window = Make(Window.StaticGuiType) as Window;
		defer window.ReleaseRef();
		window.Size = .(200.0f, 150.0f);
		window.Position = .(100.0f, 50.0f);
		root.AddChild(window);
		root.UpdateLayout();
		int arranged = 0;
		window.SetOnUserArranged(new [&] () => { ++arranged; });
		let d = root.EventDispatcher;

		// The title: +30, +20.
		d.InjectMouseDown(.(150.0f, 60.0f), .Left);
		d.InjectMouseMove(.(180.0f, 80.0f));
		d.InjectMouseUp(.(180.0f, 80.0f), .Left);
		Test.Assert(Near(window.Position.X, 130.0f));
		Test.Assert(Near(window.Position.Y, 70.0f));
		Test.Assert(arranged == 1);
		// The grip, in its corner (14 square): +20, +10.
		let grip = Float2(130.0f + 200.0f - 7.0f, 70.0f + 150.0f - 7.0f);
		d.InjectMouseDown(grip, .Left);
		d.InjectMouseMove(.(grip.X + 20.0f, grip.Y + 10.0f));
		d.InjectMouseUp(.(grip.X + 20.0f, grip.Y + 10.0f), .Left);
		Test.Assert(Near(window.Size.X, 220.0f));
		Test.Assert(Near(window.Size.Y, 160.0f));
		Test.Assert(arranged == 2);

		// A sheet that says it is not resizable takes the grip away: the corner moves it no more.
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "window { resizable: false; }");
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(!window.Resizable);
		let corner = Float2(130.0f + 220.0f - 4.0f, 70.0f + 160.0f - 4.0f);
		d.InjectMouseDown(corner, .Left);
		d.InjectMouseMove(.(corner.X + 30.0f, corner.Y + 30.0f));
		d.InjectMouseUp(.(corner.X + 30.0f, corner.Y + 30.0f), .Left);
		Test.Assert(Near(window.Size.X, 220.0f));
		Test.Assert(Near(window.Size.Y, 160.0f));
	}

	[Test]
	public static void AMessageBoxsButtonsComeFromItsButtonsItAnswersAndGoesBackToItsPage()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let page = new Panel();
		defer page.ReleaseRef();
		root.AddChild(page);
		let before = new Label();
		defer before.ReleaseRef();
		page.AddChild(before);
		let dialog = Make(MessageBox.StaticGuiType) as MessageBox;
		defer dialog.ReleaseRef();
		page.AddChild(dialog);
		let after = new Label();
		defer after.ReleaseRef();
		page.AddChild(after);
		Test.Assert(dialog.SetMarkupAttribute("text", "Delete it?"));
		Test.Assert(dialog.SetMarkupAttribute("buttons", "yes-no"));
		Test.Assert(!dialog.Displayed); // written in a page: unseen until shown
		Test.Assert(dialog.ButtonCount == 2);
		Test.Assert(dialog.ButtonAt(0).Text == "No");
		Test.Assert(dialog.ButtonAt(1).Text == "Yes"); // the default, rightmost
		Test.Assert(dialog.Message == "Delete it?");
		var got = MessageBox.Result.Cancel;
		dialog.SetOnResult(new [&] (result) => { got = result; });
		int changes = 0;
		dialog.AddEventListener(.Changed, new [&] (e) => { ++changes; });

		Test.Assert(dialog.Show());
		Test.Assert(dialog.IsOpen);
		Test.Assert(dialog.Displayed);
		Test.Assert(dialog.Parent == root); // over the GUI, out of its page
		Test.Assert(root.EventDispatcher.FocusNode == dialog.ButtonAt(1));
		Test.Assert(dialog.ButtonAt(1).HandleActivate());
		Test.Assert(got == .Yes);
		Test.Assert(dialog.ResultName == "yes");
		Test.Assert(changes == 1);
		Test.Assert(!dialog.IsOpen);
		Test.Assert(dialog.Parent == page); // back where it was written
		Test.Assert(page.GetChildIndex(dialog) == 1);
		Test.Assert(!dialog.Displayed);
	}

	[Test]
	public static void TabsAreInsertedRemovedReorderedByADragAndWalkedByTheirKeys()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let bar = Make(TabBar.StaticGuiType) as TabBar;
		defer bar.ReleaseRef();
		root.AddChild(bar);
		bar.Reorderable = true;
		String[3] names = .("B", "C", "D");
		for (let t in names)
		{
			bar.AddTab(t).EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(60.0f);
					s.Height = LayoutLength.Px(24.0f);
				});
		}
		let a = bar.InsertTab(0, "A"); // first, before the selected one
		a.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(60.0f);
				s.Height = LayoutLength.Px(24.0f);
			});
		root.UpdateLayout();
		Test.Assert(bar.TabCount == 4);
		Test.Assert(bar.IndexOf(a) == 0);
		Test.Assert(bar.SelectedTab.Text == "B"); // the selection stays on its tab
		Test.Assert(bar.SelectedIndex == 1);

		// The selected tab removed: the one after it takes its place.
		bar.RemoveTab(1);
		Test.Assert(bar.TabCount == 3);
		Test.Assert(bar.SelectedTab.Text == "C");
		root.UpdateLayout();

		// A dragged past C's middle (A's left at 0, C's middle at 62 + 30).
		let d = root.EventDispatcher;
		let start = Centre(a);
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X + 70.0f, start.Y));
		d.InjectMouseUp(.(start.X + 70.0f, start.Y), .Left);
		Test.Assert(bar.IndexOf(a) == 1);
		Test.Assert(bar.SelectedTab == a); // the press selected it

		// The keys: End, Home, Ctrl+Page Up round to the last.
		a.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.End);
		Test.Assert(bar.SelectedIndex == 2);
		Test.Assert(bar.GetTab(2).IsFocused);
		d.InjectKeyDown((uint32)KeyCode.Home);
		Test.Assert(bar.SelectedIndex == 0);
		d.InjectKeyDown((uint32)KeyCode.PageUp, KeyModCtrl);
		Test.Assert(bar.SelectedIndex == 2);
		d.InjectKeyDown((uint32)KeyCode.Right); // the arrow stops at the end
		Test.Assert(bar.SelectedIndex == 2);
	}

	[Test]
	public static void AToastsQueueItsTimeoutAndItsAction()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		let host = Make(ToastHost.StaticGuiType) as ToastHost;
		defer host.ReleaseRef();
		root.AddChild(host);
		root.Context.Update(TimeSpan(0));
		root.UpdateLayout();
		// One at a time, set as code sets it.
		var one = System.Variant.Create((int)1);
		defer one.Dispose();
		Test.Assert(ToastHost.StaticGuiType.Find("maxShown").Set(host, one));
		Test.Assert(host.MaxShown == 1);

		let first = host.Post(ToastBed.Text(scope ToastRequest(), "First"));
		let second = host.Post(ToastBed.Text(scope ToastRequest(), "Second"));
		Test.Assert(host.IsShown(first));
		Test.Assert(host.IsWaiting(second));
		root.Context.Update(SceneFixtures.Seconds(4.9)); // an info toast's 5 s
		Test.Assert(host.IsShown(first));
		root.Context.Update(SceneFixtures.Seconds(0.2));
		Test.Assert(!host.IsShown(first));
		Test.Assert(host.IsShown(second)); // its turn, at once

		// An action: its command runs, the post's callback hears it, and the toast goes.
		int undone = 0;
		root.Context.DefineCommand("undo");
		root.OnCommand("undo", new [&] (command) => { ++undone; });
		let pressed = scope String();
		let request = ToastBed.Text(scope ToastRequest(), "Deleted", .Warning);
		request.AddAction("undo", "Undo", "undo");
		host.MaxShown = 4;
		let acted = host.Post(request, new [&] (action) => { pressed.Set(action.Id); });
		let card = host.GetCard(acted);
		Test.Assert(card != null);
		Test.Assert(card.HasClass("warning"));
		Test.Assert(Near(card.Remaining, 8.0f)); // a warning's 8 s
		root.Context.Update(SceneFixtures.Frame); // the action's button binds to its command
		Test.Assert(card.ActionAt(0).HandleActivate());
		Test.Assert(undone == 1);
		Test.Assert(pressed == "undo");
		Test.Assert(!host.IsShown(acted));
	}

	[Test]
	public static void AContextMenuNamedByASheetOpensOnAWidgetAtThePointerAndAgainOnceClosed()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let page = new Panel();
		defer page.ReleaseRef();
		page.Size = .(600.0f, 400.0f);
		root.AddChild(page);
		let target = new Panel();
		defer target.ReleaseRef();
		target.Id = "target";
		target.Position = .(20.0f, 20.0f);
		target.Size = .(200.0f, 60.0f);
		page.AddChild(target);
		let plain = new Panel();
		defer plain.ReleaseRef();
		plain.Position = .(20.0f, 200.0f);
		plain.Size = .(200.0f, 60.0f);
		page.AddChild(plain);
		let menu = Make(Menu.StaticGuiType) as Menu;
		defer menu.ReleaseRef();
		menu.Id = "ctx";
		int copies = 0;
		menu.AddItem("Copy", new [&] () => { ++copies; });
		menu.AddItem("Paste", new () => { });
		page.AddChild(menu); // waits in the page, unseen
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "#target { context-menu: ctx; }");
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(target.ContextMenuId == "ctx");
		Test.Assert(!menu.Displayed);
		let d = root.EventDispatcher;

		// A right click elsewhere asks for none.
		d.InjectMouseDown(.(60.0f, 220.0f), .Right);
		d.InjectMouseUp(.(60.0f, 220.0f), .Right);
		Test.Assert(!menu.IsOpen);

		d.InjectMouseDown(.(60.0f, 40.0f), .Right);
		d.InjectMouseUp(.(60.0f, 40.0f), .Right);
		Test.Assert(menu.IsOpen);
		Test.Assert(menu.Displayed);
		Test.Assert(menu.Parent == target); // a popup of the widget it was asked over
		Test.Assert(Near(menu.Position.X, 60.0f)); // at the pointer
		Test.Assert(Near(menu.Position.Y, 40.0f));
		root.UpdateLayout();
		SceneFixtures.Click(d, Centre(menu.GetChildAt(0)));
		Test.Assert(copies == 1);
		Test.Assert(!menu.IsOpen);
		Test.Assert(menu.Parent == null); // closed, it left the page: the widget keeps it

		// The style pass writes the same id again; the menu found is kept and opens again.
		styles.ApplyTree(root);
		d.InjectMouseDown(.(100.0f, 50.0f), .Right);
		d.InjectMouseUp(.(100.0f, 50.0f), .Right);
		Test.Assert(menu.IsOpen);
		Test.Assert(Near(menu.Position.X, 100.0f));
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!menu.IsOpen);
	}
}
