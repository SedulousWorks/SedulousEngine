namespace Sedulous.UI;

/// Pooled key event args. One instance reused per event.
public class KeyEventArgs
{
	public KeyCode Key;
	public KeyModifiers Modifiers;
	public bool IsRepeat;
	public bool Handled;

	public void Reset()
	{
		Key = .Unknown;
		Modifiers = .None;
		IsRepeat = false;
		Handled = false;
	}

	public void Set(KeyCode key, KeyModifiers modifiers, bool isRepeat)
	{
		Key = key;
		Modifiers = modifiers;
		IsRepeat = isRepeat;
		Handled = false;
	}
}
