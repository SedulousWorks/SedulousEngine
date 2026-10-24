using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// What the CSS parser says about what it skips, with the line where it is known.
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
}
