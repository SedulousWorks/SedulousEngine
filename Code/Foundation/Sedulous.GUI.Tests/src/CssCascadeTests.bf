using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// CSS !important and custom properties (variables), end to end through the parser, the cascade
/// and the resolve.
class CssCascadeTests
{
	/// The `color` `css` resolves to on a button, of the class `cls` when one is given.
	private static void ColorOf(StringView css, StringView cls, String outText)
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		if (cls.Length != 0)
			w.AddClass(cls);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		outText.Append(rs.Get("color"));
	}

	[Test]
	public static void ImportantOverridesHigherSpecificity()
	{
		// .primary (1024) beats button (1) normally, but button's !important wins.
		Test.Assert(ColorOf(".primary { color: red; } button { color: blue !important; }", "primary", .. scope String()) == "blue");
	}

	[Test]
	public static void ImportantBeatsImportantBySpecificity()
	{
		Test.Assert(ColorOf("button { color: red !important; } .primary { color: green !important; }", "primary", .. scope String()) == "green"); // .primary (higher spec) important wins
	}

	[Test]
	public static void NormalDeclarationCannotOverrideAnImportantOne()
	{
		// button:!important applied first (low spec), then .primary normal (higher spec): must NOT win.
		Test.Assert(ColorOf("button { color: red !important; } .primary { color: green; }", "primary", .. scope String()) == "red");
	}

	[Test]
	public static void VarResolvesAgainstACustomProperty()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		let sheet = scope StyleSheet();
		CSSParser.Parse("button { --accent: #00ff00; color: var(--accent); }", sheet);
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(rs.Get("color") == "#00ff00");
		Test.Assert(rs.Get("--accent") == "#00ff00"); // custom property retained
	}

	[Test]
	public static void FallbackUsedWhenTheVariableIsMissing()
	{
		Test.Assert(ColorOf("button { color: var(--missing, blue); }", "", .. scope String()) == "blue");
	}

	[Test]
	public static void CascadeOfTheVariableDrivesTheResolvedValue()
	{
		// .primary overrides --accent; color: var(--accent) should pick the cascaded value.
		Test.Assert(ColorOf("button { --accent: red; color: var(--accent); } .primary { --accent: blue; }", "primary", .. scope String()) == "blue");
	}

	[Test]
	public static void VarEndToEndThroughTheApplier()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		let sheet = scope StyleSheet();
		CSSParser.Parse("button { --bg: #0000ff; background-color: var(--bg); }", sheet);
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		ApplyStyle(w, rs);

		Test.Assert(NodeFixtures.Near(w.Box.BackgroundColor.B, 1.0f)); // var(--bg) -> #0000ff -> blue
	}

	[Test]
	public static void AChildWithNoVariablesOfItsOwnSharesItsParentsAndAWriteCopiesThem()
	{
		let parent = scope ResolvedStyle();
		parent.Set("--accent", "red");
		parent.Set("--space", "4px");
		parent.Set("opacity", "0.5");

		// Nothing of its own: the same set, not a copy (a theme's hundreds of tokens per node).
		let child = scope ResolvedStyle();
		child.Set("opacity", "1");
		child.InheritCustomProperties(parent);
		Test.Assert(child.Customs === parent.Customs);
		Test.Assert(child.Count == 3); // opacity and the two variables
		Test.Assert(child.Get("--accent") == "red");
		Test.Assert(ResolvedStyle.SameCustomProperties(child, parent));

		// A write of its own copies first: the parent keeps its value.
		child.Set("--accent", "blue");
		Test.Assert(child.Customs !== parent.Customs);
		Test.Assert(child.Get("--accent") == "blue");
		Test.Assert(child.Get("--space") == "4px");
		Test.Assert(parent.Get("--accent") == "red");
		Test.Assert(!ResolvedStyle.SameCustomProperties(child, parent));

		// A child with variables of its own takes the parent's it lacks, its own winning.
		let own = scope ResolvedStyle();
		own.Set("--accent", "green");
		own.InheritCustomProperties(parent);
		Test.Assert(own.Get("--accent") == "green");
		Test.Assert(own.Get("--space") == "4px");
		Test.Assert(parent.Customs.Count == 2);
	}
}
