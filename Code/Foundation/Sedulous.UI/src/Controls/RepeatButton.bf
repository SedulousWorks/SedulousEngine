namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Button that fires repeatedly while pressed.
/// Useful for increment/decrement buttons or scroll arrows.
public class RepeatButton : Button
{
	public float Delay = 0.5f;      // initial delay before repeating
	public float Interval = 0.1f;   // interval between repeats

	private float mHeldTime;
	private float mNextRepeatTime;
	private bool mRepeating;

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;
		IsPressed = true;
		mHeldTime = 0;
		mNextRepeatTime = Delay;
		mRepeating = false;
		Context?.FocusManager.SetCapture(this);
		FireClick();
		e.Handled = true;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button != .Left) return;
		IsPressed = false;
		mRepeating = false;
		Context?.FocusManager.ReleaseCapture();
		e.Handled = true;
	}

	/// Tick repeat timer during draw (called each frame while visible).
	public override void OnDraw(UIDrawContext ctx)
	{
		if (IsPressed && IsEffectivelyEnabled)
		{
			let dt = 1.0f / 60.0f; // approximate
			mHeldTime += dt;
			if (mHeldTime >= mNextRepeatTime)
			{
				mNextRepeatTime = mHeldTime + Interval;
				FireClick();
			}
		}
		base.OnDraw(ctx);
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		// RepeatButton uses the UIInputHelper's key repeat throttling,
		// so each repeat key event fires one click.
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return)
		{
			FireClick();
			e.Handled = true;
		}
	}
}
