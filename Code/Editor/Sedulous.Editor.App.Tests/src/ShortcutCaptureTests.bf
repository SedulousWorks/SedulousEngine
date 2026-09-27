using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App.Tests;

/// The chord capture button: click, press, chosen, with the cancel, clear, modifier-alone and
/// focus-lost rules.
static class ShortcutCaptureTests
{
	private static KeyEventArgs Key(KeyCode key, KeyModifiers modifiers = .None)
	{
		let e = new KeyEventArgs();
		e.Key = key;
		e.Modifiers = modifiers;
		return e;
	}

	[Test]
	public static void ClickPressChosenWithTheCancelClearModifierAloneAndFocusLostRules()
	{
		let ctrlS = EditorShortcut(.S, .Ctrl);
		let button = new ShortcutCaptureButton(ctrlS);
		defer button.ReleaseRef();
		Test.Assert(button.Text.Value == "Ctrl+S");
		Test.Assert(!button.IsCapturing);
		let chosen = scope List<EditorShortcut>();
		button.OnChordChosen = new [&](chord) => { chosen.Add(chord); };

		// A key while idle is the button's (Return clicks, which begins a capture).
		let enter = Key(.Return);
		defer delete enter;
		button.OnKeyDown(enter);
		Test.Assert(button.IsCapturing);
		Test.Assert(button.Text.Value.StartsWith("Press a chord"));

		// A modifier alone keeps waiting; the next key with LEFT ctrl held is Ctrl+K, normalised.
		let ctrlAlone = Key(.LeftCtrl, .LeftCtrl);
		defer delete ctrlAlone;
		button.OnKeyDown(ctrlAlone);
		Test.Assert(ctrlAlone.Handled);
		Test.Assert(button.IsCapturing);
		Test.Assert(chosen.IsEmpty);
		let unknown = Key(.Unknown, .LeftCtrl); // a key the shell could not map: keep waiting
		defer delete unknown;
		button.OnKeyDown(unknown);
		Test.Assert(unknown.Handled);
		Test.Assert(button.IsCapturing);
		Test.Assert(chosen.IsEmpty);
		let k = Key(.K, .LeftCtrl | .NumLock); // a lock key is not part of a chord
		defer delete k;
		button.OnKeyDown(k);
		Test.Assert(k.Handled);
		Test.Assert(!button.IsCapturing);
		Test.Assert(chosen.Count == 1);
		Test.Assert(chosen[0] == EditorShortcut(.K, .Ctrl));
		Test.Assert(button.Chord == chosen[0]);
		Test.Assert(button.Text.Value == "Ctrl+K");

		// Escape cancels: the chord stays, nothing chosen.
		button.BeginCapture();
		let escape = Key(.Escape);
		defer delete escape;
		button.OnKeyDown(escape);
		Test.Assert(!button.IsCapturing);
		Test.Assert(chosen.Count == 1);
		Test.Assert(button.Text.Value == "Ctrl+K");

		// Delete chooses "no shortcut".
		button.BeginCapture();
		let del = Key(.Delete);
		defer delete del;
		button.OnKeyDown(del);
		Test.Assert(chosen.Count == 2);
		Test.Assert(!chosen[1].IsSet);
		Test.Assert(button.Text.Value == "(none)");

		// Losing focus cancels a capture in progress.
		button.BeginCapture();
		Test.Assert(button.IsCapturing);
		button.OnFocusLost();
		Test.Assert(!button.IsCapturing);
		Test.Assert(chosen.Count == 2);

		// SetChord shows a chord set from outside (Reset showing the default) and ends a capture.
		button.BeginCapture();
		button.SetChord(ctrlS);
		Test.Assert(!button.IsCapturing);
		Test.Assert(button.Text.Value == "Ctrl+S");
	}
}
