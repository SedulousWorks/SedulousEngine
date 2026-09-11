using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Gamekit;

/// A game fill bar: a progress bar that can DRAIN.
///
/// The inherited Value still snaps, which is what a bar being rebuilt from game state every
/// frame wants. AnimateTo adds the other reading of the same number: health falling away over a
/// moment after a hit, so the player sees how much they lost rather than only what is left.
///
/// Themed through the progress bar's own track and fill parts, so a game theme colours it
/// without this class owning any drawing.
class Bar : ProgressBar
{
	private float mDefaultDuration = 0.35f;

	public this() {}

	/// The drain length used by the AnimateTo overload that takes no duration.
	public float DefaultDuration
	{
		get => mDefaultDuration;
		set => mDefaultDuration = (value > 0.0f) ? value : 0.0f;
	}

	/// Snaps the fill. Identical to assigning Value, and named so a caller reads the intent.
	public void SetFill(float value) => Value.Value = value;

	/// Drains toward a target over a number of seconds.
	///
	/// Headless, with no context or animation manager, and a duration of zero or less both
	/// SNAP: there is no frame pump to animate against, and silently doing nothing would leave
	/// the bar showing a stale value forever.
	///
	/// A new call CANCELS this bar's in flight animation, so repeated hits retarget one drain
	/// instead of stacking several that fight over the same value.
	public void AnimateTo(float target, float duration)
	{
		let clamped = Max(0.0f, Min(target, 1.0f));
		let animations = (Context != null) ? Context.Animations : null;

		if ((animations == null) || (duration <= 0.0f))
		{
			Value.Value = clamped;
			return;
		}

		animations.CancelForView(this);

		let animation = new FloatAnimation(Value.Value, clamped, duration,
			new [=](fill) => { Value.Value = fill; });
		animation.Target = this; // cancelled if the bar is removed mid drain
		animations.Add(animation);
	}

	public void AnimateTo(float target) => AnimateTo(target, mDefaultDuration);
}
