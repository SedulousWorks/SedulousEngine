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
	/// UTF-8, null terminated, for TextInput.
	public char8[32] Text;
}
