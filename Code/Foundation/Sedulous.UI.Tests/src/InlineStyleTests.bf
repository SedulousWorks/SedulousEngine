namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

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
		let drawable = scope ColorDrawable(.Red);

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
}
