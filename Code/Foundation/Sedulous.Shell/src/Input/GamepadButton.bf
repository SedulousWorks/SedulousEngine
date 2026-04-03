namespace Sedulous.Shell.Input;

/// Gamepad button identifiers (following SDL3 naming).
public enum GamepadButton
{
	/// Bottom face button (A on Xbox, Cross on PlayStation).
	South,
	/// Right face button (B on Xbox, Circle on PlayStation).
	East,
	/// Left face button (X on Xbox, Square on PlayStation).
	West,
	/// Top face button (Y on Xbox, Triangle on PlayStation).
	North,
	/// Back/Select button.
	Back,
	/// Guide/Home button.
	Guide,
	/// Start button.
	Start,
	/// Left stick click.
	LeftStick,
	/// Right stick click.
	RightStick,
	/// Left shoulder/bumper.
	LeftShoulder,
	/// Right shoulder/bumper.
	RightShoulder,
	/// D-pad up.
	DPadUp,
	/// D-pad down.
	DPadDown,
	/// D-pad left.
	DPadLeft,
	/// D-pad right.
	DPadRight,
	/// Misc button (Xbox Series X share, PS5 mic, Nintendo Switch capture).
	Misc1,
	/// Additional paddle buttons.
	RightPaddle1,
	RightPaddle2,
	LeftPaddle1,
	LeftPaddle2,
	/// Touchpad button (PS4/PS5).
	Touchpad,

	Count
}
