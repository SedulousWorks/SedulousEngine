using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A widget with a reflected property of its own, read by attribute selectors by its CSS name.
[GuiReflect]
class FieldWidget : UIWidget
{
	private String mHint = new .() ~ delete _;

	[GuiProperty("placeholder")]
	public StringView Hint
	{
		get => mHint;
		set => mHint.Set(value);
	}
}

/// An element type a library registers, with a property a sheet may set by its CSS name.
[GuiReflect(true, "sheet-gauge")]
class SheetGauge : UIWidget
{
	[GuiProperty("needle-width")]
	public float NeedleWidth { get; set; }
}

/// What the selectors, sheets and the parser do that the ported cases leave unchecked: attribute
/// tests against reflected properties, the state and language pseudo-classes, the An+B forms,
/// what a selector reads through its relations, the CSS-wide keywords, currentColor, origins,
/// inline style and the trace of a cascade, nested @media, imports, spritesheets, the parser's
/// lines, and the check of a sheet's names.
class SheetsTests
{
	private static bool Sel(StringView selector, UIWidget element) => StyleFixtures.Selects(selector, element);
	private static int64 Spec(StringView selector) => StyleFixtures.SpecificityOf(selector);

	[Test]
	public static void AttributesReadReflectedPropertiesByTheirCssNames()
	{
		let field = new FieldWidget();
		defer field.ReleaseRef();
		let plain = new UIWidget();
		defer plain.ReleaseRef();
		field.Hint = "search the list";
		field.AddClass("dark-mode");
		Test.Assert(Sel("[placeholder]", field));
		Test.Assert(!Sel("[placeholder]", plain)); // its type has no such property
		Test.Assert(Sel("[placeholder=\"search the list\"]", field));
		Test.Assert(Sel("[placeholder='search the list']", field));
		Test.Assert(!Sel("[placeholder=search]", field));
		Test.Assert(Sel("[placeholder^=search]", field));
		Test.Assert(!Sel("[placeholder^=list]", field));
		Test.Assert(Sel("[placeholder$=list]", field));
		Test.Assert(Sel("[placeholder*=\"the l\"]", field));
		Test.Assert(!Sel("[placeholder*=\"\"]", field)); // an empty substring matches nothing
		Test.Assert(Sel("[placeholder~=the]", field));
		Test.Assert(Sel("[class|=dark]", field)); // "dark-mode": dark followed by a dash
		Test.Assert(!Sel("[class|=mode]", field));
		Test.Assert(!Sel("[no-such-attribute]", field));
		Test.Assert(!Sel("[id]", field)); // no id set
		field.Id = "q";
		Test.Assert(Sel("[id=q]", field));

		// A bool reads as true or false; a base type's property is the derived one's too.
		Test.Assert(Sel("[aria-hidden=false]", plain));
		plain.AccessHidden = true;
		Test.Assert(Sel("[aria-hidden=true]", plain));
		Test.Assert(Sel("[drag=auto]", field));
		plain.Tooltip = "Save";
		Test.Assert(Sel("[tooltip=Save]", plain));
		Test.Assert(!Sel("[tooltip=Save]", field));
		Test.Assert(!Sel("[placeholder", field)); // not closed: matches nothing
		Test.Assert(Spec("[a][b=c]") == 2 * 1024);
	}

	[Test]
	public static void PseudoClassesReadTheWidgetsStateAndWhatTheInspectorForces()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		Test.Assert(!Sel(":hover", w));
		w.Hovered = true;
		Test.Assert(Sel(":hover", w));
		w.Hovered = false;
		Test.Assert(!Sel(":active", w));
		w.Pressed = true;
		Test.Assert(Sel("button:active", w));
		w.Pressed = false;
		Test.Assert(Sel(":enabled", w));
		Test.Assert(!Sel(":disabled", w));
		w.Enabled = false;
		Test.Assert(Sel(":disabled", w));
		Test.Assert(!Sel(":enabled", w));
		w.Enabled = true;

