using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The theme's sheets: a widget part's (::part) rules resolved apart from the widget's own.
class ThemeTests
{
	[Test]
	public static void PseudoElementPartRulesResolveSeparatelyFromTheElementStyle()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.Tag = "slider";
		let sheet = scope StyleSheet();
		CSSParser.Parse("slider { background-color: #00ff00; } " +
			"slider::fill { background-color: #ff0000; } " +
			"slider::thumb { background-color: #0000ff; }", sheet);

		// The element's own style has only the non-pseudo declaration.
		let main = scope ResolvedStyle();
		sheet.Resolve(w, main);
		Test.Assert(main.Get("background-color") == "#00ff00");

		// Each part resolves its own cascade.
		let fill = scope ResolvedStyle();
		sheet.Resolve(w, MediaContext(), true, "fill", null, fill);
		Test.Assert(fill.Get("background-color") == "#ff0000");
		let thumb = scope ResolvedStyle();
		sheet.Resolve(w, MediaContext(), true, "thumb", null, thumb);
		Test.Assert(thumb.Get("background-color") == "#0000ff");

		// A part with no rule resolves to nothing.
		let none = scope ResolvedStyle();
		sheet.Resolve(w, MediaContext(), true, "track", null, none);
		Test.Assert(!none.Has("background-color"));
	}

	[Test]
	public static void TheDefaultThemeCarriesPseudoElementPartRules()
	{
		// Sanity: the built-in themes actually contain ::part rules a Slider/Window can pick up.
		// A part inherits its widget's style (its tokens, from :root).
		let dark = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, dark);
		let slider = new UIWidget();
		defer slider.ReleaseRef();
		slider.Tag = "slider";
		let sliderStyle = scope ResolvedStyle();
		dark.Resolve(slider, MediaContext(), sliderStyle);
		let fill = scope ResolvedStyle();
		dark.Resolve(slider, MediaContext(), true, "fill", sliderStyle, fill);
		Test.Assert(fill.Has("background-color"));

		let window = new UIWidget();
		defer window.ReleaseRef();
		window.Tag = "window";
		let windowStyle = scope ResolvedStyle();
		dark.Resolve(window, MediaContext(), windowStyle);
		let title = scope ResolvedStyle();
		dark.Resolve(window, MediaContext(), true, "title", windowStyle, title);
		Test.Assert(title.Has("background-color"));
	}
}
