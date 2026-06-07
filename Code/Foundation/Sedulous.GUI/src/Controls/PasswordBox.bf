namespace Sedulous.GUI;

using System;

/// Masked password input. Extends EditText to show mask characters
/// instead of the actual text. Clipboard copy is disabled for security.
public class PasswordBox : EditText
{
	private char32 mPasswordChar = '*';

	/// The character used to mask each real character.
	public char32 PasswordChar
	{
		get => mPasswordChar;
		set { mPasswordChar = value; Invalidate(); }
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
		// Block copy and cut.
		if (e.Modifiers.HasFlag(.Ctrl) && (e.Key == .C || e.Key == .X))
		{
			e.Handled = true;
			return;
		}
		base.OnKeyDown(e);
	}
}
