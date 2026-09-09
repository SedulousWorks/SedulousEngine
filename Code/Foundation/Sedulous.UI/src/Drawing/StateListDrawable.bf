using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// Maps control states to drawables, with a fallback search so a theme need only supply the
/// states it cares about.
class StateListDrawable : Drawable
{
	private Dictionary<uint32, Drawable> mDrawables = new .() ~ ReleaseAll(_);

	public this() {}

	private static void ReleaseAll(Dictionary<uint32, Drawable> drawables)
	{
		for (let pair in drawables)
		{
			if (pair.value != null)
				pair.value.ReleaseRef();
		}
		delete drawables;
	}

	/// Sets the drawable for a state, or a combination of them, replacing and releasing any
	/// previous one. CONSUMES the caller's reference.
	public void Set(ControlState state, Drawable drawable)
	{
		let key = (uint32)state;
		if (mDrawables.TryGetValue(key, let previous) && (previous != null))
			previous.ReleaseRef();
		mDrawables[key] = drawable;
	}

	/// The drawable for a state: the exact combination, then progressively fewer flags, then
	/// Normal.
	public Drawable Get(ControlState state)
	{
		let key = (uint32)state;
		if (mDrawables.TryGetValue(key, let exact))
			return exact;

		const uint32 cDisabled = (uint32)ControlState.Disabled;
		const uint32 cInteraction = (uint32)ControlState.Hover | (uint32)ControlState.Pressed
			| (uint32)ControlState.Focused;

		// Disabled DOMINATES. Stripping flags from the top down would drop Disabled before
		// Hover, so a disabled control would light up under the mouse and read as clickable.
		if (((key & cDisabled) != 0) && ((key & cInteraction) != 0))
		{
			if (mDrawables.TryGetValue(key & ~cInteraction, let disabled))
				return disabled;
		}

		// Otherwise drop flags one at a time, highest first, and take the first match.
		var remaining = key;
		let flags = scope uint32[](32, 16, 8, 4, 2, 1);
		for (let flag in flags)
		{
			if ((remaining & flag) == 0)
				continue;
			remaining &= ~flag;
			if (mDrawables.TryGetValue(remaining, let fallback))
				return fallback;
		}

		if (mDrawables.TryGetValue(0, let normal))
			return normal;
		return null;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (let drawable = Get(.Normal))
			drawable.Draw(ctx, bounds);
	}

	protected override void DrawState(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		if (let drawable = Get(state))
			drawable.Draw(ctx, bounds);
	}
}
