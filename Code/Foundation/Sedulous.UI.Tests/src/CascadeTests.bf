using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Style model v2 P1: the ordered cascade by specificity and source order, selector chains,
/// structural pseudo classes, inheritance with the `inherit` and `initial` keywords, custom
/// properties and var(), relative units, and the computed style cache's invalidation.
class CascadeTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static void EnsureGlobals()
	{
		StyleSheetLoader.InitializeGlobals();
		UITypeRegistry.Register("View", typeof(View));
		UITypeRegistry.Register("RootView", typeof(RootView));
		UITypeRegistry.Register("TestView", typeof(TestView));
		UITypeRegistry.Register("TestGroup", typeof(TestGroup));
		UITypeRegistry.Register("StateView", typeof(StateView));
	}

	/// OWNERSHIP of the sheet transfers to the caller.
	private static StyleSheet LoadSSS(StringView source)
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		return loader.Load(source);
	}

	/// A context and root with a sheet installed, plus builders for nested groups and leaves.
	private class Fixture
	{
		public UIContext Context = new .() ~ delete _;
		public RootView Root = new .() ~ _.ReleaseRef();

		/// CONSUMES the sheet's reference.
		public this(StyleSheet sheet)
		{
			EnsureGlobals();
			UITest.Init(Context, Root);
			Context.SetStyleSheet(sheet);
		}

		public TestGroup Group(ViewGroup parent, StringView styleClass = default,
			StringView name = default)
		{
			let group = new TestGroup();
			if (!styleClass.IsEmpty)
				group.AddClass(styleClass);
			if (!name.IsEmpty)
				group.Name.Set(name);
			parent.AddView(group);
			return group;
		}

		public TestView Leaf(ViewGroup parent, StringView styleClass = default,
			StringView name = default)
		{
			let view = new TestView(50.0f, 30.0f);
			if (!styleClass.IsEmpty)
				view.AddClass(styleClass);
			if (!name.IsEmpty)
				view.Name.Set(name);
			parent.AddView(view);
			return view;
		}
	}

	/// A colour no rule would produce, so an UNSET property is distinguishable from one set to
	/// the default white, whose channels would all read as one.
	private static Color cUnset = .(-1.0f, -1.0f, -1.0f, 0.0f);

	private static float Red(View view) => view.ResolveStyleColor(.TextColor, cUnset).R;
	private static float Green(View view) => view.ResolveStyleColor(.TextColor, cUnset).G;
	private static float Blue(View view) => view.ResolveStyleColor(.TextColor, cUnset).B;

	// ---- Cascade order ----------------------------------------------------------------------

	/// Type loses to class loses to id, whatever order they were DECLARED in.
	[Test]
	public static void ThreeCompetingRulesResolveBySpecificity()
	{
		let fixture = scope Fixture(LoadSSS("""
			#pick { text-color: #0000ff; }
			TestView { text-color: #ff0000; }
			.accent { text-color: #00ff00; }
			"""));

		let plain = fixture.Leaf(fixture.Root);
		let classed = fixture.Leaf(fixture.Root, "accent");
		let named = fixture.Leaf(fixture.Root, "accent", "pick");

		Test.Assert(Near(Red(plain), 1.0f));
		Test.Assert(Near(Green(classed), 1.0f));
		Test.Assert(Near(Blue(named), 1.0f), "the id rule wins although it was declared first");
	}

	/// Source order breaks a specificity tie, and it does so PER PROPERTY: the later rule wins
	/// the colour without taking the font size the earlier one alone declared.
	[Test]
	public static void EqualSpecificityResolvesByOrderPerProperty()
	{
		let fixture = scope Fixture(LoadSSS("""
			.a { text-color: #ff0000; font-size: 11; }
			.a { text-color: #00ff00; }
			"""));

		let view = fixture.Leaf(fixture.Root, "a");

		Test.Assert(Near(Green(view), 1.0f), "the later rule wins the colour");
		Test.Assert(Near(view.ResolveStyleFloat(.FontSize), 11.0f), "the earlier keeps its own");
	}

	/// A pseudo class weighs the same as a class, so these two tie and order decides.
	[Test]
	public static void APseudoClassWeighsLikeAClass()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView:hover { text-color: #ff0000; }
			TestView.primary { text-color: #00ff00; }
			"""));

		let view = fixture.Leaf(fixture.Root, "primary");

		Test.Assert(Near(Green(view), 1.0f), "declared later at equal specificity");
	}

	// ---- Selector chains --------------------------------------------------------------------

	/// A descendant combinator matches at ANY depth; a child combinator only the direct parent.
	[Test]
	public static void DescendantMatchesAtAnyDepthAndChildOnlyTheDirectParent()
	{
		let fixture = scope Fixture(LoadSSS("""
			.panel TestView { text-color: #ff0000; }
			.panel > TestView { font-size: 42; }
			"""));

		let panel = fixture.Group(fixture.Root, "panel");
		let inner = fixture.Group(panel);
		let direct = fixture.Leaf(panel);
		let deep = fixture.Leaf(inner);
		let outside = fixture.Leaf(fixture.Root);

		Test.Assert(Near(Red(direct), 1.0f));
		Test.Assert(Near(Red(deep), 1.0f), "a descendant at two levels still matches");
		Test.Assert(Near(Red(outside), -1.0f), "outside the panel entirely");
		Test.Assert(Near(direct.ResolveStyleFloat(.FontSize), 42.0f));
		Test.Assert(Near(deep.ResolveStyleFloat(.FontSize), 0.0f), "not a direct child");
	}

	/// A chain has to BACKTRACK: the .b must be the direct parent and the .a any ancestor above
	/// it, so a match cannot be decided by walking up once per part.
	[Test]
	public static void AMixedChainBacktracksOverAncestors()
	{
		let fixture = scope Fixture(LoadSSS(".a .b > TestView { text-color: #ff0000; }"));

		let a = fixture.Group(fixture.Root, "a");
		let mid = fixture.Group(a);
		let b = fixture.Group(mid, "b");
		let hit = fixture.Leaf(b);
		let deeper = fixture.Group(b);
		let miss = fixture.Leaf(deeper);

		Test.Assert(Near(Red(hit), 1.0f));
		Test.Assert(Near(Red(miss), -1.0f), "here .b is a grandparent, not the parent");
	}

	[Test]
	public static void IdAndTheStructuralPseudoClassesMatchPosition()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView:first-child { text-color: #ff0000; }
			TestView:last-child { font-size: 7; }
			TestGroup:empty { corner-radius: 3; }
			#solo { border-width: 9; }
			"""));

		let group = fixture.Group(fixture.Root);
		let first = fixture.Leaf(group);
		let middle = fixture.Leaf(group, default, "solo");
		let last = fixture.Leaf(group);
		let emptyGroup = fixture.Group(fixture.Root);

		Test.Assert(Near(Red(first), 1.0f));
		Test.Assert(Near(Red(middle), -1.0f));
		Test.Assert(Near(last.ResolveStyleFloat(.FontSize), 7.0f));
		Test.Assert(Near(first.ResolveStyleFloat(.FontSize), 0.0f));
		Test.Assert(Near(emptyGroup.ResolveStyleFloat(.CornerRadius), 3.0f));
		Test.Assert(Near(group.ResolveStyleFloat(.CornerRadius), 0.0f), "it has children");
		Test.Assert(Near(middle.ResolveStyleFloat(.BorderWidth), 9.0f));
	}

	/// The CSS state names are ALIASES for the control states, and combining two adds their
	/// specificity like any two pseudo classes.
	[Test]
	public static void TheCssStateAliasesParseToControlStates()
	{
		let sheet = LoadSSS("""
			TestView:active { font-size: 1; }
			TestView:focus { font-size: 2; }
			TestView:focus-visible:hover { font-size: 3; }
			""");
		defer sheet.ReleaseRef();

		Test.Assert(sheet.RuleCount == 3);
		Test.Assert(sheet.GetRule(0).Selector.State.Value == ControlState.Pressed);
		Test.Assert(sheet.GetRule(1).Selector.State.Value == ControlState.Focused);
		Test.Assert(sheet.GetRule(2).Selector.State.Value
			== (ControlState.Focused | ControlState.Hover));
		Test.Assert(sheet.GetRule(2).Selector.Specificity == 21);
	}

	/// An unknown type name matches NOTHING rather than everything, and crucially it does not
	/// swallow the declarations of the rules around it.
	[Test]
	public static void AnUnknownTypeNameMatchesNothing()
	{
		let fixture = scope Fixture(LoadSSS("""
			NoSuchControl { text-color: #ff0000; }
			TestView { font-size: 5; }
			"""));

		let view = fixture.Leaf(fixture.Root);

		Test.Assert(Near(Red(view), -1.0f));
		Test.Assert(Near(view.ResolveStyleFloat(.FontSize), 5.0f));
	}

	// ---- Inheritance ------------------------------------------------------------------------

	/// Text properties inherit the parent's COMPUTED value, and go on doing so through as many
	/// levels as there are. A property that is not inheritable does not walk up at all.
	[Test]
	public static void TextPropertiesInheritThroughThreeLevels()
	{
		let fixture = scope Fixture(
			LoadSSS(".top { text-color: #ff0000; font-size: 13; word-wrap: true; }"));

		let top = fixture.Group(fixture.Root, "top");
		let mid = fixture.Group(top);
		let leaf = fixture.Leaf(mid);

		Test.Assert(Near(Red(leaf), 1.0f));
		Test.Assert(Near(leaf.ResolveStyleFloat(.FontSize), 13.0f));
		Test.Assert(leaf.ResolveStyle(.WordWrap).AsBool.Value == true);
		Test.Assert(Near(leaf.ResolveStyleFloat(.CornerRadius, -1.0f), -1.0f),
			"corner radius is not inheritable");
	}

	/// `inherit` takes the parent's value even for a property that would not inherit on its own;
	/// `initial` unsets, so not even an inheritable property comes through.
	[Test]
	public static void InheritTakesTheParentsValueAndInitialUnsets()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestGroup { corner-radius: 6; text-color: #00ff00; }
			TestView { corner-radius: inherit; text-color: initial; }
			"""));

		let group = fixture.Group(fixture.Root);
		let leaf = fixture.Leaf(group);

		Test.Assert(Near(leaf.ResolveStyleFloat(.CornerRadius), 6.0f));
		Test.Assert(leaf.ResolveStyle(.TextColor).IsNone, "initial: not even inherited");
	}

	// ---- Custom properties and var() --------------------------------------------------------

	[Test]
	public static void VarReadsACustomPropertyWithAFallbackWhenUnset()
	{
		let fixture = scope Fixture(LoadSSS("""
			View { --accent: #ff0000; --ring-angle: 45; }
			TestView { text-color: var(--accent); border-color: var(--missing, #0000ff); font-size: var(--ring-angle); corner-radius: var(--nope); }
			"""));

		let view = fixture.Leaf(fixture.Root);

		Test.Assert(Near(Red(view), 1.0f));
		Test.Assert(Near(view.ResolveStyleColor(.BorderColor).B, 1.0f), "the fallback");
		Test.Assert(Near(view.ResolveStyleFloat(.FontSize), 45.0f));
		Test.Assert(Near(view.ResolveStyleFloat(.CornerRadius, -1.0f), -1.0f),
			"unset and no fallback leaves the property alone");
		Test.Assert(Near(view.CustomProperty("--ring-angle").AsFloat.Value, 45.0f));
		Test.Assert(view.CustomProperty("--nope").IsNone);
	}

	/// Custom properties inherit, and a nearer declaration overrides for its subtree.
	[Test]
	public static void CustomPropertiesInheritAndTheNearerDeclarationWins()
	{
		// Declared on the ROOT rather than on View: a `View { --accent }` rule would re-declare
		// it on every view and shadow any ancestor's, the same trap as CSS `* { --x }`.
		let fixture = scope Fixture(LoadSSS("""
			RootView { --accent: #ff0000; }
			.dark { --accent: #0000ff; }
			TestView { text-color: var(--accent); }
			"""));

		let light = fixture.Group(fixture.Root);
		let dark = fixture.Group(fixture.Root, "dark");
		let inner = fixture.Group(dark);
		let a = fixture.Leaf(light);
		let b = fixture.Leaf(inner);

		Test.Assert(Near(Red(a), 1.0f));
		Test.Assert(Near(Blue(b), 1.0f), "the .dark ancestor's value wins for its subtree");
	}

	/// The loader's palette is nothing special: it becomes a root rule of variables, which is
	/// why a palette entry and a declared custom property behave identically.
	[Test]
	public static void ThePaletteIsARootRuleOfVariables()
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		loader.SetPaletteVariable("primary", Color(0.0f, 1.0f, 0.0f, 1.0f));

		let fixture = scope Fixture(loader.Load("""
			@palette p { accent: #0000ff; }
			TestView { text-color: var(--primary); border-color: var(--accent); }
			"""));

		let view = fixture.Leaf(fixture.Root);

		Test.Assert(Near(Green(view), 1.0f));
		Test.Assert(Near(view.ResolveStyleColor(.BorderColor).B, 1.0f));
		Test.Assert(Near(view.CustomProperty("--primary").AsColor.Value.G, 1.0f));
	}

	[Test]
	public static void AVarChainResolvesThroughReferencesAndNestedFallbacks()
	{
		let fixture = scope Fixture(LoadSSS("""
			View { --base: #ff0000; --alias: var(--base); }
			TestView { text-color: var(--alias); border-color: var(--x, var(--y, #00ff00)); }
			"""));

		let view = fixture.Leaf(fixture.Root);

		Test.Assert(Near(Red(view), 1.0f), "through the alias to the base");
		Test.Assert(Near(view.ResolveStyleColor(.BorderColor).G, 1.0f), "the nested fallback");
	}

	// ---- Relative units ---------------------------------------------------------------------

	[Test]
	public static void PercentAndEmResolveAgainstTheBoxAndTheFontSize()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestGroup { font-size: 20; }
			TestView { corner-radius: 50%; border-width: 2em; font-size: 1.5em; spacing: calc(100% - 20dp); padding: 4; }
			"""));

		let group = fixture.Group(fixture.Root);
		let view = fixture.Leaf(group);

		Test.Assert(Near(view.ResolveStyleLength(.CornerRadius, 80.0f), 40.0f));
		// em is of the view's OWN font size: thirty, being 1.5em of the parent's twenty.
		Test.Assert(Near(view.ResolveStyleLength(.FontSize, 0.0f), 30.0f));
		Test.Assert(Near(view.ResolveStyleLength(.BorderWidth, 0.0f), 60.0f));
		Test.Assert(Near(view.ResolveStyleLength(.Spacing, 300.0f), 280.0f));

		// The plain float accessor resolves a length too, but it has no reference box, so em
		// works and a percentage reads as nought rather than guessing one.
		Test.Assert(Near(view.ResolveStyleFloat(.CornerRadius, -1.0f), 0.0f));
		Test.Assert(Near(view.ResolveStyleFloat(.BorderWidth, -1.0f), 60.0f));
		Test.Assert(Near(view.ResolveStyleThickness(.Padding).Left, 4.0f));
	}

	/// A Unit is a SUM of components, not a tagged value, which is what makes calc() an ordinary
	/// value rather than an expression tree.
	[Test]
	public static void CalcSumsComponentsAndTheRelativeOnesNeedTheFullResolve()
	{
		let sum = Unit.Percent(100.0f) - Unit.Dp(20.0f) + Unit.Em(1.0f);

		Test.Assert(sum.IsRelative);
		Test.Assert(Near(sum.Resolve(1.0f), -20.0f), "the absolute part alone");
		Test.Assert(Near(sum.Resolve(1.0f, 300.0f, 16.0f), 296.0f));
		Test.Assert(!Unit.Dp(5.0f).IsRelative);
		Test.Assert(Near(Unit.Px(50.0f).Resolve(2.0f, 100.0f, 16.0f), 25.0f));
	}

	[Test]
	public static void ParseLengthTextReadsTheSuffixesAndRejectsNonsense()
	{
		Test.Assert(StyleValueParser.ParseLengthText("50%").Value == Unit.Percent(50.0f));
		Test.Assert(StyleValueParser.ParseLengthText("2em").Value == Unit.Em(2.0f));
		Test.Assert(StyleValueParser.ParseLengthText("12px").Value == Unit.Px(12.0f));
		Test.Assert(StyleValueParser.ParseLengthText("calc(100% - 20dp)").Value
			== (Unit.Percent(100.0f) - Unit.Dp(20.0f)));
		Test.Assert(StyleValueParser.ParseLengthText("wide") == null);
		Test.Assert(StyleValueParser.ParseLengthText("12furlongs") == null);
		Test.Assert(Near(SizeSpec.Fixed(Unit.Percent(25.0f)).ResolveFixed(1.0f, 200.0f, 16.0f),
			50.0f));
	}

	// ---- The computed style cache -----------------------------------------------------------

	/// The cache has to follow every input that can change what matches: the view's classes,
	/// the sheet's contents, sibling ORDER, a local sheet appearing, and an inline style.
	[Test]
	public static void TheComputedStyleCacheFollowsEveryInput()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView { text-color: #ff0000; }
			.on { text-color: #00ff00; }
			TestView:first-child { font-size: 9; }
			"""));

		let group = fixture.Group(fixture.Root);
		let a = fixture.Leaf(group);
		let b = fixture.Leaf(group);

		Test.Assert(Near(Red(a), 1.0f));
		a.AddClass("on");
		Test.Assert(Near(Green(a), 1.0f), "a class edit");
		a.RemoveClass("on");
		Test.Assert(Near(Red(a), 1.0f));

		// A rule added to the context sheet AFTER the first resolve is seen.
		fixture.Context.GetStyleSheet().ForType(typeof(TestView))
			.Set(.TextColor, Color(0.0f, 0.0f, 1.0f, 1.0f));
		Test.Assert(Near(Blue(a), 1.0f), "a sheet edit");

		// Reordering the children moves which one :first-child matches.
		Test.Assert(Near(a.ResolveStyleFloat(.FontSize), 9.0f));
		Test.Assert(Near(b.ResolveStyleFloat(.FontSize), 0.0f));
		group.MoveView(b, 0);
		Test.Assert(Near(b.ResolveStyleFloat(.FontSize), 9.0f), "a reorder");
		Test.Assert(Near(a.ResolveStyleFloat(.FontSize), 0.0f));

		// A local sheet set later wins over the context sheet.
		let local = new StyleSheet();
		local.ForType(typeof(TestView)).Set(.TextColor, Color(0.5f, 0.5f, 0.5f, 1.0f));
		group.SetLocalStyleSheet(local);
		Test.Assert(Near(Red(a), 0.5f), "a local sheet");

		// And an inline style beats both.
		SSSParser.ApplyInlineStyle(a, "text-color: #00ff00;");
		Test.Assert(Near(Green(a), 1.0f), "inline");
	}

	/// Two contexts are INDEPENDENT: an editor hosting an embedded game must not have the
	/// game's sheet edits reach its own views, and the cache keys are per sheet, so the
	/// editor's cache is not even rebuilt.
	[Test]
	public static void TwoContextsWithDifferentSheetsStayIndependent()
	{
		EnsureGlobals();
		let editor = scope UIContext();
		let game = scope UIContext();
		let editorRoot = new RootView();
		defer editorRoot.ReleaseRef();
		let gameRoot = new RootView();
		defer gameRoot.ReleaseRef();
		UITest.Init(editor, editorRoot);
		UITest.Init(game, gameRoot);

		editor.SetStyleSheet(
			LoadSSS("RootView { --accent: #ff0000; } TestView { text-color: var(--accent); }"));
		game.SetStyleSheet(
			LoadSSS("RootView { --accent: #0000ff; } TestView { text-color: var(--accent); }"));

		let e = new TestView(10.0f, 10.0f);
		let g = new TestView(10.0f, 10.0f);
		let g2 = new TestView(10.0f, 10.0f);
		editorRoot.AddView(e);
		gameRoot.AddView(g);
		gameRoot.AddView(g2);

		Test.Assert(Near(Red(e), 1.0f));
		Test.Assert(Near(Blue(g), 1.0f));

		// Editing the game's sheet, or one game view's inline style, changes nothing in the
		// editor and nothing on the sibling.
		let editorSheetVersion = editor.GetStyleSheet().Version;
		game.GetStyleSheet().ForType(typeof(TestView))
			.Set(.TextColor, Color(0.0f, 1.0f, 0.0f, 1.0f));
		SSSParser.ApplyInlineStyle(g, "text-color: #ffffff;");

		Test.Assert(Near(Green(g2), 1.0f), "the sibling followed the game's sheet");
		Test.Assert(Near(Red(g), 1.0f), "and g is inline white");
		Test.Assert(Near(Green(g), 1.0f));
		Test.Assert(Near(Red(e), 1.0f), "the editor is untouched");
		Test.Assert(Near(Green(e), 0.0f));
		Test.Assert(editor.GetStyleSheet().Version == editorSheetVersion,
			"the editor's chain holds no game sheet, so nothing invalidated it");
	}
	/// A compound state selector is a CONJUNCTION: `:hover:checked` describes a view that is
	/// both, and the match used to fire on either bit alone.
	[Test]
	public static void ACompoundStateSelectorNeedsEveryFlag()
	{
		let fixture = scope Fixture(LoadSSS("""
			StateView { text-color: #000000; }
			StateView:hover:checked { text-color: #ff0000; }
			"""));

		let view = new StateView();
		fixture.Root.AddView(view);

		view.State = .Hover;
		Test.Assert(Near(Red(view), 0.0f), "hovered alone is not the compound");
		view.State = .Checked;
		Test.Assert(Near(Red(view), 0.0f), "checked alone is not either");

		view.State = ControlState.Hover | ControlState.Checked;
		Test.Assert(Near(Red(view), 1.0f), "both is");

		view.State = ControlState.Hover | ControlState.Checked | ControlState.Focused;
		Test.Assert(Near(Red(view), 1.0f), "and an extra flag does not disqualify it");
	}

}
