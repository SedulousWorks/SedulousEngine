namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Sub-phase E: lifecycle of `View.LocalStyleSheet`. Resolution
/// wiring (ancestor walk + context fallback) lands in sub-phase F and
/// gets its own tests there.
class LocalStyleSheetTests
{
	[Test]
	public static void Default_IsNull()
	{
		let view = scope TestView();
		Test.Assert(view.LocalStyleSheet == null);
	}

	[Test]
	public static void Set_AddRefsAndRetains()
	{
		let sheet = new StyleSheet();
		defer sheet.ReleaseRef();
		// sheet starts at rc=1 (creator ref).

		let view = new TestView();
		view.LocalStyleSheet = sheet;
		// Setter AddRef'd -> rc=2 (creator + view).

		Test.Assert(view.LocalStyleSheet === sheet);

		delete view;
		// View destructor released view's ref -> rc=1.
		// `defer sheet.ReleaseRef()` reaches rc=0 -> freed.
	}

	[Test]
	public static void Set_Twice_NoOpForIdentical()
	{
		let sheet = new StyleSheet();
		defer sheet.ReleaseRef();

		let view = scope TestView();
		view.LocalStyleSheet = sheet;
		view.LocalStyleSheet = sheet;
		// Two assignments to the same sheet must not over-AddRef. If
		// the setter weren't guarded, the second AddRef would leave the
		// sheet at rc=3 with no matching Release path, and the test
		// would assert at scope-exit.

		Test.Assert(view.LocalStyleSheet === sheet);
	}

	[Test]
	public static void Reassign_ReleasesPrevious()
	{
		let s1 = new StyleSheet();
		let s2 = new StyleSheet();

		let view = new TestView();
		view.LocalStyleSheet = s1; // s1 rc=2
		view.LocalStyleSheet = s2; // s1 rc=1, s2 rc=2

		Test.Assert(view.LocalStyleSheet === s2);

		s1.ReleaseRef();           // s1 rc=0 -> freed
		s2.ReleaseRef();           // s2 rc=1

		delete view;               // s2 rc=0 -> freed
	}

	[Test]
	public static void Clear_ReleasesAndFallsBackToNull()
	{
		let sheet = new StyleSheet();

		let view = scope TestView();
		view.LocalStyleSheet = sheet; // rc=2
		view.LocalStyleSheet = null;  // rc=1 (view released)

		Test.Assert(view.LocalStyleSheet == null);

		sheet.ReleaseRef(); // rc=0 -> freed
	}

	[Test]
	public static void Destruction_ReleasesSheet()
	{
		let sheet = new StyleSheet();
		// sheet rc=1.

		let view = new TestView();
		view.LocalStyleSheet = sheet; // rc=2

		delete view;                  // view destructor releases -> rc=1

		sheet.ReleaseRef();           // rc=0 -> freed (assert in
		                              // RefCounted dtor would fire if
		                              // view didn't release.)
	}

	[Test]
	public static void SharedBetweenViews()
	{
		let sheet = new StyleSheet();

		let v1 = new TestView();
		let v2 = new TestView();
		v1.LocalStyleSheet = sheet; // rc=2
		v2.LocalStyleSheet = sheet; // rc=3

		Test.Assert(v1.LocalStyleSheet === sheet);
		Test.Assert(v2.LocalStyleSheet === sheet);

		delete v1;                   // rc=2
		delete v2;                   // rc=1

		sheet.ReleaseRef();          // rc=0 -> freed
	}

	// === Resolution-order tests (sub-phase F) ===

	/// Helper: install a fresh empty StyleSheet on `ctx`, return it.
	/// Caller's ref is consumed.
	static StyleSheet SetupCtxSheet(UIContext ctx)
	{
		let s = new StyleSheet();
		ctx.StyleSheet = s;   // AddRef -> 2
		s.ReleaseRef();        // -> 1 (ctx owns)
		return s;
	}

