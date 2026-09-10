using Sedulous.Core;

namespace Sedulous.UI;

/// The common view animations, built ready to hand to an AnimationManager.
///
/// Every one of these targets the view, so AnimationManager.CancelForView finds it when the
/// view goes away.
static class ViewAnimator
{
	/// Fades between two opacities, setting the FROM value at once so the first frame is
	/// already right rather than flashing at whatever the view was.
	public static Animation FadeTo(View view, float from, float to, float duration,
		EasingFunction easing = null)
	{
		view.Opacity = from;
		let animation = new FloatAnimation(from, to, duration,
			new (value) => { view.Opacity = value; }, easing);
		animation.Target = view;
		return animation;
	}

	public static Animation FadeIn(View view, float duration, EasingFunction easing = null) =>
		FadeTo(view, 0, 1, duration, easing);

	public static Animation FadeOut(View view, float duration, EasingFunction easing = null) =>
		FadeTo(view, 1, 0, duration, easing);

	/// The transform is read, changed and written back rather than mutated in place, so a
	/// property setter on the view still sees an assignment.
	public static Animation TranslateX(View view, float from, float to, float duration,
		EasingFunction easing = null)
	{
		let animation = new FloatAnimation(from, to, duration,
			new (value) =>
			{
				var transform = view.Transform;
				transform.Translation.X = value;
				view.Transform = transform;
			}, easing);
		animation.Target = view;
		return animation;
	}

	public static Animation TranslateY(View view, float from, float to, float duration,
		EasingFunction easing = null)
	{
		let animation = new FloatAnimation(from, to, duration,
			new (value) =>
			{
				var transform = view.Transform;
				transform.Translation.Y = value;
				view.Transform = transform;
			}, easing);
		animation.Target = view;
		return animation;
	}

	/// Scales UNIFORMLY: a non uniform scale is rare enough to be worth writing out.
	public static Animation ScaleTo(View view, float from, float to, float duration,
		EasingFunction easing = null)
	{
		let animation = new FloatAnimation(from, to, duration,
			new (value) =>
			{
				var transform = view.Transform;
				transform.Scale = .(value, value);
				view.Transform = transform;
			}, easing);
		animation.Target = view;
		return animation;
	}

	/// In RADIANS, as ViewTransform stores it.
	public static Animation RotateTo(View view, float from, float to, float duration,
		EasingFunction easing = null)
	{
		let animation = new FloatAnimation(from, to, duration,
			new (value) =>
			{
				var transform = view.Transform;
				transform.Rotation = value;
				view.Transform = transform;
			}, easing);
		animation.Target = view;
		return animation;
	}
}
