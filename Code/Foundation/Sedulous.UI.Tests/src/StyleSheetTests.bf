namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class StyleSheetTests
{
	/// Helper: create a StyleSheet, assign to ctx, release creation ref.
	/// After this call, ctx owns the only ref.
	static StyleSheet SetupSheet(UIContext ctx)
	{
		let sheet = new StyleSheet();
		ctx.StyleSheet = sheet;  // AddRef -> 2
		sheet.ReleaseRef();      // -> 1 (ctx owns)
		return sheet;
	}

	// === Basic resolution ===

	[Test]
	public static void Resolve_NoSheet_ReturnsNone()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyle(.Background) case .None);
		Test.Assert(view.ResolveStyleDrawable(.Background) == null);
		Test.Assert(view.ResolveStyleColor(.TextColor, .White) == .White);
		Test.Assert(view.ResolveStyleFloat(.FontSize, 14) == 14);
	}

	[Test]
	public static void Resolve_TypeMatch()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(255, 0, 0, 255));

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor, .White);
		Test.Assert(color.R == 255 && color.G == 0 && color.B == 0);
	}

	[Test]
	public static void Resolve_TypeMismatch_ReturnsDefault()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestGroup))
			.Set(.TextColor, Color(255, 0, 0, 255));

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor, .White);
		Test.Assert(color == .White);
	}

	[Test]
	public static void Resolve_ClassMatch()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForClass("primary")
			.Set(.FontSize, 24.0f);

		let view = new TestView();
		view.AddClass("primary");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize, 14) == 24.0f);
	}

	[Test]
	public static void Resolve_ClassMismatch_ReturnsDefault()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForClass("primary")
			.Set(.FontSize, 24.0f);

		let view = new TestView();
		view.AddClass("secondary");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize, 14) == 14.0f);
	}

	[Test]
	public static void Resolve_ClassIsCaseSensitive()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForClass("Primary")
			.Set(.FontSize, 24.0f);

		let view = new TestView();
		view.AddClass("primary");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize, 14) == 14.0f);
	}

	// === Specificity / Cascade ===

	[Test]
	public static void Specificity_ClassBeatsType()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestView))
			.Set(.FontSize, 10.0f);
		sheet.ForClass("big")
			.Set(.FontSize, 30.0f);

		let view = new TestView();
		view.AddClass("big");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 30.0f);
	}

	[Test]
	public static void Specificity_TypePlusStateBeatsType()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(100, 100, 100, 255));
		sheet.ForTypeState(typeof(TestView), .Disabled)
			.Set(.TextColor, Color(50, 50, 50, 255));

		let view = new TestView();
		view.IsEnabled = false;
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 50);
	}

	[Test]
	public static void Specificity_ClassPlusStateBeatsClass()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForClass("btn")
			.Set(.FontSize, 14.0f);
		sheet.ForTypeClassState(typeof(TestView), "btn", .Disabled)
			.Set(.FontSize, 12.0f);

		let view = new TestView();
		view.AddClass("btn");
		view.IsEnabled = false;
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 12.0f);
	}

	[Test]
	public static void Specificity_StateOnlyMatchesCurrentState()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForTypeState(typeof(TestView), .Hover)
			.Set(.TextColor, Color(0, 255, 0, 255));
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(200, 200, 200, 255));

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 200);
	}

	// === Drawable resolution ===

	[Test]
	public static void Resolve_Drawable()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		let drawable = new ColorDrawable(.(60, 60, 60, 255));
		sheet.OwnDrawable(drawable);
		sheet.ForType(typeof(TestView))
			.Set(.Background, drawable);

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyleDrawable(.Background) === drawable);
	}

	[Test]
	public static void Resolve_StateListDrawable()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		let sl = Palette.CreateStateColors(.(60, 60, 60, 255));
		sheet.OwnDrawable(sl);
		sheet.ForType(typeof(TestView))
			.Set(.Background, sl);

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyleDrawable(.Background) === sl);
	}

	// === Thickness resolution ===

	[Test]
	public static void Resolve_Thickness()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestView))
			.Set(.Padding, Thickness(8, 4));

		let view = new TestView();
		root.AddView(view);

		let pad = view.ResolveStyleThickness(.Padding);
		Test.Assert(pad.Left == 8 && pad.Top == 4 && pad.Right == 8 && pad.Bottom == 4);
	}

	// === Bool resolution ===

	[Test]
	public static void Resolve_Bool()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestView))
			.Set(.WordWrap, true);

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyle(.WordWrap).AsBool == true);
	}

	// === Inheritance ===

	[Test]
	public static void Inheritance_TextColorInheritsFromParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestGroup))
			.Set(.TextColor, Color(255, 100, 0, 255));

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		let color = child.ResolveStyleColor(.TextColor, .White);
		Test.Assert(color.R == 255 && color.G == 100 && color.B == 0);
	}

	[Test]
	public static void Inheritance_FontSizeInheritsFromParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestGroup))
			.Set(.FontSize, 20.0f);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.ResolveStyleFloat(.FontSize) == 20.0f);
	}

	[Test]
	public static void Inheritance_ChildOverridesParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestGroup))
			.Set(.TextColor, Color(255, 0, 0, 255));
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(0, 0, 255, 255));

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		let color = child.ResolveStyleColor(.TextColor);
		Test.Assert(color.B == 255 && color.R == 0);
	}

	[Test]
	public static void Inheritance_BackgroundDoesNotInherit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		let drawable = new ColorDrawable(.Red);
		sheet.OwnDrawable(drawable);
		sheet.ForType(typeof(TestGroup))
			.Set(.Background, drawable);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.ResolveStyleDrawable(.Background) == null);
	}

	[Test]
	public static void Inheritance_PaddingDoesNotInherit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestGroup))
			.Set(.Padding, Thickness(20));

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		let pad = child.ResolveStyleThickness(.Padding);
		Test.Assert(pad.IsZero);
	}

	// === Subtype matching ===

	[Test]
	public static void TypeMatch_IncludesSubtypes()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(View))
			.Set(.TextColor, Color(128, 128, 128, 255));

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 128);
	}

	// === Multiple properties per rule ===

	[Test]
	public static void Rule_MultipleProperties()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(200, 200, 200, 255))
			.Set(.FontSize, 16.0f)
			.Set(.Padding, Thickness(8));

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyleColor(.TextColor).R == 200);
		Test.Assert(view.ResolveStyleFloat(.FontSize) == 16.0f);
		Test.Assert(view.ResolveStyleThickness(.Padding).Left == 8);
	}

	// === RefCounting ===

	[Test]
	public static void RefCounted_SharedBetweenContexts()
	{
		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView))
			.Set(.FontSize, 18.0f);
		// sheet starts with refcount 1

		let ctx1 = scope UIContext();
		let root1 = scope RootView();
		TestSetup.Init(ctx1, root1);
		ctx1.StyleSheet = sheet; // -> 2

		let ctx2 = scope UIContext();
		let root2 = scope RootView();
		TestSetup.Init(ctx2, root2);
		ctx2.StyleSheet = sheet; // -> 3

		let view1 = new TestView();
		root1.AddView(view1);
		let view2 = new TestView();
		root2.AddView(view2);

		Test.Assert(view1.ResolveStyleFloat(.FontSize) == 18.0f);
		Test.Assert(view2.ResolveStyleFloat(.FontSize) == 18.0f);

		// Release creation ref - contexts still hold refs
		sheet.ReleaseRef(); // -> 2

		Test.Assert(view1.ResolveStyleFloat(.FontSize) == 18.0f);
		// ctx1/ctx2 scope destructors release remaining refs
	}

	[Test]
	public static void RefCounted_ReplacingSheetReleasesOld()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet1 = new StyleSheet();
		sheet1.ForType(typeof(TestView))
			.Set(.FontSize, 10.0f);

		let sheet2 = new StyleSheet();
		sheet2.ForType(typeof(TestView))
			.Set(.FontSize, 20.0f);

		ctx.StyleSheet = sheet1; // sheet1 -> 2
		ctx.StyleSheet = sheet2; // sheet2 -> 2, sheet1 -> 1

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 20.0f);

		sheet1.ReleaseRef(); // -> 0, deleted
		sheet2.ReleaseRef(); // -> 1, ctx owns
		// ctx destructor releases last ref on sheet2
	}

	// === Palette ===

	[Test]
	public static void Palette_Lighten()
	{
		let c = Palette.Lighten(.(100, 100, 100, 255), 0.5f);
		Test.Assert(c.R > 100 && c.R < 255);
		Test.Assert(c.A == 255);
	}

	[Test]
	public static void Palette_Darken()
	{
		let c = Palette.Darken(.(200, 200, 200, 255), 0.5f);
		Test.Assert(c.R < 200 && c.R > 0);
		Test.Assert(c.A == 255);
	}

	[Test]
	public static void Palette_ComputeHover_Lighter()
	{
		let baseColor = Color(60, 60, 60, 255);
		let hover = Palette.ComputeHover(baseColor);
		Test.Assert(hover.R > baseColor.R);
	}

	[Test]
	public static void Palette_ComputePressed_Darker()
	{
		let baseColor = Color(60, 60, 60, 255);
		let pressed = Palette.ComputePressed(baseColor);
		Test.Assert(pressed.R < baseColor.R);
	}

	[Test]
	public static void Palette_ComputeDisabled_Faded()
	{
		let baseColor = Color(60, 120, 200, 255);
		let disabled = Palette.ComputeDisabled(baseColor);
		Test.Assert(disabled.A < 255);
	}

	[Test]
	public static void Palette_CreateStateColors_AllStatesSet()
	{
		let sl = Palette.CreateStateColors(.(80, 80, 80, 255));
		defer sl.ReleaseRef();

		Test.Assert(sl.Get(.Normal) != null);
		Test.Assert(sl.Get(.Hover) != null);
		Test.Assert(sl.Get(.Pressed) != null);
		Test.Assert(sl.Get(.Disabled) != null);
		Test.Assert(sl.Get(.Focused) != null);
	}

	// === StyleSelector ===

	[Test]
	public static void Selector_NullMatchesAnything()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sel = scope StyleSelector();
		let view = new TestView();
		root.AddView(view);

		Test.Assert(sel.Matches(view, .Normal));
		Test.Assert(sel.Matches(view, .Hover));
		Test.Assert(sel.Specificity == 0);
	}

	[Test]
	public static void Selector_Specificity_Computed()
	{
		let selType = scope StyleSelector();
		selType.ViewType = typeof(TestView);
		Test.Assert(selType.Specificity == 1);

		let selClass = scope StyleSelector();
		selClass.AddClass("primary");
		Test.Assert(selClass.Specificity == 10);

		let selState = scope StyleSelector();
		selState.State = .Hover;
		Test.Assert(selState.Specificity == 1);

		let selAll = scope StyleSelector();
		selAll.ViewType = typeof(TestView);
		selAll.AddClass("primary");
		selAll.State = .Hover;
		Test.Assert(selAll.Specificity == 12);
	}

	// === StyleValue accessors ===

	[Test]
	public static void StyleValue_ColorAccessor()
	{
		let val = StyleValue.ColorVal(.(255, 0, 0, 255));
		Test.Assert(val.AsColor != null);
		Test.Assert(val.AsFloat == null);
		Test.Assert(val.AsDrawable == null);
	}

	[Test]
	public static void StyleValue_FloatAccessor()
	{
		let val = StyleValue.FloatVal(42.0f);
		Test.Assert(val.AsFloat != null);
		Test.Assert(val.AsColor == null);
	}

	[Test]
	public static void StyleValue_None()
	{
		let val = StyleValue.None;
		Test.Assert(val.AsColor == null);
		Test.Assert(val.AsFloat == null);
		Test.Assert(val.AsThickness == null);
		Test.Assert(val.AsDrawable == null);
		Test.Assert(val.AsBool == null);
	}

	// === StyleRule ===

	[Test]
	public static void StyleRule_FluentSet()
	{
		let rule = scope StyleRule();
		rule.Set(.TextColor, Color.Red)
			.Set(.FontSize, 16.0f)
			.Set(.Padding, Thickness(4));

		Test.Assert(rule.PropertyCount == 3);
		Test.Assert(rule.GetValue(.TextColor) != null);
		Test.Assert(rule.GetValue(.FontSize) != null);
		Test.Assert(rule.GetValue(.Padding) != null);
		Test.Assert(rule.GetValue(.Background) == null);
	}

	// === StyleRule string-property lifecycle ===
	//
	// Set(prop, StringView) allocates a copy on capture, the destructor
	// frees it, overwriting frees the old one, and Remove frees on removal.

	[Test]
	public static void StringValue_RoundTrip()
	{
		let rule = scope StyleRule();
		rule.Set(.FontFamily, "Roboto");

		let v = rule.GetValue(.FontFamily);
		Test.Assert(v != null);
		Test.Assert(v.Value.AsString.HasValue);
		Test.Assert(v.Value.AsString.Value == "Roboto");
	}

	[Test]
	public static void StringValue_OverwriteFreesPrevious()
	{
		// Just exercise the overwrite path multiple times; the
		// destructor assertions are the leak guard.
		let rule = scope StyleRule();
		rule.Set(.FontFamily, "Roboto");
		rule.Set(.FontFamily, "JungleAdventurer");
		rule.Set(.FontFamily, "AttackOfMonster");

		Test.Assert(rule.GetValue(.FontFamily).Value.AsString.Value == "AttackOfMonster");
		// Each previous String would leak if overwrite didn't free.
	}

	[Test]
	public static void StringValue_RemoveFreesString()
	{
		let rule = scope StyleRule();
		rule.Set(.FontFamily, "Roboto");
		Test.Assert(rule.Remove(.FontFamily));
		Test.Assert(rule.GetValue(.FontFamily) == null);
	}

	[Test]
	public static void StringValue_DestructorFrees()
	{
		// Allocate many rules holding strings, drop them, the destructor
		// must free each. Beef leak detection (debug) catches misses.
		for (int i = 0; i < 16; i++)
		{
			let rule = new StyleRule();
			rule.Set(.FontFamily, "Roboto");
			rule.Set(.FontFamily, "JungleAdventurer");
			delete rule;
		}
	}

	// === ForAll() rule (empty selector) ===

	[Test]
	public static void ForAll_HasEmptySelector_SpecificityZero()
	{
		let sheet = new StyleSheet();
		defer sheet.ReleaseRef();
		let rule = sheet.ForAll();

		Test.Assert(rule.Selector.IsEmpty);
		Test.Assert(rule.Selector.Specificity == 0);
	}

	[Test]
	public static void ForAll_RuleMatchesEveryView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForAll().Set(.FontFamily, "JungleAdventurer");

		// Different view types - both match.
		let testView = new TestView();
		let testGroup = new TestGroup();
		root.AddView(testGroup);
		testGroup.AddView(testView);

		Test.Assert(testView.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
		Test.Assert(testGroup.ResolveStyle(.FontFamily).AsString.Value == "JungleAdventurer");
	}

	[Test]
	public static void ForAll_LosesSpecificityToTypedRule()
	{
		// A typed rule (specificity 1) beats ForAll (specificity 0)
		// when both define the same property on the same sheet.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForAll().Set(.FontFamily, "ForAllFamily");
		sheet.ForType(typeof(TestView)).Set(.FontFamily, "TestViewFamily");

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyle(.FontFamily).AsString.Value == "TestViewFamily");
	}
}
