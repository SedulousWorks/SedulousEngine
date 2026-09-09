using Sedulous.Core;

namespace Sedulous.UI;

/// Wraps another drawable and insets its bounds, advertising the inset as padding so that
/// layout can account for it without knowing what is inside.
class InsetDrawable : Drawable
{
	public Thickness Inset = .();
	private Drawable mInner;

	/// CONSUMES the caller's reference on `inner`.
	public this(Drawable inner, Thickness inset)
	{
		mInner = inner;
		Inset = inset;
	}

	public ~this()
	{
		if (mInner != null)
			mInner.ReleaseRef();
	}

	public Drawable Inner => mInner;

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (mInner != null)
			mInner.Draw(ctx, InsetBounds(bounds));
	}

	protected override void DrawState(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		if (mInner != null)
			mInner.Draw(ctx, InsetBounds(bounds), state);
	}

	public override Thickness DrawablePadding => Inset;

	private Rectangle InsetBounds(Rectangle bounds) =>
		.(bounds.X + Inset.Left, bounds.Y + Inset.Top,
			Max(0.0f, bounds.Width - Inset.TotalHorizontal),
			Max(0.0f, bounds.Height - Inset.TotalVertical));
}
