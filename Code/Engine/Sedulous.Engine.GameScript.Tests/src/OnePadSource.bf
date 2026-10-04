using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.GameScript.Tests;

/// One pad and no other device, recording the last rumble asked of it.
class OnePadSource : IInputSourceProvider
{
	public class Pad : IGamepad
	{
		public float RumbleLow = 0.0f;
		public float RumbleHigh = 0.0f;
		public uint32 RumbleMs = 0;
		public int RumbleCalls = 0;

		public int32 Index => 0;
		public StringView Name => "pad";
		public bool Connected => true;
		public bool IsButtonDown(GamepadButton button) => false;
		public bool IsButtonPressed(GamepadButton button) => false;
		public bool IsButtonReleased(GamepadButton button) => false;
		public float Axis(GamepadAxis axis) => 0.0f;

		public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs)
		{
			RumbleLow = lowFrequency;
			RumbleHigh = highFrequency;
			RumbleMs = durationMs;
			RumbleCalls++;
		}
	}

	public Pad Gamepad = new .() ~ delete _;

	public IKeyboard Keyboard => null;
	public IMouse Mouse => null;
	public int32 GamepadCount => 1;
	public IGamepad GetGamepad(int32 index) => (index == 0) ? Gamepad : null;
}
