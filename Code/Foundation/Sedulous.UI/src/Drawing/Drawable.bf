using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// The base of the composable visual primitives.
///
/// Stateless: a drawable renders into a bounds through a UIDrawContext and holds nothing
/// about who asked. That is what lets one instance be shared by every control using it.
///
/// Ref counted, because a theme hands the same drawable to many views and none of them owns
/// it outright.
abstract class Drawable : RefCounted
{
	/// The state unaware draw.
	public abstract void Draw(UIDrawContext ctx, Rectangle bounds);

	/// The state aware draw: the ONE entry every control uses.
	///
	/// Applies the context's transition blend, then dispatches to DrawState. The blend is
	/// CONSUMED here, so nested drawables draw plainly: a layer inside a cross-fading
	/// background must not fade a second time.
	public void Draw(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		let blend = ctx.Blend;
		if (!blend.IsActive)
		{
			DrawState(ctx, bounds, state);
			return;
		}

		ctx.SetBlend(DrawBlend());

		if ((blend.FromDrawable != null) && (blend.ToDrawable == this)
			&& (blend.FromDrawable != this))
		{
			// A background drawable swap. The OLD one goes down at full strength with the new
			// one fading in over it, so an opaque background keeps full coverage the whole way
			// rather than dipping through a half transparent middle.
			//
			// The state half of the blend is kept for the nested draws, which still have their
			// own state cross-fade to run.
			ctx.SetBlend(StatePart(blend));
			blend.FromDrawable.Draw(ctx, bounds, state);

			ctx.SetBlend(StatePart(blend));
			ctx.VG.PushOpacity(blend.DrawableT);
			Draw(ctx, bounds, state);
			ctx.VG.PopOpacity();
		}
		else if (blend.StateActive && (state == blend.ToState) && (blend.FromState != state))
		{
			DrawState(ctx, bounds, blend.FromState);
			ctx.VG.PushOpacity(blend.StateT);
			DrawState(ctx, bounds, state);
			ctx.VG.PopOpacity();
		}
		else
		{
			DrawState(ctx, bounds, state);
		}

		ctx.SetBlend(blend);
	}

	/// The blend with its DRAWABLE half cleared and its state half intact.
	private static DrawBlend StatePart(DrawBlend blend)
	{
		DrawBlend part = .();
		part.StateActive = blend.StateActive;
		part.FromState = blend.FromState;
		part.ToState = blend.ToState;
		part.StateT = blend.StateT;
		return part;
	}

	/// A natural size, for icons and images. Null means no intrinsic size.
	public virtual Float2? IntrinsicSize => null;

	/// Padding this drawable contributes, such as a nine slice's borders. Layout merges it
	/// with the explicit padding by taking the larger of the two per edge.
	public virtual Thickness DrawablePadding => .();

	/// The state aware body. Override THIS rather than Draw in a drawable that picks by
	/// state; the default ignores the state entirely.
	protected virtual void DrawState(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		Draw(ctx, bounds);
	}
}
