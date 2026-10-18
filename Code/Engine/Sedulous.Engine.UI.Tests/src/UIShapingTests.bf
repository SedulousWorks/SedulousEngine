using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.HarfBuzz;

namespace Sedulous.Engine.UI.Tests;

/// A game's UI text is shaped by HarfBuzz: the subsystem installs it before its fonts load.
class UIShapingTests
{
	[Test]
	public static void TheUIsFontsLigate()
	{
		let fixture = scope UITestFixture(false, true);
		defer HarfBuzzShaping.Uninstall(); // the subsystem leaves it installed, for the process
		Test.Assert(HarfBuzzShaping.IsInstalled);
		let font = fixture.UI.UiContext.FontService.GetFont(16.0f);
		Test.Assert((font != null) && (font.Shaper != null), "the built-in font loaded");
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(font.Shaper.ShapeText(font.Font, "fi", glyphs) case .Ok);
		Test.Assert(glyphs.Count == 1, "the fi ligature");
	}
}
