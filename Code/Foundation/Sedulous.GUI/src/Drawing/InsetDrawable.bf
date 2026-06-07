namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Wraps a drawable and insets its draw bounds. Advertises
/// the inset as DrawablePadding so layout can query it.
public class InsetDrawable : Drawable
{
	public Drawable Inner { get; private set; }
	public Thickness Inset;
	private bool mOwnsInner;

	/// If ownsInner is true (default), the InsetDrawable deletes the
	/// inner drawable on destruction.
	public this(Drawable inner, Thickness inset, bool ownsInner = true)
	{
		Inner = inner;
		Inset = inset;
		mOwnsInner = ownsInner;
	}

	public ~this()
	{
		if (mOwnsInner && Inner != null)
			delete Inner;
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
