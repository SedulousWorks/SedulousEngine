namespace Sedulous.GUI;

using System;

/// Button that fires OnClick repeatedly while held down.
/// Used for scroll arrows, numeric field increment/decrement, etc.
public class RepeatButton : Button
{
	private bool mRepeating;
	private float mHoldTime;

	/// Delay before repeating starts (seconds).
	public float RepeatDelay = 0.4f;

	/// Interval between repeats (seconds).
	public float RepeatInterval = 0.05f;

	public this(StringView text) : base(text) { }

	public override void OnMouseDown(MouseEventArgs e)
	{
		base.OnMouseDown(e);
		if (e.Button == .Left)
		{
			mRepeating = true;
			mHoldTime = 0;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		mRepeating = false;
		mHoldTime = 0;
		base.OnMouseUp(e);
	}

	/// Call each frame while the button is held. The parent must call
	/// this during its update if repeat behavior is desired.
	public void UpdateRepeat(float deltaTime)
	{
		if (!mRepeating || !IsPressed) return;

		mHoldTime += deltaTime;
		if (mHoldTime >= RepeatDelay)
		{
			mHoldTime -= RepeatInterval;
			FireClick();
		}
	}
}
