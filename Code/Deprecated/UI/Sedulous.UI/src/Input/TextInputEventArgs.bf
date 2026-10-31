namespace Sedulous.UI;

/// Text input, AFTER any input method composition has settled, so a handler sees finished
/// characters rather than the half formed state of typing them.
class TextInputEventArgs
{
	/// The Unicode codepoint entered.
	public char32 Character = 0;
	public bool Handled = false;
	public EventPhase Phase = .Target;

	public void Reset()
	{
		Character = 0;
		Handled = false;
		Phase = .Target;
	}
}
