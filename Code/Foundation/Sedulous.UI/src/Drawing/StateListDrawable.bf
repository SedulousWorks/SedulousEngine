namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Maps ControlState -> Drawable via pre-allocated array for O(1) lookup.
/// Falls back to Normal state if the requested state has no drawable.
public class StateListDrawable : Drawable
{
	private const int StateCount = 5; // Normal, Hover, Pressed, Focused, Disabled
	private Drawable[StateCount] mDrawables;
	private bool mOwnsDrawables;

	/// If ownsDrawables is true, the StateListDrawable deletes the
	/// individual drawables on destruction.
	public this(bool ownsDrawables = true) { mOwnsDrawables = ownsDrawables; }

	public ~this()
	{
		if (mOwnsDrawables)
			for (var d in ref mDrawables)
				if (d != null) { delete d; d = null; }
	}

	/// Set the drawable for a specific state.
	public void Set(ControlState state, Drawable drawable)
	{
		mDrawables[(int)state] = drawable;
	}

	/// Get the drawable for a state, with fallback to Normal.
	public Drawable Get(ControlState state)
	{
		let d = mDrawables[(int)state];
		if (d != null) return d;
		return mDrawables[(int)ControlState.Normal];
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
