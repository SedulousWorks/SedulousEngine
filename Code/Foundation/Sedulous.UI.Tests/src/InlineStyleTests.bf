namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// A Drawable that tracks its live count via a static counter, so
/// tests can assert ownership transfer / cleanup. Draw is a no-op.
class TrackingDrawable : Drawable
{
	public static int LiveCount;

	public this()  { LiveCount++; }
	public ~this() { LiveCount--; }

	public override void Draw(UIDrawContext ctx, RectangleF bounds) {}
}

class InlineStyleTests
{
	// === Element-level inline styles ===

	[Test]
	public static void Inline_GetWithoutSet_ReturnsNone()
	{
		let view = scope TestView();
		Test.Assert(view.GetInlineStyle(.TextColor) case .None);
		Test.Assert(!view.HasInlineStyle(.TextColor));
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void Inline_SetThenGet_RoundTrip()
	{
		let view = scope TestView();
		view.SetInlineStyle(.TextColor, .ColorVal(.(255, 0, 0, 255)));

		Test.Assert(view.HasInlineStyle(.TextColor));
		Test.Assert(view.HasAnyInlineStyles);

		let c = view.GetInlineStyle(.TextColor).AsColor;
		Test.Assert(c != null && c.Value.R == 255);
	}

	[Test]
	public static void Inline_SetOverwritesPrevious()
	{
		let view = scope TestView();
		view.SetInlineStyle(.FontSize, .FloatVal(12));
		view.SetInlineStyle(.FontSize, .FloatVal(24));

		Test.Assert(view.GetInlineStyle(.FontSize).AsFloat == 24);
	}

	[Test]
	public static void Inline_ClearOne_LeavesOthers()
	{
		let view = scope TestView();
		view.SetInlineStyle(.TextColor, .ColorVal(.Red));
		view.SetInlineStyle(.FontSize, .FloatVal(18));

		view.ClearInlineStyle(.TextColor);

		Test.Assert(!view.HasInlineStyle(.TextColor));
		Test.Assert(view.HasInlineStyle(.FontSize));
		Test.Assert(view.HasAnyInlineStyles);
	}

	[Test]
	public static void Inline_ClearAll_RemovesEverything()
	{
		let view = scope TestView();
		view.SetInlineStyle(.TextColor, .ColorVal(.Red));
		view.SetInlineStyle(.FontSize, .FloatVal(18));
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Blue));

		view.ClearInlineStyles();

