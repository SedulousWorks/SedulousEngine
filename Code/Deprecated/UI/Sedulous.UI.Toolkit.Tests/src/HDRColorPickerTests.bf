using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The HDR dialog, whose whole difference from the plain one is the intensity split.
class HDRColorPickerTests
{
	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	[Test]
	public static void ItBuildsItsTenControls()
	{
		let picker = new HDRColorPicker();
		defer picker.ReleaseRef();

		// The square, two strips, two previews, intensity, and four channel fields.
		Test.Assert(picker.ChildCount == 10);
	}

	[Test]
	public static void AColourPastWhiteRoundTrips()
	{
		let picker = new HDRColorPicker();
		defer picker.ReleaseRef();

		picker.SetColor(.(0.0f, 4.0f, 0.0f, 1.0f));
		let color = picker.CurrentColor;

		Test.Assert(Near(color.X, 0.0f));
		Test.Assert(Near(color.Y, 4.0f));
		Test.Assert(Near(color.Z, 0.0f));
		Test.Assert(Near(color.W, 1.0f));
	}

	[Test]
	public static void SetOriginalColorIsReadBack()
	{
		let picker = new HDRColorPicker();
		defer picker.ReleaseRef();

		picker.SetOriginalColor(.(8.0f, 0.0f, 0.0f, 1.0f));
		Test.Assert(picker.OriginalColor.X == 8.0f);
	}

	/// Intensity is the largest channel and the colour is what remains after dividing it out.
	[Test]
	public static void TheIntensitySplitDecomposesAndRecomposes()
	{
		float h = 0.0f;
		float s = 0.0f;
		float v = 0.0f;
		HDRColorPicker.Vec4ToHSVI(.(2.0f, 0.0f, 0.0f, 0.5f), ref h, ref s, ref v,
			let intensity, let alpha);

		Test.Assert(Near(intensity, 2.0f));
		Test.Assert(Near(alpha, 0.5f));
		Test.Assert(Near(s, 1.0f));

		let back = HDRColorPicker.HSVIToVec4(h, s, v, intensity, alpha);
		Test.Assert(Near(back.X, 2.0f));
		Test.Assert(Near(back.W, 0.5f));
	}

	/// TRUE BLACK has no colour to recover, so the hue and saturation are LEFT ALONE rather
	/// than reset. Otherwise dragging a value down through zero would throw away which colour
	/// the user was working on.
	[Test]
	public static void BlackKeepsTheHueItCameInWith()
	{
		var h = 200.0f;
		var s = 0.75f;
		var v = 0.5f;

		HDRColorPicker.Vec4ToHSVI(.Zero, ref h, ref s, ref v, let intensity, let alpha);

		Test.Assert(intensity == 0.0f);
		Test.Assert(h == 200.0f, "the hue survived");
		Test.Assert(s == 0.75f);
		Test.Assert(v == 0.5f);
		Test.Assert(alpha == 0.0f);
	}
}
