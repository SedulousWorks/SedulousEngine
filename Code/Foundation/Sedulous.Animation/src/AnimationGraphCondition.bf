using Sedulous.Core;

namespace Sedulous.Animation;

/// One test on a parameter, which a transition holds a set of.
struct AnimationGraphCondition
{
	public int32 ParameterIndex = 0;
	public ComparisonOp Op = .Equal;
	public float Threshold = 0.0f;

	public this() {}

	public this(int32 parameterIndex, ComparisonOp op, float threshold = 0.0f)
	{
		ParameterIndex = parameterIndex;
		Op = op;
		Threshold = threshold;
	}

	/// A missing parameter is FALSE rather than true: a condition that cannot be evaluated
	/// must not let a transition through.
	public bool Evaluate(AnimationGraphParameter parameter)
	{
		if (parameter == null)
			return false;

		switch (parameter.Type)
		{
		case .Float:
			return CompareFloat(parameter.FloatValue);
		case .Int:
			return CompareFloat((float)parameter.IntValue);
		case .Bool, .Trigger:
			switch (Op)
			{
			case .Equal: return parameter.BoolValue == (Threshold > 0.5f);
			case .NotEqual: return parameter.BoolValue != (Threshold > 0.5f);
			// An ordering on a boolean means nothing, so it reads as "is it set".
			default: return parameter.BoolValue;
			}
		}
	}

	private bool CompareFloat(float value)
	{
		switch (Op)
		{
		// Equality on a float is a TOLERANCE, since an authored threshold and a computed
		// value will not land on the same bits.
		case .Equal: return Abs(value - Threshold) < 0.0001f;
		case .NotEqual: return Abs(value - Threshold) >= 0.0001f;
		case .Greater: return value > Threshold;
		case .Less: return value < Threshold;
		case .GreaterEqual: return value >= Threshold;
		case .LessEqual: return value <= Threshold;
		}
	}
}
