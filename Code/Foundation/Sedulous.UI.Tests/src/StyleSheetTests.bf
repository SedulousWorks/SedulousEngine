using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The style sheet as data: StyleValue's accessors, StyleRule's fluent setters and string
/// lifetime, selector specificity, the palette's derived colours, and the whole thing resolving
/// over a real view tree.
class StyleSheetTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static Color Rgb(float r, float g, float b, float a = 255.0f) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);

	/// A sheet OWNED by the context; the returned pointer is borrowed, for adding rules.
	private static StyleSheet SetupSheet(UIContext context)
	{
		let sheet = new StyleSheet();
		context.SetStyleSheet(sheet);
		return sheet;
	}

	// ---- StyleValue -------------------------------------------------------------------------

	/// The accessors are DISCRIMINATING: a colour does not read back as a float, which is what
	/// makes the payload enum safer than the tagged struct it replaced.
	[Test]
	public static void TheAccessorsAnswerOnlyForTheirOwnCase()
	{
		let colour = StyleValue.Color(Color.Red);
		Test.Assert(colour.AsColor != null);
		Test.Assert(colour.AsFloat == null);
		Test.Assert(colour.AsDrawable == null);

		let number = StyleValue.Float(42.0f);
		Test.Assert(number.AsFloat != null);
		Test.Assert(number.AsColor == null);
	}

	[Test]
	public static void NoneAnswersForNothing()
	{
		let value = StyleValue.None;

		Test.Assert(value.AsColor == null);
		Test.Assert(value.AsFloat == null);
		Test.Assert(value.AsThickness == null);
		Test.Assert(value.AsDrawable == null);
		Test.Assert(value.AsBool == null);
	}

	// ---- StyleRule --------------------------------------------------------------------------

	[Test]
	public static void SettersChainAndOnlyTheSetPropertiesAnswer()
	{
		let rule = new StyleRule();
		defer rule.ReleaseRef();
		rule.Set(.TextColor, Color.Red)
			.Set(.FontSize, 16.0f)
			.Set(.Padding, Thickness(4.0f));

		Test.Assert(rule.PropertyCount == 3);
		Test.Assert(rule.GetValue(.TextColor) != null);
		Test.Assert(rule.GetValue(.FontSize) != null);
		Test.Assert(rule.GetValue(.Padding) != null);
		Test.Assert(rule.GetValue(.Background) == null);
	}

	[Test]
	public static void AStringValueRoundTrips()
	{
		let rule = new StyleRule();
		defer rule.ReleaseRef();
		rule.Set(.FontFamily, "Roboto");

		let value = rule.GetValue(.FontFamily);
		Test.Assert(value != null);
		Test.Assert(value.Value.AsString != null);
		Test.Assert(value.Value.AsString.Value == "Roboto");
	}

	/// A string value is OWNED by the rule, so overwriting one has to free the old text rather
	/// than leak it, and the property count must not grow.
	[Test]
	public static void OverwritingAStringValueReplacesRatherThanAccumulates()
	{
		let rule = new StyleRule();
		defer rule.ReleaseRef();
		rule.Set(.FontFamily, "Roboto");
		rule.Set(.FontFamily, "JungleAdventurer");
		rule.Set(.FontFamily, "AttackOfMonster");

		Test.Assert(rule.GetValue(.FontFamily).Value.AsString.Value == "AttackOfMonster");
		Test.Assert(rule.PropertyCount == 1);
	}

	[Test]
	public static void RemovingAStringValueDropsIt()
	{
		let rule = new StyleRule();
		defer rule.ReleaseRef();
		rule.Set(.FontFamily, "Roboto");

		Test.Assert(rule.Remove(.FontFamily));
		Test.Assert(rule.GetValue(.FontFamily) == null);
	}

	/// Building and dropping many string holding rules: what this pins is that nothing leaks,
	/// which the test runner's own leak check is what actually reports.
	[Test]
	public static void ManyStringHoldingRulesComeAndGoCleanly()
	{
		for (int i < 16)
		{
			let rule = new StyleRule();
			defer rule.ReleaseRef();
			rule.Set(.FontFamily, "Roboto");
			rule.Set(.FontFamily, "JungleAdventurer");
			Test.Assert(rule.GetValue(.FontFamily).Value.AsString.Value == "JungleAdventurer");
		}
	}

	// ---- StyleSelector ----------------------------------------------------------------------

	/// An empty selector matches EVERYTHING at specificity nought, which is what makes a
	/// `ForAll` rule the base layer rather than a special case.
	[Test]
	public static void AnEmptySelectorMatchesAnythingAtZero()
	{
		let selector = scope StyleSelector();
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(selector.Matches(view, .Normal));
		Test.Assert(selector.Matches(view, .Hover));
		Test.Assert(selector.Specificity == 0);
	}

	/// The CSS weights: a type is one, a class is ten, an id is a hundred, and a pseudo class
	/// weighs like a class.
	[Test]
	public static void SpecificityWeighsTypeClassStateAndId()
	{
		let byType = scope StyleSelector();
		byType.ViewType = typeof(TestView);
		Test.Assert(byType.Specificity == 1);

		let byClass = scope StyleSelector();
		byClass.AddClass("primary");
		Test.Assert(byClass.Specificity == 10);

		let byState = scope StyleSelector();
		byState.State = ControlState.Hover;
		Test.Assert(byState.Specificity == 10, "a pseudo class weighs like a class");

		let combined = scope StyleSelector();
		combined.ViewType = typeof(TestView);
		combined.AddClass("primary");
		combined.State = ControlState.Hover;
		Test.Assert(combined.Specificity == 21);

		let byId = scope StyleSelector();
		byId.SetId("ok");
		Test.Assert(byId.Specificity == 100);
	}

	/// Every part of a CHAIN contributes, ancestors included, and a compound state counts once
	/// per flag.
	[Test]
	public static void AChainAddsUpItsAncestorsAndEveryStateFlag()
	{
		// `.panel > TestView.primary:hover:checked`
		let selector = scope StyleSelector();
		selector.ViewType = typeof(TestView);
		selector.AddClass("primary");
		selector.State = ControlState.Hover | ControlState.Checked;

		// AddAncestor takes OWNERSHIP of the compound, so this must not be scoped.
		let panel = new SelectorCompound();
		panel.AddClass("panel");
		selector.AddAncestor(panel, true);

		Test.Assert(selector.Specificity == 1 + 10 + 20 + 10,
			"type, class, two state flags and the ancestor class");
	}

	// ---- Palette ----------------------------------------------------------------------------

	[Test]
	public static void LightenAndDarkenMoveTowardsTheEndsAndKeepTheAlpha()
	{
		let lighter = Palette.Lighten(Rgb(100, 100, 100), 0.5f);
		Test.Assert(lighter.R > 100.0f / 255.0f);
		Test.Assert(lighter.R < 1.0f);
		Test.Assert(lighter.A == 1.0f);

		let darker = Palette.Darken(Rgb(200, 200, 200), 0.5f);
		Test.Assert(darker.R < 200.0f / 255.0f);
		Test.Assert(darker.R > 0.0f);
		Test.Assert(darker.A == 1.0f);
	}

	/// Hover lightens, pressed darkens, disabled fades: the direction is the contract, since
	/// the amounts are a theme's business.
	[Test]
	public static void TheDerivedStateColoursMoveTheRightWay()
	{
		let baseColour = Rgb(60, 60, 60);

		Test.Assert(Palette.ComputeHover(baseColour).R > baseColour.R);
		Test.Assert(Palette.ComputePressed(baseColour).R < baseColour.R);
		Test.Assert(Palette.ComputeDisabled(Rgb(60, 120, 200)).A < 1.0f);
	}

	[Test]
	public static void CreateStateColoursFillsEveryState()
	{
		let states = Palette.CreateStateColors(Rgb(80, 80, 80));
		defer states.ReleaseRef();

		Test.Assert(states.Get(.Normal) != null);
		Test.Assert(states.Get(.Hover) != null);
		Test.Assert(states.Get(.Pressed) != null);
		Test.Assert(states.Get(.Disabled) != null);
		Test.Assert(states.Get(.Focused) != null);
	}

	[Test]
	public static void ForAllProducesAnEmptySelectorRule()
	{
		let sheet = new StyleSheet();
		defer sheet.ReleaseRef();

		let rule = sheet.ForAll();

		Test.Assert(rule.Selector.IsEmpty);
		Test.Assert(rule.Selector.Specificity == 0);
		Test.Assert(sheet.RuleCount == 1);
	}

	// ---- Resolution over a real tree --------------------------------------------------------

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	[Test]
	public static void WithNoSheetEveryLookupFallsBackToItsDefault()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(view.ResolveStyleDrawable(.Background) == null);
		Test.Assert(view.ResolveStyleColor(.TextColor, Color.White) == Color.White);
		Test.Assert(view.ResolveStyleFloat(.FontSize, 14.0f) == 14.0f);
	}

	[Test]
	public static void ATypeRuleMatchesItsTypeAndNotAnother()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForType(typeof(TestView)).Set(.TextColor, Rgb(255, 0, 0));
		sheet.ForType(typeof(TestGroup)).Set(.FontSize, 99.0f);

		let view = new TestView(50, 30);
		root.AddView(view);

		let colour = view.ResolveStyleColor(.TextColor, Color.White);
		Test.Assert((colour.R == 1.0f) && (colour.G == 0.0f) && (colour.B == 0.0f));
		Test.Assert(view.ResolveStyleFloat(.FontSize, 14.0f) == 14.0f, "the group rule missed");
	}

	/// A type rule matches SUBTYPES, so a rule on View reaches every control.
	[Test]
	public static void ATypeRuleReachesSubtypes()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForType(typeof(View)).Set(.TextColor, Rgb(128, 128, 128));

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(Near(view.ResolveStyleColor(.TextColor).R, 128 / 255.0f));
	}

	/// Class names are CASE SENSITIVE, as in CSS.
	[Test]
	public static void AClassRuleMatchesExactlyAndIsCaseSensitive()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForClass("primary").Set(.FontSize, 24.0f);
		sheet.ForClass("Capitalised").Set(.CornerRadius, 5.0f);

		let matching = new TestView(50, 30);
		matching.AddClass("primary");
		root.AddView(matching);
		let other = new TestView(50, 30);
		other.AddClass("secondary");
		root.AddView(other);
		let wrongCase = new TestView(50, 30);
		wrongCase.AddClass("capitalised");
		root.AddView(wrongCase);

		Test.Assert(matching.ResolveStyleFloat(.FontSize, 14.0f) == 24.0f);
		Test.Assert(other.ResolveStyleFloat(.FontSize, 14.0f) == 14.0f);
		Test.Assert(wrongCase.ResolveStyleFloat(.CornerRadius, -1.0f) == -1.0f);
	}

	[Test]
	public static void AClassBeatsAType()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForType(typeof(TestView)).Set(.FontSize, 10.0f);
		sheet.ForClass("big").Set(.FontSize, 30.0f);

		let view = new TestView(50, 30);
		view.AddClass("big");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 30.0f);
	}

	[Test]
	public static void AddingAStateBeatsTheSameSelectorWithout()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForType(typeof(TestView)).Set(.TextColor, Rgb(100, 100, 100));
		sheet.ForTypeState(typeof(TestView), .Disabled).Set(.TextColor, Rgb(50, 50, 50));

		let view = new TestView(50, 30);
		view.IsEnabled = false;
		root.AddView(view);

		Test.Assert(Near(view.ResolveStyleColor(.TextColor).R, 50 / 255.0f));
	}

	[Test]
	public static void AClassPlusAStateBeatsTheClassAlone()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForClass("btn").Set(.FontSize, 14.0f);
		sheet.ForTypeClassState(typeof(TestView), "btn", .Disabled).Set(.FontSize, 12.0f);

		let view = new TestView(50, 30);
		view.AddClass("btn");
		view.IsEnabled = false;
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 12.0f);
	}

	/// A state rule applies ONLY in that state, however specific it is: a hover rule must not
	/// win over a plain one on a view that is not hovered.
	[Test]
	public static void AStateRuleDoesNotApplyOutsideItsState()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForTypeState(typeof(TestView), .Hover).Set(.TextColor, Rgb(0, 255, 0));
		sheet.ForType(typeof(TestView)).Set(.TextColor, Rgb(200, 200, 200));

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(Near(view.ResolveStyleColor(.TextColor).R, 200 / 255.0f));
	}

	// ---- Value kinds through the cascade ----------------------------------------------------

	[Test]
	public static void EveryValueKindResolvesBackAsItself()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);

		let drawable = new ColorDrawable(Rgb(60, 60, 60));
		sheet.OwnDrawable(drawable);
		let states = Palette.CreateStateColors(Rgb(60, 60, 60));
		sheet.OwnDrawable(states);

		sheet.ForType(typeof(TestView))
			.Set(.Background, drawable)
			.Set(.CheckedBackground, states)
			.Set(.Padding, Thickness(8, 4))
			.Set(.WordWrap, true);

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(view.ResolveStyleDrawable(.Background) == drawable);
		// A state list resolves back as ITSELF: the cascade hands over the drawable, and
		// picking a state out of it is the drawable's own business at draw time.
		Test.Assert(view.ResolveStyleDrawable(.CheckedBackground) == states);

		let padding = view.ResolveStyleThickness(.Padding);
		Test.Assert((padding.Left == 8) && (padding.Top == 4)
			&& (padding.Right == 8) && (padding.Bottom == 4));

		let wrap = view.ResolveStyle(.WordWrap).AsBool;
		Test.Assert(wrap != null);
		Test.Assert(wrap.Value == true);
	}

	[Test]
	public static void OneRuleCarriesManyPropertiesAtOnce()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForType(typeof(TestView))
			.Set(.TextColor, Rgb(200, 200, 200))
			.Set(.FontSize, 16.0f)
			.Set(.Padding, Thickness(8));

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(Near(view.ResolveStyleColor(.TextColor).R, 200 / 255.0f));
		Test.Assert(view.ResolveStyleFloat(.FontSize) == 16.0f);
		Test.Assert(view.ResolveStyleThickness(.Padding).Left == 8);
	}

	// ---- Inheritance ------------------------------------------------------------------------

	/// The TEXT properties inherit, because text inside a panel should look like the panel's
	/// text without every control restating it.
	[Test]
	public static void TextPropertiesInheritFromTheParent()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForType(typeof(TestGroup))
			.Set(.TextColor, Rgb(255, 100, 0))
			.Set(.FontSize, 20.0f);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		let colour = child.ResolveStyleColor(.TextColor, Color.White);
		Test.Assert(colour.R == 1.0f);
		Test.Assert(Near(colour.G, 100 / 255.0f));
		Test.Assert(colour.B == 0.0f);
		Test.Assert(child.ResolveStyleFloat(.FontSize) == 20.0f);
	}

	[Test]
	public static void AChildsOwnRuleOverridesWhatItWouldInherit()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForType(typeof(TestGroup)).Set(.TextColor, Rgb(255, 0, 0));
		sheet.ForType(typeof(TestView)).Set(.TextColor, Rgb(0, 0, 255));

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		let colour = child.ResolveStyleColor(.TextColor);
		Test.Assert((colour.B == 1.0f) && (colour.R == 0.0f));
	}

	/// The BOX properties do NOT inherit: a panel's background and padding are its own, and
	/// inheriting them would paint and inset every child inside it.
	[Test]
	public static void BackgroundAndPaddingDoNotInherit()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		let drawable = new ColorDrawable(Color.Red);
		sheet.OwnDrawable(drawable);
		sheet.ForType(typeof(TestGroup))
			.Set(.Background, drawable)
			.Set(.Padding, Thickness(20));

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.ResolveStyleDrawable(.Background) == null);
		Test.Assert(child.ResolveStyleThickness(.Padding).IsZero);
	}

	// ---- Sheet ownership --------------------------------------------------------------------

	/// A sheet is reference counted so several contexts can SHARE one theme, and dropping the
	/// creation reference leaves it alive for as long as a context still holds it.
	[Test]
	public static void OneSheetIsSharedBetweenContexts()
	{
		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView)).Set(.FontSize, 18.0f);

		let first = scope UIContext();
		let firstRoot = new RootView();
		defer firstRoot.ReleaseRef();
		UITest.Init(first, firstRoot);
		sheet.AddRef();
		first.SetStyleSheet(sheet);

		let second = scope UIContext();
		let secondRoot = new RootView();
		defer secondRoot.ReleaseRef();
		UITest.Init(second, secondRoot);
		sheet.AddRef();
		second.SetStyleSheet(sheet);

		let firstView = new TestView(50, 30);
		firstRoot.AddView(firstView);
		let secondView = new TestView(50, 30);
		secondRoot.AddView(secondView);

		Test.Assert(firstView.ResolveStyleFloat(.FontSize) == 18.0f);
		Test.Assert(secondView.ResolveStyleFloat(.FontSize) == 18.0f);

		// Drop the creation reference: both contexts still hold their own.
		sheet.ReleaseRef();
		Test.Assert(firstView.ResolveStyleFloat(.FontSize) == 18.0f);
	}

	[Test]
	public static void ReplacingTheSheetReleasesTheOldOne()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let first = new StyleSheet();
		first.ForType(typeof(TestView)).Set(.FontSize, 10.0f);
		let second = new StyleSheet();
		second.ForType(typeof(TestView)).Set(.FontSize, 20.0f);

		context.SetStyleSheet(first);
		context.SetStyleSheet(second);

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 20.0f);
	}

	// ---- ForAll -----------------------------------------------------------------------------

	[Test]
	public static void AForAllRuleReachesEveryViewButLosesToATypedOne()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForAll().Set(.FontFamily, "JungleAdventurer");

		let group = new TestGroup();
		let view = new TestView(50, 30);
		root.AddView(group);
		group.AddView(view);

		Test.Assert(view.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
		Test.Assert(group.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
	}

	[Test]
	public static void ATypedRuleBeatsForAll()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForAll().Set(.FontFamily, "ForAllFamily");
		sheet.ForType(typeof(TestView)).Set(.FontFamily, "TestViewFamily");

		let view = new TestView(50, 30);
		root.AddView(view);

		Test.Assert(view.ResolveStyle(.FontFamily).AsString.Value == "TestViewFamily");
	}
}
