using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// StyleSelector: parsing, specificity, and matching against the UIWidget identity
/// (tag/#id/.class), the structural pseudo-classes, :not/:is/:where, and the combinators.
/// Derived from eepp's css selector semantics (common subset).
class StyleSelectorTests
{
	private static bool Sel(StringView selector, UIWidget element) => StyleFixtures.Selects(selector, element);
	private static int64 Spec(StringView selector) => StyleFixtures.SpecificityOf(selector);

	[Test]
	public static void SpecificityBuckets()
	{
		Test.Assert(Spec("button") == 1); // tag
		Test.Assert(Spec(".primary") == 1024); // class
		Test.Assert(Spec("#ok") == 1048576); // id
		Test.Assert(Spec("button.primary#ok") == 1048576 + 1024 + 1);
		Test.Assert(Spec("*") == 0); // universal
		Test.Assert(Spec("div .item") == 1 + 1024); // tag + class across two rules
		Test.Assert(Spec("button:hover") == 1 + 1024); // pseudo counts as a class
	}

	[Test]
	public static void TagIdClassMatching()
	{
		let w = StyleFixtures.Widget("button", "ok");
		defer w.ReleaseRef();
		w.AddClass("primary");

		Test.Assert(Sel("button", w));
		Test.Assert(!Sel("span", w));
		Test.Assert(Sel("#ok", w));
		Test.Assert(!Sel("#cancel", w));
		Test.Assert(Sel(".primary", w));
		Test.Assert(!Sel(".large", w));
		Test.Assert(Sel("button.primary#ok", w));
		Test.Assert(!Sel("button.large", w));
		Test.Assert(Sel("*", w)); // universal matches
	}

	[Test]
	public static void DescendantVsChildCombinators()
	{
		let container = new UIWidget();
		defer container.ReleaseRef();
		container.AddClass("container");
		let mid = new UIWidget();
		defer mid.ReleaseRef();
		let deep = StyleFixtures.Widget("button");
		defer deep.ReleaseRef();
		container.AddChild(mid);
		mid.AddChild(deep); // container > mid > deep(button)

		// Descendant: container is an ancestor of the button.
		Test.Assert(Sel(".container button", deep));
		// Child: button's direct parent is `mid`, not `.container` -> no match.
		Test.Assert(!Sel(".container > button", deep));

		let direct = StyleFixtures.Widget("button");
		defer direct.ReleaseRef();
		container.AddChild(direct); // container > direct(button)
		Test.Assert(Sel(".container > button", direct));
		Test.Assert(Sel(".container button", direct));
	}

	[Test]
	public static void SiblingCombinatorsPlusRightAfterAndTildeAnywhereAfter()
	{
		let row = scope Row("blbb"); // button label button button
		Test.Assert(Sel("button + label", row[1]));
		Test.Assert(Sel("label + button", row[2]));
		Test.Assert(!Sel("label + button", row[3])); // not right after the label
		Test.Assert(Sel("label ~ button", row[3]));
		Test.Assert(!Sel("label ~ button", row[0])); // before it
		Test.Assert(Sel("button+label", row[1])); // no spaces
	}

	[Test]
	public static void StructuralPseudoClassesCountWidgetsAmongTheirSiblings()
	{
		let row = scope Row("blbbl");
		Test.Assert(Sel(":first-child", row[0]));
		Test.Assert(!Sel(":first-child", row[1]));
		Test.Assert(Sel(":last-child", row[4]));
		Test.Assert(Sel("button:first-of-type", row[0]));
		Test.Assert(Sel("label:first-of-type", row[1]));
		Test.Assert(Sel("button:last-of-type", row[3]));
		Test.Assert(Sel(":nth-child(2n+1)", row[2])); // 3rd
		Test.Assert(!Sel(":nth-child(odd)", row[1]));
		Test.Assert(Sel(":nth-child(even)", row[3]));
		Test.Assert(Sel(":nth-child(3)", row[2]));
		Test.Assert(Sel(":nth-child(-n+2)", row[1]));
		Test.Assert(!Sel(":nth-child(-n+2)", row[2]));
		Test.Assert(Sel(":nth-last-child(1)", row[4]));
		Test.Assert(Sel("button:nth-of-type(2)", row[2]));
		Test.Assert(Sel("label:nth-last-of-type(1)", row[4]));
		let only = scope Row("b");
		Test.Assert(Sel(":only-child", only[0]));
		Test.Assert(!Sel(":only-child", row[0]));
		Test.Assert(Sel(":empty", row[0]));
		Test.Assert(!Sel(":empty", row.Parent));
	}

