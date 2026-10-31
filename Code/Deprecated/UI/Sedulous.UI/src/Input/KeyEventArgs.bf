namespace Sedulous.UI;

/// Key event data. Pooled, like the rest of the event args.
class KeyEventArgs
{
	public KeyCode Key = .Unknown;
	public int32 ScanCode = 0;
	public KeyModifiers Modifiers = .None;
	public bool IsRepeat = false;
	public float Timestamp = 0.0f;
	public bool Handled = false;
	public EventPhase Phase = .Target;

	public void Reset()
	{
		Key = .Unknown;
		ScanCode = 0;
		Modifiers = .None;
		IsRepeat = false;
		Timestamp = 0.0f;
		Handled = false;
		Phase = .Target;
	}

	public void Set(KeyCode key, KeyModifiers modifiers, bool isRepeat, float timestamp = 0.0f,
		int32 scanCode = 0)
	{
		Key = key;
		ScanCode = scanCode;
		Modifiers = modifiers;
		IsRepeat = isRepeat;
		Timestamp = timestamp;
		Handled = false;
		Phase = .Target;
	}
}
