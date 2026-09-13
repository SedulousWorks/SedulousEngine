using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.GameInstance.Tests;

/// One keyboard reporting a single held key, and no other device.
///
/// Two of these, each behind its own instance, is what the per instance isolation case is
/// measured with: the same map and the same key, and only the source actually holding it
/// may fire.
class OneKeySource : IInputSourceProvider
{
	private class OneKeyKeyboard : IKeyboard
	{
		public KeyCode Key = .A;
		public bool Down = false;

		public bool IsKeyDown(KeyCode key) => Down && (key == Key);
		public bool IsKeyPressed(KeyCode key) => Down && (key == Key);
		public bool IsKeyReleased(KeyCode key) => false;
		public KeyModifiers Modifiers => .None;
	}

	private OneKeyKeyboard mKeyboard = new .() ~ delete _;

	public KeyCode Key
	{
		get => mKeyboard.Key;
		set => mKeyboard.Key = value;
	}

	public bool Down
	{
		get => mKeyboard.Down;
		set => mKeyboard.Down = value;
	}

	public IKeyboard Keyboard => mKeyboard;
	public IMouse Mouse => null;
	public int32 GamepadCount => 0;
	public IGamepad GetGamepad(int32 index) => null;
}
