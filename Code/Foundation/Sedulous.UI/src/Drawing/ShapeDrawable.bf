namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Delegate-based custom drawing without subclassing.
public class ShapeDrawable : Drawable
{
	private delegate void(UIDrawContext, RectangleF) mDrawFn ~ delete _;

	public this(delegate void(UIDrawContext, RectangleF) drawFn)
	{
		mDrawFn = drawFn;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		mDrawFn?.Invoke(ctx, bounds);
	}
}
