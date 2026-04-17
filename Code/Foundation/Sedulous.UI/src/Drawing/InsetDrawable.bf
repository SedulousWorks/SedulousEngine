namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Wraps a drawable and insets its draw bounds. Advertises
/// the inset as DrawablePadding so layout can query it.
public class InsetDrawable : Drawable
{
	public Drawable Inner ~ delete _;
	public Thickness Inset;

	public this(Drawable inner, Thickness inset)
	{
		Inner = inner;
		Inset = inset;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (Inner == null) return;
		let insetBounds = RectangleF(
			bounds.X + Inset.Left,
			bounds.Y + Inset.Top,
			Math.Max(0, bounds.Width - Inset.TotalHorizontal),
			Math.Max(0, bounds.Height - Inset.TotalVertical));
		Inner.Draw(ctx, insetBounds);
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds, ControlState state)
	{
		if (Inner == null) return;
		let insetBounds = RectangleF(
			bounds.X + Inset.Left,
			bounds.Y + Inset.Top,
			Math.Max(0, bounds.Width - Inset.TotalHorizontal),
			Math.Max(0, bounds.Height - Inset.TotalVertical));
		Inner.Draw(ctx, insetBounds, state);
	}

	public override Thickness DrawablePadding => Inset;
}
