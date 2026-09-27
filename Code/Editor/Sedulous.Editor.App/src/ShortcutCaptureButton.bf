using System;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// A button that shows a chord and, once clicked, takes the next key the user presses as the
/// new one (modifiers normalised to Ctrl, Shift, Alt and Gui, the way a declaration spells
/// them). Escape cancels the capture, Backspace or Delete chooses "no shortcut", a modifier
/// alone is not a chord, and losing focus cancels. What Preferences > Shortcuts puts in every
/// row.
class ShortcutCaptureButton : Button
{
	/// Fired with the chord the user chose (unset is no shortcut); the button shows it. Owned.
	public delegate void(EditorShortcut chord) OnChordChosen ~ delete _;

	private EditorShortcut mChord;
	private bool mCapturing = false;

	public this(EditorShortcut chord) : base("")
	{
		mChord = chord;
		ShowChord();
		OnClick.Add(new (b) => { BeginCapture(); });
	}

	public EditorShortcut Chord => mChord;
	public bool IsCapturing => mCapturing;

	/// Shows a chord set from outside (Reset showing the default) and ends a capture.
	public void SetChord(EditorShortcut chord)
	{
		mChord = chord;
		mCapturing = false;
		ShowChord();
	}

	public void BeginCapture()
	{
		if (mCapturing)
			return;
		mCapturing = true;
		SetText("Press a chord... (Esc cancels, Del clears)");
		if (Context != null)
			Context.GetFocusManager().SetFocus(this);
	}

	public void CancelCapture()
	{
		if (!mCapturing)
			return;
		mCapturing = false;
		ShowChord();
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!mCapturing)
		{
			base.OnKeyDown(e); // Return or Space clicks, which begins a capture
			return;
		}
		e.Handled = true;
		switch (e.Key)
		{
		case .Escape:
			CancelCapture();
		case .Backspace, .Delete:
			Choose(.());
		case .LeftCtrl, .LeftShift, .LeftAlt, .LeftGui, .RightCtrl, .RightShift, .RightAlt, .RightGui,
			.Unknown: // a key the shell could not name is no chord either
			// A modifier alone is not a chord: keep waiting.
		default:
			Choose(.(e.Key, Shortcut.Normalize(e.Modifiers)));
		}
	}

	public override void OnFocusLost()
	{
		CancelCapture();
		base.OnFocusLost();
	}

	private void Choose(EditorShortcut chord)
	{
		mCapturing = false;
		mChord = chord;
		ShowChord();
		if (OnChordChosen != null)
			OnChordChosen(chord);
	}

	private void ShowChord()
	{
		let text = mChord.ToString(.. scope .());
		SetText(text.IsEmpty ? "(none)" : text);
	}
}
