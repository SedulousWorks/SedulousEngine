using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// CSSParser: .css text into a StyleSheet (comments, selector lists, declaration blocks), then
/// resolved end to end against a UIWidget.
class CSSParserTests
{
	[Test]
	public static void RulesSelectorListsAndComments()
	{
		let css = """
			/* theme */
			button { color: black; padding: 4; }
			.primary, .secondary { color: white; } /* two selectors share the block */
			#ok:hover { color: green; }
			""";
		Test.Assert(StyleFixtures.RuleCountOf(css) == 4); // button, .primary, .secondary, #ok:hover
	}

	[Test]
	public static void EndToEndResolveOnAWidget()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("button { color: black; padding: 4; } .primary { color: white; }", sheet);

		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		w.AddClass("primary");
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);

		Test.Assert(rs.Get("color") == "white"); // .primary beats button
		Test.Assert(rs.Get("padding-top") == "4"); // the shorthand, as its longhands
		Test.Assert(rs.Get("padding-left") == "4");
	}

	[Test]
	public static void AShorthandsValuesReachItsSidesTrailingSemicolonOptional()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("box { margin: 1 2 3 4; color: red }", sheet);
		Test.Assert(sheet.RuleCount == 1);

		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		// The shorthand's four values reach their four sides.
		Test.Assert(rs.Get("margin-top") == "1");
		Test.Assert(rs.Get("margin-right") == "2");
		Test.Assert(rs.Get("margin-bottom") == "3");
		Test.Assert(rs.Get("margin-left") == "4");
		Test.Assert(rs.Get("color") == "red"); // last decl, no semicolon
	}

	[Test]
	public static void CommentStrippingInsideBlocksAndSelectors()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("/* a */ button /* b */ { color: /* c */ red; }", sheet);
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(rs.Get("color") == "red");
	}

	[Test]
	public static void DescendantChildSelectorsSurviveParsing()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(".panel > button { color: blue; } .panel label { color: gray; }", sheet);
		Test.Assert(sheet.RuleCount == 2);

		let panel = new UIWidget();
		defer panel.ReleaseRef();
		panel.AddClass("panel");
		let button = StyleFixtures.Widget("button");
		defer button.ReleaseRef();
		panel.AddChild(button);

		let rs = scope ResolvedStyle();
		sheet.Resolve(button, rs);
		Test.Assert(rs.Get("color") == "blue"); // .panel > button matches direct child
	}

	[Test]
	public static void EmptyAndMalformedInputIsTolerated()
	{
		Test.Assert(StyleFixtures.RuleCountOf("") == 0);
		Test.Assert(StyleFixtures.RuleCountOf("   \n  ") == 0);
		Test.Assert(StyleFixtures.RuleCountOf(".x {}") == 1); // empty block ok
		Test.Assert(StyleFixtures.RuleCountOf("button { color") == 1); // unterminated block: best-effort
	}

	[Test]
	public static void EachRuleKeepsItsSheetsNameItsSelectorAsWrittenAndItsLinePastCommentsOverLines()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"/* a comment\n" +
			"   over two lines */\n" +
			"button { color: red; }\n" + // line 3
			"\n" +
			".a, .b > label\n" + // line 5: both rules of the list
			"{ color: blue; }\n" +
			"@media (min-width: 10px) {\n" +
			"  /* inside */ panel:hover { opacity: 0.5; }\n" + // line 8
			"}\n",
			"pages/demo.css", sheet);
		Test.Assert(sheet.Name == "pages/demo.css");
		Test.Assert(sheet.RuleCount == 4);
		Test.Assert(sheet.Rules[0].SelectorText == "button");
		Test.Assert(sheet.Rules[0].Line == 3);
		Test.Assert(sheet.Rules[1].SelectorText == ".a");
		Test.Assert(sheet.Rules[1].Line == 5);
		Test.Assert(sheet.Rules[2].SelectorText == ".b > label");
		Test.Assert(sheet.Rules[2].Line == 5);
		Test.Assert(sheet.Rules[3].SelectorText == "panel:hover");
		Test.Assert(sheet.Rules[3].Line == 8);
		let unnamed = scope StyleSheet();
		CSSParser.Parse("a { color: red; }", unnamed);
		Test.Assert(unnamed.Name.Length == 0);
	}

	[Test]
	public static void AQuotedStringAndParenthesesKeepTheirSemicolonsBracesAndCommentOpeners()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			".a { background-image: url(\"data:image/svg+xml,<svg style='fill:red;stroke:none'>{}/*x*/</svg>\"); color: red; }\n" +
			".b { background-image: url(data:image/svg+xml;base64,PHN2Zy8+); color: blue; }\n" +
			"@media (min-width: 1px) { .c { content: \"}\"; color: green; } }\n" +
			".d { content: 'it\\'s; } still'; color: black; }\n", sheet);
		Test.Assert(sheet.RuleCount == 4);
		let a = sheet.Rules[0].Properties;
		Test.Assert(a.Length == 2);
		Test.Assert(a[0].Value == "url(\"data:image/svg+xml,<svg style='fill:red;stroke:none'>{}/*x*/</svg>\")");
		Test.Assert(a[1].Name == "color");
		let b = sheet.Rules[1].Properties;
		Test.Assert(b.Length == 2);
		Test.Assert(b[0].Value == "url(data:image/svg+xml;base64,PHN2Zy8+)");
		let c = sheet.Rules[2].Properties;
		Test.Assert(c.Length == 2);
		Test.Assert(c[0].Value == "\"}\"");
		Test.Assert(sheet.Rules[2].SelectorText == ".c");
		let d = sheet.Rules[3].Properties;
		Test.Assert(d.Length == 2);
		Test.Assert(d[1].Value == "black");
	}
}
