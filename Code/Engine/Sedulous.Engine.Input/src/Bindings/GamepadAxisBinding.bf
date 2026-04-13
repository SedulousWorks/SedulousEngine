namespace Sedulous.Engine.Input;

using System;
using Sedulous.Shell.Input;

/// Binding for a gamepad axis (stick or trigger).
class GamepadAxisBinding : InputBinding
{
	/// The axis to bind.
	public GamepadAxis Axis = .LeftX;

	/// Gamepad index (0-based).
	public int32 GamepadIndex = 0;

	/// Dead zone threshold (0.0 to 1.0).
	public float DeadZone = 0.15f;

	/// Whether to invert the axis.
	public bool Invert = false;

	/// Sensitivity multiplier.
	public float Sensitivity = 1.0f;

	public this()
	{
	}

	public this(GamepadAxis axis, int32 gamepadIndex = 0, float deadZone = 0.15f)
	{
		Axis = axis;
		GamepadIndex = gamepadIndex;
		DeadZone = deadZone;
		UpdateDisplayName();
	}

	public override InputSource Source => .Gamepad;

	public override InputValue GetValue(IInputManager input)
	{
		let gamepad = input.GetGamepad(GamepadIndex);
		if (gamepad == null || !gamepad.Connected)
			return .FromFloat(0);

		float raw = gamepad.GetAxis(Axis);
		float processed = ApplyDeadZone(raw);
		if (Invert)
			processed = -processed;
		processed *= Sensitivity;
		return .FromFloat(processed);
	}

	public override bool WasPressed(IInputManager input)
	{
		let value = Math.Abs(GetValue(input).AsFloat);
		return value > 0.5f;
	}

	public override bool WasReleased(IInputManager input)
	{
		return false;
	}

	private float ApplyDeadZone(float value)
	{
		float absVal = Math.Abs(value);
		if (absVal < DeadZone)
			return 0;
		float sign = value > 0 ? 1.0f : -1.0f;
		return sign * ((absVal - DeadZone) / (1.0f - DeadZone));
	}

	protected override void UpdateDisplayName()
	{
		DisplayName.Clear();
		switch (Axis)
		{
		case .LeftX: DisplayName.Set("Left Stick X");
		case .LeftY: DisplayName.Set("Left Stick Y");
		case .RightX: DisplayName.Set("Right Stick X");
		case .RightY: DisplayName.Set("Right Stick Y");
		case .LeftTrigger: DisplayName.Set("Left Trigger");
		case .RightTrigger: DisplayName.Set("Right Trigger");
		default: Axis.ToString(DisplayName);
		}
	}

	public override InputBinding Clone()
	{
		return new GamepadAxisBinding(Axis, GamepadIndex, DeadZone)
		{
			Invert = Invert,
			Sensitivity = Sensitivity
		};
	}
}
