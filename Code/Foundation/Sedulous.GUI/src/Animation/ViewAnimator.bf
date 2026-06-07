namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// Static convenience methods for creating common view animations.
/// Returned animations are NOT automatically added to AnimationManager.
/// Caller should add them: ctx.Animations.Add(ViewAnimator.FadeIn(view, 0.3f))
public static class ViewAnimator
{
	/// Fade a view from 0 to 1 opacity.
	public static Animation FadeIn(View view, float duration, EasingFunction easing = null)
	{
		return FadeTo(view, 0, 1, duration, easing);
	}

	/// Fade a view from 1 to 0 opacity.
	public static Animation FadeOut(View view, float duration, EasingFunction easing = null)
	{
		return FadeTo(view, 1, 0, duration, easing);
	}

	/// Fade a view from one opacity to another.
	public static Animation FadeTo(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		view.Opacity = from;
		let anim = new FloatAnimation(from, to, duration, new (v) => { view.Opacity = v; }, easing);
		anim.Target = view;
		return anim;
	}

	/// Translate a view horizontally using ViewTransform.
	public static Animation TranslateX(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		let anim = new FloatAnimation(from, to, duration, new (v) =>
		{
			var t = view.Transform;
			t.Translation.X = v;
			view.Transform = t;
		}, easing);
		anim.Target = view;
		return anim;
	}

	/// Translate a view vertically using ViewTransform.
	public static Animation TranslateY(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		let anim = new FloatAnimation(from, to, duration, new (v) =>
		{
			var t = view.Transform;
			t.Translation.Y = v;
			view.Transform = t;
		}, easing);
		anim.Target = view;
		return anim;
	}

	/// Scale a view uniformly using ViewTransform.
	public static Animation ScaleTo(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		let anim = new FloatAnimation(from, to, duration, new (v) =>
		{
			var t = view.Transform;
			t.Scale = .(v, v);
			view.Transform = t;
		}, easing);
		anim.Target = view;
		return anim;
	}

	/// Rotate a view using ViewTransform (radians).
	public static Animation RotateTo(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		let anim = new FloatAnimation(from, to, duration, new (v) =>
		{
			var t = view.Transform;
			t.Rotation = v;
			view.Transform = t;
		}, easing);
		anim.Target = view;
		return anim;
	}
}
