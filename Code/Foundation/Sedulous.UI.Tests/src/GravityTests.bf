using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The Gravity flags themselves, and the helper that turns one into a rectangle.
class GravityTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	// ---- The flags --------------------------------------------------------------------------

	[Test]
	public static void NoneIsZero()
	{
		Test.Assert((uint32)Gravity.None == 0);
	}

	/// The compound names are exactly their parts, so a control can set either and code can
	/// test for either.
	[Test]
	public static void TheCompoundNamesAreTheirParts()
	{
		Test.Assert(Gravity.Center == (Gravity.CenterH | Gravity.CenterV));
		Test.Assert(Gravity.Fill == (Gravity.FillH | Gravity.FillV));
		Test.Assert((Gravity.Top | Gravity.Right) == Gravity.TopRight);
		Test.Assert((Gravity.Bottom | Gravity.Left) == Gravity.BottomLeft);
	}

	/// Every flag occupies its own bit, so combining two never accidentally names a third.
	[Test]
	public static void TheFlagsAreDistinctBits()
	{
		Test.Assert((uint32)(Gravity.Left & Gravity.Right) == 0);
		Test.Assert((uint32)(Gravity.Top & Gravity.Bottom) == 0);
		Test.Assert((uint32)(Gravity.CenterH & Gravity.FillH) == 0);
		Test.Assert((uint32)(Gravity.CenterV & Gravity.FillV) == 0);
		Test.Assert((uint32)(Gravity.Left & Gravity.Top) == 0);
	}

	// ---- The helper -------------------------------------------------------------------------

	[Test]
	public static void NoGravityPlacesAtTheTopLeftAtTheGivenSize()
	{
		let rect = GravityHelper.Apply(.None, 400.0f, 300.0f, 100.0f, 50.0f);

		Test.Assert(Near(rect.X, 0));
		Test.Assert(Near(rect.Y, 0));
		Test.Assert(Near(rect.Width, 100));
		Test.Assert(Near(rect.Height, 50));
	}

	[Test]
	public static void CentreCentresOnBothAxes()
	{
		let rect = GravityHelper.Apply(.Center, 400.0f, 300.0f, 100.0f, 50.0f);

		Test.Assert(Near(rect.X, 150));
		Test.Assert(Near(rect.Y, 125));
	}

	[Test]
	public static void BottomRightAnchorsTheFarEdges()
	{
		let rect = GravityHelper.Apply(.Bottom | .Right, 400.0f, 300.0f, 100.0f, 50.0f);

		Test.Assert(Near(rect.X, 300));
		Test.Assert(Near(rect.Y, 250));
	}

	/// Fill DISCARDS the requested size: the whole container is the answer.
	[Test]
	public static void FillTakesTheWholeContainer()
	{
		let rect = GravityHelper.Apply(.Fill, 400.0f, 300.0f, 100.0f, 50.0f);

		Test.Assert(Near(rect.X, 0));
		Test.Assert(Near(rect.Y, 0));
		Test.Assert(Near(rect.Width, 400));
		Test.Assert(Near(rect.Height, 300));
	}

	/// The helper works in MARGIN boxes, and View.Layout insets by the margin afterwards, so a
	/// gravity and a margin compose instead of fighting.
	[Test]
	public static void GravityCentresTheMarginBoxNotTheBorderBox()
	{
		// A hundred by fifty child with margins of ten and twenty is a hundred and twenty by
		// ninety of margin box.
		let rect = GravityHelper.Apply(.Center, 400.0f, 300.0f, 120.0f, 90.0f);

		Test.Assert(Near(rect.X, 140));
		Test.Assert(Near(rect.Y, 105));
		// The base Layout then insets to the border box at (150, 125), a hundred by fifty.
	}

	[Test]
	public static void FillHandsTheWholeContainerToTheMarginBox()
	{
		let rect = GravityHelper.Apply(.Fill, 400.0f, 300.0f, 120.0f, 90.0f);

		Test.Assert(Near(rect.X, 0));
		Test.Assert(Near(rect.Y, 0));
		Test.Assert(Near(rect.Width, 400));
		Test.Assert(Near(rect.Height, 300));
	}
}
