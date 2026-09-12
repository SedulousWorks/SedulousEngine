using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// A view's LOCAL style sheet: its lifetime, and where it sits in the resolution order between
/// the context sheet below it and the inline overrides above.
///
/// This is what scopes a theme to a subtree, so a dialog or an embedded panel can restyle
/// everything inside it without touching the rest of the tree.
class LocalStyleSheetTests
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

	/// An empty sheet on the context; the returned pointer is BORROWED.
	private static StyleSheet SetupContextSheet(UIContext context)
	{
		let sheet = new StyleSheet();
		context.SetStyleSheet(sheet);
		return sheet;
	}

	/// An empty local sheet on a view; the returned pointer is BORROWED.
	private static StyleSheet SetupLocalSheet(View view)
	{
		let sheet = new StyleSheet();
		view.SetLocalStyleSheet(sheet);
		return sheet;
	}

	// ---- Lifetime ---------------------------------------------------------------------------

	[Test]
	public static void AViewHasNoLocalSheetUntilOneIsGivenToIt()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(view.GetLocalStyleSheet() == null);
	}

	/// SetLocalStyleSheet CONSUMES the caller's reference, so a caller that wants to keep the
	/// sheet takes one of its own first.
	[Test]
	public static void SettingALocalSheetHoldsItUntilTheViewGoes()
	{
		let sheet = new StyleSheet();
		sheet.AddRef(); // our own, held past the view
		defer sheet.ReleaseRef();

		let view = new TestView(50, 30);
		view.SetLocalStyleSheet(sheet);
		Test.Assert(view.GetLocalStyleSheet() == sheet);

		view.ReleaseRef();
		// The sheet is still alive on our reference.
	}

	/// Setting the SAME sheet twice is a guarded no op, not a double retain and not a release
	/// of the thing being set.
	[Test]
	public static void SettingTheSameSheetTwiceIsHarmless()
	{
		let sheet = new StyleSheet();
		sheet.AddRef();
		defer sheet.ReleaseRef();

		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		view.SetLocalStyleSheet(sheet);
		sheet.AddRef(); // the second call consumes a reference like the first
		view.SetLocalStyleSheet(sheet);

		Test.Assert(view.GetLocalStyleSheet() == sheet);
	}

	[Test]
	public static void ReassigningReleasesThePreviousSheet()
	{
		let first = new StyleSheet();
		let second = new StyleSheet();

		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		view.SetLocalStyleSheet(first);
		view.SetLocalStyleSheet(second); // the view's reference on `first` goes

		Test.Assert(view.GetLocalStyleSheet() == second);
	}

	[Test]
	public static void ClearingFallsBackToNone()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();
		view.SetLocalStyleSheet(new StyleSheet());

		view.SetLocalStyleSheet(null);

		Test.Assert(view.GetLocalStyleSheet() == null);
	}

	/// One sheet SHARED by several views: each holds its own reference, so neither view going
	/// away takes the sheet with it.
	[Test]
	public static void OneLocalSheetIsSharedBetweenViews()
	{
		let sheet = new StyleSheet();
		defer sheet.ReleaseRef();

		let first = new TestView(50, 30);
		let second = new TestView(50, 30);
		sheet.AddRef();
		first.SetLocalStyleSheet(sheet);
		sheet.AddRef();
		second.SetLocalStyleSheet(sheet);

		Test.Assert(first.GetLocalStyleSheet() == sheet);
		Test.Assert(second.GetLocalStyleSheet() == sheet);

		first.ReleaseRef();
		second.ReleaseRef();
		// Our creation reference still holds it.
	}

	// ---- Resolution order -------------------------------------------------------------------

	[Test]
	public static void ALocalSheetOnTheViewBeatsTheContextSheet()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context).ForType(typeof(TestView)).Set(.TextColor, Rgb(255, 0, 0));

		let view = new TestView(50, 30);
		root.AddView(view);
		SetupLocalSheet(view).ForType(typeof(TestView)).Set(.TextColor, Rgb(0, 255, 0));

		let colour = view.ResolveStyleColor(.TextColor);
		Test.Assert((colour.G == 1.0f) && (colour.R == 0.0f));
	}

	[Test]
	public static void ALocalSheetOnAnAncestorBeatsTheContextSheet()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context).ForType(typeof(TestView)).Set(.TextColor, Color.Red);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		SetupLocalSheet(group).ForType(typeof(TestView)).Set(.TextColor, Rgb(50, 200, 50));

		Test.Assert(Near(child.ResolveStyleColor(.TextColor).G, 200 / 255.0f));
	}

	/// With local sheets at two depths, the NEARER one wins: a dialog inside a panel restyles
	/// what the panel already restyled.
	[Test]
	public static void ACloserAncestorsSheetBeatsAFartherOne()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let outer = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(outer);
		outer.AddView(inner);
		inner.AddView(child);

		SetupLocalSheet(outer).ForType(typeof(TestView)).Set(.TextColor, Color.Red);
		SetupLocalSheet(inner).ForType(typeof(TestView)).Set(.TextColor, Rgb(0, 0, 255));

		Test.Assert(child.ResolveStyleColor(.TextColor).B == 1.0f);
	}

	/// A nearer sheet that says nothing about a property does not BLOCK a farther one: the walk
	/// is per property, not per sheet.
	[Test]
	public static void ANearerSheetOnlyWinsThePropertiesItDeclares()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let outer = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(outer);
		outer.AddView(inner);
		inner.AddView(child);

		SetupLocalSheet(outer).ForType(typeof(TestView)).Set(.TextColor, Rgb(0, 200, 0));
		SetupLocalSheet(inner).ForType(typeof(TestView)).Set(.FontSize, 24.0f);

		Test.Assert(Near(child.ResolveStyleColor(.TextColor).G, 200 / 255.0f), "from the outer");
		Test.Assert(child.ResolveStyleFloat(.FontSize) == 24.0f, "from the inner");
	}

	[Test]
	public static void APropertyNoLocalSheetDeclaresFallsThroughToTheContext()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context).ForType(typeof(TestView)).Set(.TextColor, Rgb(100, 100, 100));

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		SetupLocalSheet(group).ForType(typeof(TestView)).Set(.FontSize, 18.0f);

		Test.Assert(Near(child.ResolveStyleColor(.TextColor).R, 100 / 255.0f));
	}

	/// Inheritance and local sheets COMPOSE: a rule in a dialog's local sheet that matches the
	/// dialog itself still reaches a grandchild through the ordinary inheritance walk.
	[Test]
	public static void AnInheritablePropertyCascadesOutOfAnAncestorsLocalSheet()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let dialog = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(dialog);
		dialog.AddView(inner);
		inner.AddView(child);

		SetupLocalSheet(dialog).ForType(typeof(TestGroup)).Set(.TextColor, Rgb(50, 150, 250));

		Test.Assert(Near(child.ResolveStyleColor(.TextColor).B, 250 / 255.0f));
	}

	[Test]
	public static void ANonInheritablePropertyStillDoesNotCascade()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		SetupLocalSheet(group).ForType(typeof(TestGroup)).Set(.Padding, Thickness(8));

		Test.Assert(child.ResolveStyleThickness(.Padding).IsZero);
	}

	// ---- Pseudo elements --------------------------------------------------------------------

	[Test]
	public static void APseudoElementRuleInALocalSheetBeatsTheContextSheet()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context).ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 4.0f);

		let view = new TestView(50, 30);
		root.AddView(view);
		SetupLocalSheet(view).ForTypePseudo(typeof(TestView), "thumb").Set(.CornerRadius, 12.0f);

		Test.Assert(view.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 12.0f);
	}

	[Test]
	public static void APseudoElementRuleOnAnAncestorReachesTheChild()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context).ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 2.0f);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		SetupLocalSheet(group).ForTypePseudo(typeof(TestView), "thumb").Set(.CornerRadius, 16.0f);

		Test.Assert(child.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 16.0f);
	}

	[Test]
	public static void ACloserAncestorWinsForPseudoElementsToo()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let outer = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(outer);
		outer.AddView(inner);
		inner.AddView(child);

		SetupLocalSheet(outer).ForTypePseudo(typeof(TestView), "thumb").Set(.CornerRadius, 4.0f);
		SetupLocalSheet(inner).ForTypePseudo(typeof(TestView), "thumb").Set(.CornerRadius, 10.0f);

		Test.Assert(child.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 10.0f);
	}

	/// The same order holds for parts as for the element: inline over local, wherever the local
	/// sheet sits.
	[Test]
	public static void AnInlinePartOverrideBeatsALocalSheetOnTheViewOrAnAncestor()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let group = new TestGroup();
		let onSelf = new TestView(50, 30);
		let onAncestor = new TestView(50, 30);
		root.AddView(group);
		group.AddView(onSelf);
		group.AddView(onAncestor);

		SetupLocalSheet(group).ForTypePseudo(typeof(TestView), "thumb").Set(.CornerRadius, 4.0f);
		SetupLocalSheet(onSelf).ForTypePseudo(typeof(TestView), "thumb").Set(.CornerRadius, 4.0f);

		onSelf.SetPartStyle("thumb", .CornerRadius, 20.0f);
		onAncestor.SetPartStyle("thumb", .CornerRadius, 22.0f);

		Test.Assert(onSelf.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 20.0f);
		Test.Assert(onAncestor.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 22.0f);
	}

	/// A local sheet that styles a DIFFERENT part does not shadow the context's rule for this
	/// one: parts fall through independently.
	[Test]
	public static void AnUnmatchedPartFallsThroughToTheContext()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context).ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 7.0f);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		SetupLocalSheet(group).ForTypePseudo(typeof(TestView), "track").Set(.CornerRadius, 99.0f);

		Test.Assert(child.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 7.0f);
	}

	// ---- ForAll in a local sheet ------------------------------------------------------------

	/// A ForAll rule in a subtree's local sheet reaches every DESCENDANT type, which is how a
	/// pause screen sets one font for everything inside it without naming the controls.
	[Test]
	public static void AForAllRuleInALocalSheetReachesEveryDescendant()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let pauseRoot = new TestGroup();
		let inner = new TestGroup();
		let view = new TestView(50, 30);
		root.AddView(pauseRoot);
		pauseRoot.AddView(inner);
		inner.AddView(view);

		SetupLocalSheet(pauseRoot).ForAll().Set(.FontFamily, "JungleAdventurer");

		Test.Assert(pauseRoot.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
		Test.Assert(inner.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
		Test.Assert(view.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
	}

	/// A TYPE scoped rule reaches nothing when no view in the chain is that type, even though
	/// the property itself inherits: there has to be a match somewhere to inherit FROM.
	[Test]
	public static void ATypeScopedRuleMatchingNothingInTheChainResolvesToNone()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let outer = new TestGroup();
		let inner = new TestView(50, 30);
		root.AddView(outer);
		outer.AddView(inner);

		// A type that appears nowhere in this chain. Raptor uses Label here; the substitution
		// keeps the point, which is that the type simply does not occur above the view.
		SetupLocalSheet(outer).ForType(typeof(FrameLayout)).Set(.FontFamily, "JungleAdventurer");

		Test.Assert(inner.ResolveStyle(.FontFamily).IsNone);
	}

	[Test]
	public static void ATypeScopedRuleMatchingAnAncestorInheritsDown()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupContextSheet(context);

		let outer = new TestGroup();
		let inner = new TestView(50, 30);
		root.AddView(outer);
		outer.AddView(inner);

		SetupLocalSheet(outer).ForType(typeof(TestGroup)).Set(.FontFamily, "JungleAdventurer");

		Test.Assert(inner.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
	}
}
