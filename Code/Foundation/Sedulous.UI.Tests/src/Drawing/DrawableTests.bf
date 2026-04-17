namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class DrawableTests
{
	[Test]
	public static void StateListDrawable_FallbackToNormal()
	{
		let sld = scope StateListDrawable(false);
		let normalDrawable = scope ColorDrawable(.(255, 0, 0, 255));
		sld.Set(.Normal, normalDrawable);

		// Requesting Hover with no Hover set -> falls back to Normal.
		let result = sld.Get(.Hover);
		Test.Assert(result === normalDrawable);
	}

	[Test]
	public static void StateListDrawable_ExplicitStateReturned()
	{
		let sld = scope StateListDrawable(false);
		let normalDrawable = scope ColorDrawable(.(255, 0, 0, 255));
		let hoverDrawable = scope ColorDrawable(.(0, 255, 0, 255));
		sld.Set(.Normal, normalDrawable);
		sld.Set(.Hover, hoverDrawable);

		let result = sld.Get(.Hover);
		Test.Assert(result === hoverDrawable);
	}

	[Test]
	public static void StateListDrawable_AllStatesIndependent()
	{
		let sld = scope StateListDrawable(false);
		let d0 = scope ColorDrawable(.Red);
		let d1 = scope ColorDrawable(.Green);
		let d2 = scope ColorDrawable(.Blue);
		let d3 = scope ColorDrawable(.White);
		let d4 = scope ColorDrawable(.Black);
		sld.Set(.Normal, d0);
		sld.Set(.Hover, d1);
		sld.Set(.Pressed, d2);
		sld.Set(.Focused, d3);
		sld.Set(.Disabled, d4);

		Test.Assert(sld.Get(.Normal) === d0);
		Test.Assert(sld.Get(.Hover) === d1);
		Test.Assert(sld.Get(.Pressed) === d2);
		Test.Assert(sld.Get(.Focused) === d3);
		Test.Assert(sld.Get(.Disabled) === d4);
	}

	[Test]
	public static void InsetDrawable_ReportsDrawablePadding()
	{
		let inset = scope InsetDrawable(null, .(10, 5, 10, 5));

		let pad = inset.DrawablePadding;
		Test.Assert(pad.Left == 10);
		Test.Assert(pad.Top == 5);
		Test.Assert(pad.Right == 10);
		Test.Assert(pad.Bottom == 5);
	}

	[Test]
	public static void NineSliceDrawable_DrawablePadding_WithExpand()
	{
		let nsd = scope NineSliceDrawable(null, .(8, 8, 8, 8));
		nsd.Expand = .(4, 4, 4, 4);

		let pad = nsd.DrawablePadding;
		// DrawablePadding = max(0, Slices - Expand) per side.
		Test.Assert(pad.Left == 4);   // 8 - 4
		Test.Assert(pad.Top == 4);
		Test.Assert(pad.Right == 4);
		Test.Assert(pad.Bottom == 4);
	}

	[Test]
	public static void NineSliceDrawable_DrawablePadding_NoExpand()
	{
		let nsd = scope NineSliceDrawable(null, .(12, 8, 12, 8));

		let pad = nsd.DrawablePadding;
		Test.Assert(pad.Left == 12);
		Test.Assert(pad.Top == 8);
		Test.Assert(pad.Right == 12);
		Test.Assert(pad.Bottom == 8);
	}
}
