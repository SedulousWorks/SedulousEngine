using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// Custom drawing through a delegate, so a one off shape needs no subclass.
class ShapeDrawable : Drawable
{
	public typealias DrawFn = delegate void(UIDrawContext ctx, Rectangle bounds);

	private DrawFn mDrawFn ~ delete _;

	/// OWNERSHIP of the delegate transfers.
	public this(DrawFn drawFn)
	{
		mDrawFn = drawFn;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (mDrawFn != null)
			mDrawFn(ctx, bounds);
	}
}
