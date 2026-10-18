using System;

namespace Sedulous.Shell;

/// One input state change, tagged with the window it came from.
///
/// The event stream is the SOURCE OF TRUTH: the polled device snapshots are a fold over a
/// frame's events. That is what keeps polling and event handling from disagreeing, which
/// they do the moment each is maintained separately.
///
/// One struct for every kind rather than a variant per kind, because a backend queues
/// these by the thousand and the fields are read by whoever knows the kind.
struct InputEvent
{
	public InputEventKind Kind;
	/// The source window, or 0 for unknown or global.
	public uint32 Window;

	public KeyCode Key;
	public KeyModifiers Modifiers;
	public MouseButton Button;
	public GamepadButton PadButton;
	public GamepadAxis PadAxis;
	/// The gamepad's device index.
	public int32 Gamepad;

	/// Window space position for a move or a touch, or the wheel delta.
	public float X;
	public float Y;
	/// Relative movement, for a move.
	public float DX;
	public float DY;
	/// An axis value, or a touch pressure.
	public float Value;
	public uint64 TouchId;
	/// UTF-8, null terminated and in whole characters, for TextInput and TextEditing.
	public char8[64] Text;
	/// TextEditing: the caret within the composition, in characters.
	public int32 EditCursor;
	/// TextEditing: the characters selected from the caret, nought for none.
	public int32 EditLength;

	/// Copies null terminated UTF-8 into an event's text, as much as fits in whole characters.
	public static void CopyEventText(ref char8[64] outText, char8* source)
	{
		int n = 0;
		if (source != null)
		{
			while (((n + 1) < outText.Count) && (source[n] != 0))
				n++;
			// Back off a character the buffer would cut in two.
			if (source[n] != 0)
			{
				while ((n > 0) && (((uint8)source[n] & 0xC0) == 0x80))
					n--;
			}
			for (int i < n)
				outText[i] = source[i];
		}
		outText[n] = 0;
	}
}
