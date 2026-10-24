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

	[Test]
	public static void CurrentColorIsTheNearestDeclaredColourADescendantsTooOnColorTheParents()
	{
		bool Near(float a, float b) => NodeFixtures.Near(a, b);
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let outer = new Panel();
		defer outer.ReleaseRef();
		let inner = new Panel();
		defer inner.ReleaseRef();
		let text = new Label();
		defer text.ReleaseRef();
		root.AddChild(outer);
		outer.AddChild(inner);
		inner.AddChild(text);
		outer.AddClass("outer");
		inner.AddClass("inner");
		text.AddClass("text");
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".outer { border-color: currentColor; border-width: 1px; color: #ff0000; }" +
			".inner { background-color: color-mix(in srgb, currentColor 50%, transparent); }" +
			".text { color: currentColor; background-color: currentColor; }");
		styles.ApplyTree(root);
		// Declared after it in the rule, the colour still applies to the border (the cascade's winner).
		Test.Assert(Near(outer.Box.BorderColors.Top.R, 1.0f));
		Test.Assert(Near(outer.Box.BorderColors.Top.G, 0.0f));
		// A descendant that declares none reads its ancestor's.
		Test.Assert(Near(inner.Box.BackgroundColor.R, 1.0f));
		Test.Assert(Near(inner.Box.BackgroundColor.A, 0.5f));
		Test.Assert(Near(text.TextColor.R, 1.0f)); // color: currentColor is the inherited one
		Test.Assert(Near(text.Box.BackgroundColor.R, 1.0f));
		// A theme's retint reaches every currentColor.
		WidgetFixtures.UseSheet(styles, ".outer { color: hsl(240, 100%, 50%); } .inner { background-color: currentColor; }");
		styles.ApplyTree(root);
		Test.Assert(Near(inner.Box.BackgroundColor.B, 1.0f));
	}
}
