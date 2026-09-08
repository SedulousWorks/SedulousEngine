namespace Sedulous.Input;

/// What a rebind screen is willing to accept as the next binding.
///
/// The analog sources are OFF by default: a key rebind that listened to sticks would bind
/// whatever drift the pad happens to be reporting, before the player has touched anything.
struct CaptureFilter
{
	public bool Keys = true;
	public bool MouseButtons = true;
	public bool GamepadButtons = true;
	/// An axis rebind opts in.
	public bool GamepadAxes = false;
	public bool GamepadSticks = false;

	public this() {}
}
