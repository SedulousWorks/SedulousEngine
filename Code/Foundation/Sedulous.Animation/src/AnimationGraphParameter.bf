using System;

namespace Sedulous.Animation;

/// A named value that drives transitions and blend trees.
class AnimationGraphParameter
{
	private String mName = new .() ~ delete _;

	public AnimationParameterType Type = .Float;
	public float FloatValue = 0.0f;
	public int32 IntValue = 0;
	public bool BoolValue = false;

	public this() {}

	public this(StringView name, AnimationParameterType type)
	{
		mName.Set(name);
		Type = type;
	}

	public String Name => mName;

	public void CopyFrom(AnimationGraphParameter other)
	{
		mName.Set(other.mName);
		Type = other.Type;
		FloatValue = other.FloatValue;
		IntValue = other.IntValue;
		BoolValue = other.BoolValue;
	}

	/// Clears a trigger once it has been seen. Only a trigger: a plain bool is the caller's
	/// to clear.
	public void ConsumeTrigger()
	{
		if (Type == .Trigger)
			BoolValue = false;
	}
}
