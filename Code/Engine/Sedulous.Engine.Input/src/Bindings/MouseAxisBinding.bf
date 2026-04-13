namespace Sedulous.Engine.Input;

using System;
using Sedulous.Shell.Input;

/// Mouse axis type for binding.
enum MouseAxisType
{
	/// Mouse X delta (movement).
	DeltaX,
	/// Mouse Y delta (movement).
	DeltaY,
	/// Mouse scroll X (horizontal scroll).
	ScrollX,
	/// Mouse scroll Y (vertical scroll).
	ScrollY,
	/// Both X and Y delta as Vector2.
	Delta,
	/// Both scroll axes as Vector2.
	Scroll
}

/// Binding for mouse movement or scroll wheel.
class MouseAxisBinding : InputBinding
{
	/// The mouse axis to bind.
	public MouseAxisType AxisType = .DeltaX;

	/// Sensitivity multiplier.
	public float Sensitivity = 1.0f;

	/// Whether to invert the axis.
	public bool Invert = false;

	public this()
	{
	}

	public this(MouseAxisType axisType, float sensitivity = 1.0f, bool invert = false)
	{
		AxisType = axisType;
		Sensitivity = sensitivity;
		Invert = invert;
		UpdateDisplayName();
	}

	public override InputSource Source => .Mouse;

	public override InputValue GetValue(IInputManager input)
	{
		let mouse = input.Mouse;
		float multiplier = Invert ? -Sensitivity : Sensitivity;

		switch (AxisType)
		{
		case .DeltaX:
			return .FromFloat(mouse.DeltaX * multiplier);
		case .DeltaY:
			return .FromFloat(mouse.DeltaY * multiplier);
		case .ScrollX:
			return .FromFloat(mouse.ScrollX * multiplier);
		case .ScrollY:
			return .FromFloat(mouse.ScrollY * multiplier);
		case .Delta:
			return .FromVector2(mouse.DeltaX * multiplier, mouse.DeltaY * multiplier);
		case .Scroll:
			return .FromVector2(mouse.ScrollX * multiplier, mouse.ScrollY * multiplier);
		}
	}

	public override bool WasPressed(IInputManager input)
	{
		return false;
	}

	public override bool WasReleased(IInputManager input)
	{
		return false;
	}

	protected override void UpdateDisplayName()
	{
		DisplayName.Clear();
		switch (AxisType)
		{
		case .DeltaX: DisplayName.Set("Mouse X");
		case .DeltaY: DisplayName.Set("Mouse Y");
		case .ScrollX: DisplayName.Set("Scroll X");
		case .ScrollY: DisplayName.Set("Scroll Y");
		case .Delta: DisplayName.Set("Mouse Movement");
		case .Scroll: DisplayName.Set("Mouse Scroll");
		}
	}

	public override InputBinding Clone()
	{
		return new MouseAxisBinding(AxisType, Sensitivity, Invert);
	}
}
