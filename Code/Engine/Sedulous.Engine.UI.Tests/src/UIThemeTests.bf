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
}
