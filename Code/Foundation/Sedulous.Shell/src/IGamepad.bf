using System;

namespace Sedulous.Shell;

interface IGamepad
{
	int32 Index { get; }
	StringView Name { get; }
	bool Connected { get; }

	bool IsButtonDown(GamepadButton button);
	bool IsButtonPressed(GamepadButton button);
	bool IsButtonReleased(GamepadButton button);
	/// Sticks report -1 to 1, triggers 0 to 1.
	float Axis(GamepadAxis axis);

	/// Motor strengths from 0 to 1, for a duration in milliseconds.
	void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs);
}
