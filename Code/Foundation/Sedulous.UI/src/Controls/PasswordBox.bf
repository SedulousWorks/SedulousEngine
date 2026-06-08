namespace Sedulous.UI;

using System;

/// Masked password input. Extends EditText to show mask characters
/// instead of the actual text. Clipboard copy is disabled for security.
public class PasswordBox : EditText
{
	/// The character used to mask each real character.
	public Property<char32> PasswordChar = new .('*') ~ delete _;

	public this() : base()
	{
		mBehavior.AllowClipboardCopy = false;
		PasswordChar.SetOwner(this, .Visual);
	}

	protected override void GetDisplayText(String outText)
	{
		outText.Clear();
		for (let c in Text.DecodedChars)
			outText.Append(PasswordChar.Value);
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
