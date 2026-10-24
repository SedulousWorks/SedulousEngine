using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// @import: the paths a sheet imports, as the parser reads them.
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
}
