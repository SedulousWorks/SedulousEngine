using System;
using Sedulous.Engine.UI;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI.Tests;

/// The project default theme: a cooked sheet swapped into the context, and the built in one
/// standing behind it.
class UIThemeTests
{
	[Test]
	public static void TheProjectDefaultThemeSwapsTheContextStyleSheet()
	{
		let fixture = scope UITestFixture();

		let builtin = fixture.UI.UiContext.GetStyleSheet();
		Test.Assert(builtin != null, "the built in game theme ships by default");

		// A cooked theme, which is validated sheet text, replaces the context's stylesheet.
		let theme = scope UITheme();
		theme.StyleSheet.Set("Button { text-color: #ff0000; }");
		fixture.UI.SetDefaultTheme(theme);
		let custom = fixture.UI.UiContext.GetStyleSheet();
		Test.Assert(custom != null);
		Test.Assert(custom != builtin);

		// Null, which is a cleared or nil manifest reference, restores the built in one.
		fixture.UI.SetDefaultTheme(null);
		let restored = fixture.UI.UiContext.GetStyleSheet();
		Test.Assert(restored != null);
		Test.Assert(restored != custom);

		// The built in LIGHT variant exists alongside the dark one and differs in palette.
		let light = GameLightTheme.Create();
		Test.Assert(light != null);
		light.ReleaseRef();
		Test.Assert(GameLightTheme.Palette().Background.R != GameTheme.Palette().Background.R);
	}

	/// A cooked theme carries the vector images its @icon directives name; the game's parse
	/// reads them from the theme, so svg(name) draws with nothing else loaded.
	[Test]
	public static void AThemesEmbeddedIconsDrawThroughSvgInTheGameUI()
	{
		let fixture = scope UITestFixture();

		let reference = "{0b9f3c2e-4a7d-4e21-9c55-6a1d2b3c4d5e}";
		let theme = scope UITheme();
		theme.StyleSheet.AppendF("@icon heart \"{}\";\n.heart {{ background: svg(heart, tint=#E53935); }}\n.plain {{ background: svg(nothing); }}\n", reference);
		theme.IconIds.Add(new .(reference));
		theme.IconSvgs.Add(new .("<svg viewBox=\"0 0 24 24\"><path d=\"M12 21 L3 12 L12 3 L21 12 Z\" fill=\"#ffffff\"/></svg>"));
		fixture.UI.SetDefaultTheme(theme);

		let root = new RootView();
		fixture.UI.UiContext.AddRootView(root);
		defer { fixture.UI.UiContext.RemoveRootView(root); root.ReleaseRef(); }
		let heart = new Panel();
		heart.AddClass("heart");
		root.AddView(heart);
		let plain = new Panel();
		plain.AddClass("plain");
		root.AddView(plain);

		let drawn = heart.ResolveStyleDrawable(.Background);
		Test.Assert(drawn != null);
		Test.Assert(drawn is SVGDrawable);
		Test.Assert(plain.ResolveStyleDrawable(.Background) == null, "no such icon");
	}
}
