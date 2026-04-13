namespace Sedulous.Engine.Input;

using System;
using Sedulous.Shell.Input;

/// Binding for a mouse button.
class MouseButtonBinding : InputBinding
{
	/// The mouse button to bind.
	public MouseButton Button = .Left;

	public this()
	{
	}

	public this(MouseButton button)
	{
		Button = button;
		UpdateDisplayName();
	}

	public override InputSource Source => .Mouse;

	public override InputValue GetValue(IInputManager input)
	{
		return .FromBool(input.Mouse.IsButtonDown(Button));
	}

	public override bool WasPressed(IInputManager input)
	{
		return input.Mouse.IsButtonPressed(Button);
	}

	public override bool WasReleased(IInputManager input)
	{
		return input.Mouse.IsButtonReleased(Button);
	}

	protected override void UpdateDisplayName()
	{
		DisplayName.Clear();
		switch (Button)
		{
		case .Left: DisplayName.Set("Left Mouse");
		case .Middle: DisplayName.Set("Middle Mouse");
		case .Right: DisplayName.Set("Right Mouse");
		case .X1: DisplayName.Set("Mouse X1");
		case .X2: DisplayName.Set("Mouse X2");
		}
	}

	public override InputBinding Clone()
	{
		return new MouseButtonBinding(Button);
	}
}
