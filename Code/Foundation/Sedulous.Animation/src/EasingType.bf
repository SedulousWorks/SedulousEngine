namespace Sedulous.Animation;

/// The easing curves, one for one with Core's family of them.
///
/// THE ORDER IS THE SERIALIZED VALUE, and several tools index by it, so a new curve is
/// appended rather than inserted.
enum EasingType : int32
{
	case Linear = 0;
	case EaseInQuadratic;
	case EaseOutQuadratic;
	case EaseInOutQuadratic;
	case EaseInCubic;
	case EaseOutCubic;
	case EaseInOutCubic;
	case EaseInQuartic;
	case EaseOutQuartic;
	case EaseInOutQuartic;
	case EaseInQuintic;
	case EaseOutQuintic;
	case EaseInOutQuintic;
	case EaseInSin;
	case EaseOutSin;
	case EaseInOutSin;
	case EaseInExponential;
	case EaseOutExponential;
	case EaseInOutExponential;
	case EaseInCircular;
	case EaseOutCircular;
	case EaseInOutCircular;
	case EaseInBack;
	case EaseOutBack;
	case EaseInOutBack;
	case EaseInElastic;
	case EaseOutElastic;
	case EaseInOutElastic;
	case EaseInBounce;
	case EaseOutBounce;
	case EaseInOutBounce;

	public const int Count = 31;
}
