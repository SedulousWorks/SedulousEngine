using System;

namespace Sedulous.Core;

/// Standard easing functions, each mapping an interpolation factor t in [0,1] to an
/// eased value, itself roughly in [0,1]. Consumed by animation and UI transitions.
///
/// Several of these mutate t as they go, which Raptor does by taking it by value. Beef
/// parameters are immutable, so `var t;` aliases the parameter into a mutable local and
/// the bodies stay identical to the originals.
static
{
	/// A function mapping t in [0,1] to an eased interpolation factor.
	public typealias EasingFunction = function float(float t);

	// --- linear ---
	[Scriptable]
	public static float EaseInLinear(float t) => t;
	[Scriptable]
	public static float EaseOutLinear(float t) => t;

	// --- quadratic ---
	[Scriptable]
	public static float EaseInQuadratic(float t) => t * t;
	[Scriptable]
	public static float EaseOutQuadratic(float t) => -1.0f * t * (t - 2.0f);
	[Scriptable]
	public static float EaseInOutQuadratic(float t)
	{
		var t;
		t *= 2.0f;
		if (t < 1.0f)
			return 0.5f * t * t;
		t -= 1.0f;
		return -0.5f * (t * (t - 2.0f) - 1.0f);
	}

	// --- cubic ---
	[Scriptable]
	public static float EaseInCubic(float t) => t * t * t;
	[Scriptable]
	public static float EaseOutCubic(float t)
	{
		var t;
		t -= 1.0f;
		return t * t * t + 1.0f;
	}
	[Scriptable]
	public static float EaseInOutCubic(float t)
	{
		var t;
		t *= 2.0f;
		if (t < 1.0f)
			return 0.5f * t * t * t;
		t -= 2.0f;
		return 0.5f * (t * t * t + 2.0f);
	}

	// --- quartic ---
	[Scriptable]
	public static float EaseInQuartic(float t) => t * t * t * t;
	[Scriptable]
	public static float EaseOutQuartic(float t)
	{
		var t;
		t -= 1.0f;
		return -1.0f * (t * t * t * t - 1.0f);
	}
	[Scriptable]
	public static float EaseInOutQuartic(float t)
	{
		var t;
		t *= 2.0f;
		if (t < 1.0f)
			return 0.5f * t * t * t * t;
		t -= 2.0f;
		return -0.5f * (t * t * t * t - 2.0f);
	}

	// --- quintic ---
	[Scriptable]
	public static float EaseInQuintic(float t) => t * t * t * t * t;
	[Scriptable]
	public static float EaseOutQuintic(float t)
	{
		var t;
		t -= 1.0f;
		return t * t * t * t * t + 1.0f;
	}
	[Scriptable]
	public static float EaseInOutQuintic(float t)
	{
		var t;
		t *= 2.0f;
		if (t < 1.0f)
			return 0.5f * t * t * t * t * t;
		t -= 2.0f;
		return 0.5f * (t * t * t * t * t + 2.0f);
	}

	// --- sinusoidal ---
	[Scriptable]
	public static float EaseInSin(float t) => -1.0f * Cos(t * HalfPi) + 1.0f;
	[Scriptable]
	public static float EaseOutSin(float t) => Sin(t * HalfPi);
	[Scriptable]
	public static float EaseInOutSin(float t) => -0.5f * (Cos(Pi * t) - 1.0f);

	// --- exponential ---
	[Scriptable]
	public static float EaseInExponential(float t)
	{
		if (t == 0.0f)
			return 0.0f;
		return Pow(2.0f, 10.0f * (t - 1.0f));
	}
	[Scriptable]
	public static float EaseOutExponential(float t)
	{
		if (t == 1.0f)
			return 1.0f;
		return -Pow(2.0f, -10.0f * t) + 1.0f;
	}
	[Scriptable]
	public static float EaseInOutExponential(float t)
	{
		var t;
		if (t == 0.0f)
			return 0.0f;
		if (t == 1.0f)
			return 1.0f;
		t *= 2.0f;
		if (t < 1.0f)
			return 0.5f * Pow(2.0f, 10.0f * (t - 1.0f));
		t -= 1.0f;
		return 0.5f * (-Pow(2.0f, -10.0f * t) + 2.0f);
	}

	// --- circular ---
	[Scriptable]
	public static float EaseInCircular(float t) => -1.0f * (Sqrt(1.0f - t * t) - 1.0f);
	[Scriptable]
	public static float EaseOutCircular(float t)
	{
		var t;
		t -= 1.0f;
		return Sqrt(1.0f - t * t);
	}
	[Scriptable]
	public static float EaseInOutCircular(float t)
	{
		var t;
		t *= 2.0f;
		if (t < 1.0f)
			return -0.5f * (Sqrt(1.0f - t * t) - 1.0f);
		t -= 2.0f;
		return 0.5f * (Sqrt(1.0f - t * t) + 1.0f);
	}

	// --- back, which overshoots ---
	[Scriptable]
	public static float EaseInBack(float t)
	{
		const float s = 1.70158f;
		return t * t * ((s + 1.0f) * t - s);
	}
	[Scriptable]
	public static float EaseOutBack(float t)
	{
		var t;
		const float s = 1.70158f;
		t -= 1.0f;
		return t * t * ((s + 1.0f) * t + s) + 1.0f;
	}
	[Scriptable]
	public static float EaseInOutBack(float t)
	{
		var t;
		const float s = 1.70158f;
		const float s2 = s * 1.525f;
		t *= 2.0f;
		if (t < 1.0f)
			return 0.5f * (t * t * ((s2 + 1.0f) * t - s2));
		t -= 2.0f;
		return 0.5f * (t * t * ((s2 + 1.0f) * t + s2) + 2.0f);
	}

	// --- elastic ---
	[Scriptable]
	public static float EaseInElastic(float t)
	{
		var t;
		if (t == 0.0f)
			return 0.0f;
		if (t == 1.0f)
			return 1.0f;
		const float p = 0.3f;
		const float s = p / 4.0f;
		t -= 1.0f;
		return -(Pow(2.0f, 10.0f * t) * Sin((t - s) * (2.0f * Pi) / p));
	}
	[Scriptable]
	public static float EaseOutElastic(float t)
	{
		if (t == 0.0f)
			return 0.0f;
		if (t == 1.0f)
			return 1.0f;
		const float p = 0.3f;
		const float s = p / 4.0f;
		return Pow(2.0f, -10.0f * t) * Sin((t - s) * (2.0f * Pi) / p) + 1.0f;
	}
	[Scriptable]
	public static float EaseInOutElastic(float t)
	{
		var t;
		if (t == 0.0f)
			return 0.0f;
		if (t == 1.0f)
			return 1.0f;
		t *= 2.0f;
		const float p = 0.3f * 1.5f;
		const float s = p / 4.0f;
		if (t < 1.0f)
		{
			t -= 1.0f;
			return -0.5f * (Pow(2.0f, 10.0f * t) * Sin((t - s) * (2.0f * Pi) / p));
		}
		t -= 1.0f;
		return Pow(2.0f, -10.0f * t) * Sin((t - s) * (2.0f * Pi) / p) * 0.5f + 1.0f;
	}

	// --- bounce; out is defined first because in and inout are written in terms of it ---
	[Scriptable]
	public static float EaseOutBounce(float t)
	{
		var t;
		if (t < 1.0f / 2.75f)
			return 7.5625f * t * t;
		if (t < 2.0f / 2.75f)
		{
			t -= 1.5f / 2.75f;
			return 7.5625f * t * t + 0.75f;
		}
		if (t < 2.5f / 2.75f)
		{
			t -= 2.25f / 2.75f;
			return 7.5625f * t * t + 0.9375f;
		}
		t -= 2.625f / 2.75f;
		return 7.5625f * t * t + 0.984375f;
	}
	[Scriptable]
	public static float EaseInBounce(float t) => 1.0f - EaseOutBounce(1.0f - t);
	[Scriptable]
	public static float EaseInOutBounce(float t)
	{
		if (t < 0.5f)
			return EaseInBounce(t * 2.0f) * 0.5f;
		return EaseOutBounce(t * 2.0f - 1.0f) * 0.5f + 0.5f;
	}
}