	[Test]
	public static void NotIsAndWhereWithTheirSpecificity()
	{
		let w = StyleFixtures.Widget("button", "ok");
		defer w.ReleaseRef();
		w.AddClass("primary");
		Test.Assert(Sel("button:not(.large)", w));
		Test.Assert(!Sel("button:not(.primary)", w));
		Test.Assert(!Sel(":not(label, .primary)", w));
		Test.Assert(Sel(":is(label, .primary)", w));
		Test.Assert(!Sel(":is(label, .large)", w));
		Test.Assert(Sel(":where(#ok)", w));
		// :not and :is add their most specific argument; :where adds nothing.
		Test.Assert(Spec(":is(.a, #b)") == 1048576);
		Test.Assert(Spec("button:not(.a)") == 1 + 1024);
		Test.Assert(Spec(":where(#b) button") == 1);
	}

	[Test]
	public static void AnUnknownPseudoClassOrAStrayCharacterMakesTheRuleMatchNothing()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		Test.Assert(!Sel("button:hovr", w));
		Test.Assert(!Sel(":frobnicate(2)", w));
		Test.Assert(!Sel("button:nth-child(banana)", w));
		Test.Assert(!Sel("button$", w));
		Test.Assert(Sel("button", w));
	}

	[Test]
	public static void CombinatorsTryEveryCandidateNotOnlyTheNearest()
	{
		// a.x > b > c, and c's nearest `b` ancestor is not a child of .x: a greedy walk fails.
		let x = new UIWidget();
		defer x.ReleaseRef();
		x.AddClass("x");
		let b1 = StyleFixtures.Widget("b");
		defer b1.ReleaseRef();
		let b2 = StyleFixtures.Widget("b");
		defer b2.ReleaseRef();
		let c = StyleFixtures.Widget("c");
		defer c.ReleaseRef();
		x.AddChild(b1);
		b1.AddChild(b2);
		b2.AddChild(c);
		Test.Assert(Sel(".x > b c", c));
		Test.Assert(Sel(".x > b > b > c", c));
		Test.Assert(!Sel(".x > c", c));
	}

	[Test]
	public static void ASheetsSelectorListsSplitOnlyAtTheirTopLevel()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(":is(.a, .b), label { opacity: 0.5; } [title=\"x, y\"] { opacity: 0.2; }", sheet);
		Test.Assert(sheet.RuleCount == 3);
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.AddClass("b");
		Test.Assert(sheet.Rules[0].Selector.Select(w));
	}

	[Test]
	public static void TheAncestorKeysComeFromCompoundsAChildOrDescendantCombinatorReaches()
	{
		bool Has(StyleSelector s, StringView name)
		{
			for (let key in s.AncestorKeys)
			{
				if (key == HashText(name))
					return true;
			}
			return false;
		}
		let parentOfSibling = scope StyleSelector("panel > label + .note");
		Test.Assert(Has(parentOfSibling, "panel")); // label's parent is .note's parent too
		Test.Assert(!Has(parentOfSibling, "label"));
		Test.Assert(!Has(parentOfSibling, "note")); // the subject's own names are not an ancestor's

		let siblingOfParent = scope StyleSelector("panel + #box .cell");
		Test.Assert(Has(siblingOfParent, "box"));
		Test.Assert(!Has(siblingOfParent, "panel")); // only a sibling of an ancestor

		let many = scope StyleSelector(".a.b .c.d .e .f");
		Test.Assert(many.AncestorKeys.Length == StyleSelector.cAncestorKeys);
		let none = scope StyleSelector("button:hover");
		Test.Assert(none.AncestorKeys.Length == 0);
	}

	[Test]
	public static void TheAncestorFilterTurnsAwayARuleWhoseAncestorIsMissingAndNeverOneThatCouldMatch()
	{
		let top = StyleFixtures.Widget("panel", "top");
		defer top.ReleaseRef();
		top.AddClass("page");
		let deep = StyleFixtures.Widget("panel");
		defer deep.ReleaseRef();
		deep.AddClass("deep");
		let needsPage = scope StyleSelector(".page .cell");
		let needsTop = scope StyleSelector("#top > .cell");
		let needsDeep = scope StyleSelector(".deep .cell");

		let filter = scope AncestorFilter();
		Test.Assert(!filter.MayMatch(needsPage));
		filter.Push(top);
		Test.Assert(filter.MayMatch(needsPage));
		Test.Assert(filter.MayMatch(needsTop));
		Test.Assert(!filter.MayMatch(needsDeep));

		// More of one name than a counter holds: popping all but one still says maybe.
		for (int i = 0; i < 300; i++)
			filter.Push(deep);
		for (int i = 0; i < 299; i++)
			filter.Pop();
		Test.Assert(filter.MayMatch(needsDeep));
		filter.Pop();
		filter.Pop();
		Test.Assert(!filter.MayMatch(needsPage));
	}

	[Test]
	public static void PositionsAndSiblingsFollowTheChildrenAsTheyAreAddedMovedAndRemoved()
	{
		let row = scope Row("bbbb");
		Test.Assert(Sel(":nth-child(1)", row[0]));
		Test.Assert(Sel(":nth-last-child(1)", row[3]));
		row.Parent.SetChildIndex(row.Kids[3], 0); // the last goes first
		Test.Assert(Sel(":nth-child(1)", row[3]));
		Test.Assert(Sel(":nth-child(2)", row[0]));
		Test.Assert(Sel(":nth-last-child(1)", row[2]));

		// A plain node among them is not counted, and a label added after changes the count.
		let plain = new Node();
		defer plain.ReleaseRef();
		row.Parent.AddChildAt(plain, 1);
		let label = StyleFixtures.Widget("label");
		defer label.ReleaseRef();
		row.Parent.AddChild(label);
		Test.Assert(Sel(":nth-child(2)", row[0]));
		Test.Assert(Sel(":nth-last-child(1)", label));
		Test.Assert(Sel("button + label", label));

		// Moved to another parent: numbered there, and gone from here.
		let other = scope Row("ll");
		other.Parent.AddChild(row.Kids[3]);
		Test.Assert(Sel(":nth-child(3)", row[3]));
		Test.Assert(Sel(":nth-child(1)", row[0]));
		Test.Assert(Sel("label + button", row[3]));
		row.Parent.RemoveChild(label);
		Test.Assert(Sel(":nth-last-child(1)", row[2]));
	}

	[Test]
	public static void APartsStateCountsAsAPseudoClassOfItsOwnBesideTheCompounds()
	{
		// :first-of-type and the part's :hover both count (they shared bits before).
		Test.Assert(Spec("slider:first-of-type::thumb:hover") == 2 * 1024 + 1 + 1);
		Test.Assert(Spec("slider::thumb:hover") == 1024 + 1 + 1);
		Test.Assert(Spec("slider:hover::thumb:hover") == 2 * 1024 + 1 + 1);
	}

	[Test]
	public static void PseudoClassesTrackControlState()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		w.Size = .(100.0f, 100.0f);
		w.TabFocusable = true; // a click focuses what takes focus
		root.AddChild(w);
		let d = root.EventDispatcher;

		Test.Assert(!Sel("button:hover", w)); // not hovered yet
		Test.Assert(StyleFixtures.Selects("button:hover", w, false)); // pseudo ignored

		d.InjectMouseMove(.(50.0f, 50.0f)); // hover w
		Test.Assert(Sel("button:hover", w));

		d.InjectMouseDown(.(50.0f, 50.0f), .Left); // press and focus
		Test.Assert(Sel("button:active", w));
		Test.Assert(Sel("button:focus", w));

		w.Enabled = false;
		Test.Assert(Sel(":disabled", w));
		Test.Assert(Sel("button:disabled", w));
	}

	[Test]
	public static void WhatChangesAStructuralOrStateMatchRestylesTheWidgetsItTouches()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let list = StyleFixtures.Widget("list");
		defer list.ReleaseRef();
		root.AddChild(list);
		let first = StyleFixtures.Widget("item");
		defer first.ReleaseRef();
		list.AddChild(first);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "item:last-child { opacity: 0.5; } checkbox:checked { opacity: 0.25; }");
		styles.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(first.Alpha, 0.5f));

		// A new last child: the old one is no longer last.
		let second = StyleFixtures.Widget("item");
		defer second.ReleaseRef();
		list.AddChild(second);
		styles.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(second.Alpha, 0.5f));

		let area = new CheckBox();
		defer area.ReleaseRef();
		root.AddChild(area);
		styles.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(area.Alpha, 1.0f));
		area.Checked = true;
		styles.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(area.Alpha, 0.25f));
	}
}
