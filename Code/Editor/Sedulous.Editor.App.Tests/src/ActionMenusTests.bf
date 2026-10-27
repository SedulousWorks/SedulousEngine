using System;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A GUI menu's rows, for comparing whole menus at once.
static class MenuRows
{
	/// Its rows as "Label|-|Sub>": an item's text, ">" after a submenu's, "-" a separator; its
	/// scroll arrows are not rows.
	public static void Labels(Menu menu, String outText)
	{
		bool first = true;
		for (int i < menu.ChildCount)
		{
			let row = menu.GetChildAt(i);
			StringView text;
			bool sub = false;
			if (row is MenuSeparator)
				text = "-";
			else if (let subItem = row as MenuSubItem)
			{
				text = subItem.Text;
				sub = true;
			}
			else if (let item = row as MenuItem)
				text = item.Text;
			else
				continue;
			if (!first)
				outText.Append("|");
			first = false;
			outText.Append(text);
			if (sub)
				outText.Append(">");
		}
	}

	public static bool Is(Menu menu, StringView expected)
	{
		let text = Labels(menu, .. scope .());
		if (text != expected)
			Console.WriteLine("  menu is '{}', expected '{}'", text, expected);
		return text == expected;
	}

	/// The plain item `text` in `menu`; null with none.
	public static MenuItem ItemNamed(Menu menu, StringView text)
	{
		for (int i < menu.ChildCount)
		{
			let item = menu.GetChildAt(i) as MenuItem;
			if ((item != null) && !(item is MenuSubItem) && (item.Text == text))
				return item;
		}
		return null;
	}

	/// The submenu item `text` in `menu`; null with none.
	public static MenuSubItem SubItemNamed(Menu menu, StringView text)
	{
		for (int i < menu.ChildCount)
		{
			let item = menu.GetChildAt(i) as MenuSubItem;
			if ((item != null) && (item.Text == text))
				return item;
		}
		return null;
	}

	public static Menu SubMenuNamed(Menu menu, StringView text)
	{
		let item = SubItemNamed(menu, text);
		return (item != null) ? item.SubMenu : null;
	}
}

/// The menu bar generated from the action registry: menus in first-appearance order or the
/// declared one, items by order band with separators and their chords, nested paths as
/// submenus, leading list-driven items, enabled and checked as the registry answers when a menu
/// (or a submenu) opens, a click executing through the registry, the bar built again on a
/// registration and on a rebind, and a bar that dies leaving nothing behind.
static class ActionMenusTests
{
	/// A GUI scene holding a menu bar, so its menus open as a click on the bar opens them.
	private class MenusBed
	{
		public SceneRoot Root;
		/// The bed's reference; the root takes its own.
		public MenuBar Bar = new .();

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
			Root.AddChild(Bar);
		}

		public ~this()
		{
			Bar.ReleaseRef();
			Root.ReleaseRef();
		}

