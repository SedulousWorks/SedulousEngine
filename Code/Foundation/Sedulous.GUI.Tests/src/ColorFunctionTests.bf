using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Colour functions: hsl() and hsla(), color-mix() in sRGB (premultiplied, percentages
// normalized), and currentColor, the nearest declared colour.

/// hsl() and hsla() in each of their spellings, and color-mix() in srgb.
class ColorFunctionTests
{
	private static void CheckColor(Color? c, float r, float g, float b, float a)
	{
		Test.Assert(c.HasValue);
		Test.Assert(NodeFixtures.Near(c.Value.R, r, 0.002f), scope $"r {c.Value.R}, expected {r}");
		Test.Assert(NodeFixtures.Near(c.Value.G, g, 0.002f), scope $"g {c.Value.G}, expected {g}");
		Test.Assert(NodeFixtures.Near(c.Value.B, b, 0.002f), scope $"b {c.Value.B}, expected {b}");
		Test.Assert(NodeFixtures.Near(c.Value.A, a, 0.002f), scope $"a {c.Value.A}, expected {a}");
	}

	[Test]
	public static void HslAndHslaCommasOrSpacesAnAlphaAsANumberOrAPercentage()
	{
		CheckColor(ParseColor("hsl(120, 100%, 50%)"), 0.0f, 1.0f, 0.0f, 1.0f);
		CheckColor(ParseColor("hsl(0 100% 50% / 0.5)"), 1.0f, 0.0f, 0.0f, 0.5f);
		CheckColor(ParseColor("hsla(240deg, 100%, 25%, 25%)"), 0.0f, 0.0f, 0.5f, 0.25f);
		CheckColor(ParseColor("hsl(-120, 100%, 50%)"), 0.0f, 0.0f, 1.0f, 1.0f); // a hue round the circle
		CheckColor(ParseColor("hsl(30, 0%, 40%)"), 0.4f, 0.4f, 0.4f, 1.0f); // no saturation: grey
		Test.Assert(!ParseColor("hsl(10, 20%)").HasValue);
	}

	[Test]
	public static void ColorMixInSrgbPremultipliedItsPercentagesNormalized()
	{
		CheckColor(ParseColor("color-mix(in srgb, red 25%, blue)"), 0.25f, 0.0f, 0.75f, 1.0f);
		CheckColor(ParseColor("color-mix(in srgb, red, blue 75%)"), 0.25f, 0.0f, 0.75f, 1.0f);
		CheckColor(ParseColor("color-mix(in srgb, red 60%, blue 60%)"), 0.5f, 0.0f, 0.5f, 1.0f); // over 100: scaled down
		CheckColor(ParseColor("color-mix(in srgb, red 20%, blue 20%)"), 0.5f, 0.0f, 0.5f, 0.4f); // under: the alpha
		CheckColor(ParseColor("color-mix(in srgb, red, transparent)"), 1.0f, 0.0f, 0.0f, 0.5f); // premultiplied
		CheckColor(ParseColor("color-mix(in srgb, hsl(120, 100%, 50%), #000)"), 0.0f, 0.5f, 0.0f, 1.0f);
		Test.Assert(!ParseColor("color-mix(red, blue)").HasValue);
	}
}
