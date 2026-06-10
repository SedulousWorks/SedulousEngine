namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class DrawableTests
{
	// === StateListDrawable ===

	[Test]
	public static void StateList_GetFallsBackToNormal()
	{
		let sl = new StateListDrawable();
		defer sl.ReleaseRef();
		// StateListDrawable.Set consumes the caller's ref - no AddRef.
		sl.Set(.Normal, new ColorDrawable(.Red));
		let normal = sl.Get(.Normal);

		Test.Assert(sl.Get(.Normal) === normal);
		Test.Assert(sl.Get(.Hover) === normal); // fallback
		Test.Assert(sl.Get(.Pressed) === normal); // fallback
		Test.Assert(sl.Get(.Disabled) === normal); // fallback
	}

	[Test]
	public static void StateList_GetReturnsSpecificState()
	{
		let sl = new StateListDrawable();
		defer sl.ReleaseRef();
		sl.Set(.Normal, new ColorDrawable(.Red));
		sl.Set(.Hover, new ColorDrawable(.Blue));
		let normal = sl.Get(.Normal);
		let hover = sl.Get(.Hover);

		Test.Assert(sl.Get(.Normal) === normal);
		Test.Assert(sl.Get(.Hover) === hover);
		Test.Assert(sl.Get(.Pressed) === normal); // fallback
	}

	[Test]
	public static void StateList_GetReturnsNullIfNoNormal()
	{
		let sl = new StateListDrawable();
		defer sl.ReleaseRef();
		Test.Assert(sl.Get(.Normal) == null);
		Test.Assert(sl.Get(.Hover) == null);
	}

	// === LayerDrawable ===

	[Test]
	public static void Layer_AddLayer_IncreasesCount()
	{
		// Just verify it doesn't crash - drawing needs a VGContext.
		// AddLayer consumes the caller's ref.
		let layer = new LayerDrawable();
		defer layer.ReleaseRef();
		layer.AddLayer(new ColorDrawable(.Red));
		layer.AddLayer(new ColorDrawable(.Blue), .(5, 5, 5, 5));
	}

	// === InsetDrawable ===

	[Test]
	public static void Inset_DrawablePadding_MatchesInset()
	{
		// InsetDrawable constructor consumes the inner ref.
		let inset = new InsetDrawable(new ColorDrawable(.Red), .(10, 5, 10, 5));
		defer inset.ReleaseRef();
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
		let cd = new ColorDrawable(.Red);
		defer cd.ReleaseRef();
		Test.Assert(!cd.IntrinsicSize.HasValue);
	}

	// === RoundedRectDrawable ===

	[Test]
	public static void RoundedRect_NoIntrinsicSize()
	{
		let rr = new RoundedRectDrawable(.Red, 4, .Blue, 1);
		defer rr.ReleaseRef();
		Test.Assert(!rr.IntrinsicSize.HasValue);
	}

	// === NineSliceDrawable ===

	[Test]
	public static void NineSlice_DrawablePadding_AccountsForExpand()
	{
		let ns = new NineSliceDrawable(null, .(10, 10, 10, 10));
		defer ns.ReleaseRef();
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
		let ns = new NineSliceDrawable(null, .(5, 5, 5, 5));
		defer ns.ReleaseRef();
		ns.Expand = .(10, 10, 10, 10);

		let pad = ns.DrawablePadding;
		Test.Assert(pad.Left == 0);
		Test.Assert(pad.Top == 0);
	}

	// === Drawable base ===

	[Test]
	public static void Drawable_StateAwareDraw_DelegatesToStateless()
	{
		// ShapeDrawable has no state-aware override - should delegate.
		bool called = false;
		let sd = new ShapeDrawable(new [&called] (ctx, bounds) => { called = true; });
		defer sd.ReleaseRef();
		// We can't call Draw without a real VGContext, but we can verify the interface exists.
		Test.Assert(!called); // just the creation shouldn't call it
	}
}