		// Forced (the inspector): it reads as set; forced disabled is not enabled; forced
		// focus-visible counts as focus too.
		w.ForcedStyleStates = Node.StateHover | Node.StateDisabled | Node.StateFocusVisible;
		Test.Assert(Sel(":hover", w));
		Test.Assert(Sel(":disabled", w));
		Test.Assert(!Sel(":enabled", w));
		Test.Assert(Sel(":focus", w));
		Test.Assert(Sel(":focus-visible", w));
		w.ForcedStyleStates = 0;
		Test.Assert(!Sel(":hover", w));

		// applyPseudo false: what follows interaction is ignored, the structure is not.
		let s = scope StyleSelector("button:hover:focus");
		Test.Assert(!s.Select(w));
		Test.Assert(s.Select(w, false));
		let structural = scope StyleSelector("button:hover:empty");
		let inside = StyleFixtures.Widget("x");
		w.AddChild(inside);
		inside.ReleaseRef(); // w holds it
		Test.Assert(!structural.Select(w, false));

		// A widget's own states.
		let checkedOne = new CheckedWidget();
		defer checkedOne.ReleaseRef();
		Test.Assert(Sel(":checked", checkedOne));
		Test.Assert(!Sel(":checked", w));
		Test.Assert(Sel(":read-only", w)); // nothing it reports is editable
		Test.Assert(!Sel(":read-write", w));
		Test.Assert(!Sel(":selected", w));
		Test.Assert(!Sel(":placeholder-shown", w));
		w.ForcedStyleStates = Node.StateChecked;
		Test.Assert(Sel(":checked", w)); // forced checked reads as set
		w.ForcedStyleStates = 0;
	}

	[Test]
	public static void FocusFocusWithinAndRoot()
	{
		let panel = StyleFixtures.Widget("panel");
		defer panel.ReleaseRef();
		let input = StyleFixtures.Widget("input");
		defer input.ReleaseRef();
		panel.AddChild(input);
		Test.Assert(!Sel(":focus", input));
		Test.Assert(!Sel("panel:focus-within", panel));
		input.HandleFocusGained();
		Test.Assert(Sel("input:focus", input));
		Test.Assert(Sel("panel:focus-within", panel));
		Test.Assert(Sel("input:focus-within", input));
		Test.Assert(!Sel("panel:focus", panel));
		Test.Assert(!Sel(":focus-visible", input)); // not by the keyboard
		input.HandleFocusLost();
		Test.Assert(!Sel("panel:focus-within", panel));

		// :root: under no widget (a plain node above it still leaves it the top widget).
		Test.Assert(Sel(":root", panel));
		Test.Assert(!Sel(":root", input));
		let holder = new Node();
		defer holder.ReleaseRef();
		holder.AddChild(panel);
		Test.Assert(Sel(":root", panel));
		// The combinators step over a plain node: it is no widget to match.
		Test.Assert(!Sel(":root > panel", panel));
	}

	[Test]
	public static void LangMatchesALanguageAndItsRegionsInheritedFromAbove()
	{
		let parent = StyleFixtures.Widget("panel");
		defer parent.ReleaseRef();
		let child = StyleFixtures.Widget("label");
		defer child.ReleaseRef();
		parent.AddChild(child);
		parent.Lang = "PT_br";
		Test.Assert(Sel(":lang(pt)", child)); // its parent's, any case, _ as -
		Test.Assert(Sel(":lang(pt-BR)", child));
		Test.Assert(!Sel(":lang(p)", child)); // a prefix that is not a whole subtag
		Test.Assert(!Sel(":lang(en)", child));
		Test.Assert(Sel(":lang(en, pt)", child));
		child.Lang = "en";
		Test.Assert(Sel(":lang(en)", child));
		Test.Assert(!Sel(":lang()", child)); // an empty list matches nothing
		Test.Assert(Spec(":lang(en, fr)") == 1024); // the list counts once
	}

	[Test]
	public static void NthFormsAndTheMatchesAlias()
	{
		let row = scope Row("bbbbb");
		Test.Assert(Sel(":nth-child(-2n+5)", row[0])); // 5, 3, 1
		Test.Assert(!Sel(":nth-child(-2n+5)", row[1]));
		Test.Assert(Sel(":nth-child(-2n+5)", row[4]));
		Test.Assert(Sel(":nth-child(n)", row[3]));
		Test.Assert(Sel(":nth-child(+3)", row[2]));
		Test.Assert(Sel(":nth-child( 2n + 1 )", row[4])); // white space inside
		Test.Assert(Sel(":nth-child(3n)", row[2]));
		Test.Assert(!Sel(":nth-child(3n)", row[3]));
		Test.Assert(Sel(":nth-last-child(2n)", row[3]));
		Test.Assert(!Sel(":nth-child(2x+1)", row[0])); // not an+b: matches nothing
		Test.Assert(!Sel(":nth-child()", row[0]));
		Test.Assert(Sel(":matches(button)", row[0])); // :is's old name
		Test.Assert(!Sel(":is()", row[0])); // an empty list matches nothing
		Test.Assert(Spec(":nth-child(2):first-child") == 2 * 1024);
	}

	[Test]
	public static void WhatASelectorReadsThroughItsRelations()
	{
		uint32 Ancestor(StringView selector)
		{
			uint32 ancestor = 0;
			uint32 sibling = 0;
			let s = scope StyleSelector(selector);
			s.CollectRelationStates(ref ancestor, ref sibling);
			return ancestor;
		}
		uint32 Sibling(StringView selector)
		{
			uint32 ancestor = 0;
			uint32 sibling = 0;
			let s = scope StyleSelector(selector);
			s.CollectRelationStates(ref ancestor, ref sibling);
			return sibling;
		}
		Test.Assert(Ancestor(":hover x") == PseudoHover);
		Test.Assert(Sibling(":hover x") == 0);
		Test.Assert(Ancestor(":focus-within > x") == PseudoFocusWithin);
		Test.Assert(Sibling(":checked + x") == PseudoChecked);
		Test.Assert(Ancestor(":checked + x") == 0);
		Test.Assert(Ancestor("x:hover") == 0); // the subject's own state is not a relation's
		Test.Assert(Sibling("x:hover") == 0);
		Test.Assert(Ancestor(":not(:hover) x") == PseudoHover); // nested in an ancestor's compound
		Test.Assert(Ancestor("x:is(:active y)") == PseudoActive); // nested in the subject
		Test.Assert(Ancestor("a:first-child x") == 0); // structure is no state

		bool Reads(StringView selector)
		{
			let s = scope StyleSelector(selector);
			return s.ReadsSiblings;
		}
		Test.Assert(Reads("li:nth-child(odd)"));
		Test.Assert(Reads("a + b"));
		Test.Assert(Reads("a ~ b"));
		Test.Assert(Reads("x:not(:first-child)"));
		Test.Assert(!Reads("a b"));
		Test.Assert(!Reads("a > b:hover"));

		int Above(StringView selector, String outFirstClass)
		{
			int count = 0;
			let s = scope StyleSelector(selector);
			s.ForEachSiblingReadAbove(scope [&] (compound) =>
				{
					if ((count == 0) && (compound.Classes.Length != 0))
						outFirstClass.Append(compound.Classes[0]);
					count++;
				});
			return count;
		}
		let first = scope String();
		Test.Assert(Above(".row:first-child .label", first) == 1);
		Test.Assert(first == "row");
		Test.Assert(Above("li:nth-child(odd)", scope String()) == 0); // the subject alone: its children's place
		Test.Assert(Above(".a + .b", scope String()) == 0);
		first.Clear();
		Test.Assert(Above(".a + .b .c", first) == 2);
		Test.Assert(first == "a");
	}

	[Test]
	public static void MatchesIdentityAsksNeitherStateNorPosition()
	{
		let row = scope Row("bb");
		row[1].AddClass("a");
		let s = scope StyleSelector("button.a:hover:first-child");
		Test.Assert(s.RuleAt(0).MatchesIdentity(row[1]));
		Test.Assert(!s.RuleAt(0).Matches(row[1]));
		Test.Assert(!s.RuleAt(0).MatchesIdentity(row[0])); // no class a
		let never = scope StyleSelector("button.a:frob");
		Test.Assert(!never.RuleAt(0).MatchesIdentity(row[1]));
		Test.Assert(never.IsNever);
		let parsed = scope StyleSelector("panel > #ok.x::thumb");
		Test.Assert(parsed.RuleCount == 2);
		Test.Assert(parsed.RuleAt(1).Combinator == .Child);
		Test.Assert(parsed.RuleAt(1).Id == "ok");
		Test.Assert(parsed.RuleAt(1).Classes[0] == "x");
		Test.Assert(parsed.PseudoElement == "thumb");
		Test.Assert(parsed.RuleAt(0).Tag == "panel");
		Test.Assert(parsed.Specificity == 1 + 1048576 + 1024 + 1); // a pseudo-element counts as a tag

		// A copy is whole: it matches as the original does.
		let copy = scope StyleSelector();
		copy.Set(s);
		Test.Assert(copy.Specificity == s.Specificity);
		row[1].Hovered = true;
		Test.Assert(!copy.Select(row[1])); // not first
		Test.Assert(copy.RuleAt(0).MatchesIdentity(row[1]));
	}

	[Test]
	public static void TheCssWideKeywordsSettleAgainstTheTableAndTheParent()
	{
		let parent = scope ResolvedStyle();
		parent.Set("opacity", "0.5");
		parent.Set("color", "red");
		parent.Finalize();
		let child = scope ResolvedStyle();
		child.Set("opacity", "inherit"); // not an inherited property: the parent's value
		child.Set("color", "unset"); // inherited: it inherits, so it goes
		child.Set("visibility", "initial"); // the table's initial value
		child.Set("padding-top", "unset"); // not inherited: unset is initial
		child.Set("vertical-align", "initial"); // no initial value, not inherited: the node's own
		child.Set("font-family", "initial"); // no initial value, inherited: kept, stops inheriting
		child.Set("width", " inherit "); // the parent has none: it goes
		child.SettleKeywords(parent);
		Test.Assert(child.Get("opacity") == "0.5");
		Test.Assert(NodeFixtures.Near(child.Value("opacity").Number, 0.5f));
		Test.Assert(!child.Has("color"));
		Test.Assert(child.Get("visibility") == "visible");
		Test.Assert(child.Value("visibility").Keyword == "visible");
		Test.Assert(child.Get("padding-top") == "0");
		Test.Assert(!child.Has("vertical-align"));
		Test.Assert(child.Get("font-family") == "initial");
		Test.Assert(child.Value("font-family") == null);
		Test.Assert(!child.Has("width"));
	}

	[Test]
	public static void SetFinalizeOverrideAndRemove()
	{
		let s = scope ResolvedStyle();
		Test.Assert(s.IsFinalized); // empty: settled
		s.Set("--gap", "3px");
		s.Set("padding", "var(--gap) 1px");
		s.Set("margin-top", "var(--none)");
		Test.Assert(!s.IsFinalized);
		Test.Assert(!s.Has("padding-top"));
		s.Finalize();
		Test.Assert(s.IsFinalized);
		Test.Assert(!s.Has("padding")); // its longhands instead
		Test.Assert(s.Get("padding-top") == "3px");
		Test.Assert(s.Get("padding-left") == "1px");
		Test.Assert(!s.Has("margin-top")); // a var() with no value drops its declaration
		Test.Assert(s.Get("--gap") == "3px");

		// var() falls back to the inherited style's custom properties.
		let parent = scope ResolvedStyle();
		parent.Set("--tint", "blue");
		let child = scope ResolvedStyle();
		child.Set("color", "var(--tint)");
		child.Finalize(parent);
		Test.Assert(child.Get("color") == "blue");

		// An important value resists a later normal one, not a later important one.
		s.Set("opacity", "0.1", true);
		s.Set("opacity", "0.9");
		Test.Assert(s.Get("opacity") == "0.1");
		s.Set("opacity", "0.7", true);
		Test.Assert(s.Get("opacity") == "0.7");

		let value = scope StyleValue();
		value.Kind = .Number;
		value.Number = 0.25f;
		s.Override("opacity", value);
		Test.Assert(NodeFixtures.Near(s.Value("opacity").Number, 0.25f));
		Test.Assert(s.Get("opacity") == "0.7"); // its text stays
		s.Override("z-tween", value); // a property it did not have
		Test.Assert(s.Has("z-tween"));
		s.Remove("opacity");
		Test.Assert(!s.Has("opacity"));

		let copy = scope ResolvedStyle();
		copy.Set(s);
		Test.Assert(copy.Count == s.Count);
		Test.Assert(copy.Get("padding-top") == "3px");
		copy.Clear();
		Test.Assert((copy.Count == 0) && copy.IsFinalized);
	}

	[Test]
	public static void CurrentColorReadsTheNearestDeclaredColor()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"panel { color: blue; } " +
			"button { color: red; border-top-color: currentColor; } " +
			"label { background-color: CurrentColor; } " +
			"tag { color: currentcolor; }", sheet);
		let panel = StyleFixtures.Widget("panel");
		defer panel.ReleaseRef();
		let parent = scope ResolvedStyle();
		sheet.Resolve(panel, parent);

		let button = StyleFixtures.Widget("button");
		defer button.ReleaseRef();
		let own = scope ResolvedStyle();
		sheet.Resolve(button, MediaContext(), true, default, parent, own);
		Test.Assert(own.Get("border-top-color") == "red"); // its own colour

		let label = StyleFixtures.Widget("label");
		defer label.ReleaseRef();
		let inheriting = scope ResolvedStyle();
		sheet.Resolve(label, MediaContext(), true, default, parent, inheriting);
		Test.Assert(inheriting.Get("background-color") == "blue"); // the parent's, in any case
		let alone = scope ResolvedStyle();
		sheet.Resolve(label, alone);
		Test.Assert(!alone.Has("background-color")); // no colour anywhere: it goes

		let tag = StyleFixtures.Widget("tag");
		defer tag.ReleaseRef();
		let colorItself = scope ResolvedStyle();
		sheet.Resolve(tag, MediaContext(), true, default, parent, colorItself);
		Test.Assert(colorItself.Get("color") == "blue"); // color: currentColor is the parent's

		Test.Assert(ResolvedStyle.HasCurrentColor("1px solid CURRENTCOLOR"));
		Test.Assert(!ResolvedStyle.HasCurrentColor("red"));
	}

	[Test]
	public static void OriginsInlineStyleAndTheTraceOfACascade()
	{
		let w = StyleFixtures.Widget("button", "ok");
		defer w.ReleaseRef();
		w.AddClass("a");
		let low = scope StyleSheet();
		CSSParser.Parse("#ok { opacity: 0.1; } .a { color: red; } button { color: blue !important; } .a { padding: 1; }", low);
		let high = scope StyleSheet();
		CSSParser.Parse("button { opacity: 0.9; }", high);
		let matches = scope List<StyleRuleMatch>();
		low.CollectMatches(w, MediaContext(), true, default, 0, matches);
		high.CollectMatches(w, MediaContext(), true, default, 1, matches);
		Test.Assert(matches.Count == 5);

		let inlineStyle = scope List<InlineStyleDeclaration>();
		defer { ClearAndDeleteItems!(inlineStyle); }
		void Inline(StringView name, StringView value)
		{
			let d = new InlineStyleDeclaration();
			d.Name.Set(name);
			d.Value.Set(value);
			inlineStyle.Add(d);
		}
		Inline("color", "green");
		Inline("padding-left", "7");

		let rs = scope ResolvedStyle();
		StyleSheet.Cascade(matches, null, inlineStyle, rs);
		Test.Assert(rs.Get("opacity") == "0.9"); // a later origin wins over an id
		Test.Assert(rs.Get("color") == "blue"); // !important over the inline style
		Test.Assert(rs.Get("padding-left") == "7"); // the inline style over the rules
		Test.Assert(rs.Get("padding-top") == "1");

		let traces = scope List<LonghandTrace>();
		defer { ClearAndDeleteItems!(traces); }
		StyleSheet.Trace(matches, inlineStyle, traces);
		LonghandTrace Find(StringView name)
		{
			for (let t in traces)
			{
				if (t.Name == name)
					return t;
			}
			return null;
		}
		let color = Find("color");
		Test.Assert((color != null) && (color.Declarations.Count == 3));
		Test.Assert(color.Declarations[0].Value == "blue" && color.Declarations[0].Important); // the winner first
		Test.Assert(color.Declarations[1].Value == "green" && (color.Declarations[1].Rule == null)); // inline: no rule
		Test.Assert(color.Declarations[2].Value == "red" && (color.Declarations[2].Rule != null));
		let opacity = Find("opacity");
		Test.Assert(opacity.Declarations.Count == 2);
		Test.Assert((opacity.Declarations[0].Value == "0.9") && (opacity.Declarations[0].Origin == 1));
		let paddingLeft = Find("padding-left");
		Test.Assert(paddingLeft.Declarations.Count == 2);
		Test.Assert(paddingLeft.Declarations[0].Value == "7");
		Test.Assert(paddingLeft.Declarations[1].Value == "1"); // the shorthand, as this longhand
		Test.Assert(Find("padding") == null);
	}

	[Test]
	public static void CollectMatchesHonoursTheAncestorFilterAndThePartsStates()
	{
		let page = StyleFixtures.Widget("panel");
		defer page.ReleaseRef();
		page.AddClass("page");
		let w = StyleFixtures.Widget("slider");
		defer w.ReleaseRef();
		page.AddChild(w);
		let sheet = scope StyleSheet();
		CSSParser.Parse(".page slider { opacity: 0.5; } slider::thumb { color: red; } slider::thumb:hover { color: blue; }", sheet);

		let matches = scope List<StyleRuleMatch>();
		sheet.CollectMatches(w, MediaContext(), true, default, 0, matches);
		Test.Assert(matches.Count == 1);
		matches.Clear();
		let filter = scope AncestorFilter();
		sheet.CollectMatches(w, MediaContext(), true, default, 0, matches, 0, filter); // told no ancestor has .page
		Test.Assert(matches.Count == 0);
		filter.Push(page);
		sheet.CollectMatches(w, MediaContext(), true, default, 0, matches, 0, filter);
		Test.Assert(matches.Count == 1);

		matches.Clear();
		sheet.CollectMatches(w, MediaContext(), true, "thumb", 0, matches);
		Test.Assert(matches.Count == 1); // the part's :hover asks for a state it does not have
		matches.Clear();
		sheet.CollectMatches(w, MediaContext(), true, "thumb", 0, matches, PseudoHover);
		Test.Assert(matches.Count == 2);
		let rs = scope ResolvedStyle();
		StyleSheet.Cascade(matches, null, default, rs);
		Test.Assert(rs.Get("color") == "blue");
		matches.Clear();
		sheet.CollectMatches(w, MediaContext(), false, "thumb", 0, matches);
		Test.Assert(matches.Count == 2); // applyPseudo false: the part's states are not asked
	}

	[Test]
	public static void AnInnerMediaBlockReplacesTheOuter()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("@media (min-width: 600px) { a { color: red; } @media (max-width: 100px) { b { color: blue; } } }", sheet);
		Test.Assert(sheet.RuleCount == 2);
		Test.Assert(sheet.Rules[0].Media.Evaluate(.(800.0f, 0.0f, 96.0f)));
		Test.Assert(!sheet.Rules[0].Media.Evaluate(.(50.0f, 0.0f, 96.0f)));
		Test.Assert(sheet.Rules[1].Media.Evaluate(.(50.0f, 0.0f, 96.0f))); // the outer condition is not kept
		Test.Assert(!sheet.Rules[1].Media.Evaluate(.(800.0f, 0.0f, 96.0f)));
		let plain = scope StyleSheet();
		CSSParser.Parse("a { color: red; }", plain);
		Test.Assert(plain.Rules[0].Media.IsEmpty);
	}

	[Test]
	public static void ImportsAreReadInTheirFormsAndAnImportedSheetGoesFirst()
	{
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		let sheet = scope StyleSheet();
		CSSParser.Parse("@import \"a.css\"; @import url(b.css); @import url( 'c.css' ) screen; @import; @import \"\"; .b { opacity: 0.5; }",
			"main.css", said, sheet);
		Test.Assert(sheet.Imports.Length == 3);
		Test.Assert(sheet.Imports[0] == "a.css");
		Test.Assert(sheet.Imports[1] == "b.css");
		Test.Assert(sheet.Imports[2] == "c.css");
		Test.Assert(said.Count == 2); // the two with no path
		Test.Assert(StyleFixtures.Says(said, "an at-rule it does not read: @import"));

		let imported = scope StyleSheet();
		CSSParser.Parse(".b { opacity: 0.25; } .a { opacity: 0.1; } @keyframes k { to { opacity: 0; } } " +
			"@font-face { font-family: F; src: url(f.ttf); } @spritesheet s { src: url(s.png); }", imported);
		CSSParser.Parse("@keyframes own { to { opacity: 1; } }", sheet);
		sheet.PrependImported(imported);
		Test.Assert(sheet.RuleCount == 3);
		Test.Assert(sheet.Rules[0].SelectorText == ".b"); // the import's first
		Test.Assert(sheet.Rules[2].SelectorText == ".b"); // its own after
		Test.Assert(sheet.KeyframesCount == 2);
		Test.Assert(sheet.AllKeyframes[0].Name == "own"); // its own first, the import's after
		Test.Assert(sheet.FindKeyframes("k") != null);
		Test.Assert(sheet.FontFaces.Length == 1);
		Test.Assert(sheet.Spritesheets.Length == 1);
		Test.Assert((imported.RuleCount == 0) && (imported.KeyframesCount == 0)); // taken, not copied

		let b = StyleFixtures.Widget("x");
		defer b.ReleaseRef();
		b.AddClass("b");
		let rs = scope ResolvedStyle();
		sheet.Resolve(b, rs);
		Test.Assert(rs.Get("opacity") == "0.5"); // the importing sheet wins the tie
	}

	[Test]
	public static void SpritesheetsNameRegionsAndASheetsUrlsResolveToThem()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"@spritesheet ui { src: url(\"atlas.png\"); button-normal: 0px 0px 64px 32px; button-hover: 64 0 64 32; short: 1 2 3; } " +
			"@spritesheet nothing { a: 0 0 1 1; } " +
			"button { background-image: url(button-normal); } " +
			"button:hover { background-image: url('button-hover'), url(other.png); } " +
			".x { color: red; }", sheet);
		Test.Assert(sheet.Spritesheets.Length == 1); // one without a source is dropped
		let ui = sheet.Spritesheets[0];
		Test.Assert(ui.Name == "ui");
		Test.Assert(ui.Source == "atlas.png");
		Test.Assert(ui.Sprites.Count == 2); // three numbers are no region
		Test.Assert(ui.Sprites[1].Name == "button-hover");
		Test.Assert(NodeFixtures.Near(ui.Sprites[1].X, 64.0f) && NodeFixtures.Near(ui.Sprites[1].Height, 32.0f));

		sheet.ResolveSprites(sheet.Spritesheets);
		Test.Assert(sheet.Rules[0].Properties[0].Value == "url(atlas.png#xywh=0,0,64,32)");
		Test.Assert(sheet.Rules[1].Properties[0].Value == "url(atlas.png#xywh=64,0,64,32), url(other.png)");
		Test.Assert(sheet.Rules[2].Properties[0].Value == "red");
	}

	[Test]
	public static void TheParserSaysWhereItSkips()
	{
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"a { color: red; }\n" +
			"\n" +
			"  .b:frob,\n" + // line 3: the list's line
			"  .c { color: blue; }\n" +
			"@spritesheet s { src: url(x.png);\n" +
			"  oops; }\n" + // line 6
			"@namespace svg;\n" + // line 7
			"/* a\n comment */ stray", // line 9
			"lines.css", said, sheet);
		Test.Assert(sheet.RuleCount == 3);
		Test.Assert(sheet.Rules[1].Line == 3);
		Test.Assert(sheet.Rules[2].Line == 3);
		uint32 LineOf(StringView part)
		{
			for (let d in said)
			{
				if (d.Message.Contains(part))
					return d.Line;
			}
			return uint32.MaxValue;
		}
		Test.Assert(said.Count == 4);
		Test.Assert(LineOf("the selector .b:frob matches nothing") == 3);
		Test.Assert(LineOf("a declaration with no colon: oops") == 6);
		Test.Assert(LineOf("an at-rule it does not read: @namespace svg") == 7);
		Test.Assert(LineOf("text with no rule block: stray") == 9);

		let open = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(open); }
		let unclosed = scope StyleSheet();
		CSSParser.Parse("a { color: red; }\nd { color: red;", "", open, unclosed);
		Test.Assert(unclosed.RuleCount == 2);
		Test.Assert((open.Count == 1) && (open[0].Line == 2));
		Test.Assert(open[0].Message == "the rule for d is not closed");
		Test.Assert(unclosed.Rules[1].Properties[0].Value == "red");
	}

	[Test]
	public static void StyleCheckKnowsTheTableCustomPropertiesShorthandsAndRegisteredNames()
	{
		let none = scope List<String>();
		Test.Assert(IsKnownStyleName("--accent", "#fff", none));
		Test.Assert(!IsKnownStyleName("--", "x", none)); // no name after the dashes
		Test.Assert(IsKnownStyleName("color", "red", none));
		Test.Assert(IsKnownStyleName("border", "1px solid red", none));
		Test.Assert(IsKnownStyleName("margin", "4px", none));
		Test.Assert(!IsKnownStyleName("colour", "red", none));
		Test.Assert(!IsKnownStyleName("needle-width", "2", none));
		let names = scope List<String>();
		names.Add("needle-width");
		Test.Assert(IsKnownStyleName("needle-width", "2", names));

		Test.Assert(ElementTypes.Register(SheetGauge.StaticGuiType));
		defer ElementTypes.Unregister(SheetGauge.StaticGuiType);
		let registered = scope List<String>();
		defer { ClearAndDeleteItems!(registered); }
		RegisteredCssNames(registered);
		Test.Assert(registered.ContainsAlt("needle-width")); // its own
		Test.Assert(registered.ContainsAlt("nav-up")); // a base's (Node's)
		int navUps = 0;
		for (let n in registered)
		{
			if (n == "nav-up")
				navUps++;
		}
		Test.Assert(navUps == 1); // each once

		let sheet = scope StyleSheet();
		CSSParser.Parse(
			".a { colour: red; color: red; --accent: #fff; margin: 4px; }\n" +
			"sheet-gauge { needle-width: 2; nav-up: #b; }\n" +
			"@keyframes k { from { opactiy: 0; animation-timing-function: ease; } to { opacity: 1; } }", sheet);
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		CheckStyleSheetNames(sheet, said);
		Test.Assert(said.Count == 2);
		Test.Assert(said[0].Message == ".a sets 'colour', which no style or element takes");
		Test.Assert(said[0].Line == 1);
		Test.Assert(said[1].Message == "@keyframes k sets 'opactiy', which no style takes");
		Test.Assert(said[1].Line == 0);
		Test.Assert(!StyleFixtures.Says(said, "needle-width"));
		Test.Assert(!StyleFixtures.Says(said, "nav-up"));
	}

	[Test]
	public static void CopiesAreDeep()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("@import url(x.css); a:not(.b) { color: red; } @keyframes k { to { opacity: 0; } } @font-face { font-family: F; src: url(f.ttf); }",
			"one.css", sheet);
		let copy = scope StyleSheet();
		copy.Set(sheet);
		Test.Assert(copy.Name == "one.css");
		Test.Assert((copy.RuleCount == 1) && (copy.KeyframesCount == 1) && (copy.FontFaces.Length == 1) && (copy.Imports.Length == 1));
		Test.Assert(copy.Rules[0] !== sheet.Rules[0]);
		Test.Assert(copy.Rules[0].Specificity == sheet.Rules[0].Specificity);
		sheet.Rules[0].SetProperty("color", "blue");
		Test.Assert(copy.Rules[0].Properties[0].Value == "red");
		let a = StyleFixtures.Widget("a");
		defer a.ReleaseRef();
		Test.Assert(copy.Rules[0].Selector.Select(a));
		a.AddClass("b");
		Test.Assert(!copy.Rules[0].Selector.Select(a)); // its nested selector came too
		Test.Assert(copy.MutableRule(copy.Rules[0]) === copy.Rules[0]);
		Test.Assert(copy.MutableRule(sheet.Rules[0]) == null);
	}
}
