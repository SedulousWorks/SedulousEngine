using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Convenience wrapper for easing functions.
/// Re-exports Sedulous.Core.Mathematics.Easings with GUI-friendly names.
public static class Easing
{
	// Linear
	public static readonly EasingFunction Linear = Easings.EaseInLinear;

	// Quadratic
	public static readonly EasingFunction EaseIn = Easings.EaseInQuadratic;
	public static readonly EasingFunction EaseOut = Easings.EaseOutQuadratic;
	public static readonly EasingFunction EaseInOut = Easings.EaseInOutQuadratic;

	// Cubic (default for smooth UI animations)
	public static readonly EasingFunction EaseInCubic = Easings.EaseInCubic;
	public static readonly EasingFunction EaseOutCubic = Easings.EaseOutCubic;
	public static readonly EasingFunction EaseInOutCubic = Easings.EaseInOutCubic;

	// Quartic
	public static readonly EasingFunction EaseInQuartic = Easings.EaseInQuartic;
	public static readonly EasingFunction EaseOutQuartic = Easings.EaseOutQuartic;
	public static readonly EasingFunction EaseInOutQuartic = Easings.EaseInOutQuartic;

	// Quintic
	public static readonly EasingFunction EaseInQuintic = Easings.EaseInQuintic;
	public static readonly EasingFunction EaseOutQuintic = Easings.EaseOutQuintic;
	public static readonly EasingFunction EaseInOutQuintic = Easings.EaseInOutQuintic;

	// Bounce
	public static readonly EasingFunction BounceIn = Easings.EaseInBounce;
	public static readonly EasingFunction BounceOut = Easings.EaseOutBounce;
	public static readonly EasingFunction BounceInOut = Easings.EaseInOutBounce;

	// Elastic
	public static readonly EasingFunction ElasticIn = Easings.EaseInElastic;
	public static readonly EasingFunction ElasticOut = Easings.EaseOutElastic;
	public static readonly EasingFunction ElasticInOut = Easings.EaseInOutElastic;

	// Back (overshoot)
	public static readonly EasingFunction BackIn = Easings.EaseInBack;
	public static readonly EasingFunction BackOut = Easings.EaseOutBack;
	public static readonly EasingFunction BackInOut = Easings.EaseInOutBack;

	// Exponential
	public static readonly EasingFunction ExpoIn = Easings.EaseInExponential;
	public static readonly EasingFunction ExpoOut = Easings.EaseOutExponential;
	public static readonly EasingFunction ExpoInOut = Easings.EaseInOutExponential;

	// Sinusoidal
	public static readonly EasingFunction SineIn = Easings.EaseInSin;
	public static readonly EasingFunction SineOut = Easings.EaseOutSin;
	public static readonly EasingFunction SineInOut = Easings.EaseInOutSin;

	// Circular
	public static readonly EasingFunction CircIn = Easings.EaseInCircular;
	public static readonly EasingFunction CircOut = Easings.EaseOutCircular;
	public static readonly EasingFunction CircInOut = Easings.EaseInOutCircular;
}
