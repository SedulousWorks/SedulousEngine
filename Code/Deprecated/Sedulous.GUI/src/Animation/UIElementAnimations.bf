using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Extension methods for easy animation creation on UIElement.
public static class UIElementAnimations
{
	// === Fade Animations ===

	/// Creates a fade-in animation (opacity 0 to 1).
	public static FloatAnimation FadeIn(this UIElement element, float duration = 0.3f)
	{
		let anim = FloatAnimation.Opacity(0, 1);
		anim.Duration = duration;
		anim.SetTarget(element);
		return anim;
	}

	/// Creates a fade-out animation (opacity 1 to 0).
	public static FloatAnimation FadeOut(this UIElement element, float duration = 0.3f)
	{
		let anim = FloatAnimation.Opacity(1, 0);
		anim.Duration = duration;
		anim.SetTarget(element);
		return anim;
	}

	/// Creates an opacity animation to a specific value.
	public static FloatAnimation FadeTo(this UIElement element, float opacity, float duration = 0.3f)
	{
		let anim = FloatAnimation.Opacity(opacity);
		anim.Duration = duration;
		anim.SetTarget(element);
		return anim;
	}

	// === Slide Animations ===

	/// Creates a slide-in-from-left animation.
	public static ThicknessAnimation SlideInFromLeft(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let currentMargin = element.Margin;
		let startMargin = Thickness(currentMargin.Left - distance, currentMargin.Top, currentMargin.Right, currentMargin.Bottom);

		let anim = ThicknessAnimation.Margin(startMargin, currentMargin);
		anim.Duration = duration;
		anim.EasingFunction = Easing.EaseOutCubic;
		anim.SetTarget(element);
		return anim;
	}

	/// Creates a slide-in-from-right animation.
	public static ThicknessAnimation SlideInFromRight(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let currentMargin = element.Margin;
		// Start offset to the right (increased left margin), animate back to normal
		let startMargin = Thickness(currentMargin.Left + distance, currentMargin.Top, currentMargin.Right, currentMargin.Bottom);

		let anim = ThicknessAnimation.Margin(startMargin, currentMargin);
		anim.Duration = duration;
		anim.EasingFunction = Easing.EaseOutCubic;
		anim.SetTarget(element);
		return anim;
	}

	/// Creates a slide-in-from-top animation.
	public static ThicknessAnimation SlideInFromTop(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let currentMargin = element.Margin;
		let startMargin = Thickness(currentMargin.Left, currentMargin.Top - distance, currentMargin.Right, currentMargin.Bottom);

		let anim = ThicknessAnimation.Margin(startMargin, currentMargin);
		anim.Duration = duration;
		anim.EasingFunction = Easing.EaseOutCubic;
		anim.SetTarget(element);
		return anim;
	}

	/// Creates a slide-in-from-bottom animation.
	public static ThicknessAnimation SlideInFromBottom(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let currentMargin = element.Margin;
		// Start offset downward (increased top margin), animate back to normal
		let startMargin = Thickness(currentMargin.Left, currentMargin.Top + distance, currentMargin.Right, currentMargin.Bottom);

		let anim = ThicknessAnimation.Margin(startMargin, currentMargin);
		anim.Duration = duration;
		anim.EasingFunction = Easing.EaseOutCubic;
		anim.SetTarget(element);
		return anim;
	}

	// === Size Animations ===

	/// Creates a width animation to a target value.
	public static FloatAnimation AnimateWidth(this UIElement element, float targetWidth, float duration = 0.3f)
	{
		let anim = FloatAnimation.Width(targetWidth);
		anim.Duration = duration;
		anim.SetTarget(element);
		return anim;
	}

	/// Creates a height animation to a target value.
	public static FloatAnimation AnimateHeight(this UIElement element, float targetHeight, float duration = 0.3f)
	{
		let anim = FloatAnimation.Height(targetHeight);
		anim.Duration = duration;
		anim.SetTarget(element);
		return anim;
	}

	// === Margin/Padding Animations ===

	/// Creates a margin animation to a target value.
	public static ThicknessAnimation AnimateMargin(this UIElement element, Thickness targetMargin, float duration = 0.3f)
	{
		let anim = ThicknessAnimation.Margin(targetMargin);
		anim.Duration = duration;
		anim.SetTarget(element);
		return anim;
	}

	/// Creates a padding animation to a target value.
	public static ThicknessAnimation AnimatePadding(this UIElement element, Thickness targetPadding, float duration = 0.3f)
	{
		let anim = ThicknessAnimation.Padding(targetPadding);
		anim.Duration = duration;
		anim.SetTarget(element);
		return anim;
	}

	// === Convenience: Start animation immediately ===

	/// Starts a fade-in animation immediately.
	public static void StartFadeIn(this UIElement element, float duration = 0.3f)
	{
		let context = element.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
			manager.Start(element.FadeIn(duration));
	}

	/// Starts a fade-out animation immediately.
	public static void StartFadeOut(this UIElement element, float duration = 0.3f)
	{
		let context = element.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
			manager.Start(element.FadeOut(duration));
	}

	/// Starts a slide-in-from-left animation immediately.
	public static void StartSlideInFromLeft(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let context = element.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
			manager.Start(element.SlideInFromLeft(distance, duration));
	}

	/// Starts a slide-in-from-right animation immediately.
	public static void StartSlideInFromRight(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let context = element.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
			manager.Start(element.SlideInFromRight(distance, duration));
	}

	/// Starts a slide-in-from-top animation immediately.
	public static void StartSlideInFromTop(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let context = element.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
			manager.Start(element.SlideInFromTop(distance, duration));
	}

	/// Starts a slide-in-from-bottom animation immediately.
	public static void StartSlideInFromBottom(this UIElement element, float distance = 50, float duration = 0.3f)
	{
		let context = element.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
			manager.Start(element.SlideInFromBottom(distance, duration));
	}
}
