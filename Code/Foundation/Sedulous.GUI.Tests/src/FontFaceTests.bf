using System;
using System.Collections;
using Sedulous.Fonts.TrueType;
using Sedulous.VFS;
using Sedulous.GUI;
using internal Sedulous.GUI;

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

	[Test]
	public static void AFaceLoadedThroughTheHostDrawsTheLabelThatAsksForItsWeight()
	{
		let service = scope TrueTypeFontService();
		TextFixtures.Load(service, "Brand", TextFixtures.cRoboto);
		let dataRoot = FindDataRoot(.. scope String());
		int loads = 0;
		let styles = scope StyleManager();
		styles.FontService = service;
		styles.SetFontFaceLoader(new [&] (face, source) =>
			{
				++loads;
				let path = DataPath(dataRoot, source, .. scope String());
				return service.LoadFont(face, path) == .Success;
			});
		// The regular face the service has already is not asked for.
		WidgetFixtures.UseSheet(styles, "@font-face { font-family: Brand; src: url(Engine/Fonts/roboto/Roboto-Regular.ttf); }" +
			"@font-face { font-family: Brand; src: url(Engine/Fonts/roboto/Roboto-Bold.ttf); font-weight: bold; }" +
			".text { font-family: Brand; font-size: 16px; font-weight: 700; }");
		let scene = SceneFixtures.NewScene();
		defer scene.ReleaseRef();
		scene.Context.FontService = service;
		let label = new Label();
		defer label.ReleaseRef();
		scene.AddChild(label);
		label.AddClass("text");
		label.Text = "Bold";
		styles.ApplyTree(scene);

		Test.Assert(loads == 1);
		Test.Assert(label.GetTextStyle().Selection.Weight == 700);
		Test.Assert(label.GetTextLayout().Font === service.GetFont("Brand", 16.0f));
		Test.Assert(service.HasFamily("Brand Bold"));
		let face = scope TextLayoutDetail.FaceChoice();
		TextLayoutDetail.ChooseFace(service, "Brand", 700, false, face);
		Test.Assert(face.Face == "Brand Bold");
		Test.Assert(label.GetTextLayout().FontService === service);
		let layout = label.GetTextLayout().LayoutFor(Rect(0.0f, 0.0f, 400.0f, 40.0f));
		Test.Assert(!layout.GlyphRuns.IsEmpty);
		Test.Assert(layout.GlyphRuns[0].Font === service.GetFont("Brand Bold", 16.0f));
		Test.Assert(!layout.GlyphRuns[0].SyntheticBold);
	}
}
