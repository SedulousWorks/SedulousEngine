using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Ported from Raptor's "runtime: fixed stepper - exact cadence, alpha, and the hitch
/// clamp". The type is Core's; Raptor tests it through Runtime.
class FixedStepperTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// Sixty frames of a sixtieth each is sixty steps, and the leftover never grows.
	[Test]
	public static void ExactCadenceHoldsWithoutDrift()
	{
		var stepper = FixedStepper(1.0f / 60.0f, 4);

		uint32 total = 0;
		for (int i < 60)
			total += stepper.Advance(1.0f / 60.0f);

		// Float accumulation can defer one step to the next frame, which is why this is a
		// range rather than an equality.
		Test.Assert(total >= 59 && total <= 60, scope $"got {total}");
		Test.Assert(stepper.Alpha >= 0.0f);
		Test.Assert(stepper.Alpha < 1.0f);
	}

	[Test]
	public static void SubStepFramesAccumulate()
	{
		var half = FixedStepper();
		half.Step = 0.02f;

		Test.Assert(half.Advance(0.01f) == 0, "half a step is not a step");
		Test.Assert(Near(half.Alpha, 0.5f), "but it is half way there");
		Test.Assert(half.Advance(0.01f) == 1);
		Test.Assert(Near(half.Alpha, 0.0f, 0.01f));
	}

	/// A hitch is clamped, never a step storm. The excess time is DROPPED: carrying it
	/// would make the next frame longer still, which is the spiral of death.
	[Test]
	public static void AHitchIsClampedAndTheExcessIsDropped()
	{
		var hitch = FixedStepper(1.0f / 60.0f, 4);

		Test.Assert(hitch.Advance(1.0f) == 4, "a whole second yields exactly the clamp");
		Test.Assert(hitch.Alpha >= 0.0f);
		Test.Assert(hitch.Alpha < 1.0f);

		// No debt carried into the next frame.
		Test.Assert(hitch.Advance(1.0f / 60.0f) <= 1);
	}

	[Test]
	public static void DegenerateInputsNeitherStepNorSpin()
	{
		var degenerate = FixedStepper();
		Test.Assert(degenerate.Advance(-1.0f) == 0, "negative time is not a thing");
		Test.Assert(degenerate.Advance(0.0f) == 0);

		degenerate.Step = 0.0f;
		Test.Assert(degenerate.Alpha == 0.0f, "and no divide by zero");
		Test.Assert(degenerate.Advance(1.0f) == 0, "a zero step must not spin");
	}

	/// Ported from Raptor's "runtime: time scale clamps at zero and defaults to realtime":
	/// the half speed half of it, which is the stepper's side of that test.
	[Test]
	public static void ScaledTimeYieldsProportionallyFewerSteps()
	{
		var stepper = FixedStepper();
		uint32 steps = 0;
		for (int i < 60)
			steps += stepper.Advance((1.0f / 60.0f) * 0.5f);

		Test.Assert(steps >= 29 && steps <= 30, scope $"got {steps}");
	}
}
