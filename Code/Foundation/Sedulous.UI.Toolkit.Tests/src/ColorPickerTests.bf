using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The colour dialog: the state it keeps, and the colour space maths under it.
class ColorPickerTests
{
	private static bool Near(float a, float b, float tolerance = 1.0f / 255.0f) =>
		Abs(a - b) <= tolerance;

	[Test]
	public static void ItBuildsItsNineControls()
	{
		let picker = new ColorPicker();
		defer picker.ReleaseRef();

		// The square, two strips, two previews, the hex field and three channel fields.
		Test.Assert(picker.ChildCount == 9);
		Test.Assert(picker.CurrentColor.A == 1.0f);
	}

	[Test]
	public static void AColourRoundTripsThroughHSV()
	{
		let picker = new ColorPicker();
		defer picker.ReleaseRef();

		picker.SetColor(Color.Rgb(128, 64, 32));
		let color = picker.CurrentColor;

		// Approximate, because the trip through hue and saturation is not exact.
		Test.Assert(Near(color.R, 128 / 255.0f, 2 / 255.0f));
		Test.Assert(Near(color.G, 64 / 255.0f, 2 / 255.0f));
		Test.Assert(Near(color.B, 32 / 255.0f, 2 / 255.0f));
		Test.Assert(color.A == 1.0f);
	}

	/// SetColor is the HOST writing a value in, so it must not report a change back. Otherwise
	/// an editor that sets the picker from the value it just received loops.
	[Test]
	public static void SetColorDoesNotReportAChange()
	{
		let picker = new ColorPicker();
		defer picker.ReleaseRef();

		var fired = false;
		picker.OnColorChanged.Add(new [&fired](sender, color) => { fired = true; });

		picker.SetColor(Color.Rgb(0, 255, 0));
		Test.Assert(!fired);
	}

	[Test]
	public static void SetOriginalColorIsReadBack()
	{
		let picker = new ColorPicker();
		defer picker.ReleaseRef();

		picker.SetOriginalColor(Color.Rgb(255, 0, 0));
		Test.Assert(picker.OriginalColor.R == 1.0f);
		Test.Assert(picker.OriginalColor.G == 0.0f);
	}

	[Test]
	public static void HSVToRGBHitsThePrimaries()
	{
		let red = ColorPicker.HSVToRGB(0, 1, 1);
		Test.Assert((red.R == 1.0f) && (red.G == 0.0f) && (red.B == 0.0f));

		let green = ColorPicker.HSVToRGB(120, 1, 1);
		Test.Assert((green.R == 0.0f) && (green.G == 1.0f) && (green.B == 0.0f));

		let blue = ColorPicker.HSVToRGB(240, 1, 1);
		Test.Assert((blue.R == 0.0f) && (blue.G == 0.0f) && (blue.B == 1.0f));

		// Saturation nought is grey at whatever value, so hue does not matter.
		let white = ColorPicker.HSVToRGB(0, 0, 1);
		Test.Assert((white.R == 1.0f) && (white.G == 1.0f) && (white.B == 1.0f));

		let black = ColorPicker.HSVToRGB(0, 0, 0);
		Test.Assert((black.R == 0.0f) && (black.G == 0.0f) && (black.B == 0.0f));
	}

	/// A REGRESSION GATE on the wrap: the hue from a red dominant colour is negative before
	/// it, and a modulus in place of the wrap looks right and is not.
	[Test]
	public static void RGBToHSVInvertsHSVToRGB()
	{
		ColorPicker.RGBToHSV(1.0f, 0.5f, 0.25f, let h, let s, let v);
		let color = ColorPicker.HSVToRGB(h, s, v);

		Test.Assert(Near(color.R, 1.0f));
		Test.Assert(Near(color.G, 0.5f));
		Test.Assert(Near(color.B, 0.25f));
	}

	[Test]
	public static void RGBToHSVNamesThePrimaryHues()
	{
		ColorPicker.RGBToHSV(0.0f, 1.0f, 0.0f, let h, let s, let v);
		Test.Assert(Near(h, 120.0f, 0.01f));
		Test.Assert(s == 1.0f);
		Test.Assert(v == 1.0f);

		// Red sits at the wrap: the raw hue is negative for blue above green, and comes back
		// as a wrapped value rather than a negative one.
		ColorPicker.RGBToHSV(1.0f, 0.0f, 0.5f, let magentaHue, ?, ?);
		Test.Assert(magentaHue > 0.0f);
		Test.Assert(Near(magentaHue, 330.0f, 0.01f));
	}
}
