using System;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// The zoom readout's pure parts: the scale bar's round length and its pixels at the focus,
/// the words for a length, and when the readout shows (held, then fading).
static class ZoomReadoutTests
{
	private static bool Near(float a, float b, float tolerance = 1e-4f) => Math.Abs(a - b) <= tolerance * Math.Max(1.0f, Math.Abs(b));

	/// The bar is the longest round length within its target pixels.
	[Test]
	public static void TheScaleBarIsTheLongestRoundLengthWithinItsTarget()
	{
		// At 60 degrees the view is 2 tan(30) d tall: at 10 m over 1000 px, 1.1547 cm a pixel.
		let fovY = 1.0471976f;
		let metresPerPixel = 2.0f * 10.0f * Math.Tan(0.5f * fovY) / 1000.0f;
		let bar = ZoomReadout.ScaleBarAt(10.0f, fovY, 1000.0f, 120.0f);
		// 120 px is 1.39 m there: the bar is 1 m (2 m would not fit), spanning 86.6 px.
		Test.Assert(Near(bar.Metres, 1.0f));
		Test.Assert(Near(bar.Pixels, 1.0f / metresPerPixel));
		Test.Assert(bar.Pixels <= 120.0f);

		// Steps 1, 2, 5 through the decades as the focus moves out.
		Test.Assert(Near(ZoomReadout.ScaleBarAt(20.0f, fovY, 1000.0f).Metres, 2.0f));
		Test.Assert(Near(ZoomReadout.ScaleBarAt(40.0f, fovY, 1000.0f).Metres, 5.0f));
		Test.Assert(Near(ZoomReadout.ScaleBarAt(100.0f, fovY, 1000.0f).Metres, 10.0f));
		Test.Assert(Near(ZoomReadout.ScaleBarAt(0.5f, fovY, 1000.0f).Metres, 0.05f));

		// Every bar fits its target and is more than 0.4 of it (1, 2, 5 steps are at most 2.5
		// apart).
		for (var distance = 0.05f; distance < 5000.0f; distance *= 1.37f)
		{
			let b = ZoomReadout.ScaleBarAt(distance, fovY, 900.0f, 120.0f);
			Test.Assert(b.Pixels <= 120.0f + 1e-3f, scope $"at {distance} m the bar is {b.Pixels} px");
			Test.Assert(b.Pixels >= 120.0f * 0.4f - 1e-3f, scope $"at {distance} m the bar is {b.Pixels} px");
		}

		// A degenerate view has no bar.
		Test.Assert(ZoomReadout.ScaleBarAt(0.0f, fovY, 1000.0f).Metres == 0.0f);
		Test.Assert(ZoomReadout.ScaleBarAt(10.0f, fovY, 0.0f).Metres == 0.0f);
	}

	/// A length reads in millimetres, centimetres, metres or kilometres.
	[Test]
	public static void ALengthReadsInTheUnitThatFitsIt()
	{
		void Check(float metres, StringView expected)
		{
			let text = ZoomReadout.FormatMetres(metres, .. scope String());
			Test.Assert(text == expected, scope $"{metres} m read as '{text}', not '{expected}'");
		}
		Check(0.005f, "5 mm");
		Check(0.05f, "5 cm");
		Check(0.5f, "50 cm");
		Check(1.0f, "1 m");
		Check(2.5f, "2.5 m");
		Check(12.4f, "12 m");
		Check(500.0f, "500 m");
		Check(1200.0f, "1.2 km");
		Check(2000.0f, "2 km");
	}

	/// Shown whole after a zoom, fading once the zoom stops, then gone.
	[Test]
	public static void ShownWholeAfterAZoomThenFadingThenGone()
	{
		let readout = scope ZoomReadout();
		Test.Assert(readout.Opacity == 0.0f);

		readout.Zoomed();
		Test.Assert(readout.Opacity == 1.0f);
		readout.Advance(ZoomReadout.cHoldSeconds * 0.9f);
		Test.Assert(readout.Opacity == 1.0f);

		// Another notch holds it again from the start.
		readout.Zoomed();
		readout.Advance(ZoomReadout.cHoldSeconds * 0.9f);
		Test.Assert(readout.Opacity == 1.0f);

		// Half way through the fade, half there.
		readout.Advance(ZoomReadout.cHoldSeconds * 0.1f + ZoomReadout.cFadeSeconds * 0.5f);
		Test.Assert(Math.Abs(readout.Opacity - 0.5f) < 0.01f);

		readout.Advance(ZoomReadout.cFadeSeconds);
		Test.Assert(readout.Opacity == 0.0f);
	}
}
