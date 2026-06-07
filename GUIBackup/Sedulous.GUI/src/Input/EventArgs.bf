namespace Sedulous.GUI;

using System;

/// Base for all input event args. Pooled for efficiency.
public class InputEventArgs
{
	/// The current phase of event propagation.
	public EventPhase Phase;

	/// Set to true to stop further propagation.
	public bool Handled;

	public void Reset()
	{
		Phase = .Target;
		Handled = false;
	}
}

/// Mouse button event args (down, up, move).
public class MouseEventArgs : InputEventArgs
{
	public float X, Y;
	public MouseButton Button;
	public int32 ClickCount;
	public KeyModifiers Modifiers;
	public float Timestamp;

	public new void Reset()
	{
		base.Reset();
		X = 0; Y = 0;
		Button = .Left;
		ClickCount = 0;
		Modifiers = .None;
		Timestamp = 0;
	}
}

/// Mouse wheel event args.
public class MouseWheelEventArgs : InputEventArgs
{
	public float X, Y;
	public float DeltaX, DeltaY;
	public KeyModifiers Modifiers;

	public new void Reset()
	{
		base.Reset();
		X = 0; Y = 0;
		DeltaX = 0; DeltaY = 0;
		Modifiers = .None;
	}
}

/// Keyboard event args.
public class KeyEventArgs : InputEventArgs
{
	public KeyCode Key;
	public int32 ScanCode;
	public KeyModifiers Modifiers;
	public bool IsRepeat;
	public float Timestamp;

	public new void Reset()
	{
		base.Reset();
		Key = .Unknown;
		ScanCode = 0;
		Modifiers = .None;
		IsRepeat = false;
		Timestamp = 0;
	}
}

/// Text input event args (post-IME composition).
public class TextInputEventArgs : InputEventArgs
{
	public char32 Character;

	public new void Reset()
	{
		base.Reset();
		Character = 0;
	}
}
