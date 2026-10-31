using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A button that keeps clicking while it is held: scroll arrows, numeric steppers, anything
/// where holding should do the thing over and over.
///
/// The caller drives it, by calling UpdateRepeat every frame. The repeat is not a timer the
/// button owns, because a control that owns a timer has to be told when the frame stops.
class RepeatButton : Button
{
	/// How long the button is held before the repeat starts.
	public float RepeatDelay = 0.4f;
	/// The gap between repeats once it has started.
	public float RepeatInterval = 0.05f;

	private bool mRepeating = false;
	private float mHoldTime = 0.0f;

	public this(StringView text) : base(text) {}

	public override void OnMouseDown(MouseEventArgs e)
	{
		base.OnMouseDown(e);
		if (e.Button == .Left)
		{
			mRepeating = true;
			mHoldTime = 0.0f;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		mRepeating = false;
		mHoldTime = 0.0f;
		base.OnMouseUp(e);
	}

	/// Call every frame while the button is held. Fires after RepeatDelay, then every
	/// RepeatInterval.
	public void UpdateRepeat(float deltaTime)
	{
		if (!mRepeating || !IsPressed)
			return;

		mHoldTime += deltaTime;
		if (mHoldTime >= RepeatDelay)
		{
			// SUBTRACTS the interval rather than resetting: the next repeat is due one
			// interval after this one, so a long frame does not swallow the ones it covered.
			mHoldTime -= RepeatInterval;
			FireClick();
		}
	}
}
