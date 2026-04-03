namespace Sedulous.Animation;

using System;
using System.Collections;

/// Comparison operators for transition conditions.
enum ComparisonOp
{
	Equal,
	NotEqual,
	Greater,
	Less,
	GreaterEqual,
	LessEqual
}

/// A single condition that must be met for a transition to fire.
struct AnimationGraphCondition
{
	/// Index of the parameter to compare.
	public int32 ParameterIndex;

	/// Comparison operator.
	public ComparisonOp Op;

	/// Threshold value for float/int comparisons.
	public float Threshold;

	public this(int32 parameterIndex, ComparisonOp op, float threshold = 0)
	{
		ParameterIndex = parameterIndex;
		Op = op;
		Threshold = threshold;
	}

	/// Evaluates this condition against a parameter value.
	public bool Evaluate(AnimationGraphParameter param)
	{
		if (param == null)
			return false;

		switch (param.Type)
		{
		case .Float:
			return CompareFloat(param.FloatValue);

		case .Int:
			return CompareFloat((float)param.IntValue);

		case .Bool, .Trigger:
			// For bool/trigger, treat as true/false comparison
			// Equal with threshold > 0.5 means "is true"
			// Equal with threshold <= 0.5 means "is false"
			switch (Op)
			{
			case .Equal:
				return param.BoolValue == (Threshold > 0.5f);
			case .NotEqual:
				return param.BoolValue != (Threshold > 0.5f);
			default:
				return param.BoolValue;
			}
		}
	}

	private bool CompareFloat(float value)
	{
		switch (Op)
		{
		case .Equal: return Math.Abs(value - Threshold) < 0.0001f;
		case .NotEqual: return Math.Abs(value - Threshold) >= 0.0001f;
		case .Greater: return value > Threshold;
		case .Less: return value < Threshold;
		case .GreaterEqual: return value >= Threshold;
		case .LessEqual: return value <= Threshold;
		}
	}
}

/// A transition between two states in an animation layer.
class AnimationGraphTransition
{
	/// Source state index (-1 = "Any State" transition).
	public int32 SourceStateIndex = -1;

	/// Destination state index.
	public int32 DestStateIndex;

	/// Conditions that must ALL be true for this transition to fire.
	public List<AnimationGraphCondition> Conditions = new .() ~ delete _;

	/// Cross-fade duration in seconds.
	public float Duration = 0.25f;

	/// Whether to wait for exit time before allowing this transition.
	public bool HasExitTime;

	/// Normalized time [0..1] at which the transition can fire (if HasExitTime is true).
	public float ExitTime = 1.0f;

	/// Priority for ordering when multiple transitions are valid (lower = higher priority).
	public int32 Priority;

	/// Evaluates whether all conditions are met.
	public bool EvaluateConditions(List<AnimationGraphParameter> parameters)
	{
		for (let condition in Conditions)
		{
			if (condition.ParameterIndex < 0 || condition.ParameterIndex >= parameters.Count)
				return false;

			if (!condition.Evaluate(parameters[condition.ParameterIndex]))
				return false;
		}
		return true;
	}

	/// Adds a condition that checks if a bool/trigger parameter is true.
	public void AddBoolCondition(int32 parameterIndex, bool expectedValue = true)
	{
		Conditions.Add(.(parameterIndex, .Equal, expectedValue ? 1.0f : 0.0f));
	}

	/// Adds a float comparison condition.
	public void AddFloatCondition(int32 parameterIndex, ComparisonOp op, float threshold)
	{
		Conditions.Add(.(parameterIndex, op, threshold));
	}

	/// Adds an int comparison condition.
	public void AddIntCondition(int32 parameterIndex, ComparisonOp op, int32 threshold)
	{
		Conditions.Add(.(parameterIndex, op, (float)threshold));
	}
}
