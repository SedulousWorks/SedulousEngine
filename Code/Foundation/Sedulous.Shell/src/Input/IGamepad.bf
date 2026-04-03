using System;

namespace Sedulous.Shell.Input;

/// Gamepad/controller input interface.
public interface IGamepad
{
	/// Gets the gamepad index (0-based).
	int Index { get; }

	/// Gets the gamepad name.
	StringView Name { get; }

	/// Gets whether the gamepad is currently connected.
	bool Connected { get; }

	/// Returns true if the button is currently held down.
	bool IsButtonDown(GamepadButton button);

	/// Returns true if the button was just pressed this frame.
	bool IsButtonPressed(GamepadButton button);

	/// Returns true if the button was just released this frame.
	bool IsButtonReleased(GamepadButton button);

	/// Gets the axis value (-1 to 1 for sticks, 0 to 1 for triggers).
	float GetAxis(GamepadAxis axis);

	/// Starts a rumble effect.
	/// lowFreq and highFreq are intensity values from 0 to 1.
	void SetRumble(float lowFreq, float highFreq, uint32 durationMs);
}
