namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// Base class for all composable visual primitives. Subclasses implement
/// concrete rendering (solid color, rounded rect, image, nine-slice, etc.).
public abstract class Drawable
{
	/// Draw this drawable into the given bounds.
	public abstract void Draw(UIDrawContext ctx, RectangleF bounds);

	/// Draw with control state awareness (e.g., StateListDrawable
	/// selects a variant per state). Default delegates to unaware Draw.
	public virtual void Draw(UIDrawContext ctx, RectangleF bounds, ControlState state)
	{
		Draw(ctx, bounds);
	}

	/// Optional intrinsic size (e.g., image dimensions). Null = no intrinsic size.
	public virtual Vector2? IntrinsicSize => null;

	/// Padding contributed by this drawable (e.g., NineSlice border regions).
	public virtual Thickness DrawablePadding => Thickness();
}
