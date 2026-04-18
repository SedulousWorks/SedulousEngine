namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Static convenience methods for creating common view animations.
/// Returned animations are NOT automatically added to AnimationManager.
/// Caller should add them: ctx.Animations.Add(ViewAnimator.FadeIn(view, 0.3f))
public static class ViewAnimator
{
	/// Fade a view from 0 to 1 alpha.
	public static Animation FadeIn(View view, float duration, EasingFunction easing = null)
	{
		return FadeTo(view, 0, 1, duration, easing);
	}

	/// Fade a view from 1 to 0 alpha.
	public static Animation FadeOut(View view, float duration, EasingFunction easing = null)
	{
		return FadeTo(view, 1, 0, duration, easing);
	}

	/// Fade a view from one alpha to another.
	public static Animation FadeTo(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		view.Alpha = from;
		let anim = new FloatAnimation(from, to, duration, new (v) => { view.Alpha = v; }, easing);
		anim.Target = view;
		return anim;
	}

	/// Translate a view horizontally using RenderTransform.
	public static Animation TranslateX(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		let anim = new FloatAnimation(from, to, duration, new (v) =>
		{
			view.RenderTransform = Matrix.CreateTranslation(v, 0, 0);
		}, easing);
		anim.Target = view;
		return anim;
	}

	/// Translate a view vertically using RenderTransform.
	public static Animation TranslateY(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		let anim = new FloatAnimation(from, to, duration, new (v) =>
		{
			view.RenderTransform = Matrix.CreateTranslation(0, v, 0);
		}, easing);
		anim.Target = view;
		return anim;
	}

	/// Scale a view uniformly using RenderTransform.
	public static Animation ScaleTo(View view, float from, float to, float duration, EasingFunction easing = null)
	{
		let anim = new FloatAnimation(from, to, duration, new (v) =>
		{
			view.RenderTransform = Matrix.CreateScale(v);
		}, easing);
		anim.Target = view;
		return anim;
	}
}
