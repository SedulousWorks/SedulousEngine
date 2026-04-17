namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Base class for composable visual primitives. Drawables are stateless
/// objects that render into a given bounds via UIDrawContext.
public abstract class Drawable
{
	/// State-unaware draw.
	public abstract void Draw(UIDrawContext ctx, RectangleF bounds);

	/// State-aware draw — default delegates to state-unaware.
	public virtual void Draw(UIDrawContext ctx, RectangleF bounds, ControlState state)
		=> Draw(ctx, bounds);

	/// Optional natural size (e.g., for icons/images). Null = no intrinsic size.
	public virtual Vector2? IntrinsicSize => null;

	/// Padding contributed by this drawable (e.g., nine-slice borders).
	/// Layout can merge via max(drawablePadding, explicitPadding).
	public virtual Thickness DrawablePadding => Thickness();
}
