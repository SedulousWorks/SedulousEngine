using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The surfaces generated from the action registry: the menu bar (menus in first-appearance
/// order, items by order band with separators, nested paths as submenus, leading list-driven
/// items, enabled as the registry answers when a menu opens, a click executing through the
/// registry, a rebuild on a registration) and the global shortcuts (one binding per effective
/// chord and alternate, executing through the registry, rebound on a rebind and on a
/// registration).
static class ActionSurfacesTests
{
	private static EditorActionDeclaration Declare(StringView id, StringView label, StringView menuPath, int32 order)
	{
		let d = new EditorActionDeclaration(id, label, "", menuPath, order);
		d.Execute = new (page) => {};
		return d;
	}

	/// A menu's rows as "Label|-|Sub>" for comparing whole menus at once.
	private static void Labels(ContextMenu menu, String outText)
	{
		for (int i < menu.ItemCount)
		{
			let item = menu.ItemAt(i);
			if (i > 0)
				outText.Append("|");
			outText.Append(item.IsSeparator ? "-" : item.Label);
			if (item.Submenu != null)
				outText.Append(">");
		}
	}

	private static bool Is(ContextMenu menu, StringView expected)
	{
		let text = Labels(menu, .. scope .());
		if (text != expected)
			Console.WriteLine("  menu is '{}', expected '{}'", text, expected);
		return text == expected;
	}

	[Test]
	public static void TheBarIsGeneratedFromTheRegistry()
	{
		let actions = scope EditorActionRegistry();
		int saves = 0;
		bool dirty = false;
		let save = Declare("file.save", "Save", "File/Save", 100);
		save.Enabled = new [&dirty](page) => dirty;
		delete save.Execute;
		save.Execute = new [&saves](page) => { saves++; };
		Test.Assert(actions.Register(save));
		Test.Assert(actions.Register(Declare("file.exit", "Exit", "File/Exit", 300)));
		Test.Assert(actions.Register(Declare("edit.undo", "Undo", "Edit/Undo", 100)));
		Test.Assert(actions.Register(Declare("file.saveAs", "Save As...", "File/Save As...", 101)));
		Test.Assert(actions.Register(Declare("scene.sim.stop", "Stop", "Scene/Simulate/Stop", 101)));
		Test.Assert(actions.Register(Declare("scene.sim.start", "Start", "Scene/Simulate/Start", 100)));
		Test.Assert(actions.Register(Declare("hidden.one", "No menu", "", 0)), "not in the bar");

		let bar = new MenuBar();
		defer bar.ReleaseRef();
		let menus = scope ActionMenuBar(bar, actions);
		Test.Assert(bar.MenuCount == 3);
		Test.Assert(bar.MenuTitle(0) == "File");
		Test.Assert(bar.MenuTitle(1) == "Edit");
		Test.Assert(bar.MenuTitle(2) == "Scene");
		// File: the 100 band (Save, Save As...), a separator, the 300 band (Exit).
		Test.Assert(Is(bar.MenuAt(0), "Save|Save As...|-|Exit"));
		Test.Assert(Is(bar.MenuAt(1), "Undo"));
		// Scene/Simulate/* nests: one submenu holding Start then Stop by order.
		Test.Assert(Is(bar.MenuAt(2), "Simulate>"));
		let simulate = bar.MenuAt(2).ItemAt(0);
		Test.Assert(simulate.Submenu != null);
		Test.Assert(Is(simulate.Submenu, "Start|Stop"));

		// Enabled is the registry's answer at the moment the menu opens.
		Test.Assert(!bar.MenuAt(0).ItemAt(0).Enabled);
		dirty = true;
		Test.Assert(!bar.MenuAt(0).ItemAt(0).Enabled, "not yet: built before the change");
		Test.Assert(bar.MenuAt(0).OnOpening != null);
		bar.MenuAt(0).OnOpening(bar.MenuAt(0));
		Test.Assert(bar.MenuAt(0).ItemAt(0).Enabled);
		// A click executes through the registry.
		bar.MenuAt(0).ItemAt(0).Action();
		Test.Assert(saves == 1);

		// Leading items come first, then a separator, then the actions; a registration rebuilds
		// the bar and a new menu takes its place at the end.
		int leading = 0;
		menus.AddLeadingItems("File", new [&leading](file) =>
			{
				file.AddItem("New Scene", new [&leading]() => { leading++; });
				file.AddItem("New Material", new () => {});
			});
		Test.Assert(Is(bar.MenuAt(0), "New Scene|New Material|-|Save|Save As...|-|Exit"));
		bar.MenuAt(0).ItemAt(0).Action();
		Test.Assert(leading == 1);
		Test.Assert(actions.Register(Declare("help.about", "About", "Help/About", 100)));
		Test.Assert(bar.MenuCount == 4);
		Test.Assert(bar.MenuTitle(3) == "Help");
		Test.Assert(Is(bar.MenuAt(3), "About"));
		// A menu with only leading items and no actions shows them without a trailing separator.
		menus.AddLeadingItems("Recent", new (recent) => { recent.AddItem("yesterday.scene", new () => {}); });
		Test.Assert(bar.MenuCount == 5);
		Test.Assert(Is(bar.MenuAt(4), "yesterday.scene"));
	}

	[Test]
	public static void OneGlobalPerChordAndAlternateReboundOnARebindAndARegistration()
	{
		let ctx = scope UIContext();
		let actions = scope EditorActionRegistry();
		int saves = 0;
		int redos = 0;
		let save = Declare("file.save", "Save", "File/Save", 100);
		save.Shortcut = .(.S, .Ctrl);
		delete save.Execute;
		save.Execute = new [&saves](page) => { saves++; };
		Test.Assert(actions.Register(save));
		let redo = Declare("edit.redo", "Redo", "Edit/Redo", 101);
		redo.Shortcut = .(.Z, .Ctrl | .Shift);
		redo.AlternateShortcut = .(.Y, .Ctrl);
		delete redo.Execute;
		redo.Execute = new [&redos](page) => { redos++; };
		Test.Assert(actions.Register(redo));
		Test.Assert(actions.Register(Declare("view.reset", "Reset Layout", "View/Reset Layout", 100)));

		let shortcuts = scope ActionShortcuts(ctx.GetShortcuts(), actions);
		Test.Assert(shortcuts.BoundCount == 3, "save, redo, redo's alternate; reset has none");
		let manager = ctx.GetShortcuts();
		Test.Assert(manager.TryDispatch(.S, .LeftCtrl));
		Test.Assert(saves == 1);
		Test.Assert(manager.TryDispatch(.Y, .LeftCtrl));
		Test.Assert(redos == 1);
		Test.Assert(manager.TryDispatch(.Z, .LeftCtrl | .LeftShift));
		Test.Assert(redos == 2);
		Test.Assert(!manager.TryDispatch(.S, .None));

		// A rebind moves the binding; the old chord is free, the new one fires.
		Test.Assert(actions.Rebind("file.save", .(.F2)) case .Ok);
		Test.Assert(shortcuts.BoundCount == 3);
		Test.Assert(!manager.TryDispatch(.S, .LeftCtrl));
		Test.Assert(manager.TryDispatch(.F2, .None));
		Test.Assert(saves == 2);
		// Clearing an override unbinds; a registration with a chord binds.
		Test.Assert(actions.Rebind("file.save", .()) case .Ok);
		Test.Assert(shortcuts.BoundCount == 2);
		Test.Assert(!manager.TryDispatch(.F2, .None));
		int runs = 0;
		let run = Declare("sim.run", "Simulate", "", 0);
		run.Shortcut = .(.F5);
		delete run.Execute;
		run.Execute = new [&runs](page) => { runs++; };
		Test.Assert(actions.Register(run));
		Test.Assert(shortcuts.BoundCount == 3);
		Test.Assert(manager.TryDispatch(.F5, .None));
		Test.Assert(runs == 1);
	}
}
