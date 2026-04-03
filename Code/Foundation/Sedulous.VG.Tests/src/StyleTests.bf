namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class StyleTests
{
	[Test]
	public static void SolidFill_ReturnsSameColor()
	{
		let fill = VGSolidFill(Color.Red);
		let c1 = fill.GetColorAt(.(0, 0), .(0, 0, 100, 100));
		let c2 = fill.GetColorAt(.(50, 50), .(0, 0, 100, 100));

		Test.Assert(c1 == Color.Red);
		Test.Assert(c2 == Color.Red);
		Test.Assert(!fill.RequiresInterpolation);
	}

	[Test]
	public static void LinearGradient_TwoStop_Interpolates()
	{
		let fill = scope VGLinearGradientFill(.(0, 0), .(100, 0));
		fill.AddStop(0, Color.Black);
		fill.AddStop(1, Color.White);

		let atStart = fill.GetColorAt(.(0, 0), .(0, 0, 100, 100));
		let atEnd = fill.GetColorAt(.(100, 0), .(0, 0, 100, 100));
		let atMid = fill.GetColorAt(.(50, 0), .(0, 0, 100, 100));

		Test.Assert(atStart.R == 0);
		Test.Assert(atEnd.R == 255);
		// Mid should be approximately 127/128
		Test.Assert(atMid.R > 100 && atMid.R < 155);
	}

	[Test]
	public static void LinearGradient_MultiStop()
	{
		let fill = scope VGLinearGradientFill(.(0, 0), .(100, 0));
		fill.AddStop(0, Color.Red);
		fill.AddStop(0.5f, Color.Green);
		fill.AddStop(1, Color.Blue);

		let atStart = fill.GetColorAt(.(0, 0), default);
		let atMid = fill.GetColorAt(.(50, 0), default);
		let atEnd = fill.GetColorAt(.(100, 0), default);

		Test.Assert(atStart.R == 255 && atStart.G == 0);
		Test.Assert(atMid.G > 100); // Should be near green
		Test.Assert(atEnd.B == 255 && atEnd.R == 0);
	}

	[Test]
	public static void RadialGradient_CenterAndEdge()
	{
		let fill = scope VGRadialGradientFill(.(50, 50), 50);
		fill.AddStop(0, Color.White);
		fill.AddStop(1, Color.Black);

		let atCenter = fill.GetColorAt(.(50, 50), default);
		let atEdge = fill.GetColorAt(.(100, 50), default);

		Test.Assert(atCenter.R == 255);
		Test.Assert(atEdge.R == 0);
	}

	[Test]
	public static void ConicGradient_AtAngles()
	{
		let fill = scope VGConicGradientFill(.(50, 50), 0);
		fill.AddStop(0, Color.Red);
		fill.AddStop(1, Color.Blue);

		// At angle 0 (right) should be red
		let atRight = fill.GetColorAt(.(100, 50), default);
		Test.Assert(atRight.R > 200);

		// At angle PI (left) should be roughly halfway
		let atLeft = fill.GetColorAt(.(0, 50), default);
		// Should be somewhere between red and blue
		Test.Assert(atLeft.R > 0 || atLeft.B > 0);
	}

	[Test]
	public static void ColorUtils_LerpColor()
	{
		let result = ColorUtils.LerpColor(Color.Black, Color.White, 0.5f);
		Test.Assert(result.R > 120 && result.R < 135);
		Test.Assert(result.G > 120 && result.G < 135);
		Test.Assert(result.B > 120 && result.B < 135);
	}

	[Test]
	public static void ColorUtils_InterpolateStops_BoundaryClamp()
	{
		GradientStop[2] stops = .(.(0.2f, Color.Red), .(0.8f, Color.Blue));
		let before = ColorUtils.InterpolateStops(Span<GradientStop>(&stops, 2), 0.0f);
		let after = ColorUtils.InterpolateStops(Span<GradientStop>(&stops, 2), 1.0f);

		Test.Assert(before == Color.Red);
		Test.Assert(after == Color.Blue);
	}
}
