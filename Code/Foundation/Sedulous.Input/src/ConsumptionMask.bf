namespace Sedulous.Input;

/// The device CLASSES a UI took this frame.
///
/// Bindings on a consumed class read released through actions, while the raw facades stay
/// unfiltered: a tool that legitimately wants the pointer regardless can still have it.
///
/// Two classes rather than one flag, so a menu eating the mouse does not also mute gamepad
/// movement. Republished every frame by whoever owns the UI, and sticky until it changes.
struct ConsumptionMask
{
	/// MouseButton, MouseAxis, MouseDelta, TouchButton and TouchStick.
	public bool Pointer = false;
	/// Key, and Composite2D, which is four keys.
	public bool Keyboard = false;

	public this() {}
}
