using System;
using System.Collections;

namespace Sedulous.Animation;

/// A move from one state to another, taken when every condition holds.
class AnimationGraphTransition
{
	/// Minus one is ANY state, which is how a death or a hit reaction is reached from
	/// wherever the character happened to be.
	public int32 SourceStateIndex = -1;
	public int32 DestStateIndex = 0;

	/// The cross fade, in seconds.
	public float Duration = 0.25f;

	/// Whether the source has to reach a point in its own playback first, which is what
	/// keeps a transition from cutting an attack's swing in half.
	public bool HasExitTime = false;
	public float ExitTime = 1.0f;

	/// LOWER WINS, so a nought priority beats everything and the default set of transitions
	/// is resolved in the order they read.
	public int32 Priority = 0;

	public List<AnimationGraphCondition> Conditions = new .() ~ delete _;

	public void AddBoolCondition(int32 parameterIndex, bool expected = true)
	{
		Conditions.Add(.(parameterIndex, .Equal, expected ? 1.0f : 0.0f));
	}

	public void AddFloatCondition(int32 parameterIndex, ComparisonOp op, float threshold)
	{
		Conditions.Add(.(parameterIndex, op, threshold));
	}

	public void AddIntCondition(int32 parameterIndex, ComparisonOp op, int32 threshold)
	{
		Conditions.Add(.(parameterIndex, op, (float)threshold));
	}

	/// EVERY condition has to hold. An empty set is unconditional, which is how a state that
	/// simply follows another is spelled.
	public bool EvaluateConditions(Span<AnimationGraphParameter> parameters)
	{
		for (let condition in Conditions)
		{
			if ((condition.ParameterIndex < 0) || (condition.ParameterIndex >= parameters.Length))
				return false;
			if (!condition.Evaluate(parameters[condition.ParameterIndex]))
				return false;
		}
		return true;
	}
}
