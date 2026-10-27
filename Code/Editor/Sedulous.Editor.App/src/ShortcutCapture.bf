using System;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// ShortcutCaptureButton: a button that shows a chord and, once clicked, takes the next key the user
// presses as the new one, with the modifiers held. While it waits its focus captures every key
// (Node.CapturesAllKeys), so no binding runs the chord instead. Escape cancels the capture,
// Backspace or Delete chooses "no shortcut", a modifier alone is not a chord, and losing focus
// cancels. What Preferences > Shortcuts puts in every row.

class ShortcutCaptureButton : Sedulous.GUI.Button
{
	private EditorShortcut mChord = .();
	private bool mCapturing = false;
	/// Told the chord the user chose. Owned.
	private delegate void(EditorShortcut chord) mOnChosen ~ delete _;

	public this()
	{
		AddClass("shortcut-capture");
		ShowChord();
		SetOnClick(new () => { BeginCapture(); });
	}

	/// Told the chord the user chose (unset: no shortcut); the button shows it. OWNERSHIP of
	/// `chosen` transfers.
	public void SetOnChordChosen(delegate void(EditorShortcut chord) chosen)
	{
		delete mOnChosen;
		mOnChosen = chosen;
	}

	public EditorShortcut Chord => mChord;
	public bool IsCapturing => mCapturing;

	/// Shows a chord set from outside (Reset showing the default) and ends a capture.
	public void SetChord(EditorShortcut chord)
	{
		mChord = chord;
		StopCapture();
		ShowChord();
	}

	public void BeginCapture()
	{
		if (mCapturing)
			return;
		mCapturing = true;
		AddClass("capturing");
		Text = "Press the keys (Esc cancels, Del clears)";
		RequestFocus();
		CapturesAllKeys = true;
	}

	public void CancelCapture()
	{
		if (!mCapturing)
			return;
		StopCapture();
		ShowChord();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if (!mCapturing)
		{
			base.OnKeyDown(e); // Return or Space click it (the dispatcher's activation), which begins a capture
			return;
		}
		e.Handled = true;
		let key = (KeyCode)e.KeyCode;
		if ((key == .Escape) && (e.Modifiers == 0))
			CancelCapture();
		else if (((key == .Backspace) || (key == .Delete)) && (e.Modifiers == 0))
			Choose(.());
		else if ((key != .Unknown) && (ModifierOfKey(key) == KeyModNone))
			Choose(.(Keystroke(e.KeyCode, e.Modifiers & (KeyModShift | KeyModCtrl | KeyModAlt | KeyModSuper), false)));
		// A modifier alone, or a key the shell could not name, is no chord: it keeps waiting.
	}

	protected override void OnFocusLost()
	{
		CancelCapture();
		base.OnFocusLost();
	}

	private void StopCapture()
	{
		if (!mCapturing)
			return;
		mCapturing = false;
		RemoveClass("capturing");
		CapturesAllKeys = false;
	}

	private void Choose(EditorShortcut chord)
	{
		StopCapture();
		mChord = chord;
		ShowChord();
		if (mOnChosen != null)
			mOnChosen(chord);
	}

	private void ShowChord()
	{
		let text = mChord.ToString(.. scope .());
		Text = text.IsEmpty ? "None" : text;
	}
}
