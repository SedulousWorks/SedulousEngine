namespace Sedulous.Engine.Input;

using System;
using Sedulous.Shell.Input;

/// Binding for a gamepad button.
class GamepadButtonBinding : InputBinding
{
	/// The button to bind.
	public GamepadButton Button = .South;

	/// Gamepad index (0-based).
	public int32 GamepadIndex = 0;

	public this()
	{
	}

	public this(GamepadButton button, int32 gamepadIndex = 0)
	{
		Button = button;
		GamepadIndex = gamepadIndex;
		UpdateDisplayName();
	}

	public override InputSource Source => .Gamepad;

	public override InputValue GetValue(IInputManager input)
	{
		let gamepad = input.GetGamepad(GamepadIndex);
		if (gamepad == null || !gamepad.Connected)
			return .FromBool(false);
		return .FromBool(gamepad.IsButtonDown(Button));
	}

	public override bool WasPressed(IInputManager input)
	{
		let gamepad = input.GetGamepad(GamepadIndex);
		if (gamepad == null || !gamepad.Connected)
			return false;
		return gamepad.IsButtonPressed(Button);
	}

	public override bool WasReleased(IInputManager input)
	{
		let gamepad = input.GetGamepad(GamepadIndex);
		if (gamepad == null || !gamepad.Connected)
			return false;
		return gamepad.IsButtonReleased(Button);
	}

	protected override void UpdateDisplayName()
	{
		DisplayName.Clear();
		switch (Button)
		{
		case .South: DisplayName.Set("Gamepad A");
		case .East: DisplayName.Set("Gamepad B");
		case .West: DisplayName.Set("Gamepad X");
		case .North: DisplayName.Set("Gamepad Y");
		case .Back: DisplayName.Set("Gamepad Back");
		case .Guide: DisplayName.Set("Gamepad Guide");
		case .Start: DisplayName.Set("Gamepad Start");
		case .LeftStick: DisplayName.Set("Left Stick Click");
		case .RightStick: DisplayName.Set("Right Stick Click");
		case .LeftShoulder: DisplayName.Set("Left Bumper");
		case .RightShoulder: DisplayName.Set("Right Bumper");
		case .DPadUp: DisplayName.Set("D-Pad Up");
		case .DPadDown: DisplayName.Set("D-Pad Down");
		case .DPadLeft: DisplayName.Set("D-Pad Left");
		case .DPadRight: DisplayName.Set("D-Pad Right");
		default: Button.ToString(DisplayName);
		}
	}

	public override InputBinding Clone()
	{
		return new GamepadButtonBinding(Button, GamepadIndex);
	}
}
