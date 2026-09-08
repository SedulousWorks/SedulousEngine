using System;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// How a shape is coloured: the stop ramp, the gradient parameters, and the spread methods.
class FillTests
{
	private const Rectangle cUnitBounds = .(0, 0, 1, 1);

	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static bool NearColor(Color a, Color b, float epsilon = 0.001f)
		=> Near(a.R, b.R, epsilon) && Near(a.G, b.G, epsilon) && Near(a.B, b.B, epsilon)
			&& Near(a.A, b.A, epsilon);

	[Test]
	public static void ASolidFillIsOneColourEverywhere()
	{
		let fill = scope VGSolidFill(.Red);
		Test.Assert(fill.BaseColor == Color.Red);
		Test.Assert(fill.GetColorAt(Float2(0, 0), cUnitBounds) == Color.Red);
		Test.Assert(fill.GetColorAt(Float2(100, -50), cUnitBounds) == Color.Red);
		Test.Assert(!fill.RequiresInterpolation, "nothing varies, so nothing is evaluated");
	}

	/// A solid answers the gradient questions with defaults rather than having to implement
	/// them, which is the point of the interface's defaults.
	[Test]
	public static void ASolidAnswersTheGradientQuestionsWithDefaults()
	{
		IVGFill fill = scope VGSolidFill(.Green);
		Test.Assert(fill.GradientKind == .Solid);
		Test.Assert(fill.GetParameterAt(.(9, 9), cUnitBounds) == 0.0f);
		Test.Assert(fill.SampleRamp(0.7f) == Color.Green, "the ramp of a solid is itself");
		Test.Assert(fill.Spread == .Pad);
		Test.Assert(fill.GradientCoord(.(9, 9), cUnitBounds) == Float2.Zero);
	}

	[Test]
	public static void ThePresetSolidsAreTheColoursTheyName()
	{
		let presets = scope (VGSolidFill fill, Color expected)[](
			(VGSolidFill.White(), .White), (VGSolidFill.Black(), .Black),
			(VGSolidFill.Red(), .Red), (VGSolidFill.Green(), .Green),
			(VGSolidFill.Blue(), .Blue), (VGSolidFill.Transparent(), .Transparent));

		for (let preset in presets)
		{
			Test.Assert(preset.fill.BaseColor == preset.expected);
			delete preset.fill;
		}
	}

	// ---- stop interpolation ----

	[Test]
	public static void StopsInterpolateBetweenTheirNeighbours()
	{
		let stops = scope GradientStop[](.(0.0f, .Red), .(1.0f, .Blue));

		Test.Assert(ColorUtils.InterpolateStops(stops, 0.0f) == Color.Red);
		Test.Assert(ColorUtils.InterpolateStops(stops, 1.0f) == Color.Blue);

		let middle = ColorUtils.InterpolateStops(stops, 0.5f);
		Test.Assert(NearColor(middle, .(0.5f, 0.0f, 0.5f, 1.0f)));
	}

	/// Outside the first and last stop the ends hold, which is what makes a ramp that does
	/// not span the whole range still usable.
	[Test]
	public static void TheEndStopsHoldOutsideTheirRange()
	{
		let stops = scope GradientStop[](.(0.25f, .Red), .(0.75f, .Blue));
		Test.Assert(ColorUtils.InterpolateStops(stops, 0.0f) == Color.Red);
		Test.Assert(ColorUtils.InterpolateStops(stops, 0.1f) == Color.Red);
		Test.Assert(ColorUtils.InterpolateStops(stops, 0.9f) == Color.Blue);
		Test.Assert(ColorUtils.InterpolateStops(stops, 1.0f) == Color.Blue);

		// And the halfway point of the ramp is the halfway point BETWEEN the stops, not of
		// the parameter range.
		Test.Assert(NearColor(ColorUtils.InterpolateStops(stops, 0.5f), .(0.5f, 0, 0.5f, 1)));
	}

	/// Degenerate ramps are answered rather than faulted: these come out of importers,
	/// where a visible wrong colour is diagnosable and a crash is not.
	[Test]
	public static void ADegenerateRampStillAnswers()
	{
		Test.Assert(ColorUtils.InterpolateStops(.(), 0.5f) == Color.White, "no stops at all");

		let single = scope GradientStop[](.(0.5f, .Green));
		Test.Assert(ColorUtils.InterpolateStops(single, 0.0f) == Color.Green);
		Test.Assert(ColorUtils.InterpolateStops(single, 1.0f) == Color.Green);
	}

