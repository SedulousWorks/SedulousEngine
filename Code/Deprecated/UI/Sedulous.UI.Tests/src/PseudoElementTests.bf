using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Pseudo elements: the `::thumb` parts of a compound control, which a sheet styles without the
/// control exposing a sub view for each.
class PseudoElementTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static Color Rgb(float r, float g, float b, float a = 255.0f) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	private static StyleSheet SetupSheet(UIContext context)
	{
		let sheet = new StyleSheet();
		context.SetStyleSheet(sheet);
		return sheet;
	}

	private static void EnsureGlobals()
	{
		StyleSheetLoader.InitializeGlobals();
		UITypeRegistry.Register("View", typeof(View));
		UITypeRegistry.Register("TestView", typeof(TestView));
		UITypeRegistry.Register("TestGroup", typeof(TestGroup));
	}

	/// OWNERSHIP of the sheet transfers.
	private static StyleSheet LoadSSS(StringView source)
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		return loader.Load(source);
	}

	// ---- Selector matching ------------------------------------------------------------------

	/// A pseudo element selector matches ONLY its own part, and only when a part is being
	/// asked about at all.
	[Test]
	public static void APseudoElementSelectorMatchesItsOwnPartAlone()
	{
		let selector = scope StyleSelector();
		selector.ViewType = typeof(TestView);
		selector.SetPseudoElement("thumb");

		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(selector.Matches(view, .Normal, "thumb"));
		Test.Assert(!selector.Matches(view, .Normal, "track"), "a different part");
		Test.Assert(!selector.Matches(view, .Normal), "no part asked about at all");
	}

	/// And the converse: an ELEMENT selector must not answer a part query, or every control
	/// would paint its parts with its own background.
	[Test]
	public static void AnElementSelectorRejectsAPartQuery()
	{
		let selector = scope StyleSelector();
		selector.ViewType = typeof(TestView);

		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(selector.Matches(view, .Normal), "the element level match");
		Test.Assert(!selector.Matches(view, .Normal, "thumb"));
	}

	[Test]
	public static void APartSelectorCanAlsoCarryAState()
	{
		let selector = scope StyleSelector();
		selector.ViewType = typeof(TestView);
		selector.SetPseudoElement("thumb");
		selector.State = ControlState.Hover;

		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(selector.Matches(view, .Hover, "thumb"));
		Test.Assert(!selector.Matches(view, .Normal, "thumb"), "the wrong state");
		Test.Assert(!selector.Matches(view, .Hover, "track"), "the wrong part");
	}

	/// A pseudo ELEMENT weighs one, like a type, where a pseudo CLASS weighs ten like a class.
	/// That is CSS's split, and it is what keeps `::thumb` from outweighing a class.
	[Test]
	public static void APseudoElementWeighsOneLikeAType()
	{
		let typeAndPart = scope StyleSelector();
		typeAndPart.ViewType = typeof(TestView);
		typeAndPart.SetPseudoElement("thumb");
		Test.Assert(typeAndPart.Specificity == 2, "type plus pseudo element");

		let everything = scope StyleSelector();
		everything.ViewType = typeof(TestView);
		everything.AddClass("primary");
		everything.State = ControlState.Hover;
		everything.SetPseudoElement("thumb");
		Test.Assert(everything.Specificity == 22, "1 type, 10 class, 10 pseudo class, 1 element");
	}

	// ---- Resolution -------------------------------------------------------------------------

	/// Parts resolve independently of each other AND of the element, so a rule on `::thumb`
	/// leaves the view's own width alone.
	[Test]
	public static void PartsResolveSeparatelyFromEachOtherAndFromTheElement()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForTypePseudo(typeof(TestView), "thumb").Set(.Width, 12.0f).Set(.Height, 12.0f);
		sheet.ForTypePseudo(typeof(TestView), "track").Set(.Height, 4.0f);

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(Near(view.ResolvePartFloat("thumb", .Width, .Normal), 12.0f));
		Test.Assert(Near(view.ResolvePartFloat("track", .Height, .Normal), 4.0f));
		Test.Assert(view.ResolveStyleFloat(.Width) == 0, "the element itself was not styled");
	}

	[Test]
	public static void APartRuleWithAStateWinsInThatState()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);

		let normalBackground = new ColorDrawable(Rgb(100, 100, 100));
		let hoverBackground = new ColorDrawable(Rgb(200, 200, 200));
		sheet.OwnDrawable(normalBackground);
		sheet.OwnDrawable(hoverBackground);

		sheet.ForTypePseudo(typeof(TestView), "thumb").Set(.Background, normalBackground);
		sheet.ForTypePseudoState(typeof(TestView), "thumb", .Hover)
			.Set(.Background, hoverBackground);

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(view.ResolvePartDrawable("thumb", .Background, .Normal) == normalBackground);
		Test.Assert(view.ResolvePartDrawable("thumb", .Background, .Hover) == hoverBackground);
	}

	/// Specificity applies within a part exactly as it does at element level.
	[Test]
	public static void PartRulesCascadeBySpecificity()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForTypePseudo(typeof(TestView), "thumb").Set(.Width, 12.0f);
		sheet.ForTypePseudoState(typeof(TestView), "thumb", .Hover).Set(.Width, 16.0f);

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(view.ResolvePartFloat("thumb", .Width, .Normal) == 12.0f);
		Test.Assert(view.ResolvePartFloat("thumb", .Width, .Hover) == 16.0f);
	}

	/// Part rules do NOT inherit down the tree. A scroll bar's thumb styling must not reach the
	/// thumbs of every scroll bar nested inside it.
	[Test]
	public static void PartRulesDoNotInherit()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForTypePseudo(typeof(ViewGroup), "thumb")
			.Set(.Background, sheet.OwnColor(Rgb(100, 100, 100)));

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView(50, 30);
		group.AddView(child);

		Test.Assert(child.ResolvePartDrawable("thumb", .Background, .Normal) == null);
	}

	[Test]
	public static void APartRuleOnABaseTypeReachesItsSubtypes()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForTypePseudo(typeof(View), "thumb").Set(.Width, 16.0f);

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(Near(view.ResolvePartFloat("thumb", .Width, .Normal), 16.0f));
	}

	[Test]
	public static void APartRuleCanBeScopedByClass()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);

		let rule = new StyleRule();
		rule.Selector.AddClass("custom");
		rule.Selector.SetPseudoElement("track");
		rule.Set(.Height, 8.0f);
		sheet.AddRule(rule);

		let classed = new TestView(50, 30);
		classed.AddClass("custom");
		root.AddView(classed);
		let plain = new TestView(50, 30);
		root.AddView(plain);

		Test.Assert(Near(classed.ResolvePartFloat("track", .Height, .Normal), 8.0f));
		Test.Assert(plain.ResolvePartFloat("track", .Height, .Normal) == 0, "no class, no match");
	}

	/// The other direction of the same rule: an element level declaration must not leak into a
	/// part query.
	[Test]
	public static void AnElementRuleDoesNotAnswerAPartQuery()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForType(typeof(TestView)).Set(.Background, sheet.OwnColor(Rgb(255, 0, 0)));

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(view.ResolveStyleDrawable(.Background) != null, "the element has one");
		Test.Assert(view.ResolvePartDrawable("thumb", .Background, .Normal) == null);
	}

	// ---- The SSS syntax ---------------------------------------------------------------------

	[Test]
	public static void TheDoubleColonSyntaxParsesIntoPartRules()
	{
		let sheet = LoadSSS("""
			View::thumb { width: 12; height: 12; }
			View::track { height: 4; }
			""");

		Test.Assert(sheet.RuleCount == 2);

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(sheet);

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(Near(view.ResolvePartFloat("thumb", .Width, .Normal), 12.0f));
		Test.Assert(Near(view.ResolvePartFloat("track", .Height, .Normal), 4.0f));
	}

	/// A part and a state can be written in EITHER order, which matters because CSS itself
	/// allows both and a theme author will write whichever reads better.
	[Test]
	public static void APartAndAStateParseInEitherOrder()
	{
		let stateAfter = LoadSSS("""
			View::thumb { background: color(#666666); }
			View::thumb:hover { background: color(#999999); }
			""");
		defer stateAfter.ReleaseRef();

		Test.Assert(stateAfter.RuleCount == 2);
		let hovered = stateAfter.GetRule(1);
		Test.Assert(hovered.Selector.PseudoElement == "thumb");
		Test.Assert(hovered.Selector.State != null);
		Test.Assert(hovered.Selector.State.Value.HasFlag(.Hover));

		let stateBefore = LoadSSS("View:disabled::thumb { background: color(#333333); }");
		defer stateBefore.ReleaseRef();

		Test.Assert(stateBefore.RuleCount == 1);
		let disabled = stateBefore.GetRule(0);
		Test.Assert(disabled.Selector.PseudoElement == "thumb");
		Test.Assert(disabled.Selector.State != null);
		Test.Assert(disabled.Selector.State.Value.HasFlag(.Disabled));
	}

	[Test]
	public static void APartRuleCarriesAFullDrawableValue()
	{
		let sheet = LoadSSS("View::thumb { background: rounded-rect(#aabbcc, radius=6); }");

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(sheet);

		let view = new TestView(50, 30);
		root.AddView(view);

		let background = view.ResolvePartDrawable("thumb", .Background, .Normal);
		Test.Assert(background != null);
		Test.Assert(background is RoundedRectDrawable);
	}

	[Test]
	public static void APartRuleResolvesAPaletteVariable()
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		loader.SetPaletteVariable("accent", Rgb(61, 174, 233));

		let sheet = loader.Load("View::fill { background: color($accent); }");

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(sheet);

		let view = new TestView(50, 30);
		root.AddView(view);

		let background = view.ResolvePartDrawable("fill", .Background, .Normal);
		Test.Assert(background != null);
		let colour = background as ColorDrawable;
		Test.Assert(colour != null);
		Test.Assert(Near(colour.Color.R, 61 / 255.0f));
	}
}
