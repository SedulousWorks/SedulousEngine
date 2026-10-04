using System;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// A pad whose buttons and axes a test sets directly.
class FakeGamepad : IGamepad
{
	private bool[32] mDown = .();
	private bool[32] mPressed = .();
	private float[6] mAxes = .();

	public int32 Index { get; set; } = 0;
	public bool Connected { get; set; } = true;
	public StringView Name => "fake";

	public bool IsButtonDown(GamepadButton button) => mDown[(uint32)button & 31];
	public bool IsButtonPressed(GamepadButton button) => mPressed[(uint32)button & 31];
	public bool IsButtonReleased(GamepadButton button) => false;
	public float Axis(GamepadAxis axis) => mAxes[(uint32)axis % 6];

	public void SetDown(GamepadButton button, bool value = true) => mDown[(uint32)button & 31] = value;
	public void SetPressed(GamepadButton button, bool value = true) => mPressed[(uint32)button & 31] = value;
	public void SetAxis(GamepadAxis axis, float value) => mAxes[(uint32)axis % 6] = value;

	/// The last rumble asked of the pad, and how many times one was.
	public float RumbleLow = 0.0f;
	public float RumbleHigh = 0.0f;
	public uint32 RumbleMs = 0;
	public int RumbleCalls = 0;

	public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs)
	{
		RumbleLow = lowFrequency;
		RumbleHigh = highFrequency;
		RumbleMs = durationMs;
		RumbleCalls++;
	}
}
