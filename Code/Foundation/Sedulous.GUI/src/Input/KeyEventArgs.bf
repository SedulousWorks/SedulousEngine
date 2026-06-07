namespace Sedulous.GUI;



/// Pooled key event args. One instance reused per event.
public class KeyEventArgs
{
	/// The key that was pressed/released.
	public KeyCode Key;

	/// Physical key scan code (platform-specific).
	public int32 ScanCode;

	/// Modifier keys held during this event.
	public KeyModifiers Modifiers;

	/// Whether this is a key repeat (held down).
	public bool IsRepeat;

	/// Time of event in seconds (from frame clock).
	public float Timestamp;

	/// Set by handler to stop event propagation.
	public bool Handled;

	/// Current phase of event propagation.
	public EventPhase Phase;

	public void Reset()
	{
		Key = .Unknown;
		ScanCode = 0;
		Modifiers = .None;
		IsRepeat = false;
		Timestamp = 0;
		Handled = false;
		Phase = .Target;
	}

	public void Set(KeyCode key, KeyModifiers modifiers, bool isRepeat,
		float timestamp = 0, int32 scanCode = 0)
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
