using System;
using System.Collections;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// @font-face: a sheet names a face of a family and its file; the style manager asks the host's
/// loader for each, once, under the name the face is chosen by ("Brand Bold"), before the restyle
/// that draws in it.
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

	[Test]
	public static void TheLoaderIsAskedOncePerFacePerSheetUnderTheNameTheFaceIsChosenBy()
	{
		let service = scope TrueTypeFontService();
		let asked = scope List<String>();
		defer { ClearAndDeleteItems!(asked); }
		let styles = scope StyleManager();
		styles.FontService = service;
		styles.SetFontFaceLoader(new [&] (face, source) =>
			{
				let line = new String(face);
				line.Append("=");
				line.Append(source);
				asked.Add(line);
				return false;
			});
		let sheet = scope StyleSheet();
		CSSParser.Parse("@font-face { font-family: Brand; src: url(b.ttf); font-weight: 700; }" +
			"@font-face { font-family: Brand; src: url(li.ttf); font-weight: 300; font-style: italic; }" +
			"@font-face { font-family: Brand; src: url(r.ttf); }", sheet);
		styles.StyleSheet = sheet;
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		styles.ApplyTree(root);
		Test.Assert(asked.Count == 3);
		Test.Assert(asked[0] == "Brand Bold=b.ttf");
		Test.Assert(asked[1] == "Brand Light Italic=li.ttf");
		Test.Assert(asked[2] == "Brand=r.ttf");
		styles.ApplyTree(root);
		Test.Assert(asked.Count == 3); // not again for the same sheet
	}
}
