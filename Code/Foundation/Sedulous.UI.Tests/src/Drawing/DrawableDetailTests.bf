namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Detailed drawable tests.
class DrawableDetailTests
{
	// === ColorDrawable ===

	[Test]
	public static void ColorDrawable_StoresColor()
	{
		let d = scope ColorDrawable(.(255, 0, 0, 255));
		Test.Assert(d.Color.R == 255);
		Test.Assert(d.Color.G == 0);
	}

	[Test]
	public static void ColorDrawable_IntrinsicSizeNull()
	{
		let d = scope ColorDrawable(.White);
		Test.Assert(!d.IntrinsicSize.HasValue);
	}

	// === RoundedRectDrawable ===

	[Test]
	public static void RoundedRectDrawable_Properties()
	{
		let d = scope RoundedRectDrawable(.(100, 100, 100, 255), 8, .(200, 200, 200, 255), 2);
		Test.Assert(d.FillColor.R == 100);
		Test.Assert(d.CornerRadius == 8);
		Test.Assert(d.BorderWidth == 2);
		Test.Assert(d.BorderColor.R == 200);
	}

	// === GradientDrawable ===

	[Test]
	public static void GradientDrawable_Properties()
	{
		let d = scope GradientDrawable(.(255, 0, 0, 255), .(0, 0, 255, 255), .LeftToRight);
		Test.Assert(d.Direction == .LeftToRight);
		Test.Assert(d.StartColor.R == 255);
		Test.Assert(d.EndColor.B == 255);
	}

	// === InsetDrawable ===

	[Test]
	public static void InsetDrawable_WrapsInner()
	{
		let inner = new ColorDrawable(.(255, 0, 0, 255));
		let d = scope InsetDrawable(inner, .(10, 10, 10, 10));
		Test.Assert(d.Inset.Left == 10);
		Test.Assert(d.Inner === inner);
	}

	// === LayerDrawable ===

	[Test]
	public static void LayerDrawable_AddLayers()
	{
		let d = scope LayerDrawable();
		d.AddLayer(new ColorDrawable(.Red));
		d.AddLayer(new ColorDrawable(.Blue));
		// LayerDrawable stores layers internally — verify it doesn't crash.
	}

	// === StateListDrawable ===

	[Test]
	public static void StateListDrawable_SetAndGet()
	{
		let d = scope StateListDrawable();
		let normal = new ColorDrawable(.(100, 100, 100, 255));
		let hover = new ColorDrawable(.(150, 150, 150, 255));
		let pressed = new ColorDrawable(.(50, 50, 50, 255));

		d.Set(.Normal, normal);
		d.Set(.Hover, hover);
		d.Set(.Pressed, pressed);

		Test.Assert(d.Get(.Normal) === normal);
		Test.Assert(d.Get(.Hover) === hover);
		Test.Assert(d.Get(.Pressed) === pressed);
	}

	[Test]
	public static void StateListDrawable_FallsBackToNormal()
	{
		let d = scope StateListDrawable();
		let normal = new ColorDrawable(.(100, 100, 100, 255));
		d.Set(.Normal, normal);

		// Disabled not set — should fall back to normal.
		let resolved = d.Get(.Disabled);
		Test.Assert(resolved === normal);
	}

	[Test]
	public static void StateListDrawable_NullWhenEmpty()
	{
		let d = scope StateListDrawable();
		let resolved = d.Get(.Normal);
		Test.Assert(resolved == null);
	}

	// === ShapeDrawable ===

	[Test]
	public static void ShapeDrawable_Construction()
	{
		bool drawn = false;
		let d = scope ShapeDrawable(new [&drawn](ctx, bounds) => { drawn = true; });
		Test.Assert(d != null);
		Test.Assert(!drawn);
	}

	// === Drawable on View ===

	[Test]
	public static void View_Background_SetAndGet()
	{
		let view = scope Panel();
		let bg = new ColorDrawable(.Red);
		view.Background = bg;
		Test.Assert(view.Background === bg);
	}
}
