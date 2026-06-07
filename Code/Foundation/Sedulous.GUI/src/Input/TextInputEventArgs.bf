namespace Sedulous.GUI;

/// Pooled text input event args (post-IME composition).
public class TextInputEventArgs
{
	/// The Unicode character entered.
	public char32 Character;

	/// Set by handler to stop event propagation.
	public bool Handled;

	public void Reset()
	{
		Character = 0;
		Handled = false;
	}
}
