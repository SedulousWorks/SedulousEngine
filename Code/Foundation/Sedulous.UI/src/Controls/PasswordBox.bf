using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A text field that shows a mask instead of what was typed.
///
/// Only the DISPLAY is masked; the field still holds the real text, which is what a caller
/// reads back. Copying out is blocked at both doors: the behaviour's clipboard copy is off, and
/// the shortcuts are swallowed before they reach it.
class PasswordBox : EditText
{
	public Property<char32> PasswordChar = new .('*') ~ delete _;

	public this()
	{
		Behavior.AllowClipboardCopy = false;
		PasswordChar.SetOwner(this, .Visual);
	}

	/// One mask character per CHARACTER, not per byte, so the mask is as long as the text
	/// looks rather than as long as it is encoded.
	public override void GetDisplayText(String outText)
	{
		outText.Clear();
		let mask = PasswordChar.Value;
		for (int32 i < Utf8CharCount(Text))
			outText.Append(mask);
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		// Copy and cut are swallowed HERE as well as being off in the behaviour, so a
		// shortcut cannot reach a path that might still serve the real text.
		if (e.Modifiers.HasFlag(.Ctrl) && ((e.Key == .C) || (e.Key == .X)))
		{
			e.Handled = true;
			return;
		}

		base.OnKeyDown(e);
	}
}
