using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// StyleRule and the StyleSheet cascade: property blocks and specificity-ordered resolution
/// against a UIWidget.
class StyleSheetTests
{
	[Test]
	public static void SetAndOverrideDeclarations()
	{
		let r = scope StyleRule("button");
		r.SetProperty("color", "black");
		r.SetProperty("padding", "4");
		Test.Assert(r.PropertyCount == 2);
		r.SetProperty("color", "white"); // override, not append
		Test.Assert(r.PropertyCount == 2);
		Test.Assert(r.Specificity == 1); // tag
	}

	[Test]
	public static void ResolvedStyleSetGetHasOverride()
	{
		let s = scope ResolvedStyle();
		Test.Assert(!s.Has("color"));
		s.Set("color", "red");
		s.Set("color", "blue"); // override
		Test.Assert(s.Count == 1);
		Test.Assert(s.Has("color"));
		Test.Assert(s.Get("color") == "blue");
		Test.Assert(s.Get("missing", "fallback") == "fallback");
	}

	[Test]
	public static void HigherSpecificityWins()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		w.AddClass("primary");

		let sheet = scope StyleSheet();
		let tagRule = new StyleRule("button");
		tagRule.SetProperty("color", "black");
		tagRule.SetProperty("padding", "4");
		let classRule = new StyleRule(".primary");
		classRule.SetProperty("color", "white"); // class (1024) beats tag (1)
		sheet.AddRule(tagRule);
		sheet.AddRule(classRule);

		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(rs.Get("color") == "white"); // from .primary
		Test.Assert(rs.Get("padding-top") == "4"); // only in the tag rule
		Test.Assert(!rs.Has("margin"));
	}

	[Test]
	public static void IdBeatsClassBeatsTag()
	{
		let w = StyleFixtures.Widget("button", "ok");
		defer w.ReleaseRef();
		w.AddClass("primary");

		let sheet = scope StyleSheet();
		let t = new StyleRule("button");
		t.SetProperty("color", "tag");
		let c = new StyleRule(".primary");
		c.SetProperty("color", "class");
		let i = new StyleRule("#ok");
		i.SetProperty("color", "id");
		sheet.AddRule(t);
		sheet.AddRule(i); // add id before class to prove ordering is by specificity
		sheet.AddRule(c);

		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(rs.Get("color") == "id");
	}

	[Test]
	public static void EqualSpecificityResolvesBySourceOrderLastWins()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		w.AddClass("x");

		let sheet = scope StyleSheet();
		let a = new StyleRule(".x");
		a.SetProperty("color", "red");
		let b = new StyleRule(".x");
		b.SetProperty("color", "blue");
		sheet.AddRule(a);
		sheet.AddRule(b);

		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(rs.Get("color") == "blue"); // later source wins the tie
	}

	[Test]
	public static void NonMatchingRulesContributeNothing()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		let sheet = scope StyleSheet();
		let other = new StyleRule("span");
		other.SetProperty("color", "nope");
		sheet.AddRule(other);

		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(rs.Count == 0);
	}

	[Test]
	public static void RulesFoundThroughDifferentKeysStillTieBySourceOrder()
	{
		// The index keys .a and .b apart; the element lists b first, so .b's rule is found first,
		// yet .a came first in the sheet and the later .b wins.
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		w.AddClass("b");
		w.AddClass("a");
		let sheet = scope StyleSheet();
		let a = new StyleRule(".a");
		a.SetProperty("color", "red");
		let b = new StyleRule(".b");
		b.SetProperty("color", "blue");
		sheet.AddRule(a);
		sheet.AddRule(b);
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(rs.Get("color") == "blue");
	}

	[Test]
	public static void EachKeyKindFindsItsRulesAndARuleAddedAfterAResolveIsSeen()
	{
		let w = StyleFixtures.Widget("button", "ok");
		defer w.ReleaseRef();
		w.AddClass("primary");
		let sheet = scope StyleSheet();
		void Add(StringView selector, StringView name)
		{
			let rule = new StyleRule(selector);
			rule.SetProperty(name, "1px");
			sheet.AddRule(rule);
		}
		Add("#ok", "padding-left");
		Add("panel .primary", "padding-top"); // keyed by its subject's class, not the ancestor's
		Add("button:hover", "padding-right"); // keyed by tag; the state turns it away
		Add("*", "padding-bottom");
		Add("[id=ok]", "margin-left"); // no id, class or tag: tried everywhere
		Add("#other", "margin-top");
		Add("label", "margin-right");
		Add("button:no-such-state", "margin-bottom"); // never matches: in no list

		let first = scope ResolvedStyle();
		sheet.Resolve(w, first);
		Test.Assert(first.Has("padding-left"));
		Test.Assert(!first.Has("padding-top")); // no panel above it
		Test.Assert(!first.Has("padding-right"));
		Test.Assert(first.Has("padding-bottom"));
		Test.Assert(first.Has("margin-left"));
		Test.Assert(!first.Has("margin-top"));
		Test.Assert(!first.Has("margin-right"));
		Test.Assert(!first.Has("margin-bottom"));

		Add("button.primary", "border-left-width");
		let second = scope ResolvedStyle();
		sheet.Resolve(w, second);
		Test.Assert(second.Has("border-left-width"));
	}
}
