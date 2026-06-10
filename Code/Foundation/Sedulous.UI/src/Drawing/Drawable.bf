namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Base class for composable visual primitives. Drawables are stateless
/// objects that render into a given bounds via UIDrawContext.
///
/// Drawables are `RefCounted`. Construct with `new XxxDrawable(...)`
/// (refcount 1) and `ReleaseRef()` when done. Containers that hold a
/// drawable past the caller's scope (StyleRule values, View inline
/// styles, `StyleSheet.OwnDrawable` list, etc.) take a ref on capture
/// and release it on eviction. Drawable subclasses that hold child
/// drawables (`InsetDrawable.Inner`, `LayerDrawable` layers,
/// `StateListDrawable` map values) consume the caller's ref - no
/// AddRef in the constructor or Add/Set; destructors call `ReleaseRef`.
public abstract class Drawable : RefCounted
{
	/// State-unaware draw.
	public abstract void Draw(UIDrawContext ctx, RectangleF bounds);

	/// State-aware draw - default delegates to state-unaware.
	public virtual void Draw(UIDrawContext ctx, RectangleF bounds, ControlState state)
		=> Draw(ctx, bounds);

	/// Optional natural size (e.g., for icons/images). Null = no intrinsic size.
	public virtual Vector2? IntrinsicSize => null;

	/// Padding contributed by this drawable (e.g., nine-slice borders).
	/// Layout can merge via max(drawablePadding, explicitPadding).
	public virtual Thickness DrawablePadding => Thickness();
}
