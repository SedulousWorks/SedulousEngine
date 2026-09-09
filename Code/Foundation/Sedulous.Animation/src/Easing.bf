using Sedulous.Core;

namespace Sedulous.Animation;

/// The bridge from the serializable curve name to the maths.
static class Easing
{
	/// The function a type names. NEVER null: an unknown value is linear, because a curve
	/// that cannot be resolved should play straight rather than not at all.
	public static EasingFunction ToFunction(EasingType type)
	{
		switch (type)
		{
		case .Linear: return => EaseInLinear;
		case .EaseInQuadratic: return => EaseInQuadratic;
		case .EaseOutQuadratic: return => EaseOutQuadratic;
		case .EaseInOutQuadratic: return => EaseInOutQuadratic;
		case .EaseInCubic: return => EaseInCubic;
		case .EaseOutCubic: return => EaseOutCubic;
		case .EaseInOutCubic: return => EaseInOutCubic;
		case .EaseInQuartic: return => EaseInQuartic;
		case .EaseOutQuartic: return => EaseOutQuartic;
		case .EaseInOutQuartic: return => EaseInOutQuartic;
		case .EaseInQuintic: return => EaseInQuintic;
		case .EaseOutQuintic: return => EaseOutQuintic;
		case .EaseInOutQuintic: return => EaseInOutQuintic;
		case .EaseInSin: return => EaseInSin;
		case .EaseOutSin: return => EaseOutSin;
		case .EaseInOutSin: return => EaseInOutSin;
		case .EaseInExponential: return => EaseInExponential;
		case .EaseOutExponential: return => EaseOutExponential;
		case .EaseInOutExponential: return => EaseInOutExponential;
		case .EaseInCircular: return => EaseInCircular;
		case .EaseOutCircular: return => EaseOutCircular;
		case .EaseInOutCircular: return => EaseInOutCircular;
		case .EaseInBack: return => EaseInBack;
		case .EaseOutBack: return => EaseOutBack;
		case .EaseInOutBack: return => EaseInOutBack;
		case .EaseInElastic: return => EaseInElastic;
		case .EaseOutElastic: return => EaseOutElastic;
		case .EaseInOutElastic: return => EaseInOutElastic;
		case .EaseInBounce: return => EaseInBounce;
		case .EaseOutBounce: return => EaseOutBounce;
		case .EaseInOutBounce: return => EaseInOutBounce;
		default: return => EaseInLinear;
		}
	}

	/// Shapes an interpolation factor. Linear short circuits, since it is by far the most
	/// common and a call through a function pointer to return the argument is waste.
	public static float Apply(EasingType type, float t)
	{
		if (type == .Linear)
			return t;
		return ToFunction(type)(t);
	}
}