	/// Two stops at the SAME offset are a hard edge, which is how a ramp states a colour
	/// band. Dividing by that zero range would be a NaN across the whole span.
	[Test]
	public static void TwoStopsAtOneOffsetAreAHardEdge()
	{
		let stops = scope GradientStop[](
			.(0.0f, .Red), .(0.5f, .Red), .(0.5f, .Blue), .(1.0f, .Blue));

		Test.Assert(ColorUtils.InterpolateStops(stops, 0.25f) == Color.Red);
		Test.Assert(ColorUtils.InterpolateStops(stops, 0.75f) == Color.Blue);

		let atTheEdge = ColorUtils.InterpolateStops(stops, 0.5f);
		Test.Assert((atTheEdge == Color.Red) || (atTheEdge == Color.Blue), "one side or the other");
	}

	// ---- spread ----

	[Test]
	public static void PadClampsAndRepeatWraps()
	{
		Test.Assert(ColorUtils.ApplyGradientSpread(-0.5f, .Pad) == 0.0f);
		Test.Assert(ColorUtils.ApplyGradientSpread(1.5f, .Pad) == 1.0f);
		Test.Assert(ColorUtils.ApplyGradientSpread(0.3f, .Pad) == 0.3f);

		Test.Assert(Near(ColorUtils.ApplyGradientSpread(1.25f, .Repeat), 0.25f));
		Test.Assert(Near(ColorUtils.ApplyGradientSpread(2.75f, .Repeat), 0.75f));
		// A negative wraps forward rather than mirroring, which is what the sampler does.
		Test.Assert(Near(ColorUtils.ApplyGradientSpread(-0.25f, .Repeat), 0.75f));
	}

	/// Reflect mirrors on every other period, so a ramp run back to back is continuous
	/// rather than snapping at the seam.
	[Test]
	public static void ReflectMirrorsOnAlternatePeriods()
	{
		Test.Assert(Near(ColorUtils.ApplyGradientSpread(0.25f, .Reflect), 0.25f));
		Test.Assert(Near(ColorUtils.ApplyGradientSpread(1.25f, .Reflect), 0.75f));
		Test.Assert(Near(ColorUtils.ApplyGradientSpread(2.25f, .Reflect), 0.25f));
		Test.Assert(Near(ColorUtils.ApplyGradientSpread(-0.25f, .Reflect), 0.25f));

		// Continuous across the seam: approaching one from either side gives the same value.
		Test.Assert(Near(ColorUtils.ApplyGradientSpread(0.99f, .Reflect),
			ColorUtils.ApplyGradientSpread(1.01f, .Reflect), 0.03f));
	}

	// ---- linear ----

	[Test]
	public static void ALinearParameterIsTheProjectionOntoItsLine()
	{
		let fill = scope VGLinearGradientFill(.(0, 0), .(10, 0));
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		Test.Assert(Near(fill.GetParameterAt(.(0, 0), cUnitBounds), 0.0f));
		Test.Assert(Near(fill.GetParameterAt(.(5, 0), cUnitBounds), 0.5f));
		Test.Assert(Near(fill.GetParameterAt(.(10, 0), cUnitBounds), 1.0f));
		// Off axis projects onto the line, so a point beside the midpoint is still a half.
		Test.Assert(Near(fill.GetParameterAt(.(5, 99), cUnitBounds), 0.5f));
		// And past the end it keeps going, which is what the spread is then applied to.
		Test.Assert(Near(fill.GetParameterAt(.(20, 0), cUnitBounds), 2.0f));

		Test.Assert(fill.GradientKind == .Linear);
		Test.Assert(fill.RequiresInterpolation);
		Test.Assert(fill.BaseColor == Color.Red, "the first stop");
	}

	/// A gradient whose endpoints coincide has no direction, so it is one colour rather
	/// than a division by zero.
	[Test]
	public static void ADegenerateLinearIsOneColour()
	{
		let fill = scope VGLinearGradientFill(.(4, 4), .(4, 4));
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		Test.Assert(fill.GetParameterAt(.(99, 99), cUnitBounds) == 0.0f);
		Test.Assert(fill.GetColorAt(.(99, 99), cUnitBounds) == Color.Red);
	}

	/// The spread is applied on the way to a colour, so a repeating gradient tiles.
	[Test]
	public static void ALinearAppliesItsSpread()
	{
		let fill = scope VGLinearGradientFill(.(0, 0), .(10, 0));
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		Test.Assert(fill.GetColorAt(.(20, 0), cUnitBounds) == Color.Blue, "padded by default");

		fill.Spread = .Repeat;
		Test.Assert(NearColor(fill.GetColorAt(.(15, 0), cUnitBounds), .(0.5f, 0, 0.5f, 1)),
			"one and a half tiles back to the middle");
	}

