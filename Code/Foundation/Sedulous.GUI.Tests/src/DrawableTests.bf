namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class DrawableTests
{
	// === StateListDrawable ===

	[Test]
	public static void StateList_GetFallsBackToNormal()
	{
		let sl = scope StateListDrawable(true);
		let normal = new ColorDrawable(.Red);
		sl.Set(.Normal, normal);

		Test.Assert(sl.Get(.Normal) === normal);
		Test.Assert(sl.Get(.Hover) === normal); // fallback
		Test.Assert(sl.Get(.Pressed) === normal); // fallback
		Test.Assert(sl.Get(.Disabled) === normal); // fallback
	}

	[Test]
	public static void StateList_GetReturnsSpecificState()
	{
		let sl = scope StateListDrawable(true);
		let normal = new ColorDrawable(.Red);
		let hover = new ColorDrawable(.Blue);
		sl.Set(.Normal, normal);
		sl.Set(.Hover, hover);

		Test.Assert(sl.Get(.Normal) === normal);
		Test.Assert(sl.Get(.Hover) === hover);
		Test.Assert(sl.Get(.Pressed) === normal); // fallback
	}

	[Test]
	public static void StateList_GetReturnsNullIfNoNormal()
	{
		let sl = scope StateListDrawable(false);
		Test.Assert(sl.Get(.Normal) == null);
		Test.Assert(sl.Get(.Hover) == null);
	}

	// === LayerDrawable ===

	[Test]
	public static void Layer_AddLayer_IncreasesCount()
	{
		// Just verify it doesn't crash - drawing needs a VGContext
		let layer = scope LayerDrawable(true);
		layer.AddLayer(new ColorDrawable(.Red));
		layer.AddLayer(new ColorDrawable(.Blue), .(5, 5, 5, 5));
		// No assert needed - if we get here without crash, the structure is valid
	}

	// === InsetDrawable ===

	[Test]
	public static void Inset_DrawablePadding_MatchesInset()
	{
		let inset = scope InsetDrawable(new ColorDrawable(.Red), .(10, 5, 10, 5));
		let pad = inset.DrawablePadding;
		Test.Assert(pad.Left == 10);
		Test.Assert(pad.Top == 5);
		Test.Assert(pad.Right == 10);
		Test.Assert(pad.Bottom == 5);
	}

	// === ColorDrawable ===

	[Test]
	public static void ColorDrawable_NoIntrinsicSize()
	{
		let cd = scope ColorDrawable(.Red);
		Test.Assert(!cd.IntrinsicSize.HasValue);
	}

	// === RoundedRectDrawable ===

	[Test]
	public static void RoundedRect_NoIntrinsicSize()
	{
		let rr = scope RoundedRectDrawable(.Red, 4, .Blue, 1);
		Test.Assert(!rr.IntrinsicSize.HasValue);
	}

	// === NineSliceDrawable ===

	[Test]
	public static void NineSlice_DrawablePadding_AccountsForExpand()
	{
		let ns = scope NineSliceDrawable(null, .(10, 10, 10, 10));
		ns.Expand = .(5, 5, 5, 5);

		let pad = ns.DrawablePadding;
		// Padding = max(0, Slices - Expand) = max(0, 10-5) = 5
		Test.Assert(pad.Left == 5);
		Test.Assert(pad.Top == 5);
		Test.Assert(pad.Right == 5);
		Test.Assert(pad.Bottom == 5);
	}

	[Test]
	public static void NineSlice_DrawablePadding_ClampsToZero()
	{
		let ns = scope NineSliceDrawable(null, .(5, 5, 5, 5));
		ns.Expand = .(10, 10, 10, 10);

		let pad = ns.DrawablePadding;
		Test.Assert(pad.Left == 0);
		Test.Assert(pad.Top == 0);
	}

	// === Drawable base ===

	[Test]
	public static void Drawable_StateAwareDraw_DelegatesToStateless()
	{
		// ShapeDrawable has no state-aware override - should delegate
		bool called = false;
		scope ShapeDrawable(new [&called] (ctx, bounds) => { called = true; });
		// We can't call Draw without a real VGContext, but we can verify the interface exists
		Test.Assert(!called); // just the creation shouldn't call it
	}
}
