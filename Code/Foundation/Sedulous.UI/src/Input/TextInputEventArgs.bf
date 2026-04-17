namespace Sedulous.UI;

/// Pooled text input event args. Carries a Unicode character from
/// the OS text input pipeline (after IME composition).
public class TextInputEventArgs
{
	public char32 Character;
	public bool Handled;

	public void Reset()
	{
		Character = 0;
		Handled = false;
	}
}