	[Test]
	public static void AGradientWithNoStopsIsWhite()
	{
		let fill = scope VGLinearGradientFill(.(0, 0), .(1, 0));
		Test.Assert(fill.BaseColor == Color.White);
		Test.Assert(fill.GetColorAt(.(0.5f, 0), cUnitBounds) == Color.White);
	}

	// ---- radial ----

	[Test]
	public static void ARadialParameterIsDistanceOverRadius()
	{
		let fill = scope VGRadialGradientFill(.(10, 10), 5.0f);
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		Test.Assert(Near(fill.GetParameterAt(.(10, 10), cUnitBounds), 0.0f));
		Test.Assert(Near(fill.GetParameterAt(.(15, 10), cUnitBounds), 1.0f));
		Test.Assert(Near(fill.GetParameterAt(.(10, 12.5f), cUnitBounds), 0.5f));
		// Symmetric in every direction, which is what makes it radial.
		Test.Assert(Near(fill.GetParameterAt(.(5, 10), cUnitBounds), 1.0f));

		Test.Assert(fill.GradientKind == .Radial);
	}

	/// The coordinate handed to the shader is the offset over the radius. The shader takes
	/// its LENGTH, so the two have to agree with the CPU parameter.
	[Test]
	public static void TheRadialCoordinateLengthIsTheParameter()
	{
		let fill = scope VGRadialGradientFill(.(10, 10), 5.0f);

		for (let point in scope Float2[](.(15, 10), .(10, 15), .(13, 14), .(7, 8)))
		{
			let coord = fill.GradientCoord(point, cUnitBounds);
			Test.Assert(Near(Length(coord), fill.GetParameterAt(point, cUnitBounds)),
				"the shader's length must be the CPU's parameter");
		}
	}

	/// A zero radius is one colour rather than a division by zero, and the coordinate falls
	/// back to a radius of one so the shader still gets something finite.
	[Test]
	public static void ADegenerateRadialIsOneColour()
	{
		let fill = scope VGRadialGradientFill(.(0, 0), 0.0f);
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		Test.Assert(fill.GetParameterAt(.(9, 9), cUnitBounds) == 0.0f);
		Test.Assert(fill.GetColorAt(.(9, 9), cUnitBounds) == Color.Red);
		Test.Assert(fill.GradientCoord(.(3, 4), cUnitBounds) == Float2(3, 4), "radius one");
	}

	// ---- conic ----

	[Test]
	public static void AConicParameterIsTheAngleOverAFullTurn()
	{
		let fill = scope VGConicGradientFill(.(0, 0));

		Test.Assert(Near(fill.GetParameterAt(.(1, 0), cUnitBounds), 0.0f));
		Test.Assert(Near(fill.GetParameterAt(.(0, 1), cUnitBounds), 0.25f));
		Test.Assert(Near(fill.GetParameterAt(.(-1, 0), cUnitBounds), 0.5f));
		Test.Assert(Near(fill.GetParameterAt(.(0, -1), cUnitBounds), 0.75f));

		Test.Assert(fill.GradientKind == .Conic);
	}

	/// The start angle rotates where the ramp begins, and the parameter stays inside one
	/// turn whichever way that pushes it.
	[Test]
	public static void TheStartAngleRotatesTheRamp()
	{
		let fill = scope VGConicGradientFill(.(0, 0), HalfPi);

		Test.Assert(Near(fill.GetParameterAt(.(0, 1), cUnitBounds), 0.0f), "the start angle");
		Test.Assert(Near(fill.GetParameterAt(.(-1, 0), cUnitBounds), 0.25f));
		// A point BEFORE the start wraps forward rather than going negative.
		Test.Assert(Near(fill.GetParameterAt(.(1, 0), cUnitBounds), 0.75f));
	}

	/// The coordinate handed to the shader is rotated back by the start angle, so the
	/// shader's own angle measurement starts where the fill says it does.
	[Test]
	public static void TheConicCoordinateAngleIsTheParameter()
	{
		let fill = scope VGConicGradientFill(.(2, 3), 0.7f);

		for (let point in scope Float2[](.(5, 3), .(2, 8), .(0, 1), .(4, 6)))
		{
			let coord = fill.GradientCoord(point, cUnitBounds);
			var angle = Atan2(coord.Y, coord.X);
			while (angle < 0.0f)
				angle += TwoPi;

			Test.Assert(Near(angle / TwoPi, fill.GetParameterAt(point, cUnitBounds)),
				"the shader's angle must be the CPU's parameter");
		}
	}
}
