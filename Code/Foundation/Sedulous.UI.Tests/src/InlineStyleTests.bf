using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Inline styles: the per view overrides that beat every rule, element level and pseudo element
/// alike, and the ownership of any drawable set through them.
class InlineStyleTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static Color Rgb(float r, float g, float b, float a = 255.0f) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);

	/// A sheet OWNED by the context; the returned pointer is borrowed.
	private static StyleSheet SetupSheet(UIContext context)
	{
		let sheet = new StyleSheet();
		context.SetStyleSheet(sheet);
		return sheet;
	}

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	/// A drawable that counts its own live instances, so a test can watch ownership rather than
	/// infer it.
	private class TrackingDrawable : Drawable
	{
		public static int LiveCount = 0;

		public this() { LiveCount++; }
		public ~this() { LiveCount--; }

		public override void Draw(UIDrawContext ctx, Rectangle bounds) {}
	}

	/// The part getters have no dedicated View method, so the same intent goes through the
	/// public inline sheet's part rule.
	private static StyleValue GetInlinePartStyle(View view, StringView part,
		StyleProperty property)
	{
		let sheet = view.InlineSheet;
		if (sheet == null)
			return .None;
		let rule = sheet.FindInlinePartRule(part);
		if (rule == null)
			return .None;
		let value = rule.GetValue(property);
		return (value != null) ? value.Value : StyleValue.None;
	}

	private static bool HasInlinePartStyle(View view, StringView part, StyleProperty property) =>
		!GetInlinePartStyle(view, part, property).IsNone;

	private static bool ClearInlinePartStyle(View view, StringView part, StyleProperty property)
	{
		let sheet = view.InlineSheet;
		if (sheet == null)
			return false;
		let rule = sheet.FindInlinePartRule(part);
		return (rule != null) && rule.Remove(property);
	}

	// ---- Element level ----------------------------------------------------------------------

	/// The storage is LAZY: reading, testing and clearing a view that was never styled must not
	/// allocate a sheet for it, since most views never have an inline style at all.
	[Test]
	public static void AnUnstyledViewHasNoInlineSheetAtAll()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(view.GetInlineStyle(.TextColor).IsNone);
		Test.Assert(!view.HasInlineStyle(.TextColor));
		Test.Assert(!view.HasAnyInlineStyles);

		view.ClearInlineStyle(.TextColor);
		view.ClearInlineStyles();

		Test.Assert(!view.HasAnyInlineStyles);
		Test.Assert(view.InlineSheet == null);
	}

	[Test]
	public static void SettingAnInlineStyleRoundTripsAndOverwrites()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		view.SetStyle(.TextColor, Rgb(255, 0, 0));
		Test.Assert(view.HasInlineStyle(.TextColor));
		Test.Assert(view.HasAnyInlineStyles);
		Test.Assert(view.GetInlineStyle(.TextColor).AsColor.Value.R == 1.0f);

		view.SetStyle(.FontSize, 12.0f);
		view.SetStyle(.FontSize, 24.0f);
		Test.Assert(view.GetInlineStyle(.FontSize).AsFloat.Value == 24.0f);
	}

	[Test]
	public static void ClearingOneInlineStyleLeavesTheOthers()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();
		view.SetStyle(.TextColor, Color.Red);
		view.SetStyle(.FontSize, 18.0f);

		view.ClearInlineStyle(.TextColor);

		Test.Assert(!view.HasInlineStyle(.TextColor));
		Test.Assert(view.HasInlineStyle(.FontSize));
		Test.Assert(view.HasAnyInlineStyles);
	}

	/// Clearing ALL drops the whole sheet, so the part overrides go with it.
	[Test]
	public static void ClearingEveryInlineStyleDropsTheSheet()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();
		view.SetStyle(.TextColor, Color.Red);
		view.SetStyle(.FontSize, 18.0f);
		view.SetPartStyle("thumb", .Background, Color.Blue);

		view.ClearInlineStyles();

		Test.Assert(!view.HasInlineStyle(.TextColor));
		Test.Assert(!view.HasInlineStyle(.FontSize));
		Test.Assert(view.InlineSheet == null, "the part override went with it");
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void EveryValueKindSurvivesTheInlineRoundTrip()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		// Our own reference, so identity can be compared after the view takes ownership.
		let drawable = new ColorDrawable(Color.Red);
		drawable.AddRef();
		defer drawable.ReleaseRef();

		view.SetStyle(.TextColor, Rgb(10, 20, 30));
		view.SetStyle(.FontSize, 16.0f);
		view.SetStyle(.Padding, Thickness(2, 4));
		view.SetStyle(.WordWrap, true);
		view.SetStyle(.Background, drawable);

		Test.Assert(Near(view.GetInlineStyle(.TextColor).AsColor.Value.R, 10 / 255.0f));
		Test.Assert(view.GetInlineStyle(.FontSize).AsFloat.Value == 16.0f);
		Test.Assert(view.GetInlineStyle(.Padding).AsThickness.Value.Left == 2.0f);
		Test.Assert(view.GetInlineStyle(.WordWrap).AsBool.Value == true);
		Test.Assert(view.GetInlineStyle(.Background).AsDrawable == drawable);
	}

	[Test]
	public static void AStringValueRoundTripsAndOverwritesCleanly()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		view.SetStyle(.FontFamily, "Roboto");
		Test.Assert(view.HasInlineStyle(.FontFamily));

		// Held in a NAMED local: AsString borrows a view INTO the value, which would dangle if
		// the value were a destroyed temporary.
		let value = view.GetInlineStyle(.FontFamily);
		Test.Assert(value.AsString != null);
		Test.Assert(value.AsString.Value == "Roboto");

		view.SetStyle(.FontFamily, "JungleAdventurer");
		view.SetStyle(.FontFamily, "AttackOfMonster");
		Test.Assert(view.GetInlineStyle(.FontFamily).AsString.Value == "AttackOfMonster");
	}

	// ---- Pseudo element level ---------------------------------------------------------------

	[Test]
	public static void AnUnsetPartStyleReadsAsNone()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(GetInlinePartStyle(view, "thumb", .Background).IsNone);
		Test.Assert(!HasInlinePartStyle(view, "thumb", .Background));
		Test.Assert(!view.HasAnyInlineStyles);

		ClearInlinePartStyle(view, "thumb", .Background);
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void APartStyleRoundTripsAndOverwritesWithoutDuplicating()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		view.SetPartStyle("thumb", .Background, Color.Red);
		Test.Assert(HasInlinePartStyle(view, "thumb", .Background));
		Test.Assert(view.HasAnyInlineStyles);
		Test.Assert(GetInlinePartStyle(view, "thumb", .Background).AsColor.Value.R == 1.0f);

		view.SetPartStyle("thumb", .Background, Color.Blue);
		Test.Assert(GetInlinePartStyle(view, "thumb", .Background).AsColor.Value.B == 1.0f);

		// A second set must leave no stale entry behind: one clear removes it entirely.
		ClearInlinePartStyle(view, "thumb", .Background);
		Test.Assert(!HasInlinePartStyle(view, "thumb", .Background));
	}

	/// Parts are keyed by NAME and by property, so a thumb and a track keep their own values.
	[Test]
	public static void PartsAreDistinguishedByNameAndByProperty()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		view.SetPartStyle("thumb", .Background, Color.Red);
		view.SetPartStyle("track", .Background, Color.Blue);
		view.SetPartStyle("thumb", .CornerRadius, 8.0f);

		Test.Assert(GetInlinePartStyle(view, "thumb", .Background).AsColor.Value.R == 1.0f);
		Test.Assert(GetInlinePartStyle(view, "track", .Background).AsColor.Value.B == 1.0f);
		Test.Assert(GetInlinePartStyle(view, "thumb", .CornerRadius).AsFloat.Value == 8.0f);

		ClearInlinePartStyle(view, "thumb", .Background);
		Test.Assert(!HasInlinePartStyle(view, "thumb", .Background));
		Test.Assert(HasInlinePartStyle(view, "track", .Background), "untouched");
	}

	/// Dropping a view with part styles must free the part NAME strings the sheet copied.
	[Test]
	public static void DroppingAViewFreesItsPartNames()
	{
		let view = new TestView(50, 30);
		view.SetPartStyle("thumb", .Background, Color.Red);
		view.SetPartStyle("track", .Background, Color.Blue);
		view.SetPartStyle("thumb", .CornerRadius, 4.0f);

		view.ReleaseRef();
		// What this pins is that nothing leaks, which the runner's own leak check reports.
	}

	// ---- Resolution priority ----------------------------------------------------------------

	[Test]
	public static void InlineBeatsATypeRule()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForType(typeof(TestView)).Set(.TextColor, Rgb(255, 0, 0));

		let view = new TestView(50, 30);
		root.AddView(view);
		view.SetStyle(.TextColor, Rgb(0, 255, 0));

		let colour = view.ResolveStyleColor(.TextColor);
		Test.Assert((colour.R == 0.0f) && (colour.G == 1.0f));
	}

	/// Inline beats the MOST specific rule there is, which is what makes it an override rather
	/// than another layer of the cascade.
	[Test]
	public static void InlineBeatsAClassPlusStateRule()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context)
			.ForTypeClassState(typeof(TestView), "btn", .Disabled).Set(.FontSize, 12.0f);

		let view = new TestView(50, 30);
		view.AddClass("btn");
		view.IsEnabled = false;
		root.AddView(view);
		view.SetStyle(.FontSize, 99.0f);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 99.0f);
	}

	/// An inline value applies in EVERY control state, so changing state cannot make a state
	/// scoped rule reappear over it.
	[Test]
	public static void InlineIgnoresTheControlState()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForTypeState(typeof(TestView), .Hover).Set(.TextColor, Color.Red);
		sheet.ForType(typeof(TestView)).Set(.TextColor, Color.Blue);

		let view = new TestView(50, 30);
		root.AddView(view);
		view.SetStyle(.TextColor, Rgb(10, 20, 30));

		Test.Assert(Near(view.ResolveStyleColor(.TextColor).R, 10 / 255.0f));
	}

	[Test]
	public static void AnInlinePartOverrideBeatsItsRuleAndStaysInItsOwnPart()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let sheet = SetupSheet(context);
		sheet.ForTypePseudo(typeof(TestView), "thumb").Set(.CornerRadius, 4.0f);
		sheet.ForTypePseudo(typeof(TestView), "track").Set(.CornerRadius, 4.0f);

		let view = new TestView(50, 30);
		root.AddView(view);
		view.SetPartStyle("thumb", .CornerRadius, 16.0f);

		Test.Assert(view.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 16.0f);
		Test.Assert(view.ResolvePartFloat("track", .CornerRadius, .Normal) == 4.0f,
			"the thumb override did not bleed");
	}

	/// An inheritable property set INLINE on a parent still reaches the child: inheritance
	/// reads the parent's computed value, however that value was arrived at.
	[Test]
	public static void AnInlineValueOnAParentInheritsToItsChild()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context); // empty: only the parent's inline value can satisfy this

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		group.SetStyle(.TextColor, Rgb(40, 50, 60));

		let colour = child.ResolveStyleColor(.TextColor);
		Test.Assert(Near(colour.R, 40 / 255.0f));
		Test.Assert(Near(colour.G, 50 / 255.0f));
		Test.Assert(Near(colour.B, 60 / 255.0f));
	}

	[Test]
	public static void AChildsInlineValueBeatsARuleOnItsParent()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForType(typeof(TestGroup)).Set(.TextColor, Color.Red);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		child.SetStyle(.TextColor, Rgb(0, 255, 0));

		Test.Assert(child.ResolveStyleColor(.TextColor).G == 1.0f);
	}

	[Test]
	public static void InlineBeatsALocalSheetOnTheViewItself()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context);

		let view = new TestView(50, 30);
		root.AddView(view);

		let local = new StyleSheet();
		local.ForType(typeof(TestView)).Set(.TextColor, Color.Red);
		view.SetLocalStyleSheet(local);

		view.SetStyle(.TextColor, Rgb(0, 255, 0));

		Test.Assert(view.ResolveStyleColor(.TextColor).G == 1.0f);
	}

	[Test]
	public static void InlineBeatsALocalSheetOnAnAncestor()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		let local = new StyleSheet();
		local.ForType(typeof(TestView)).Set(.TextColor, Color.Red);
		group.SetLocalStyleSheet(local);

		child.SetStyle(.TextColor, Rgb(0, 0, 255));

		Test.Assert(child.ResolveStyleColor(.TextColor).B == 1.0f);
	}

	// ---- Drawable ownership -----------------------------------------------------------------

	/// SetStyle CONSUMES the caller's reference, and the view holds it until the view dies.
	[Test]
	public static void SettingADrawableConsumesTheReferenceAndFreesItWithTheView()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView(50, 30);
		view.SetStyle(.Background, new TrackingDrawable());
		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		view.ReleaseRef();
		Test.Assert(TrackingDrawable.LiveCount == before);
	}

	/// A caller that wants to KEEP a reference takes one first. Raptor expresses the same
	/// choice as a RefPtr copy against a move; Beef has no overload for it, so the caller says
	/// so explicitly.
	[Test]
	public static void ACallerKeepsItsOwnReferenceByTakingOneFirst()
	{
		let before = TrackingDrawable.LiveCount;

		let drawable = new TrackingDrawable();
		drawable.AddRef();
		defer drawable.ReleaseRef();

		let view = new TestView(50, 30);
		view.SetStyle(.Background, drawable);
		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		view.ReleaseRef();
		Test.Assert(TrackingDrawable.LiveCount == before + 1, "the caller's reference held it");
	}

	[Test]
	public static void EveryConsumedDrawableIsFreedWithTheView()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView(50, 30);
		view.SetStyle(.Background, new TrackingDrawable());
		view.SetPartStyle("thumb", .Background, new TrackingDrawable());
		Test.Assert(TrackingDrawable.LiveCount == before + 2);

		view.ReleaseRef();
		Test.Assert(TrackingDrawable.LiveCount == before);
	}

	/// Overwriting an inline drawable FREES the one it replaced.
	///
	/// This is what stops a hover handler that reassigns a background each frame from growing
	/// without bound: inline styles are set repeatedly at runtime, which is the whole point of
	/// them, unlike a sheet built once at load.
	[Test]
	public static void OverwritingADrawableFreesTheOneItReplaced()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView(50, 30);
		view.SetStyle(.Background, new TrackingDrawable());
		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		view.SetStyle(.Background, new TrackingDrawable());
		Test.Assert(TrackingDrawable.LiveCount == before + 1, "the first one went");

		view.ReleaseRef();
		Test.Assert(TrackingDrawable.LiveCount == before);
	}

	[Test]
	public static void SettingANullDrawableClearsAndFreesThePrevious()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView(50, 30);
		view.SetStyle(.Background, new TrackingDrawable());
		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		view.SetStyle(.Background, (Drawable)null);
		Test.Assert(TrackingDrawable.LiveCount == before);

		view.ReleaseRef();
	}

	[Test]
	public static void OverwritingAPartDrawableFreesTheOneItReplaced()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView(50, 30);
		view.SetPartStyle("thumb", .Background, new TrackingDrawable());
		view.SetPartStyle("thumb", .Background, new TrackingDrawable());
		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		view.ReleaseRef();
		Test.Assert(TrackingDrawable.LiveCount == before);
	}
}
