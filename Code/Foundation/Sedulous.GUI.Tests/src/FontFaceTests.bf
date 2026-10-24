using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// @font-face: a sheet names a face of a family and its file.
class FontFaceTests
{
	[Test]
	public static void TheParserReadsAFacesFamilySourceWeightAndStyle()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"@font-face { font-family: \"Brand\"; src: url('fonts/brand-bold.ttf') format(\"truetype\"), url(other.woff); font-weight: bold; }" +
			"@font-face { font-family: Brand; src: url(fonts/brand-italic.ttf); font-style: italic; font-weight: 300; }" +
			"@font-face { src: url(no-family.ttf); }" +
			".a { color: red; }", sheet);
		Test.Assert(sheet.FontFaces.Length == 2);
		let bold = sheet.FontFaces[0];
		Test.Assert(bold.Family == "Brand");
		Test.Assert(bold.Source == "fonts/brand-bold.ttf");
		Test.Assert(bold.Weight == 700);
		Test.Assert(!bold.Italic);
		let light = sheet.FontFaces[1];
		Test.Assert(light.Source == "fonts/brand-italic.ttf");
		Test.Assert(light.Weight == 300);
		Test.Assert(light.Italic);
		Test.Assert(sheet.Rules.Length == 1); // the rule after them still parses
	}
}
