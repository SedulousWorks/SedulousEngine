namespace Sedulous.UI;

/// Pooled key event args. One instance reused per event.
public class KeyEventArgs
{
	public KeyCode Key;
	public int32 ScanCode;          // physical key scan code (platform-specific)
	public KeyModifiers Modifiers;
	public bool IsRepeat;
	public float Timestamp;         // time of event in seconds (from frame clock)
	public bool Handled;

	public void Reset()
	{
		Key = .Unknown;
		ScanCode = 0;
		Modifiers = .None;
		IsRepeat = false;
		Timestamp = 0;
		Handled = false;
	}

	public void Set(KeyCode key, KeyModifiers modifiers, bool isRepeat, float timestamp = 0, int32 scanCode = 0)
	{
		Key = key;
		ScanCode = scanCode;
		Modifiers = modifiers;
		IsRepeat = isRepeat;
		Timestamp = timestamp;
		Handled = false;
	}
}
