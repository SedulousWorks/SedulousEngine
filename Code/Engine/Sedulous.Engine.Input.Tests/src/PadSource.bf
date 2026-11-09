using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.Input.Tests;

/// One pad and no other device, its buttons pressed as the test says.
class PadSource : IInputSourceProvider
{
	public class Pad : IGamepad
	{
		/// The button pressed this frame, if any.
		public GamepadButton? Pressed = null;

		public int32 Index => 0;
		public StringView Name => "pad";
		public bool Connected => true;
		public bool IsButtonDown(GamepadButton button) => Pressed.HasValue && (Pressed.Value == button);
		public bool IsButtonPressed(GamepadButton button) => Pressed.HasValue && (Pressed.Value == button);
		public bool IsButtonReleased(GamepadButton button) => false;
		public float Axis(GamepadAxis axis) => 0.0f;
		public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs) {}
	}

	public Pad Gamepad = new .() ~ delete _;

	public IKeyboard Keyboard => null;
	public IMouse Mouse => null;
	public int32 GamepadCount => 1;
	public IGamepad GetGamepad(int32 index) => (index == 0) ? Gamepad : null;
}