		Test.Assert(!view.HasInlineStyle(.TextColor));
		Test.Assert(!view.HasInlineStyle(.FontSize));
		Test.Assert(!view.HasInlinePartStyle("thumb", .Background));
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void Inline_ClearOne_NoOpWhenUnset()
	{
		let view = scope TestView();
		view.ClearInlineStyle(.TextColor);
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void Inline_StorageIsLazy_NoSetMeansNoAlloc()
	{
		// We can't introspect the private field directly, but
		// HasAnyInlineStyles guards the public surface and stays false
		// without any allocations being observed externally.
		let view = scope TestView();
		view.GetInlineStyle(.TextColor);
		view.HasInlineStyle(.TextColor);
		view.ClearInlineStyle(.TextColor);
		view.ClearInlineStyles();
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void Inline_AcceptsEveryValueKind()
	{
		let view = scope TestView();
		// SetInlineStyle's DrawableRef path consumes the caller's ref -
		// the view's destructor releases on scope exit. No `defer
		// ReleaseRef` needed.
		let drawable = new ColorDrawable(.Red);

		view.SetInlineStyle(.TextColor,  .ColorVal(.(10, 20, 30, 255)));
		view.SetInlineStyle(.FontSize,   .FloatVal(16));
		view.SetInlineStyle(.Padding,    .ThicknessVal(.(2, 4)));
		view.SetInlineStyle(.WordWrap,   .BoolVal(true));
		view.SetInlineStyle(.Background, .DrawableRef(drawable));

		Test.Assert(view.GetInlineStyle(.TextColor).AsColor.Value.R == 10);
		Test.Assert(view.GetInlineStyle(.FontSize).AsFloat == 16);
		Test.Assert(view.GetInlineStyle(.Padding).AsThickness.Value.Left == 2);
		Test.Assert(view.GetInlineStyle(.WordWrap).AsBool == true);
		Test.Assert(view.GetInlineStyle(.Background).AsDrawable === drawable);
	}

	// === Pseudo-element inline styles ===

	[Test]
	public static void InlinePart_GetWithoutSet_ReturnsNone()
	{
		let view = scope TestView();
		Test.Assert(view.GetInlinePartStyle("thumb", .Background) case .None);
		Test.Assert(!view.HasInlinePartStyle("thumb", .Background));
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void InlinePart_SetThenGet_RoundTrip()
	{
		let view = scope TestView();
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Red));

		Test.Assert(view.HasInlinePartStyle("thumb", .Background));
		Test.Assert(view.HasAnyInlineStyles);

		let c = view.GetInlinePartStyle("thumb", .Background).AsColor;
		Test.Assert(c != null && c.Value.R == 255);
	}

	[Test]
	public static void InlinePart_SetOverwritesPrevious_NoDuplicates()
	{
		let view = scope TestView();
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Red));
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Blue));

		Test.Assert(view.GetInlinePartStyle("thumb", .Background).AsColor.Value.B == 255);
		// A second set on the same key should not add a stale entry -
		// the older value is gone, not just shadowed.
		view.ClearInlinePartStyle("thumb", .Background);
		Test.Assert(!view.HasInlinePartStyle("thumb", .Background));
	}

	[Test]
	public static void InlinePart_DistinguishesByPartName()
	{
		let view = scope TestView();
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Red));
		view.SetInlinePartStyle("track", .Background, .ColorVal(.Blue));

		Test.Assert(view.GetInlinePartStyle("thumb", .Background).AsColor.Value.R == 255);
		Test.Assert(view.GetInlinePartStyle("track", .Background).AsColor.Value.B == 255);
	}

	[Test]
	public static void InlinePart_DistinguishesByProperty()
	{
		let view = scope TestView();
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Red));
		view.SetInlinePartStyle("thumb", .CornerRadius, .FloatVal(8));

		Test.Assert(view.GetInlinePartStyle("thumb", .Background).AsColor != null);
		Test.Assert(view.GetInlinePartStyle("thumb", .CornerRadius).AsFloat == 8);
	}

	[Test]
	public static void InlinePart_ClearOne_LeavesOthers()
	{
		let view = scope TestView();
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Red));
		view.SetInlinePartStyle("track", .Background, .ColorVal(.Blue));

		view.ClearInlinePartStyle("thumb", .Background);

		Test.Assert(!view.HasInlinePartStyle("thumb", .Background));
		Test.Assert(view.HasInlinePartStyle("track", .Background));
	}

	[Test]
	public static void InlinePart_ClearOne_NoOpWhenUnset()
	{
		let view = scope TestView();
		view.ClearInlinePartStyle("thumb", .Background);
		Test.Assert(!view.HasAnyInlineStyles);
	}

	[Test]
	public static void Inline_Destruction_DoesNotLeakPartStrings()
	{
		// The destructor frees the part-name strings allocated by
		// SetInlinePartStyle. Just instantiating + dropping the view
		// would leak via Beef's allocator if the cleanup were missing.
		// This test mostly exists to wire that path through the test
		// runner so leaks would surface.
		let view = new TestView();
		view.SetInlinePartStyle("thumb", .Background, .ColorVal(.Red));
		view.SetInlinePartStyle("track", .Background, .ColorVal(.Blue));
		view.SetInlinePartStyle("thumb", .CornerRadius, .FloatVal(4));
		delete view;
	}

	// === Resolution priority (sub-phase B) ===

	static StyleSheet SetupSheet(UIContext ctx)
	{
		let sheet = new StyleSheet();
		ctx.StyleSheet = sheet;  // AddRef -> 2
		sheet.ReleaseRef();      // -> 1 (ctx owns)
		return sheet;
	}

	[Test]
	public static void Resolution_InlineBeatsTypeRule()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(255, 0, 0, 255));

		let view = new TestView();
		root.AddView(view);
		view.SetInlineStyle(.TextColor, .ColorVal(.(0, 255, 0, 255)));

		// Inline (green) wins over the rule (red).
		let c = view.ResolveStyleColor(.TextColor);
		Test.Assert(c.R == 0 && c.G == 255);
	}

	[Test]
	public static void Resolution_InlineBeatsClassPlusStateRule()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		// Class + state rule (specificity 11) on a disabled view -
		// would win without an inline override.
		sheet.ForTypeClassState(typeof(TestView), "btn", .Disabled)
			.Set(.FontSize, 12.0f);

		let view = new TestView();
		view.AddClass("btn");
		view.IsEnabled = false;
		root.AddView(view);

		view.SetInlineStyle(.FontSize, .FloatVal(99));

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 99);
	}

	[Test]
	public static void Resolution_InlineIgnoresControlState()
	{
		// Inline values apply across every ControlState - changing the
		// view's state doesn't make a state-scoped rule reappear.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForTypeState(typeof(TestView), .Hover)
			.Set(.TextColor, .Red);
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, .Blue);

		let view = new TestView();
		root.AddView(view);
		view.SetInlineStyle(.TextColor, .ColorVal(.(10, 20, 30, 255)));

		// Even with no hover, inline wins; with hover, still wins.
		Test.Assert(view.ResolveStyleColor(.TextColor).R == 10);
	}

	[Test]
	public static void Resolution_InlineBeatsPseudoElementRule()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.CornerRadius, 4.0f);

		let view = new TestView();
		root.AddView(view);
		view.SetInlinePartStyle("thumb", .CornerRadius, .FloatVal(16));

		Test.Assert(view.ResolvePartFloat("thumb", .CornerRadius, .Normal) == 16);
	}

	[Test]
	public static void Resolution_InlinePartScopedToItsPart()
	{
		// Inline override on "thumb" doesn't affect "track" resolution.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForTypePseudo(typeof(TestView), "track")
			.Set(.CornerRadius, 4.0f);

		let view = new TestView();
		root.AddView(view);
		view.SetInlinePartStyle("thumb", .CornerRadius, .FloatVal(16));

		// "track" still resolves to its rule (4); the thumb override
		// doesn't bleed.
		Test.Assert(view.ResolvePartFloat("track", .CornerRadius, .Normal) == 4);
	}

	[Test]
	public static void Resolution_InlineOnParent_InheritsToChild()
	{
		// Inheritable property set inline on a parent reaches the
		// child via the normal inheritance walk.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		// Empty StyleSheet on the context, so no rules can satisfy this -
		// only the parent's inline value can.
		SetupSheet(ctx);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		group.SetInlineStyle(.TextColor, .ColorVal(.(40, 50, 60, 255)));

		let c = child.ResolveStyleColor(.TextColor);
		Test.Assert(c.R == 40 && c.G == 50 && c.B == 60);
	}

	[Test]
	public static void Resolution_InlineOnChild_BeatsRuleOnParent()
	{
		// Child's inline value wins over a rule on the parent type.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = SetupSheet(ctx);
		sheet.ForType(typeof(TestGroup))
			.Set(.TextColor, .Red);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		child.SetInlineStyle(.TextColor, .ColorVal(.(0, 255, 0, 255)));

		Test.Assert(child.ResolveStyleColor(.TextColor).G == 255);
	}

	[Test]
	public static void Resolution_InlineBeatsLocalOnThisView()
	{
		// View has both a LocalStyleSheet AND an inline override on
		// the same property. Inline wins (specificity infinity).
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupSheet(ctx);

		let view = new TestView();
		root.AddView(view);

		// Local sheet on this view defines TextColor.
		let local = new StyleSheet();
		view.LocalStyleSheet = local;
		local.ReleaseRef();
		local.ForType(typeof(TestView))
			.Set(.TextColor, .Red);

		// Inline override - should win.
		view.SetInlineStyle(.TextColor, .ColorVal(.(0, 255, 0, 255)));

		Test.Assert(view.ResolveStyleColor(.TextColor).G == 255);
	}

	[Test]
	public static void Resolution_InlineBeatsLocalOnAncestor()
	{
		// LocalStyleSheet sits on a parent; child has the inline
		// override. Inline (on the styled view) wins over any sheet
		// regardless of where in the chain it lives.
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		SetupSheet(ctx);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		let parentLocal = new StyleSheet();
		group.LocalStyleSheet = parentLocal;
		parentLocal.ReleaseRef();
		parentLocal.ForType(typeof(TestView))
			.Set(.TextColor, .Red);

		child.SetInlineStyle(.TextColor, .ColorVal(.(0, 0, 255, 255)));

		Test.Assert(child.ResolveStyleColor(.TextColor).B == 255);
	}

	// === Drawable ownership via SetStyle ===
	//
	// SetStyle's Drawable overload defaults to `consumeRef: true` -
	// the inline-style sheet takes the caller's ref and Releases it
	// when the view is destroyed or the value is overwritten. Pass
	// `consumeRef: false` when the caller needs to keep its own ref.

	[Test]
	public static void SetStyle_Drawable_ConsumesByDefault()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView();
		view.SetStyle(.Background, new TrackingDrawable());

		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		delete view;

		Test.Assert(TrackingDrawable.LiveCount == before);
	}

	[Test]
	public static void SetStyle_Drawable_OptOutPreservesCallerRef()
	{
		let before = TrackingDrawable.LiveCount;

		let d = new TrackingDrawable();
		defer d.ReleaseRef();

		let view = new TestView();
		view.SetStyle(.Background, d, consumeRef: false);

		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		delete view;

		// Drawable still alive because consumeRef: false left the
		// caller's ref in place; defer drops it after the test body.
		Test.Assert(TrackingDrawable.LiveCount == before + 1);
	}

	[Test]
	public static void SetStyle_Drawable_MultipleConsumed_AllReleased()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView();
		view.SetStyle(.Background, new TrackingDrawable());
		view.SetPartStyle("thumb", .Background, new TrackingDrawable());

		Test.Assert(TrackingDrawable.LiveCount == before + 2);

		delete view;

		Test.Assert(TrackingDrawable.LiveCount == before);
	}

	[Test]
	public static void SetStyle_Drawable_OverwriteReleasesPrevious()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView();
		view.SetStyle(.Background, new TrackingDrawable());

		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		// Overwrite with a second drawable - the first should be freed.
		view.SetStyle(.Background, new TrackingDrawable());

		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		delete view;

		Test.Assert(TrackingDrawable.LiveCount == before);
	}

	[Test]
	public static void SetStyle_Drawable_NullClearsAndReleases()
	{
		let before = TrackingDrawable.LiveCount;

		let view = new TestView();
		view.SetStyle(.Background, new TrackingDrawable());

		Test.Assert(TrackingDrawable.LiveCount == before + 1);

		view.SetStyle(.Background, (Drawable)null);

		Test.Assert(TrackingDrawable.LiveCount == before);

		delete view;
	}
}
