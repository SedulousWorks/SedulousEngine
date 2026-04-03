namespace Sedulous.Animation;

using Sedulous.Core.Mathematics;

/// Serializable easing type enum mapping 1:1 to Easings.* functions.
public enum EasingType : int32
{
	Linear = 0,
	EaseInQuadratic,
	EaseOutQuadratic,
	EaseInOutQuadratic,
	EaseInCubic,
	EaseOutCubic,
	EaseInOutCubic,
	EaseInQuartic,
	EaseOutQuartic,
	EaseInOutQuartic,
	EaseInQuintic,
	EaseOutQuintic,
	EaseInOutQuintic,
	EaseInSin,
	EaseOutSin,
	EaseInOutSin,
	EaseInExponential,
	EaseOutExponential,
	EaseInOutExponential,
	EaseInCircular,
	EaseOutCircular,
	EaseInOutCircular,
	EaseInBack,
	EaseOutBack,
	EaseInOutBack,
	EaseInElastic,
	EaseOutElastic,
	EaseInOutElastic,
	EaseInBounce,
	EaseOutBounce,
	EaseInOutBounce
}

/// Utility for converting EasingType to the corresponding easing function.
public static class EasingTypeUtil
{
	/// Returns the easing function delegate for the given easing type.
	public static EasingFunction ToFunction(EasingType type)
	{
		switch (type)
		{
		case .Linear:              return Easings.EaseInLinear;
		case .EaseInQuadratic:     return Easings.EaseInQuadratic;
		case .EaseOutQuadratic:    return Easings.EaseOutQuadratic;
		case .EaseInOutQuadratic:  return Easings.EaseInOutQuadratic;
		case .EaseInCubic:         return Easings.EaseInCubic;
		case .EaseOutCubic:        return Easings.EaseOutCubic;
		case .EaseInOutCubic:      return Easings.EaseInOutCubic;
		case .EaseInQuartic:       return Easings.EaseInQuartic;
		case .EaseOutQuartic:      return Easings.EaseOutQuartic;
		case .EaseInOutQuartic:    return Easings.EaseInOutQuartic;
		case .EaseInQuintic:       return Easings.EaseInQuintic;
		case .EaseOutQuintic:      return Easings.EaseOutQuintic;
		case .EaseInOutQuintic:    return Easings.EaseInOutQuintic;
		case .EaseInSin:           return Easings.EaseInSin;
		case .EaseOutSin:          return Easings.EaseOutSin;
		case .EaseInOutSin:        return Easings.EaseInOutSin;
		case .EaseInExponential:   return Easings.EaseInExponential;
		case .EaseOutExponential:  return Easings.EaseOutExponential;
		case .EaseInOutExponential:return Easings.EaseInOutExponential;
		case .EaseInCircular:      return Easings.EaseInCircular;
		case .EaseOutCircular:     return Easings.EaseOutCircular;
		case .EaseInOutCircular:   return Easings.EaseInOutCircular;
		case .EaseInBack:          return Easings.EaseInBack;
		case .EaseOutBack:         return Easings.EaseOutBack;
		case .EaseInOutBack:       return Easings.EaseInOutBack;
		case .EaseInElastic:       return Easings.EaseInElastic;
		case .EaseOutElastic:      return Easings.EaseOutElastic;
		case .EaseInOutElastic:    return Easings.EaseInOutElastic;
		case .EaseInBounce:        return Easings.EaseInBounce;
		case .EaseOutBounce:       return Easings.EaseOutBounce;
		case .EaseInOutBounce:     return Easings.EaseInOutBounce;
		}
	}

	/// Applies an easing function to an interpolation factor t.
	public static float Apply(EasingType type, float t)
	{
		if (type == .Linear)
			return t;
		return ToFunction(type)(t);
	}
}
