using System;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The keys generated from the action registry: one binding per effective chord and alternate
/// (none for an action with no chord), run by the root through the registry (a disabled action
/// is not run), bound again on a rebind and on a registration; a focused widget's own binding of
/// the same keys first; and a set that dies leaving the keymap and the root as they were.
static class ActionShortcutsTests
{
	/// A GUI scene with a frame in it, its keys pressed as the keyboard presses them.
	private class ShortcutsBed
	{
		public SceneRoot Root;
		/// The bed's reference; the root takes its own.
		public Panel Frame = new .();

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
			Root.AddChild(Frame);
		}

		public ~this()
		{
			Frame.ReleaseRef();
			Root.ReleaseRef();
		}

		public Sedulous.GUI.Keymap Keymap => Root.Context.Keymap;

		public bool Press(KeyCode key, uint32 modifiers = 0) => Root.EventDispatcher.InjectKeyDown((uint32)key, modifiers);
	}

	private static EditorActionDeclaration Declare(StringView id, StringView label, StringView keys)
	{
		let d = new EditorActionDeclaration(id, label);
		d.Shortcut = EditorShortcut.Of(keys);
		d.Execute = new (page) => {};
		return d;
	}

	[Test]
	public static void OneBindingPerChordAndAlternateRunThroughTheRegistryBoundAgainOnARebindAndARegistration()
	{
		let actions = scope EditorActionRegistry();
		int saves = 0;
		int redos = 0;
		let save = Declare("file.save", "Save", "ctrl-s");
		delete save.Execute;
		save.Execute = new [&saves](page) => { saves++; };
		Test.Assert(actions.Register(save));
		let redo = Declare("edit.redo", "Redo", "ctrl-shift-z");
		redo.AlternateShortcut = EditorShortcut.Of("ctrl-y");
		delete redo.Execute;
		redo.Execute = new [&redos](page) => { redos++; };
		Test.Assert(actions.Register(redo));
		Test.Assert(actions.Register(Declare("view.reset", "Reset Layout", "")), "no chord");

		let bed = scope ShortcutsBed();
		let before = bed.Keymap.BindingCount;
		let shortcuts = scope ActionShortcuts(bed.Keymap, bed.Root, actions);
		Test.Assert(shortcuts.BoundCount == 3, "save, redo, redo's alternate");
		// An action with no chord has no key and no handler.
		Test.Assert(bed.Keymap.BindingCount == before + 3);
		Test.Assert(bed.Keymap.ShortcutText("view.reset", .. scope .()).IsEmpty);
		Test.Assert(!bed.Root.HandlesCommand("view.reset"));
		bed.Press(.S, KeyModCtrl);
		Test.Assert(saves == 1);
		// The alternate runs it as the chord does.
		bed.Press(.Y, KeyModCtrl);
		Test.Assert(redos == 1);
		bed.Press(.Z, KeyModCtrl | KeyModShift);
		Test.Assert(redos == 2);
		bed.Press(.S);
		Test.Assert(saves == 1, "S alone runs nothing");

		// A rebind moves the binding: the old chord is free, the new one runs it, once (the earlier
		// handler went with the earlier binding).
		Test.Assert(actions.Rebind("file.save", EditorShortcut.Of("f2")) case .Ok);
		Test.Assert(shortcuts.BoundCount == 3);
		Test.Assert(bed.Keymap.BindingCount == before + 3);
		bed.Press(.S, KeyModCtrl);
		Test.Assert(saves == 1);
		bed.Press(.F2);
		Test.Assert(saves == 2);
		// Clearing an override unbinds; a registration with a chord binds.
		Test.Assert(actions.Rebind("file.save", .()) case .Ok);
		Test.Assert(shortcuts.BoundCount == 2);
		Test.Assert(!bed.Root.HandlesCommand("file.save"));
		bed.Press(.F2);
		Test.Assert(saves == 2);
		int runs = 0;
		let run = Declare("sim.run", "Simulate", "f5");
		delete run.Execute;
		run.Execute = new [&runs](page) => { runs++; };
		Test.Assert(actions.Register(run));
		Test.Assert(shortcuts.BoundCount == 3);
		bed.Press(.F5);
		Test.Assert(runs == 1);
	}

	[Test]
	public static void ADisabledActionIsNotRun()
	{
		let actions = scope EditorActionRegistry();
		int saves = 0;
		bool dirty = false;
		let save = Declare("file.save", "Save", "ctrl-s");
		save.Enabled = new [&dirty](page) => dirty;
		delete save.Execute;
		save.Execute = new [&saves](page) => { saves++; };
		Test.Assert(actions.Register(save));
		let bed = scope ShortcutsBed();
		let shortcuts = scope ActionShortcuts(bed.Keymap, bed.Root, actions);
		Test.Assert(shortcuts.BoundCount == 1);
		// The chord runs through the registry, which refuses an action that is not enabled.
		bed.Press(.S, KeyModCtrl);
		Test.Assert(saves == 0);
		dirty = true;
		bed.Press(.S, KeyModCtrl);
		Test.Assert(saves == 1);
	}

	[Test]
	public static void AFocusedWidgetsOwnBindingOfTheSameKeysRunsFirst()
	{
		let actions = scope EditorActionRegistry();
		int undos = 0;
		let undo = Declare("edit.undo", "Undo", "ctrl-z");
		delete undo.Execute;
		undo.Execute = new [&undos](page) => { undos++; };
		Test.Assert(actions.Register(undo));
		let bed = scope ShortcutsBed();
		let shortcuts = scope ActionShortcuts(bed.Keymap, bed.Root, actions);
		Test.Assert(shortcuts.BoundCount == 1);
		// A field of its own context with its own undo on the same keys.
		let field = new Button();
		defer field.ReleaseRef();
		field.KeyContext = "field";
		int own = 0;
		field.OnCommand("field.undo", new [&own](command) => { own++; });
		Test.Assert(bed.Keymap.Bind("ctrl-z", "field.undo", "field"));
		bed.Frame.AddChild(field);
		field.RequestFocus();
		bed.Press(.Z, KeyModCtrl);
		Test.Assert(own == 1);
		Test.Assert(undos == 0);
		bed.Root.EventDispatcher.FocusNode = null;
		bed.Press(.Z, KeyModCtrl);
		Test.Assert(own == 1);
		Test.Assert(undos == 1);

		// The GUI's own text field keeps Ctrl+Z for its undo the same way.
		let text = new TextField();
		defer text.ReleaseRef();
		text.Size = .(100.0f, 20.0f);
		bed.Frame.AddChild(text);
		text.RequestFocus();
		text.Text = "hello";
		bed.Press(.Z, KeyModCtrl);
		Test.Assert(undos == 1);
	}

	[Test]
	public static void ASetThatDiesTakesItsBindingsAndHandlers()
	{
		let actions = scope EditorActionRegistry();
		int saves = 0;
		let save = Declare("file.save", "Save", "ctrl-s");
		delete save.Execute;
		save.Execute = new [&saves](page) => { saves++; };
		Test.Assert(actions.Register(save));
		let bed = scope ShortcutsBed();
		let before = bed.Keymap.BindingCount;
		{
			let shortcuts = scope ActionShortcuts(bed.Keymap, bed.Root, actions);
			Test.Assert(shortcuts.BoundCount == 1);
			Test.Assert(bed.Keymap.BindingCount == before + 1);
			Test.Assert(bed.Root.HandlesCommand("file.save"));
		}
		Test.Assert(bed.Keymap.BindingCount == before);
		Test.Assert(!bed.Root.HandlesCommand("file.save"));
		bed.Press(.S, KeyModCtrl);
		Test.Assert(saves == 0);
		// A registration after it is gone reaches nobody (it would call into freed memory).
		Test.Assert(actions.Register(Declare("file.exit", "Exit", "ctrl-q")));
		Test.Assert(bed.Keymap.BindingCount == before);
	}
}
