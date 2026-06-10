namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using System.Collections;

/// Maps ControlState flags -> Drawable with fallback lookup.
/// Supports compound states (e.g., .Checked | .Hover).
///
/// Lookup: tries exact flag combination first, then strips flags
/// one at a time until a match is found. Ultimate fallback is Normal (0).
public class StateListDrawable : Drawable
{
	private Dictionary<int, Drawable> mDrawables = new .() ~ delete _;

	public this() {}

	public ~this()
	{
		for (var kv in ref mDrawables)
			if (kv.valueRef != null) { (*kv.valueRef).ReleaseRef(); kv.valueRef = null; }
	}

	/// Set the drawable for a specific state (or flag combination).
	/// Consumes the caller's ref - no AddRef. If a drawable was
	/// already set for this state, the previous one is released.
	public void Set(ControlState state, Drawable drawable)
	{
		let key = (int)state;
		if (mDrawables.TryGetValue(key, let prev))
		{
			if (prev != null && prev !== drawable)
				prev.ReleaseRef();
		}
		mDrawables[key] = drawable;
	}

	/// Get the drawable for a state. Tries exact match first, then
	/// strips flags one at a time. Fallback is Normal (0).
	public Drawable Get(ControlState state)
	{
		// Exact match
		let key = (int)state;
		if (mDrawables.TryGetValue(key, let d))
			return d;

		// Strip flags from highest to lowest until we find a match
		var remaining = key;
		for (let flag in int[?](32, 16, 8, 4, 2, 1))
		{
			if ((remaining & flag) == 0) continue;
			remaining &= ~flag;
			if (mDrawables.TryGetValue(remaining, let fallback))
				return fallback;
		}

		// Ultimate fallback: Normal
		if (mDrawables.TryGetValue(0, let normal))
			return normal;

		return null;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		Get(.Normal)?.Draw(ctx, bounds);
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds, ControlState state)
	{
		Get(state)?.Draw(ctx, bounds);
	}
}
