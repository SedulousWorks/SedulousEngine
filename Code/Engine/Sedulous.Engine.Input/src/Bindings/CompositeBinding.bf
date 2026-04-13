namespace Sedulous.Engine.Input;

using System;
using Sedulous.Shell.Input;
using Sedulous.Core.Mathematics;

/// Combines 4 bindings into a Vector2 (e.g., WASD movement).
/// PositiveY = forward (W), NegativeY = back (S)
/// PositiveX = right (D), NegativeX = left (A)
class CompositeBinding : InputBinding
{
	/// Binding for positive X direction (e.g., D key).
	public InputBinding PositiveX ~ delete _;
	/// Binding for negative X direction (e.g., A key).
	public InputBinding NegativeX ~ delete _;
	/// Binding for positive Y direction (e.g., W key).
	public InputBinding PositiveY ~ delete _;
	/// Binding for negative Y direction (e.g., S key).
	public InputBinding NegativeY ~ delete _;

	/// Whether to normalize the resulting vector.
	public bool Normalize = true;

	public this()
	{
	}

	/// Creates a composite binding from 4 key codes (WASD order: forward, back, left, right).
	public this(KeyCode forward, KeyCode back, KeyCode left, KeyCode right)
	{
		PositiveY = new KeyBinding(forward);
		NegativeY = new KeyBinding(back);
		NegativeX = new KeyBinding(left);
		PositiveX = new KeyBinding(right);
		UpdateDisplayName();
	}

	/// Creates a composite binding from 4 existing bindings.
	public this(InputBinding positiveX, InputBinding negativeX, InputBinding positiveY, InputBinding negativeY)
	{
		PositiveX = positiveX;
		NegativeX = negativeX;
		PositiveY = positiveY;
		NegativeY = negativeY;
		UpdateDisplayName();
	}

	public override InputSource Source => .Keyboard;

	public override InputValue GetValue(IInputManager input)
	{
		float x = 0, y = 0;

		if (PositiveX != null)
			x += PositiveX.GetValue(input).AsFloat;
		if (NegativeX != null)
			x -= NegativeX.GetValue(input).AsFloat;
		if (PositiveY != null)
			y += PositiveY.GetValue(input).AsFloat;
		if (NegativeY != null)
			y -= NegativeY.GetValue(input).AsFloat;

		var result = Vector2(x, y);
		if (Normalize && result.LengthSquared() > 1.0f)
			result = Vector2.Normalize(result);

		return .FromVector2(result);
	}

	public override bool WasPressed(IInputManager input)
	{
		if (PositiveX != null && PositiveX.WasPressed(input)) return true;
		if (NegativeX != null && NegativeX.WasPressed(input)) return true;
		if (PositiveY != null && PositiveY.WasPressed(input)) return true;
		if (NegativeY != null && NegativeY.WasPressed(input)) return true;
		return false;
	}

	public override bool WasReleased(IInputManager input)
	{
		bool allReleased = true;
		if (PositiveX != null && !PositiveX.WasReleased(input) && PositiveX.GetValue(input).AsBool) allReleased = false;
		if (NegativeX != null && !NegativeX.WasReleased(input) && NegativeX.GetValue(input).AsBool) allReleased = false;
		if (PositiveY != null && !PositiveY.WasReleased(input) && PositiveY.GetValue(input).AsBool) allReleased = false;
		if (NegativeY != null && !NegativeY.WasReleased(input) && NegativeY.GetValue(input).AsBool) allReleased = false;
		return allReleased;
	}

	protected override void UpdateDisplayName()
	{
		DisplayName.Clear();
		DisplayName.Set("Composite");
	}

	public override InputBinding Clone()
	{
		let clone = new CompositeBinding();
		if (PositiveX != null) clone.PositiveX = PositiveX.Clone();
		if (NegativeX != null) clone.NegativeX = NegativeX.Clone();
		if (PositiveY != null) clone.PositiveY = PositiveY.Clone();
		if (NegativeY != null) clone.NegativeY = NegativeY.Clone();
		clone.Normalize = Normalize;
		return clone;
	}
}
