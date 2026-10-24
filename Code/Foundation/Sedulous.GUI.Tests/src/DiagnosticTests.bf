using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// What the loaders say: the markup loader's and the CSS parser's diagnostics, with lines where
/// they are known, and the check of a sheet's property names against the style table and the
/// registered element types: what a cook warns of or fails on.
class DiagnosticTests
{
	[Test]
	public static void TheCssParserSaysWhatItSkipsEachWithItsLine()
	{
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"@charset \"utf-8\";\n" +
			".a { color: red; width 10px; }\n" +
			".b:hovr { color: blue; }\n" +
			"@unknown { x: y; }\n" +
			".c { color: green; }\n" +
			".d",
			"test.css", said, sheet);
		Test.Assert(sheet.Rules.Length == 3); // .a, .b (never matching), .c
		Test.Assert(StyleFixtures.Says(said, "@charset"));
		Test.Assert(StyleFixtures.Says(said, "width 10px"));
		Test.Assert(StyleFixtures.Says(said, ".b:hovr"));
		Test.Assert(StyleFixtures.Says(said, "@unknown"));
		Test.Assert(StyleFixtures.Says(said, ".d"));
		for (let d in said)
			Test.Assert(d.Level == .Warning);
		for (let d in said)
		{
			if (d.Message.Contains("width 10px"))
				Test.Assert(d.Line == 2);
			else if (d.Message.Contains(".b:hovr"))
				Test.Assert(d.Line == 3);
		}

		let none = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(none); }
		let ok = scope StyleSheet();
		CSSParser.Parse("@import \"other.css\"; @media (max-width: 600px) { .a { color: red; } } @keyframes k { from { opacity: 0; } }",
			"ok.css", none, ok);
		Test.Assert(none.IsEmpty);
	}

	[Test]
	public static void MarkupThatDoesNotParseIsAnErrorWithItsLineAnUnknownElementAndAttributeAreWarnings()
	{
		RegisterGuiElements();
		let elements = scope ElementSet();
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		let loader = scope MarkupLoader(elements);
		loader.SetDiagnostics(said);
		Test.Assert(loader.LoadFromString("<Panel>\n  <Label text=\"a\">\n</Panel>") == null);
		Test.Assert(said.Count == 1);
		Test.Assert(said[0].Level == .Error);
		Test.Assert(said[0].Line >= 2);

		ClearAndDeleteItems!(said);
		let made = loader.LoadFromString("<Panel><Lable text=\"typo\"/><Label txet=\"x\"/></Panel>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		Test.Assert(made.ChildCount == 1); // the unknown element left out, the Label kept
		Test.Assert(said.Count == 2);
		Test.Assert(said[0].Level == .Warning);
		Test.Assert(MarkupFixtures.Says(said, "<Lable>"));
		Test.Assert(MarkupFixtures.Says(said, "'txet'"));

		ClearAndDeleteItems!(said);
		Test.Assert(loader.LoadFromString("<?xml version=\"1.0\"?>") == null);
		Test.Assert(said.Count == 1);

		// Each warning names its line: the dropped element's, the unknown attribute's own (on a line
		// of its own here), so an editor marks it and a cook's warning says where.
		ClearAndDeleteItems!(said);
		let lined = loader.LoadFromString("<Panel>\n  <Lable text=\"typo\"/>\n  <Label text=\"ok\"\n         txet=\"x\"/>\n</Panel>");
		Test.Assert(lined != null);
		defer lined.ReleaseRef();
		Test.Assert(said.Count == 2);
		for (let d in said)
		{
			if (MarkupFixtures.Has(d.Message, "<Lable>"))
				Test.Assert(d.Line == 2);
			else if (MarkupFixtures.Has(d.Message, "'txet'"))
				Test.Assert(d.Line == 4);
		}
	}

	[Test]
	public static void ASheetsPropertyNamesAreCheckedAgainstTheStyleTableAndTheRegisteredElementTypes()
	{
		RegisterGuiElements();
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		let sheet = scope StyleSheet();
		CSSParser.Parse(".a { colour: red; color: red; --accent: #fff; margin: 4px; }\n" +
			"button { nav-up: #b; }\n" +
			"@keyframes k { from { opactiy: 0; } to { opacity: 1; } }", sheet);
		CheckStyleSheetNames(sheet, said);
		Test.Assert(said.Count == 2);
		Test.Assert(MarkupFixtures.Says(said, "'colour'"));
		Test.Assert(said[0].Line == 1);
		Test.Assert(MarkupFixtures.Says(said, "'opactiy'"));
		Test.Assert(!MarkupFixtures.Says(said, "nav-up")); // an element type takes it by its CSS name
	}
}
