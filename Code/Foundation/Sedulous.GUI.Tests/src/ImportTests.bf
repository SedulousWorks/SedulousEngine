using System;
using System.Collections;
using Sedulous.Image;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Sheets by path; every load counted.
class ImportSheets : IResourceProvider
{
	public List<String> Paths = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Texts = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Loaded = new .() ~ DeleteContainerAndItems!(_);

	public void Add(StringView path, StringView text)
	{
		Paths.Add(new String(path));
		Texts.Add(new String(text));
	}

	public override ImageData LoadImage(StringView path) => null;

	public override SVGDocument LoadSvg(StringView path) => null;

	public override bool LoadText(StringView path, String outText)
	{
		Loaded.Add(new String(path));
		for (int i = 0; i < Paths.Count; ++i)
		{
			if (Paths[i] == path)
			{
				outText.Set(Texts[i]);
				return true;
			}
		}
		return false;
	}
}

/// @import: the paths a sheet imports, as the parser reads them, and the sheets they bring in.
class ImportTests
{
	[Test]
	public static void TheParserReadsUrlAndQuotedPaths()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("@import url(\"theme/base.css\"); @import 'theme/extra.css' screen; .a { color: red; }", sheet);
		Test.Assert(sheet.Imports.Length == 2);
		Test.Assert(sheet.Imports[0] == "theme/base.css");
		Test.Assert(sheet.Imports[1] == "theme/extra.css");
		Test.Assert(sheet.RuleCount == 1);
	}

	[Test]
	public static void ImportedRulesComeFirstNestedImportsBeforeThemACycleStopsAMissingOneIsSkipped()
	{
		bool Near(float a, float b) => NodeFixtures.Near(a, b);
		let sheets = scope ImportSheets();
		sheets.Add("base.css", "@import url(tokens.css); .a { opacity: 0.25; } .b { opacity: 0.25; }");
		sheets.Add("tokens.css", "@import url(base.css); .a { opacity: 0.1; } .c { opacity: 0.1; }"); // back to base: stops
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let a = new Panel();
		defer a.ReleaseRef();
		let b = new Panel();
		defer b.ReleaseRef();
		let c = new Panel();
		defer c.ReleaseRef();
		a.AddClass("a");
		b.AddClass("b");
		c.AddClass("c");
		root.AddChild(a);
		root.AddChild(b);
		root.AddChild(c);
		let styles = scope StyleManager();
		styles.ResourceProvider = sheets;
		let sheet = scope StyleSheet();
		CSSParser.Parse("@import url(base.css); @import url(missing.css); .b { opacity: 0.5; }", "main.css", sheet);
		styles.StyleSheet = sheet;
		styles.ApplyTree(root);
		Test.Assert(Near(a.Alpha, 0.25f)); // base.css after tokens.css: it wins
		Test.Assert(Near(b.Alpha, 0.5f)); // the importing sheet after both
		Test.Assert(Near(c.Alpha, 0.1f));
		Test.Assert(sheets.Loaded.Count == 3); // base, tokens, missing; base not again
		styles.ApplyTree(root);
		Test.Assert(sheets.Loaded.Count == 3); // once per sheet
		// A new sheet expands its imports again (hot reload).
		let again = scope StyleSheet();
		CSSParser.Parse("@import url(tokens.css);", "main.css", again);
		styles.StyleSheet = again;
		styles.ApplyTree(root);
		Test.Assert(Near(c.Alpha, 0.1f));
		Test.Assert(Near(a.Alpha, 0.1f)); // tokens imports base ahead of itself: tokens wins now
	}
}
