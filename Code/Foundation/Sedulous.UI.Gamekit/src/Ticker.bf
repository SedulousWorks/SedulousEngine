using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Gamekit;

/// A label showing an integer that ROLLS to new values rather than snapping: the score counting
/// up over a moment, which is how a number reads as having been earned.
///
/// It IS a label, so alignment, font and colour all come from the label surface and the theme,
/// and nothing here draws.
///
/// Interpolation is single precision, so exact intermediate frames beyond about sixteen million
/// lose resolution; the target itself is always written EXACTLY on completion, because the
/// rounded end of a float ramp is not reliably the number asked for.
class Ticker : Label
{
	private int64 mCurrent = 0;
	private float mDefaultDuration = 0.5f;

	public this()
	{
		Render(0);
	}

	public int64 Number => mCurrent;

	/// The roll length used by the AnimateTo overload that takes no duration.
	public float DefaultDuration
	{
		get => mDefaultDuration;
		set => mDefaultDuration = (value > 0.0f) ? value : 0.0f;
	}

	/// Snaps the displayed number.
	public void SetNumber(int64 value) => Render(value);

	/// Rolls from the current number to a target over a number of seconds.
	///
	/// Headless, with no context, and a duration of zero or less both SNAP. A new call replaces
	/// the in flight roll rather than adding a second one.
	public void AnimateTo(int64 target, float duration)
	{
		let animations = (Context != null) ? Context.Animations : null;

		if ((animations == null) || (duration <= 0.0f))
		{
			Render(target);
			return;
		}

		animations.CancelForView(this);

		let animation = new FloatAnimation((float)mCurrent, (float)target, duration,
			new (value) =>
			{
				// Rounded to the nearest whole number each frame, away from zero, so a
				// countdown reads the same way a count up does.
				let rounded = (value >= 0.0f) ? (value + 0.5f) : (value - 0.5f);
				Render((int64)rounded);
			});
		animation.Target = this;
		// The exact target on completion: the float end value need not round back to it.
		animation.OnComplete.Add(new (finished) => { Render(target); });
		animations.Add(animation);
	}

	public void AnimateTo(int64 target) => AnimateTo(target, mDefaultDuration);

	private void Render(int64 value)
	{
		mCurrent = value;
		SetText(scope $"{value}");
	}
}
