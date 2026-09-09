using Sedulous.Core;

namespace Sedulous.UI;

/// Short, UI friendly names for Sedulous.Core's easing functions.
///
/// Nothing is implemented here: the curves live in Core and this is the vocabulary the UI
/// spells them with, so a theme or animation reads `Easing.EaseOut` rather than
/// `EaseOutQuadratic`.
static class Easing
{
	public static readonly EasingFunction Linear = => EaseInLinear;

	// Quadratic, which is what the bare EaseIn, EaseOut and EaseInOut names mean.
	public static readonly EasingFunction EaseIn = => EaseInQuadratic;
	public static readonly EasingFunction EaseOut = => EaseOutQuadratic;
	public static readonly EasingFunction EaseInOut = => EaseInOutQuadratic;

	// Cubic: the default for a smooth UI animation.
	public static readonly EasingFunction EaseInCubic = => Sedulous.Core.EaseInCubic;
	public static readonly EasingFunction EaseOutCubic = => Sedulous.Core.EaseOutCubic;
	public static readonly EasingFunction EaseInOutCubic = => Sedulous.Core.EaseInOutCubic;

	public static readonly EasingFunction EaseInQuartic = => Sedulous.Core.EaseInQuartic;
	public static readonly EasingFunction EaseOutQuartic = => Sedulous.Core.EaseOutQuartic;
	public static readonly EasingFunction EaseInOutQuartic = => Sedulous.Core.EaseInOutQuartic;

	public static readonly EasingFunction EaseInQuintic = => Sedulous.Core.EaseInQuintic;
	public static readonly EasingFunction EaseOutQuintic = => Sedulous.Core.EaseOutQuintic;
	public static readonly EasingFunction EaseInOutQuintic = => Sedulous.Core.EaseInOutQuintic;

	public static readonly EasingFunction BounceIn = => EaseInBounce;
	public static readonly EasingFunction BounceOut = => EaseOutBounce;
	public static readonly EasingFunction BounceInOut = => EaseInOutBounce;

	public static readonly EasingFunction ElasticIn = => EaseInElastic;
	public static readonly EasingFunction ElasticOut = => EaseOutElastic;
	public static readonly EasingFunction ElasticInOut = => EaseInOutElastic;

	// Back overshoots the target and settles back.
	public static readonly EasingFunction BackIn = => EaseInBack;
	public static readonly EasingFunction BackOut = => EaseOutBack;
	public static readonly EasingFunction BackInOut = => EaseInOutBack;

	public static readonly EasingFunction ExpoIn = => EaseInExponential;
	public static readonly EasingFunction ExpoOut = => EaseOutExponential;
	public static readonly EasingFunction ExpoInOut = => EaseInOutExponential;

	public static readonly EasingFunction SineIn = => EaseInSin;
	public static readonly EasingFunction SineOut = => EaseOutSin;
	public static readonly EasingFunction SineInOut = => EaseInOutSin;

	public static readonly EasingFunction CircIn = => EaseInCircular;
	public static readonly EasingFunction CircOut = => EaseOutCircular;
	public static readonly EasingFunction CircInOut = => EaseInOutCircular;
}
