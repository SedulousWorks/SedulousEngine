using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The compile-time facts. Compiler.Assert has to sit in a function body, so the
/// convention is a private, never-called Assert_* method: it is evaluated at compile
/// time regardless, and a failure stops the build rather than the run.
static
{
	private static void Assert_AbsFolds()
	{
		Compiler.Assert(Abs(-1.0f) == 1.0f);
	}

	private static void Assert_ScalarConstantsFold()
	{
		Compiler.Assert(TwoPi == Pi * 2.0f);
		Compiler.Assert(DegToRad * 180.0f == Pi);
	}
}

/// Scalar math: the helpers, the Round tie rule on both parities and both signs, and
/// the trigonometry and exponentials.
class MathTests
{
	[Test]
	public static void ScalarHelpers()
	{
		Test.Assert(Abs(-3.0f) == 3.0f);
		Test.Assert(NearlyEqual(DegreesToRadians(180.0f), Pi));
		Test.Assert(NearlyEqual(RadiansToDegrees(Pi), 180.0f));
		Test.Assert(NearlyEqual(Lerp(0.0f, 10.0f, 0.25f), 2.5f));
		Test.Assert(NearlyEqual(Sqrt(16.0f), 4.0f));
		Test.Assert(NearlyZero(1.0e-8f));
		Test.Assert(Floor(3.7f) == 3.0f);
		Test.Assert(Ceil(3.2f) == 4.0f);
		Test.Assert(Round(3.3f) == 3.0f);
		Test.Assert(Round(3.5f) == 4.0f);
		Test.Assert(Round(-3.5f) == -4.0f);
	}

	/// A delegated Round that used banker's rounding would send 3.5 to 4 and 2.5 to 2,
	/// so checking only the odd case would miss it. Both parities, both signs.
	[Test]
	public static void RoundsHalfAwayFromZero()
	{
		Test.Assert(Round(2.5f) == 3.0f);
		Test.Assert(Round(-2.5f) == -3.0f);
		Test.Assert(Round(-3.3f) == -3.0f);
		Test.Assert(Round(0.0f) == 0.0f);
	}

	/// Floor(x + 0.5f) is the obvious way to write half-away-from-zero and it is wrong:
	/// for the largest float below 0.5 the addition rounds up to exactly 1.0f, so the
	/// result is 1 where it should be 0. The cases above do not catch this, because every
	/// value they use is comfortably away from the representable boundary.
	[Test]
	public static void RoundIsExactAtTheRepresentableBoundary()
	{
		Test.Assert(Round(0.49999997f) == 0.0f);
		Test.Assert(Round(-0.49999997f) == 0.0f);
		Test.Assert(Round(0.5f) == 1.0f);
		Test.Assert(Round(-0.5f) == -1.0f);
	}

	[Test]
	public static void AbsKeepsIntegersIntegral()
	{
		Test.Assert(Abs(-3) == 3);
		Test.Assert(Abs((int64)-3) == 3);
		Test.Assert(Abs(-3.0) == 3.0);

		// int32.MinValue has no positive counterpart; this wraps.
		Test.Assert(Abs(int32.MinValue) == int32.MinValue);
	}

	[Test]
	public static void Trigonometry()
	{
		Test.Assert(NearlyZero(Sin(0.0f)));
		Test.Assert(NearlyEqual(Sin(HalfPi), 1.0f));
		Test.Assert(NearlyEqual(Cos(0.0f), 1.0f));
		Test.Assert(NearlyZero(Cos(HalfPi)));
		Test.Assert(NearlyEqual(Tan(0.0f), 0.0f));

		Test.Assert(NearlyEqual(Asin(1.0f), HalfPi));
		Test.Assert(NearlyEqual(Acos(1.0f), 0.0f));

		// Atan2 takes y first: the quadrant is the whole reason it exists, so an
		// implementation with the arguments swapped has to fail here.
		Test.Assert(NearlyEqual(Atan2(1.0f, 0.0f), HalfPi));
		Test.Assert(NearlyEqual(Atan2(0.0f, 1.0f), 0.0f));
		Test.Assert(NearlyEqual(Atan2(1.0f, 1.0f), Pi * 0.25f));
	}

	[Test]
	public static void ExponentialsAndLogs()
	{
		Test.Assert(NearlyEqual(Pow(2.0f, 10.0f), 1024.0f));
		Test.Assert(NearlyEqual(Exp(0.0f), 1.0f));
		Test.Assert(NearlyEqual(Log(1.0f), 0.0f));
		Test.Assert(NearlyEqual(Log(Exp(3.0f)), 3.0f, 1.0e-5f));
	}

	[Test]
	public static void NearlyEqualHonoursItsEpsilon()
	{
		Test.Assert(!NearlyEqual(1.0f, 1.1f));
		Test.Assert(NearlyEqual(1.0f, 1.1f, 0.2f));

		// Inclusive at the boundary.
		Test.Assert(NearlyEqual(1.0f, 2.0f, 1.0f));
		Test.Assert(!NearlyZero(1.0f));
	}

	[Test]
	public static void ConstantsAreConsistent()
	{
		Test.Assert(NearlyEqual(TwoPi, Pi * 2.0f));
		Test.Assert(NearlyEqual(HalfPi, Pi * 0.5f));
		Test.Assert(NearlyEqual(InvPi * Pi, 1.0f));
		Test.Assert(NearlyEqual(DegToRad * 180.0f, Pi));
		Test.Assert(NearlyEqual(RadToDeg * Pi, 180.0f));
	}

	[Test]
	public static void LerpEndpointsAndMidpoint()
	{
		Test.Assert(Lerp(2.0f, 6.0f, 0.0f) == 2.0f);
		Test.Assert(Lerp(2.0f, 6.0f, 1.0f) == 6.0f);
		Test.Assert(Lerp(2.0f, 6.0f, 0.5f) == 4.0f);
		// Extrapolates rather than clamping, which is the documented behaviour.
		Test.Assert(Lerp(0.0f, 10.0f, 2.0f) == 20.0f);
	}
}
