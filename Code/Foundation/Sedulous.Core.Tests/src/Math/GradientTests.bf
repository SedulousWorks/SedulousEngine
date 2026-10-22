using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The gradient: colour stops and alpha stops apart, blended in sRGB values, as light, in
/// OKLab, or held; the ends clamped; no stops white and opaque.
class GradientTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Math.Abs(a - b) <= epsilon;

	[Test]
	public static void NoStopsIsWhiteAndOpaqueAndOneStopIsItsColourThroughout()
	{
		let white = EvaluateGradient(.(), .(), .Srgb, 0.5f);
		Test.Assert(Near(white.R, 1.0f));
		Test.Assert(Near(white.A, 1.0f));

		GradientColorStop[1] one = .(.(0.3f, .(0.2f, 0.4f, 0.6f, 0.1f)));
		let c = EvaluateGradient(one, .(), .Srgb, 0.9f);
		Test.Assert(Near(c.B, 0.6f));
		Test.Assert(Near(c.A, 1.0f));   // a colour stop's own alpha is not the gradient's
	}

	/// sRGB values blend straight, light blends brighter, OKLab keeps both ends' hues in
	/// the middle, and Constant holds.
	[Test]
	public static void EachSpaceBlendsItsOwnWay()
	{
		GradientColorStop[2] stops = .(.(0.0f, .(1.0f, 0.0f, 0.0f)), .(1.0f, .(0.0f, 0.0f, 1.0f)));
		let srgb = EvaluateGradient(stops, .(), .Srgb, 0.5f);
		Test.Assert(Near(srgb.R, 0.5f));
		Test.Assert(Near(srgb.B, 0.5f));

		let light = EvaluateGradient(stops, .(), .LinearLight, 0.5f);
		Test.Assert(Near(light.R, LinearToSrgb(0.5f)));   // half the light, encoded
		Test.Assert(light.R > srgb.R);

		let oklab = EvaluateGradient(stops, .(), .OkLab, 0.5f);
		Test.Assert(oklab.R > 0.0f);
		Test.Assert(oklab.B > 0.0f);
		Test.Assert(!Near(oklab.R, srgb.R, 0.01f));
		let end = EvaluateGradient(stops, .(), .OkLab, 1.0f);
		Test.Assert(Near(end.B, 1.0f));   // an end is its stop exactly
		Test.Assert(Near(end.R, 0.0f));
		// A colour in gamut goes into OKLab and back unchanged, which a clamped end cannot show.
		GradientColorStop[2] same = .(.(0.0f, .(0.2f, 0.5f, 0.7f)), .(1.0f, .(0.2f, 0.5f, 0.7f)));
		let through = EvaluateGradient(same, .(), .OkLab, 0.5f);
		Test.Assert(Near(through.R, 0.2f) && Near(through.G, 0.5f) && Near(through.B, 0.7f));

		Test.Assert(Near(EvaluateGradient(stops, .(), .Constant, 0.99f).R, 1.0f));
		Test.Assert(Near(EvaluateGradient(stops, .(), .Srgb, -1.0f).R, 1.0f));   // clamped before
	}

	[Test]
	public static void AlphaStopsAreApartFromTheColoursStraightBetweenAndHeldUnderConstant()
	{
		GradientColorStop[1] colors = .(.(0.0f, .(1.0f, 1.0f, 1.0f)));
		GradientAlphaStop[3] alphas = .(.(0.0f, 1.0f), .(0.5f, 1.0f), .(1.0f, 0.0f));
		Test.Assert(Near(EvaluateGradient(colors, alphas, .Srgb, 0.25f).A, 1.0f));
		Test.Assert(Near(EvaluateGradient(colors, alphas, .Srgb, 0.75f).A, 0.5f));
		Test.Assert(Near(EvaluateGradient(colors, alphas, .Constant, 0.75f).A, 1.0f));
		Test.Assert(Near(EvaluateGradient(colors, alphas, .LinearLight, 2.0f).A, 0.0f));
	}
}
