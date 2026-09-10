using System;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The built in themes are read from their .sss files at COMPILE time.
///
/// A path that does not resolve yields an EMPTY string rather than failing the build, so the
/// embedding needs a test of its own or a broken path would ship silently as a theme with no
/// rules in it.
class EmbeddedThemeTests
{
	[Test]
	public static void EveryBuiltInThemeIsEmbedded()
	{
		Test.Assert(EmbeddedThemes.Dark.Length > 0);
		Test.Assert(EmbeddedThemes.Light.Length > 0);
		Test.Assert(EmbeddedThemes.RoundedDark.Length > 0);
	}

	[Test]
	public static void AnEmbeddedThemeIsTheStyleSheetItWasAuthoredAs()
	{
		// A marker from the top of each authored sheet, so a truncated or wrongly resolved
		// read fails rather than passing on length alone.
		Test.Assert(EmbeddedThemes.Dark.Contains("View {"));
		Test.Assert(EmbeddedThemes.Light.Contains("View {"));
		Test.Assert(EmbeddedThemes.RoundedDark.Contains("View {"));

		// The motion the themes now declare for themselves, rather than the engine's old
		// hard coded control list.
		Test.Assert(EmbeddedThemes.Dark.Contains("transition:"));
	}
}
