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

	/// The drawable for a state: the exact combination; else, among the defined combinations
	/// the state contains, the one that says the most about it (Weight); then Normal.
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

		// Otherwise the defined part of the state that weighs most. A pointer that presses a
		// control also hovers it, and Pressed|Hover is rarely defined: stripping flags by bit
		// value dropped Pressed (2) before Hover (1), so a pressed button drew its hover look and
		// never showed it was pressed. Every non-empty subset of the state is tried; the first
		// found of the heaviest wins.
		Drawable best = null;
		var bestWeight = 0;
		for (var subset = key; subset != 0; subset = (subset - 1) & key)
		{
			if (!mDrawables.TryGetValue(subset, let found))
				continue;
			let weight = Weight(subset);
			if ((best == null) || (weight > bestWeight))
			{
				best = found;
				bestWeight = weight;
			}
		}
		if (best != null)
			return best;

		if (mDrawables.TryGetValue(0, let normal))
			return normal;
		return null;
	}

	/// How much a combination of flags says about a control: disabled over everything, then
	/// pressed, then checked (a toggle stays checked under the pointer), then focused, then
	/// hovered.
	private static int Weight(uint32 flags)
	{
		var weight = 0;
		if ((flags & (uint32)ControlState.Disabled) != 0) weight += 64;
		if ((flags & (uint32)ControlState.Pressed) != 0) weight += 32;
		if ((flags & (uint32)ControlState.Checked) != 0) weight += 16;
		if ((flags & (uint32)ControlState.Indeterminate) != 0) weight += 16;
		if ((flags & (uint32)ControlState.Focused) != 0) weight += 4;
		if ((flags & (uint32)ControlState.Hover) != 0) weight += 2;
		return weight;
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
