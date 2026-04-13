namespace Sedulous.Engine.Input;

using System;
using System.Collections;
using Sedulous.Shell.Input;
using Sedulous.Core.Mathematics;

/// A named action with one or more bindings.
/// Supports multiple bindings per action (e.g., W key OR Up arrow OR gamepad stick).
class InputAction
{
	/// Unique name for this action (e.g., "MoveForward", "Jump", "Fire").
	public String Name { get; private set; } = new .() ~ delete _;

	/// All bindings that can trigger this action.
	private List<InputBinding> mBindings = new .() ~ DeleteContainerAndItems!(_);

	/// Cached value from last update.
	private InputValue mCurrentValue;
	private InputValue mPreviousValue;

	public this(StringView name)
	{
		Name.Set(name);
	}

	/// Adds a binding to this action.
	public void AddBinding(InputBinding binding)
	{
		mBindings.Add(binding);
	}

	/// Removes a binding at the specified index.
	public void RemoveBindingAt(int index)
	{
		if (index >= 0 && index < mBindings.Count)
		{
			delete mBindings[index];
			mBindings.RemoveAt(index);
		}
	}

	/// Clears all bindings.
	public void ClearBindings()
	{
		DeleteContainerAndItems!(mBindings);
		mBindings = new .();
	}

	/// Gets the number of bindings.
	public int BindingCount => mBindings.Count;

	/// Gets a binding by index.
	public InputBinding GetBinding(int index)
	{
		if (index >= 0 && index < mBindings.Count)
			return mBindings[index];
		return null;
	}

	/// Updates the action's cached value from input.
	public void Update(IInputManager input)
	{
		mPreviousValue = mCurrentValue;
		mCurrentValue = .Zero;

		for (let binding in mBindings)
		{
			let value = binding.GetValue(input);
			// Use highest magnitude value across all bindings
			if (Math.Abs(value.X) > Math.Abs(mCurrentValue.X))
				mCurrentValue.X = value.X;
			if (Math.Abs(value.Y) > Math.Abs(mCurrentValue.Y))
				mCurrentValue.Y = value.Y;
		}
	}

	/// Returns true if action is currently active (button held or axis > threshold).
	public bool IsActive => mCurrentValue.AsBool;

	/// Returns true if action was just activated this frame.
	public bool WasPressed => mCurrentValue.AsBool && !mPreviousValue.AsBool;

	/// Returns true if action was just deactivated this frame.
	public bool WasReleased => !mCurrentValue.AsBool && mPreviousValue.AsBool;

	/// Gets the current value (for analog inputs).
	public float Value => mCurrentValue.AsFloat;

	/// Gets the current Vector2 value (for 2D composites).
	public Vector2 Vector2Value => mCurrentValue.AsVector2;

	/// Gets the raw InputValue.
	public InputValue RawValue => mCurrentValue;
}
