using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Raptor's endpoint sweep and known values, plus the properties that actually
/// distinguish one easing from another: the in/out duality, monotonicity, and the
/// overshoot that defines the back and elastic families.
class EasingsTests
{
	private static EasingFunction[?] cAll = .(
		=> EaseInLinear,       => EaseOutLinear,     => EaseInQuadratic,    => EaseOutQuadratic,
		=> EaseInOutQuadratic, => EaseInCubic,       => EaseOutCubic,       => EaseInOutCubic,
		=> EaseInQuartic,      => EaseOutQuartic,    => EaseInOutQuartic,   => EaseInQuintic,
		=> EaseOutQuintic,     => EaseInOutQuintic,  => EaseInSin,          => EaseOutSin,
		=> EaseInOutSin,       => EaseInExponential, => EaseOutExponential, => EaseInOutExponential,
		=> EaseInCircular,     => EaseOutCircular,   => EaseInOutCircular,  => EaseInBack,
		=> EaseOutBack,        => EaseInOutBack,     => EaseInElastic,      => EaseOutElastic,
		=> EaseInOutElastic,   => EaseInBounce,      => EaseOutBounce,      => EaseInOutBounce);

	[Test]
	public static void EveryEasingMapsTheEndpoints()
	{
		for (let f in cAll)
		{
			Test.Assert(NearlyEqual(f(0.0f), 0.0f));
			Test.Assert(NearlyEqual(f(1.0f), 1.0f));
		}
	}

	[Test]
	public static void KnownPolynomialValues()
	{
		Test.Assert(NearlyEqual(EaseInQuadratic(0.5f), 0.25f));
		Test.Assert(NearlyEqual(EaseOutQuadratic(0.5f), 0.75f));
		Test.Assert(NearlyEqual(EaseInOutQuadratic(0.5f), 0.5f));
		Test.Assert(NearlyEqual(EaseInCubic(0.5f), 0.125f));
		Test.Assert(NearlyEqual(EaseInOutCubic(0.5f), 0.5f));
		Test.Assert(NearlyEqual(EaseInOutSin(0.5f), 0.5f));
		Test.Assert(NearlyEqual(EaseInOutQuartic(0.5f), 0.5f));
		Test.Assert(NearlyEqual(EaseInOutQuintic(0.5f), 0.5f));
		Test.Assert(NearlyEqual(EaseInOutCircular(0.5f), 0.5f));

		Test.Assert(NearlyEqual(EaseInQuartic(0.5f), 0.0625f));
		Test.Assert(NearlyEqual(EaseInQuintic(0.5f), 0.03125f));
		Test.Assert(NearlyEqual(EaseInSin(1.0f), 1.0f));
		Test.Assert(NearlyEqual(EaseOutSin(0.5f), Sin(HalfPi * 0.5f)));
	}

	/// The defining relationship of an ease-out: it is the ease-in run backwards,
	/// out(t) == 1 - in(1 - t). Raptor checks endpoints and a couple of midpoints, which
	/// an out function derived from the wrong family would also pass.
	[Test]
	public static void EaseOutIsEaseInReversed()
	{
		(EasingFunction easeIn, EasingFunction easeOut, StringView name)[?] pairs = .(
			(=> EaseInQuadratic,   => EaseOutQuadratic,   "quadratic"),
			(=> EaseInCubic,       => EaseOutCubic,       "cubic"),
			(=> EaseInQuartic,     => EaseOutQuartic,     "quartic"),
			(=> EaseInQuintic,     => EaseOutQuintic,     "quintic"),
			(=> EaseInSin,         => EaseOutSin,         "sin"),
			(=> EaseInCircular,    => EaseOutCircular,    "circular"),
			(=> EaseInBack,        => EaseOutBack,        "back"),
			(=> EaseInExponential, => EaseOutExponential, "exponential"),
			(=> EaseInBounce,      => EaseOutBounce,      "bounce"));

		for (let pair in pairs)
		{
			for (int i = 0; i <= 10; i++)
			{
				let t = (float)i / 10.0f;
				let expected = 1.0f - pair.easeIn(1.0f - t);
				Test.Assert(NearlyEqual(pair.easeOut(t), expected, 1.0e-4f),
					scope $"{pair.name} at t={t}");
			}
		}
	}

	/// The in-out variants are continuous at the halfway seam where their two branches
	/// meet. An off-by-one in the branch arithmetic shows up as a visible jump.
	///
	/// Sampled very close to the seam because circular easing has an unbounded
	/// derivative there: its value moves like sqrt(h), so at h = 1e-4 the two sides sit
	/// 0.02 apart while still being perfectly continuous. h = 1e-6 puts that gap at
	/// 0.002, well inside the tolerance, while a genuine branch error stays large.
	[Test]
	public static void InOutVariantsAreContinuousAtTheSeam()
	{
		EasingFunction[?] inOut = .(
			=> EaseInOutQuadratic, => EaseInOutCubic, => EaseInOutQuartic,
			=> EaseInOutQuintic,   => EaseInOutSin,   => EaseInOutExponential,
			=> EaseInOutCircular,  => EaseInOutBack,  => EaseInOutBounce);

		var idx = 0;
		for (let f in inOut)
		{
			let justBefore = f(0.5f - 1.0e-6f);
			let justAfter = f(0.5f + 1.0e-6f);
			Test.Assert(NearlyEqual(justBefore, justAfter, 1.0e-2f),
				scope $"inOut[{idx}] before={justBefore} after={justAfter}");
			idx++;
		}
	}