	/// Helper: attach a fresh empty StyleSheet to `view` as its local
	/// sheet, return it. Caller's ref is consumed.
	static StyleSheet SetupLocalSheet(View view)
	{
		let s = new StyleSheet();
		view.LocalStyleSheet = s; // AddRef -> 2
		s.ReleaseRef();            // -> 1 (view owns)
		return s;
	}

	[Test]
	public static void Resolution_LocalOnThisView_WinsOverContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let ctxSheet = SetupCtxSheet(ctx);
		ctxSheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(255, 0, 0, 255));

		let view = new TestView();
		root.AddView(view);
		let local = SetupLocalSheet(view);
		local.ForType(typeof(TestView))
			.Set(.TextColor, Color(0, 255, 0, 255));

		// View's own local sheet wins over context.
		let c = view.ResolveStyleColor(.TextColor);
		Test.Assert(c.G == 255 && c.R == 0);
	}

	[Test]
	public static void Resolution_LocalOnAncestor_WinsOverContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let ctxSheet = SetupCtxSheet(ctx);
		ctxSheet.ForType(typeof(TestView))
			.Set(.TextColor, .Red);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		// LocalStyleSheet on the parent group applies to descendants.
		let parentLocal = SetupLocalSheet(group);
		parentLocal.ForType(typeof(TestView))
			.Set(.TextColor, Color(50, 200, 50, 255));

		Test.Assert(child.ResolveStyleColor(.TextColor).G == 200);
	}

	[Test]
	public static void Resolution_CloserAncestor_WinsOverFarther()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupCtxSheet(ctx);

		let outer = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView();
		root.AddView(outer);
		outer.AddView(inner);
		inner.AddView(child);

		let outerLocal = SetupLocalSheet(outer);
		outerLocal.ForType(typeof(TestView)).Set(.TextColor, .Red);

		let innerLocal = SetupLocalSheet(inner);
		innerLocal.ForType(typeof(TestView)).Set(.TextColor, Color(0, 0, 255, 255));

		// Inner (closer) wins.
		Test.Assert(child.ResolveStyleColor(.TextColor).B == 255);
	}

	[Test]
	public static void Resolution_NotFound_FallsThroughToNextAncestor()
	{
		// Closer ancestor's local sheet has NO rule for the queried
		// property. Resolution must skip to the next ancestor (option a
		// semantics from the design doc).
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupCtxSheet(ctx);

		let outer = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView();
		root.AddView(outer);
		outer.AddView(inner);
		inner.AddView(child);

		// Outer defines TextColor; inner defines a different property.
		let outerLocal = SetupLocalSheet(outer);
		outerLocal.ForType(typeof(TestView)).Set(.TextColor, Color(0, 200, 0, 255));

		let innerLocal = SetupLocalSheet(inner);
		innerLocal.ForType(typeof(TestView)).Set(.FontSize, 24f);

		// Inner doesn't define TextColor - fall through to outer.
		Test.Assert(child.ResolveStyleColor(.TextColor).G == 200);
		Test.Assert(child.ResolveStyleFloat(.FontSize) == 24f);
	}

	[Test]
	public static void Resolution_NotFound_FallsThroughToContext()
	{
		// No ancestor defines the property - fall all the way through
		// to the context sheet.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let ctxSheet = SetupCtxSheet(ctx);
		ctxSheet.ForType(typeof(TestView)).Set(.TextColor, Color(100, 100, 100, 255));

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		// Local sheets exist but define unrelated props.
		let groupLocal = SetupLocalSheet(group);
		groupLocal.ForType(typeof(TestView)).Set(.FontSize, 18f);

		Test.Assert(child.ResolveStyleColor(.TextColor).R == 100);
	}

	[Test]
	public static void Resolution_InheritableProperty_CascadesThroughLocalOnAncestor()
	{
		// TextColor is inheritable. A rule declared in a Dialog-like
		// ancestor's LocalStyleSheet should reach a descendant Label
		// that has no direct rule for itself.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupCtxSheet(ctx);

		let dialog = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView();
		root.AddView(dialog);
		dialog.AddView(inner);
		inner.AddView(child);

		// Dialog's local sheet sets TextColor on the GROUP type -
		// matches `dialog` and `inner` (both TestGroups), not the
		// child TestView.
		let dialogLocal = SetupLocalSheet(dialog);
		dialogLocal.ForType(typeof(TestGroup))
			.Set(.TextColor, Color(50, 150, 250, 255));

		// child's ResolveStyle:
		//  1. child's inline / locals - nothing
		//  2. dialog's local: TestView doesn't match
		//  3. context sheet: empty
		//  4. inheritance recursion to inner -> matches via inner's
		//     ResolveStyle which finds dialog's TextColor for TestGroup
		Test.Assert(child.ResolveStyleColor(.TextColor).B == 250);
	}

	[Test]
	public static void Resolution_NonInheritable_DoesNotCascade()
	{
		// Background is NOT inheritable. A rule declared in a
		// LocalStyleSheet on an ancestor that matches the ancestor
		// must NOT leak down to a descendant of a different type.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupCtxSheet(ctx);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		let groupLocal = SetupLocalSheet(group);
		groupLocal.ForType(typeof(TestGroup))
			.Set(.Padding, Thickness(8));

		// Padding isn't inheritable; child doesn't see the group's value.
		Test.Assert(child.ResolveStyleThickness(.Padding).IsZero);
	}

	// === Pseudo-element resolution (sub-phase G) ===

	[Test]
	public static void Pseudo_LocalOnThisView_WinsOverContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let ctxSheet = SetupCtxSheet(ctx);
		ctxSheet.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 4f);

		let view = new TestView();
		root.AddView(view);

		let local = SetupLocalSheet(view);
		local.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 12f);

		Test.Assert(view.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 12f);
	}

	[Test]
	public static void Pseudo_LocalOnAncestor_WinsOverContext()
	{
		// `Slider::thumb` overridden via a LocalStyleSheet on the
		// scene's root, applied to a TestView descendant - the doc's
		// "Slider::thumb via ancestor's local sheet" case.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let ctxSheet = SetupCtxSheet(ctx);
		ctxSheet.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 2f);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		let parentLocal = SetupLocalSheet(group);
		parentLocal.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 16f);

		Test.Assert(child.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 16f);
	}

	[Test]
	public static void Pseudo_CloserAncestor_WinsOverFarther()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupCtxSheet(ctx);

		let outer = new TestGroup();
		let inner = new TestGroup();
		let child = new TestView();
		root.AddView(outer);
		outer.AddView(inner);
		inner.AddView(child);

		let outerLocal = SetupLocalSheet(outer);
		outerLocal.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 4f);

		let innerLocal = SetupLocalSheet(inner);
		innerLocal.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 10f);

		Test.Assert(child.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 10f);
	}

	[Test]
	public static void Pseudo_InlineBeatsLocalOnThisView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupCtxSheet(ctx);

		let view = new TestView();
		root.AddView(view);

		let local = SetupLocalSheet(view);
		local.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 4f);

		// Inline part override - should win.
		view.SetInlinePartStyle("thumb", .CornerRadius, .FloatVal(20f));

		Test.Assert(view.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 20f);
	}

	[Test]
	public static void Pseudo_InlineBeatsLocalOnAncestor()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupCtxSheet(ctx);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		let parentLocal = SetupLocalSheet(group);
		parentLocal.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 4f);

		child.SetInlinePartStyle("thumb", .CornerRadius, .FloatVal(22f));

		Test.Assert(child.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 22f);
	}

	[Test]
	public static void Pseudo_NotFound_FallsThroughToContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let ctxSheet = SetupCtxSheet(ctx);
		ctxSheet.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 7f);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		// Local sheet exists but defines pseudo-element for a
		// different part name, so it doesn't match.
		let parentLocal = SetupLocalSheet(group);
		parentLocal.ForTypePseudo(typeof(TestView), "track")
			.Set(.CornerRadius, 99f);

		Test.Assert(child.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 7f);
	}
}
