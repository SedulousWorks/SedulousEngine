using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The global shortcuts generated from the action registry: one binding per effective chord
/// and alternate, executing through the registry, rebound on a rebind and on a registration. The
/// menu bar's tests moved to ActionMenusTests with its port onto the GUI; these come back with
/// ActionShortcuts'.
static class ActionSurfacesTests
{
	private static EditorActionDeclaration Declare(StringView id, StringView label, StringView menuPath, int32 order)
	{
		let d = new EditorActionDeclaration(id, label, "", menuPath, order);
		d.Execute = new (page) => {};
		return d;
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
