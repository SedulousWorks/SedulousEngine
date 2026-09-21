using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The curve: keys, evaluation and clamping, Clear, mixed interpolation modes across a
/// single curve, and per-segment tangents.
class CurveTests
{
	[Test]
	public static void EmptyAndSingleKey()
	{
		let empty = scope Curve();
		Test.Assert(empty.IsEmpty);
		Test.Assert(empty.Evaluate(0.0f) == 0.0f);
		Test.Assert(empty.Duration == 0.0f);

		let one = scope Curve();
		one.AddKey(CurveKey(0.5f, 7.0f));
		Test.Assert(one.KeyCount == 1);
		Test.Assert(one.Evaluate(0.0f) == 7.0f);    // clamped before
		Test.Assert(one.Evaluate(0.5f) == 7.0f);    // at the key
		Test.Assert(one.Evaluate(10.0f) == 7.0f);   // clamped after
		Test.Assert(one.Duration == 0.5f);
	}

	[Test]
	public static void LinearInterpolationExactHitsAndEndClamp()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(0.0f, 0.0f));
		c.AddKey(CurveKey(1.0f, 10.0f));
		c.AddKey(CurveKey(2.0f, 20.0f));

		// Exact key hits.
		Test.Assert(NearlyEqual(c.Evaluate(0.0f), 0.0f));
		Test.Assert(NearlyEqual(c.Evaluate(1.0f), 10.0f));
		Test.Assert(NearlyEqual(c.Evaluate(2.0f), 20.0f));
		// Between keys.
		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 5.0f));
		Test.Assert(NearlyEqual(c.Evaluate(1.25f), 12.5f));
		// Clamped outside the range.
		Test.Assert(NearlyEqual(c.Evaluate(-1.0f), 0.0f));
		Test.Assert(NearlyEqual(c.Evaluate(5.0f), 20.0f));
		Test.Assert(NearlyEqual(c.Duration, 2.0f));
	}

	[Test]
	public static void ConstantInterpolationHoldsTheLeftValue()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(0.0f, 1.0f, .Constant));
		c.AddKey(CurveKey(1.0f, 9.0f, .Constant));

		// The left key's mode drives the segment: hold 1.0 across [0,1), jump at the key.
		Test.Assert(NearlyEqual(c.Evaluate(0.0f), 1.0f));
		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 1.0f));
		Test.Assert(NearlyEqual(c.Evaluate(0.999f), 1.0f));
		Test.Assert(NearlyEqual(c.Evaluate(1.0f), 9.0f));
	}

	[Test]
	public static void CubicHermiteWithFlatTangentsIsSmoothstep()
	{
		// Zero tangents at both ends over [0,1] with values 0..1 reduce Hermite to
		// smoothstep, 3t^2 - 2t^3.
		let c = scope Curve();
		c.AddKey(CurveKey(0.0f, 0.0f, .Cubic, 0.0f, 0.0f));
		c.AddKey(CurveKey(1.0f, 1.0f, .Cubic, 0.0f, 0.0f));

		Test.Assert(NearlyEqual(c.Evaluate(0.0f), 0.0f));
		Test.Assert(NearlyEqual(c.Evaluate(1.0f), 1.0f));
		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 0.5f));
		Test.Assert(NearlyEqual(c.Evaluate(0.25f), 0.15625f));   // 3*.0625 - 2*.015625

		// Smoothstep is symmetric: f(t) + f(1-t) == 1.
		Test.Assert(NearlyEqual(c.Evaluate(0.25f) + c.Evaluate(0.75f), 1.0f));
	}

	[Test]
	public static void CubicWithMatchedLinearTangentsIsTheStraightLine()
	{
		// Tangent equal to the slope at both ends collapses the cubic onto the line
		// through the endpoints, which also pins that tangents are scaled by the
		// segment length rather than used raw.
		let c = scope Curve();
		let slope = 5.0f;   // (10 - 0) / (2 - 0)
		c.AddKey(CurveKey(0.0f, 0.0f, .Cubic, slope, slope));
		c.AddKey(CurveKey(2.0f, 10.0f, .Cubic, slope, slope));

		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 2.5f, 1.0e-5f));
		Test.Assert(NearlyEqual(c.Evaluate(1.0f), 5.0f, 1.0e-5f));
		Test.Assert(NearlyEqual(c.Evaluate(1.5f), 7.5f, 1.0e-5f));
	}

	[Test]
	public static void AddKeyKeepsKeysSorted()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(2.0f, 20.0f));
		c.AddKey(CurveKey(0.0f, 0.0f));
		c.AddKey(CurveKey(1.0f, 10.0f));

		Test.Assert(c.KeyCount == 3);
		Test.Assert(NearlyEqual(c.Keys[0].Time, 0.0f));
		Test.Assert(NearlyEqual(c.Keys[1].Time, 1.0f));
		Test.Assert(NearlyEqual(c.Keys[2].Time, 2.0f));

		// Sampling still works after out-of-order inserts.
		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 5.0f));
		Test.Assert(NearlyEqual(c.Evaluate(1.5f), 15.0f));
	}

	[Test]
	public static void CoincidentKeysJumpToTheLaterValue()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(0.0f, 0.0f));
		c.AddKey(CurveKey(1.0f, 5.0f));
		c.AddKey(CurveKey(1.0f, 50.0f));   // the same time: a hard step

		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 2.5f));
		// At the coincident pair the segment is degenerate, so the later value wins.
		Test.Assert(NearlyEqual(c.Evaluate(1.0f), 50.0f));
	}

	/// The degenerate-segment guard is only reachable for keys that are near-coincident
	/// rather than exactly so: with equal times the segment scan advances past both, and
	/// a sample at that time is answered by the end clamp or the following segment.
	/// Without the guard, dividing by a segment of 5e-7 makes localT enormous and the
	/// interpolation explodes.
	[Test]
	public static void NearCoincidentKeysDoNotDivideByAlmostZero()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(0.0f, 0.0f));
		c.AddKey(CurveKey(1.0f, 5.0f));
		c.AddKey(CurveKey(1.0000005f, 50.0f));   // 5e-7 later, under the 1e-6 guard
		c.AddKey(CurveKey(2.0f, 60.0f));

		// Sampling inside the degenerate segment yields the later value, not a number
		// scaled by 1/5e-7.
		let v = c.Evaluate(1.0000002f);
		Test.Assert(NearlyEqual(v, 50.0f), scope $"expected 50, got {v}");

		// The keys on either side are unaffected.
		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 2.5f));
		Test.Assert(NearlyEqual(c.Evaluate(2.0f), 60.0f));
	}

	/// Insertion is stable for equal times: a key added later lands after existing keys
	/// at the same time. That ordering is what makes the coincident-key step
	/// deterministic rather than dependent on insertion order.
	[Test]
	public static void EqualTimeInsertionIsStable()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(1.0f, 1.0f));
		c.AddKey(CurveKey(1.0f, 2.0f));
		c.AddKey(CurveKey(1.0f, 3.0f));

		Test.Assert(c.KeyCount == 3);
		Test.Assert(NearlyEqual(c.Keys[0].Value, 1.0f));
		Test.Assert(NearlyEqual(c.Keys[1].Value, 2.0f));
		Test.Assert(NearlyEqual(c.Keys[2].Value, 3.0f));
	}

	/// Each segment reads its own left key's mode, so a curve can mix them; a curve whose
	/// keys all share one mode would not tell.
	[Test]
	public static void InterpolationIsPerSegment()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(0.0f, 0.0f, .Linear));
		c.AddKey(CurveKey(1.0f, 10.0f, .Constant));
		c.AddKey(CurveKey(2.0f, 20.0f, .Linear));

		// First segment lerps.
		Test.Assert(NearlyEqual(c.Evaluate(0.5f), 5.0f));
		// Second holds, because its left key is Constant.
		Test.Assert(NearlyEqual(c.Evaluate(1.5f), 10.0f));
		Test.Assert(NearlyEqual(c.Evaluate(1.99f), 10.0f));
		// And the final key is still reached exactly.
		Test.Assert(NearlyEqual(c.Evaluate(2.0f), 20.0f));
	}

	/// tangentOut belongs to the left key and tangentIn to the right one. A version that
	/// read both from the same key would still pass the matched-tangent cases above,
	/// where every tangent is equal.
	[Test]
	public static void CubicUsesOutOfTheLeftKeyAndInOfTheRight()
	{
		// Leaving flat and arriving steep is not the same curve as the reverse.
		let flatThenSteep = scope Curve();
		flatThenSteep.AddKey(CurveKey(0.0f, 0.0f, .Cubic, 0.0f, 0.0f));
		flatThenSteep.AddKey(CurveKey(1.0f, 1.0f, .Cubic, 3.0f, 0.0f));

		let steepThenFlat = scope Curve();
		steepThenFlat.AddKey(CurveKey(0.0f, 0.0f, .Cubic, 0.0f, 3.0f));
		steepThenFlat.AddKey(CurveKey(1.0f, 1.0f, .Cubic, 0.0f, 0.0f));

		Test.Assert(!NearlyEqual(flatThenSteep.Evaluate(0.5f), steepThenFlat.Evaluate(0.5f), 0.01f));

		// Both still hit their endpoints exactly.
		Test.Assert(NearlyEqual(flatThenSteep.Evaluate(0.0f), 0.0f));
		Test.Assert(NearlyEqual(flatThenSteep.Evaluate(1.0f), 1.0f));
	}

	[Test]
	public static void ClearEmptiesTheCurve()
	{
		let c = scope Curve();
		c.AddKey(CurveKey(0.0f, 1.0f));
		c.AddKey(CurveKey(1.0f, 2.0f));
		Test.Assert(!c.IsEmpty);

		c.Clear();
		Test.Assert(c.IsEmpty);
		Test.Assert(c.KeyCount == 0);
		Test.Assert(c.Duration == 0.0f);
		Test.Assert(c.Evaluate(0.5f) == 0.0f);
	}
}
