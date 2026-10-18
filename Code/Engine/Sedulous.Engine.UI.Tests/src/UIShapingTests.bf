using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.HarfBuzz;
using Sedulous.Fonts.Bidi;

namespace Sedulous.Engine.UI.Tests;

/// A game's UI text is shaped by HarfBuzz: the subsystem installs it before its fonts load.
class UIShapingTests
{
	[Test]
	public static void TheUIsFontsLigate()
	{
		let fixture = scope UITestFixture(false, true);
		defer HarfBuzzShaping.Uninstall(); // the subsystem leaves it installed, for the process
		defer BidiAlgorithm.Uninstall();
		Test.Assert(HarfBuzzShaping.IsInstalled);
		Test.Assert(BidiAlgorithm.IsInstalled, "and the bidi algorithm beside it");
		let font = fixture.UI.UiContext.FontService.GetFont(16.0f);
		Test.Assert((font != null) && (font.Shaper != null), "the built-in font loaded");
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(font.Shaper.ShapeText(font.Font, "fi", glyphs) case .Ok);
		Test.Assert(glyphs.Count == 1, "the fi ligature");
	}
}
