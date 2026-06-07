namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// Maps ControlState -> Drawable for state-aware rendering.
/// With v3's bit-flag ControlState, lookup tries the exact flag
/// combination first, then falls back to subsets.
public class StateListDrawable : Drawable
{
	// Allocate enough slots for common flag combinations.
	// Index by raw enum value. For compound states beyond the array,
	// we fall back to subset matching.
	private const int SlotCount = 64;
	private Drawable[SlotCount] mDrawables;
	private bool mOwnsDrawables;

	public this(bool ownsDrawables = true) { mOwnsDrawables = ownsDrawables; }

	public ~this()
	{
		if (mOwnsDrawables)
			for (var d in ref mDrawables)
				if (d != null) { delete d; d = null; }
	}

	/// Set the drawable for a specific state (or combination of flags).
	public void Set(ControlState state, Drawable drawable)
	{
		let idx = (int)state;
		if (idx >= 0 && idx < SlotCount)
			mDrawables[idx] = drawable;
	}

	/// Get the drawable for a state. Tries exact match first, then
	/// falls back by removing flags until a match is found.
	/// Ultimate fallback is Normal (index 0).
	public Drawable Get(ControlState state)
	{
		let idx = (int)state;
		if (idx >= 0 && idx < SlotCount)
		{
			let d = mDrawables[idx];
			if (d != null) return d;
		}

		// Fallback: try removing one flag at a time
		var remaining = state;
		for (let flag in ControlState.GetValues<ControlState>())
		{
			if (flag == .Normal) continue;
			if (!remaining.HasFlag(flag)) continue;

			remaining = (ControlState)((int)remaining & ~(int)flag);
			let fallbackIdx = (int)remaining;
			if (fallbackIdx >= 0 && fallbackIdx < SlotCount)
			{
				let d = mDrawables[fallbackIdx];
				if (d != null) return d;
			}
		}

		return mDrawables[0]; // Normal
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
