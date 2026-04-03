namespace Sedulous.Animation;

using System;

/// Types of parameters that can drive animation graph transitions and blend trees.
enum AnimationParameterType
{
	Float,
	Int,
	Bool,
	/// Trigger is like Bool but auto-resets to false after being consumed.
	Trigger
}

/// A named parameter used to drive animation graph behavior.
class AnimationGraphParameter
{
	/// Parameter name.
	public String Name ~ delete _;

	/// Parameter type.
	public AnimationParameterType Type;

	/// Current value stored as a union-like set of fields.
	private float mFloatValue;
	private int32 mIntValue;
	private bool mBoolValue;

	public this(StringView name, AnimationParameterType type)
	{
		Name = new .(name);
		Type = type;
	}

	/// Gets/sets the float value. Only meaningful when Type == .Float.
	public float FloatValue
	{
		get => mFloatValue;
		set => mFloatValue = value;
	}

	/// Gets/sets the int value. Only meaningful when Type == .Int.
	public int32 IntValue
	{
		get => mIntValue;
		set => mIntValue = value;
	}

	/// Gets/sets the bool value. Meaningful for Type == .Bool or .Trigger.
	public bool BoolValue
	{
		get => mBoolValue;
		set => mBoolValue = value;
	}

	/// Resets trigger to false (called after all layers have processed transitions).
	public void ConsumeTrigger()
	{
		if (Type == .Trigger)
			mBoolValue = false;
	}
}