		public StringView Title(int index) => Bar.ButtonAt(index).Text;
	}

	private static EditorActionDeclaration Declare(StringView id, StringView label, StringView menuPath, int32 order)
	{
		let d = new EditorActionDeclaration(id, label, "", menuPath, order);
		d.Execute = new (page) => {};
		return d;
	}

	private static String Chord(StringView keys, String outText) => EditorShortcut.Of(keys).ToString(.. outText);

	[Test]
	public static void TheBarIsGeneratedFromTheRegistry()
	{
		let actions = scope EditorActionRegistry();
		int saves = 0;
		bool dirty = false;
		bool grid = false;
		bool running = false;
		let save = Declare("file.save", "Save", "File/Save", 100);
		save.Enabled = new [&dirty](page) => dirty;
		delete save.Execute;
		save.Execute = new [&saves](page) => { saves++; };
		save.Shortcut = EditorShortcut.Of("ctrl-s");
		Test.Assert(actions.Register(save));
		Test.Assert(actions.Register(Declare("file.exit", "Exit", "File/Exit", 300)));
		Test.Assert(actions.Register(Declare("edit.undo", "Undo", "Edit/Undo", 100)));
		Test.Assert(actions.Register(Declare("file.saveAs", "Save As...", "File/Save As...", 101)));
		let stop = Declare("scene.sim.stop", "Stop", "Scene/Simulate/Stop", 101);
		stop.Enabled = new [&running](page) => running;
		Test.Assert(actions.Register(stop));
		Test.Assert(actions.Register(Declare("scene.sim.start", "Start", "Scene/Simulate/Start", 100)));
		let toggle = Declare("scene.grid", "Grid", "Scene/Grid", 200);
		toggle.Checked = new [&grid](page) => grid;
		Test.Assert(actions.Register(toggle));
		Test.Assert(actions.Register(Declare("hidden.one", "No menu", "", 0)), "not in the bar");

		let bed = scope MenusBed();
		let menus = scope ActionMenuBar(bed.Bar, actions);
		Test.Assert(bed.Bar.MenuCount == 3);
		Test.Assert(bed.Title(0) == "File");
		Test.Assert(bed.Title(1) == "Edit");
		Test.Assert(bed.Title(2) == "Scene");
		// File: the 100 band (Save, Save As...), a separator, the 300 band (Exit).
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(0), "Save|Save As...|-|Exit"));
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(1), "Undo"));
		// Each item shows its effective chord; one with none shows none.
		Test.Assert(MenuRows.ItemNamed(bed.Bar.MenuAt(0), "Save").Shortcut == "Ctrl+S");
		Test.Assert(MenuRows.ItemNamed(bed.Bar.MenuAt(0), "Exit").Shortcut.IsEmpty);
		// Scene/Simulate/* nests: one submenu holding Start then Stop by order.
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(2), "Simulate>|-|Grid"));
		let simulate = MenuRows.SubMenuNamed(bed.Bar.MenuAt(2), "Simulate");
		Test.Assert(simulate != null);
		Test.Assert(MenuRows.Is(simulate, "Start|Stop"));

		// Enabled and checked are the registry's answer as the menu opens, opened the way a click
		// on the bar opens it.
		let saveItem = MenuRows.ItemNamed(bed.Bar.MenuAt(0), "Save");
		Test.Assert(!saveItem.Enabled);
		// Every item runs through the registry, which refuses an action that is not enabled.
		Test.Assert(saveItem.HandleActivate());
		Test.Assert(saves == 0);
		dirty = true;
		Test.Assert(!saveItem.Enabled, "not yet: built before the change");
		Test.Assert(bed.Bar.ButtonAt(0).HandleActivate());
		Test.Assert(bed.Bar.MenuAt(0).IsOpen);
		Test.Assert(saveItem.Enabled);
		bed.Bar.MenuAt(0).Close();
		let gridItem = MenuRows.ItemNamed(bed.Bar.MenuAt(2), "Grid");
		Test.Assert(gridItem != null);
		Test.Assert(gridItem.Checkable);
		Test.Assert(!gridItem.Checked);
		Test.Assert(!MenuRows.ItemNamed(bed.Bar.MenuAt(0), "Exit").Checkable, "only an action with a checked state");
		grid = true;
		Test.Assert(!gridItem.Checked, "not yet: built before the change");
		Test.Assert(bed.Bar.ButtonAt(2).HandleActivate());
		Test.Assert(gridItem.Checked);
		// A submenu's items too, as it opens.
		let stopItem = MenuRows.ItemNamed(simulate, "Stop");
		Test.Assert(!stopItem.Enabled);
		running = true;
		Test.Assert(!stopItem.Enabled, "not yet: built before the change");
		Test.Assert(MenuRows.SubItemNamed(bed.Bar.MenuAt(2), "Simulate").HandleActivate());
		Test.Assert(simulate.IsOpen);
		Test.Assert(stopItem.Enabled);
		bed.Bar.MenuAt(2).Close();
		// A click executes through the registry.
		Test.Assert(saveItem.HandleActivate());
		Test.Assert(saves == 1);

		// Leading items come first, then a separator, then the actions; a registration builds the
		// bar again and a new menu takes its place at the end.
		int leading = 0;
		menus.AddLeadingItems("File", new [&leading](file) =>
			{
				file.AddItem("New Scene", new [&leading]() => { leading++; });
				file.AddItem("New Material", new () => {});
			});
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(0), "New Scene|New Material|-|Save|Save As...|-|Exit"));
		Test.Assert(MenuRows.ItemNamed(bed.Bar.MenuAt(0), "New Scene").HandleActivate());
		Test.Assert(leading == 1);
		Test.Assert(actions.Register(Declare("help.about", "About", "Help/About", 100)));
		Test.Assert(bed.Bar.MenuCount == 4);
		Test.Assert(bed.Title(3) == "Help");
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(3), "About"));
		// A menu with only leading items and no actions shows them without a trailing separator.
		menus.AddLeadingItems("Recent", new (recent) => { recent.AddItem("yesterday.scene", new () => {}); });
		Test.Assert(bed.Bar.MenuCount == 5);
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(4), "yesterday.scene"));

		// A declared order: the named menus in their places, the rest at "*", in the order they
		// first appear; a domain's menu registered after Help still lands before it.
		menus.SetMenuOrder(scope StringView[]("File", "Edit", "*", "Help", "Nowhere"));
		Test.Assert(bed.Bar.MenuCount == 5, "\"Nowhere\" has nothing in it: no menu");
		Test.Assert(bed.Title(0) == "File");
		Test.Assert(bed.Title(1) == "Edit");
		Test.Assert(bed.Title(2) == "Scene");
		Test.Assert(bed.Title(3) == "Recent");
		Test.Assert(bed.Title(4) == "Help");
		Test.Assert(actions.Register(Declare("tools.bake", "Bake", "Tools/Bake", 100)), "late");
		Test.Assert(bed.Bar.MenuCount == 6);
		Test.Assert(bed.Title(3) == "Tools", "with the action menus, before the leading-only Recent");
		Test.Assert(bed.Title(4) == "Recent");
		Test.Assert(bed.Title(5) == "Help");
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(0), "New Scene|New Material|-|Save|Save As...|-|Exit"), "items unchanged");

		// A rebind builds the bar again: the item shows the new chord.
		Test.Assert(actions.Rebind("file.save", EditorShortcut.Of("f2")) case .Ok);
		let rebound = MenuRows.ItemNamed(bed.Bar.MenuAt(0), "Save");
		Test.Assert(!rebound.Shortcut.IsEmpty);
		Test.Assert(rebound.Shortcut == Chord("f2", .. scope .()));
	}

	[Test]
	public static void AGeneratedBarThatDiesLeavesItEmptyAndTheRegistryNoLongerReachesIt()
	{
		let actions = scope EditorActionRegistry();
		Test.Assert(actions.Register(Declare("file.save", "Save", "File/Save", 100)));
		let bed = scope MenusBed();
		{
			let menus = scope ActionMenuBar(bed.Bar, actions);
			Test.Assert((menus != null) && (bed.Bar.MenuCount == 1));
		}
		Test.Assert(bed.Bar.MenuCount == 0);
		// A registration after it is gone reaches nobody.
		Test.Assert(actions.Register(Declare("file.exit", "Exit", "File/Exit", 300)));
		Test.Assert(bed.Bar.MenuCount == 0);
	}

	/// Items sharing an order keep their registration order: enough of them that the sort takes
	/// its unstable path (past the insertion sort's 16), so only the tiebreak keeps them.
	[Test]
	public static void ItemsOfOneOrderKeepTheirRegistrationOrder()
	{
		let actions = scope EditorActionRegistry();
		let expected = scope String();
		for (int i < 24)
		{
			// Registered out of name order, so neither the name nor the id sorts them back.
			let label = scope $"Item{(i * 7) % 24}";
			Test.Assert(actions.Register(Declare(scope $"tools.item{i}", label, scope $"Tools/{label}", 100)));
			if (i > 0)
				expected.Append("|");
			expected.Append(label);
		}
		let bed = scope MenusBed();
		let menus = scope ActionMenuBar(bed.Bar, actions);
		Test.Assert((menus != null) && (bed.Bar.MenuCount == 1));
		Test.Assert(MenuRows.Is(bed.Bar.MenuAt(0), expected));
	}
}
