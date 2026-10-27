using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The chord capture button: a click begins a capture, its focus taking every key; the next key
/// not a modifier is the chord, with the modifiers held; Escape cancels, Delete chooses none, a
/// modifier alone keeps waiting, and losing focus cancels. A chord a binding holds goes to the
/// button while it waits, not to the binding.
static class ShortcutCaptureTests
{
	[Test]
	public static void ClickPressChosenWithTheCancelClearModifierAloneAndFocusLostRules()
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(400.0f, 300.0f);
		let d = root.EventDispatcher;
		let button = new ShortcutCaptureButton();
		defer button.ReleaseRef();
		let other = new Sedulous.GUI.Button();
		defer other.ReleaseRef();
		root.AddChild(button);
		root.AddChild(other);
		button.SetChord(EditorShortcut.Of("ctrl-s"));
		Test.Assert(button.Text == EditorShortcut.Of("ctrl-s").ToString(.. scope .()));
		Test.Assert(!button.IsCapturing);
		let chosen = scope List<EditorShortcut>();
		button.SetOnChordChosen(new [&chosen](chord) => { chosen.Add(chord); });
		// A binding of the keys the user will press: while the button waits, it does not run.
		int bound = 0;
		Test.Assert(root.Context.Keymap.Bind("ctrl-shift-k", "test.bound"));
		root.OnCommand("test.bound", new [&bound](command) => { bound++; });

		Test.Assert(button.HandleActivate()); // a click (or Return): it waits
		Test.Assert(button.IsCapturing);
		Test.Assert(button.IsFocused);
		Test.Assert(button.CapturesAllKeys);
		Test.Assert(button.HasClass("capturing"));

		d.InjectKeyDown((uint32)KeyCode.LeftCtrl, KeyModCtrl); // a modifier alone
		Test.Assert(button.IsCapturing);
		Test.Assert(chosen.IsEmpty);
		d.InjectKeyDown((uint32)KeyCode.Unknown, KeyModCtrl); // a key the shell could not name
		Test.Assert(button.IsCapturing);
		Test.Assert(chosen.IsEmpty);
		d.InjectKeyDown((uint32)KeyCode.K, KeyModCtrl | KeyModShift);
		Test.Assert(!button.IsCapturing);
		Test.Assert(!button.CapturesAllKeys);
		Test.Assert(chosen.Count == 1);
		Test.Assert(chosen[0] == EditorShortcut.Of("ctrl-shift-k"));
		Test.Assert(bound == 0, "the button's, not the binding's");
		Test.Assert(button.Text == EditorShortcut.Of("ctrl-shift-k").ToString(.. scope .()));

		// Escape cancels: the chord stays, nothing chosen.
		Test.Assert(button.HandleActivate());
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!button.IsCapturing);
		Test.Assert(chosen.Count == 1);
		Test.Assert(button.Chord == EditorShortcut.Of("ctrl-shift-k"));
		Test.Assert(button.Text == EditorShortcut.Of("ctrl-shift-k").ToString(.. scope .()));

		// Delete chooses none.
		Test.Assert(button.HandleActivate());
		d.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(chosen.Count == 2);
		Test.Assert(!chosen[1].IsSet);
		Test.Assert(!button.Chord.IsSet);
		Test.Assert(button.Text == "None");

		// The focus leaving cancels; the keys are the GUI's again.
		Test.Assert(button.HandleActivate());
		other.RequestFocus();
		Test.Assert(!button.IsCapturing);
		Test.Assert(!button.CapturesAllKeys);
		Test.Assert(!button.HasClass("capturing"));
		Test.Assert(button.Text == "None", "the chord shown again");
		d.InjectKeyDown((uint32)KeyCode.K, KeyModCtrl | KeyModShift);
		Test.Assert(bound == 1);
		Test.Assert(chosen.Count == 2);

		// SetChord shows a chord set from outside (Reset showing the default) and ends a capture.
		Test.Assert(button.HandleActivate());
		button.SetChord(EditorShortcut.Of("ctrl-s"));
		Test.Assert(!button.IsCapturing);
		Test.Assert(!button.CapturesAllKeys);
		Test.Assert(button.Text == EditorShortcut.Of("ctrl-s").ToString(.. scope .()));
		Test.Assert(chosen.Count == 2, "not chosen by the user");
	}
}
