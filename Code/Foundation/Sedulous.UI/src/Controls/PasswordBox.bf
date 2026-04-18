namespace Sedulous.UI;

using System;

/// Text input that masks characters for password entry.
/// Copy and cut are disabled to prevent leaking passwords.
public class PasswordBox : EditText
{
	private char32 mPasswordChar = '*';

	public char32 PasswordChar
	{
		get => mPasswordChar;
		set { mPasswordChar = value; InvalidateVisual(); }
	}

	public this() : base()
	{
		mBehavior.AllowClipboardCopy = false;
	}

	protected override void GetDisplayText(String outText)
	{
		outText.Clear();
		for (let c in Text.DecodedChars)
			outText.Append(mPasswordChar);
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		// Block Ctrl+C and Ctrl+X for password security.
		if (e.Modifiers.HasFlag(.Ctrl) && (e.Key == .C || e.Key == .X))
		{
			e.Handled = true;
			return;
		}
		base.OnKeyDown(e);
	}
}