	/// The families that are supposed to stay inside [0,1] do, and the ones that
	/// overshoot actually overshoot. Back and elastic exist precisely for that
	/// overshoot, so a version clamped into range would be silently wrong.
	[Test]
	public static void OvershootIsPresentOnlyWhereIntended()
	{
		EasingFunction[?] bounded = .(
			=> EaseInQuadratic, => EaseOutQuadratic, => EaseInCubic, => EaseOutCubic,
			=> EaseInSin, => EaseOutSin, => EaseInCircular, => EaseOutCircular,
			=> EaseInBounce, => EaseOutBounce);

		for (let f in bounded)
		{
			for (int i = 0; i <= 20; i++)
			{
				let t = (float)i / 20.0f;
				let v = f(t);
				Test.Assert((v >= -1.0e-4f) && (v <= 1.0f + 1.0e-4f));
			}
		}

		// EaseInBack dips below zero on its way out of the gate.
		var sawNegative = false;
		for (int i = 0; i <= 20; i++)
			if (EaseInBack((float)i / 20.0f) < -1.0e-3f)
				sawNegative = true;
		Test.Assert(sawNegative);

		// EaseOutBack rises above one before settling.
		var sawOvershoot = false;
		for (int i = 0; i <= 20; i++)
			if (EaseOutBack((float)i / 20.0f) > 1.0f + 1.0e-3f)
				sawOvershoot = true;
		Test.Assert(sawOvershoot);

		// Elastic oscillates on both sides.
		var elasticSwings = false;
		for (int i = 0; i <= 20; i++)
			if (EaseOutElastic((float)i / 20.0f) > 1.0f + 1.0e-3f)
				elasticSwings = true;
		Test.Assert(elasticSwings);
	}

	/// The polynomial and trigonometric families rise monotonically. Bounce and the
	/// overshooting families are excluded because they are not supposed to.
	[Test]
	public static void MonotonicFamiliesNeverGoBackwards()
	{
		EasingFunction[?] monotonic = .(
			=> EaseInLinear, => EaseInQuadratic, => EaseOutQuadratic, => EaseInOutQuadratic,
			=> EaseInCubic, => EaseOutCubic, => EaseInOutCubic,
			=> EaseInQuartic, => EaseOutQuartic, => EaseInQuintic, => EaseOutQuintic,
			=> EaseInSin, => EaseOutSin, => EaseInOutSin,
			=> EaseInCircular, => EaseOutCircular);

		for (let f in monotonic)
		{
			var previous = f(0.0f);
			for (int i = 1; i <= 50; i++)
			{
				let v = f((float)i / 50.0f);
				Test.Assert(v >= previous - 1.0e-5f);
				previous = v;
			}
		}
	}

	/// Bounce is piecewise over four segments, so a single midpoint sample cannot tell
	/// whether the later ones are wired up. These land one inside each.
	[Test]
	public static void BounceCoversAllFourSegments()
	{
		// The segment boundaries are at 1/2.75, 2/2.75 and 2.5/2.75.
		float[?] insideEach = .(0.15f, 0.5f, 0.8f, 0.95f);
		var previousWasFinite = true;
		for (let t in insideEach)
		{
			let v = EaseOutBounce(t);
			Test.Assert((v >= 0.0f) && (v <= 1.0f));
			previousWasFinite = previousWasFinite && (v == v);   // not NaN
		}
		Test.Assert(previousWasFinite);

		// Each segment peaks below 1 and the curve reaches 1 only at the end.
		Test.Assert(EaseOutBounce(1.0f) == 1.0f);
		Test.Assert(EaseOutBounce(0.99f) < 1.0f);

		// The first segment is the plain parabola.
		Test.Assert(NearlyEqual(EaseOutBounce(0.2f), 7.5625f * 0.2f * 0.2f, 1.0e-5f));
	}

	/// The exponential and elastic families special-case their endpoints, so those
	/// branches need reaching separately from the general formula.
	[Test]
	public static void ExponentialAndElasticEndpointBranches()
	{
		Test.Assert(EaseInExponential(0.0f) == 0.0f);
		Test.Assert(EaseOutExponential(1.0f) == 1.0f);
		Test.Assert(EaseInOutExponential(0.0f) == 0.0f);
		Test.Assert(EaseInOutExponential(1.0f) == 1.0f);
		Test.Assert(EaseInElastic(0.0f) == 0.0f);
		Test.Assert(EaseInElastic(1.0f) == 1.0f);
		Test.Assert(EaseOutElastic(0.0f) == 0.0f);
		Test.Assert(EaseOutElastic(1.0f) == 1.0f);
		Test.Assert(EaseInOutElastic(0.0f) == 0.0f);
		Test.Assert(EaseInOutElastic(1.0f) == 1.0f);

		// Just inside the endpoint takes the general path and stays close.
		Test.Assert(NearlyEqual(EaseInExponential(0.0001f), 0.0f, 1.0e-2f));
		Test.Assert(NearlyEqual(EaseOutExponential(0.9999f), 1.0f, 1.0e-2f));
	}

	[Test]
	public static void LinearIsTheIdentity()
	{
		for (int i = 0; i <= 10; i++)
		{
			let t = (float)i / 10.0f;
			Test.Assert(EaseInLinear(t) == t);
			Test.Assert(EaseOutLinear(t) == t);
		}
	}
}
