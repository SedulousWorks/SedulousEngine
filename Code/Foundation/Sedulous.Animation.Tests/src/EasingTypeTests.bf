using System;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// The bridge from the serializable curve name to the maths.
class EasingTypeTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void LinearAnswersWhatItWasGiven()
	{
		Test.Assert(Near(Easing.Apply(.Linear, 0.0f), 0.0f));
		Test.Assert(Near(Easing.Apply(.Linear, 0.25f), 0.25f));
		Test.Assert(Near(Easing.Apply(.Linear, 1.0f), 1.0f));
	}

	/// EVERY type resolves and pins its endpoints, which is what a curve is for: a shaped
	/// interpolation still has to start where it started and end where it ends.
	[Test]
	public static void EveryTypeResolvesAndPinsItsEndpoints()
	{
		for (int32 i = 0; i < EasingType.Count; i++)
		{
			let type = (EasingType)i;
			Test.Assert(Easing.ToFunction(type) != null);
			Test.Assert(Near(Easing.Apply(type, 0.0f), 0.0f, 0.01f));
			Test.Assert(Near(Easing.Apply(type, 1.0f), 1.0f, 0.01f));
		}
	}

	/// An ease IN starts slow, so it is below the line halfway; an ease OUT starts fast and
	/// is above it. That is the whole difference between the two families.
	[Test]
	public static void InAndOutLieOnOppositeSidesOfTheLine()
	{
		Test.Assert(Easing.Apply(.EaseInQuadratic, 0.5f) < 0.5f);
		Test.Assert(Easing.Apply(.EaseOutQuadratic, 0.5f) > 0.5f);
		Test.Assert(Easing.Apply(.EaseInCubic, 0.5f) < 0.5f);
		Test.Assert(Easing.Apply(.EaseOutCubic, 0.5f) > 0.5f);
		// An ease in and out meets the line in the middle, by symmetry.
		Test.Assert(Near(Easing.Apply(.EaseInOutQuadratic, 0.5f), 0.5f, 0.01f));
	}
}
