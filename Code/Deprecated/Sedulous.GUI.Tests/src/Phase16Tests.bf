using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Tests for Phase 16: Animation System

// === Animation Base Tests ===

class AnimationBaseTests
{
	[Test]
	public static void AnimationDefaultProperties()
	{
		let anim = scope TestAnimation();
		Test.Assert(anim.Duration == 0.3f);
		Test.Assert(anim.Delay == 0);
		Test.Assert(anim.Progress == 0);
		Test.Assert(anim.State == .Pending);
		Test.Assert(anim.IsLooping == false);
		Test.Assert(anim.AutoReverse == false);
		Test.Assert(anim.Target == null);
	}

	[Test]
	public static void AnimationSetDuration()
	{
		let anim = scope TestAnimation();
		anim.Duration = 1.5f;
		Test.Assert(anim.Duration == 1.5f);
	}

	[Test]
	public static void AnimationSetDelay()
	{
		let anim = scope TestAnimation();
		anim.Delay = 0.5f;
		Test.Assert(anim.Delay == 0.5f);
	}

	[Test]
	public static void AnimationStart()
	{
		let anim = scope TestAnimation();
		anim.Start();
		Test.Assert(anim.State == .Running);
	}

	[Test]
	public static void AnimationPause()
	{
		let anim = scope TestAnimation();
		anim.Start();
		anim.Pause();
		Test.Assert(anim.State == .Paused);
	}

	[Test]
	public static void AnimationResume()
	{
		let anim = scope TestAnimation();
		anim.Start();
		anim.Pause();
		anim.Resume();
		Test.Assert(anim.State == .Running);
	}

	[Test]
	public static void AnimationCancel()
	{
		let anim = scope TestAnimation();
		anim.Start();
		anim.Cancel();
		Test.Assert(anim.State == .Cancelled);
	}

	[Test]
	public static void AnimationCompletes()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let anim = scope TestAnimation();
		anim.Duration = 0.1f;
		anim.SetTarget(panel);
		anim.Start();
		// Update past duration
		anim.Update(0.15f);
		Test.Assert(anim.State == .Completed);
	}

	[Test]
	public static void AnimationProgressUpdates()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let anim = scope TestAnimation();
		anim.Duration = 1.0f;
		anim.SetTarget(panel);
		anim.Start();
		anim.Update(0.5f);
		// Progress should be around 0.5 (may vary due to easing)
		Test.Assert(anim.Progress >= 0.4f && anim.Progress <= 0.6f);
	}

	[Test]
	public static void AnimationDelayWorks()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let anim = scope TestAnimation();
		anim.Duration = 0.5f;
		anim.Delay = 0.2f;
		anim.SetTarget(panel);
		anim.Start();
		// During delay, progress should be 0
		anim.Update(0.1f);
		Test.Assert(anim.Progress == 0);
		Test.Assert(anim.State == .Running);
		// After delay, animation starts
		anim.Update(0.2f);
		Test.Assert(anim.Progress > 0);
	}

	[Test]
	public static void AnimationLoops()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let anim = scope TestAnimation();
		anim.Duration = 0.1f;
		anim.IsLooping = true;
		anim.SetTarget(panel);
		anim.Start();
		// Complete one cycle
		anim.Update(0.15f);
		// Should still be running (looped)
		Test.Assert(anim.State == .Running);
	}

	[Test]
	public static void AnimationAutoReverse()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let anim = scope TestAnimation();
		anim.Duration = 0.1f;
		anim.IsLooping = true;
		anim.AutoReverse = true;
		anim.SetTarget(panel);
		anim.Start();
		// First half
		anim.Update(0.05f);
		// Progress is approximately mid-animation
		Test.Assert(anim.Progress > 0 && anim.Progress < 1);
		// Continue into reverse
		anim.Update(0.1f);
		// Should be in reverse now
		Test.Assert(anim.State == .Running);
	}

	[Test]
	public static void AnimationSetTarget()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let anim = scope TestAnimation();
		anim.SetTarget(panel);
		Test.Assert(anim.Target == panel);
	}
}

// === FloatAnimation Tests ===

class FloatAnimationTests
{
	[Test]
	public static void FloatAnimationDefaultProperties()
	{
		let anim = scope FloatAnimation();
		Test.Assert(anim.Duration == 0.3f);
		Test.Assert(anim.From == 0);
		Test.Assert(anim.To == 0);
	}

	[Test]
	public static void FloatAnimationSetFromTo()
	{
		let anim = scope FloatAnimation();
		anim.From = 0.5f;
		anim.To = 1.0f;
		Test.Assert(anim.From == 0.5f);
		Test.Assert(anim.To == 1.0f);
	}

	[Test]
	public static void FloatAnimationOpacityFactory()
	{
		let anim = FloatAnimation.Opacity(0.5f);
		defer delete anim;
		Test.Assert(anim.To == 0.5f);
	}

	[Test]
	public static void FloatAnimationOpacityFromToFactory()
	{
		let anim = FloatAnimation.Opacity(0.2f, 0.8f);
		defer delete anim;
		Test.Assert(anim.From == 0.2f);
		Test.Assert(anim.To == 0.8f);
	}

	[Test]
	public static void FloatAnimationWidthFactory()
	{
		let anim = FloatAnimation.Width(200);
		defer delete anim;
		Test.Assert(anim.To == 200);
	}

	[Test]
	public static void FloatAnimationHeightFactory()
	{
		let anim = FloatAnimation.Height(150);
		defer delete anim;
		Test.Assert(anim.To == 150);
	}
}

// === ThicknessAnimation Tests ===

class ThicknessAnimationTests
{
	[Test]
	public static void ThicknessAnimationDefaultProperties()
	{
		let anim = scope ThicknessAnimation();
		Test.Assert(anim.Duration == 0.3f);
	}

	[Test]
	public static void ThicknessAnimationSetFromTo()
	{
		let anim = scope ThicknessAnimation();
		anim.From = .(10, 20, 30, 40);
		anim.To = .(50, 60, 70, 80);
		Test.Assert(anim.From.Left == 10);
		Test.Assert(anim.From.Top == 20);
		Test.Assert(anim.To.Left == 50);
		Test.Assert(anim.To.Bottom == 80);
	}

	[Test]
	public static void ThicknessAnimationMarginFactory()
	{
		let target = Thickness(10, 20, 30, 40);
		let anim = ThicknessAnimation.Margin(target);
		defer delete anim;
		Test.Assert(anim.To.Left == 10);
		Test.Assert(anim.To.Top == 20);
	}

	[Test]
	public static void ThicknessAnimationPaddingFactory()
	{
		let target = Thickness(5, 10, 15, 20);
		let anim = ThicknessAnimation.Padding(target);
		defer delete anim;
		Test.Assert(anim.To.Left == 5);
		Test.Assert(anim.To.Bottom == 20);
	}
}

// === ColorAnimation Tests ===

class ColorAnimationTests
{
	[Test]
	public static void ColorAnimationDefaultProperties()
	{
		let anim = scope ColorAnimation();
		Test.Assert(anim.Duration == 0.3f);
	}

	[Test]
	public static void ColorAnimationSetFromTo()
	{
		let anim = scope ColorAnimation();
		anim.From = Color.Red;
		anim.To = Color.Blue;
		Test.Assert(anim.From.R == 255);
		Test.Assert(anim.From.G == 0);
		Test.Assert(anim.To.B == 255);
	}

	[Test]
	public static void ColorAnimationBackgroundFactory()
	{
		let anim = ColorAnimation.Background(Color.Green);
		defer delete anim;
		Test.Assert(anim.To.G == 128);
	}

	[Test]
	public static void ColorAnimationForegroundFactory()
	{
		let anim = ColorAnimation.Foreground(Color.Yellow);
		defer delete anim;
		Test.Assert(anim.To.R == 255);
		Test.Assert(anim.To.G == 255);
	}
}

// === Easing Tests ===

class EasingTests
{
	[Test]
	public static void EasingLinear()
	{
		let result = Easing.Linear(0.5f);
		Test.Assert(Math.Abs(result - 0.5f) < 0.01f);
	}

	[Test]
	public static void EasingLinearAtZero()
	{
		let result = Easing.Linear(0);
		Test.Assert(result == 0);
	}

	[Test]
	public static void EasingLinearAtOne()
	{
		let result = Easing.Linear(1);
		Test.Assert(result == 1);
	}

	[Test]
	public static void EasingEaseOutCubic()
	{
		// EaseOutCubic should be faster at start, slower at end
		let mid = Easing.EaseOutCubic(0.5f);
		// At 0.5, EaseOutCubic should be > 0.5
		Test.Assert(mid > 0.5f);
	}

	[Test]
	public static void EasingEaseInCubic()
	{
		// EaseInCubic should be slower at start, faster at end
		let mid = Easing.EaseInCubic(0.5f);
		// At 0.5, EaseInCubic should be < 0.5
		Test.Assert(mid < 0.5f);
	}

	[Test]
	public static void EasingBounceOut()
	{
		// BounceOut should reach 1 at t=1
		let end = Easing.BounceOut(1.0f);
		Test.Assert(Math.Abs(end - 1.0f) < 0.01f);
	}

	[Test]
	public static void EasingElasticOut()
	{
		// ElasticOut should reach approximately 1 at t=1
		let end = Easing.ElasticOut(1.0f);
		Test.Assert(Math.Abs(end - 1.0f) < 0.01f);
	}

	[Test]
	public static void EasingBackOut()
	{
		// BackOut may overshoot before settling at 1
		let end = Easing.BackOut(1.0f);
		Test.Assert(Math.Abs(end - 1.0f) < 0.01f);
	}
}

// === AnimationManager Tests ===

class AnimationManagerTests
{
	[Test]
	public static void AnimationManagerDefaultState()
	{
		let context = scope GUIContext();
		let manager = context.AnimationManager;
		Test.Assert(manager != null);
		Test.Assert(manager.ActiveCount == 0);
		Test.Assert(manager.StoryboardCount == 0);
	}

	[Test]
	public static void AnimationManagerStartAnimation()
	{
		let context = scope GUIContext();
		let manager = context.AnimationManager;
		let anim = new TestAnimation();
		anim.Duration = 1.0f;
		manager.Start(anim);
		Test.Assert(manager.ActiveCount == 1);
	}

	[Test]
	public static void AnimationManagerStopAnimation()
	{
		let context = scope GUIContext();
		let manager = context.AnimationManager;
		let anim = new TestAnimation();
		anim.Duration = 1.0f;
		manager.Start(anim);
		Test.Assert(manager.ActiveCount == 1);
		manager.Stop(anim);
		Test.Assert(manager.ActiveCount == 0);
	}

	[Test]
	public static void AnimationManagerUpdateRemovesCompleted()
	{
		let context = scope GUIContext();
		let manager = context.AnimationManager;
		let anim = new TestAnimation();
		anim.Duration = 0.1f;
		manager.Start(anim);
		Test.Assert(manager.ActiveCount == 1);
		// Update past completion
		manager.Update(0.2f);
		Test.Assert(manager.ActiveCount == 0);
	}

	[Test]
	public static void AnimationManagerStopAll()
	{
		let context = scope GUIContext();
		let manager = context.AnimationManager;
		manager.Start(new TestAnimation());
		manager.Start(new TestAnimation());
		manager.Start(new TestAnimation());
		Test.Assert(manager.ActiveCount == 3);
		manager.StopAll();
		Test.Assert(manager.ActiveCount == 0);
	}

	[Test]
	public static void AnimationManagerStopAllFor()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;
		let manager = context.AnimationManager;

		let anim1 = new TestAnimation();
		anim1.SetTarget(panel);
		let anim2 = new TestAnimation();
		anim2.SetTarget(panel);
		let anim3 = new TestAnimation();
		// anim3 has no target

		manager.Start(anim1);
		manager.Start(anim2);
		manager.Start(anim3);
		Test.Assert(manager.ActiveCount == 3);

		manager.StopAllFor(panel);
		Test.Assert(manager.ActiveCount == 1);
	}

	[Test]
	public static void AnimationManagerStartStoryboard()
	{
		let context = scope GUIContext();
		let manager = context.AnimationManager;
		let sb = new Storyboard();
		sb.Add(new TestAnimation(), 0);
		manager.Start(sb);
		Test.Assert(manager.StoryboardCount == 1);
	}
}

// === Storyboard Tests ===

class StoryboardTests
{
	[Test]
	public static void StoryboardDefaultState()
	{
		let sb = scope Storyboard();
		Test.Assert(sb.State == .Pending);
		Test.Assert(sb.IsActive == false);
		Test.Assert(sb.TotalDuration == 0);
	}

	[Test]
	public static void StoryboardAddAnimation()
	{
		let sb = scope Storyboard();
		let anim = new TestAnimation();
		anim.Duration = 0.5f;
		sb.Add(anim, 0);
		Test.Assert(sb.TotalDuration == 0.5f);
	}

	[Test]
	public static void StoryboardTotalDurationWithDelay()
	{
		let sb = scope Storyboard();
		let anim = new TestAnimation();
		anim.Duration = 0.5f;
		sb.Add(anim, 0.2f); // Start at 0.2s
		Test.Assert(sb.TotalDuration == 0.7f); // 0.2 + 0.5
	}

	[Test]
	public static void StoryboardTotalDurationMultipleAnimations()
	{
		let sb = scope Storyboard();
		let anim1 = new TestAnimation();
		anim1.Duration = 0.3f;
		let anim2 = new TestAnimation();
		anim2.Duration = 0.4f;
		sb.Add(anim1, 0);
		sb.Add(anim2, 0.3f); // Start when anim1 ends
		// Use epsilon comparison for floating point
		Test.Assert(Math.Abs(sb.TotalDuration - 0.7f) < 0.001f); // 0.3 + 0.4
	}

	[Test]
	public static void StoryboardStart()
	{
		let sb = scope Storyboard();
		sb.Add(new TestAnimation(), 0);
		sb.Start();
		Test.Assert(sb.State == .Running);
		Test.Assert(sb.IsActive == true);
	}

	[Test]
	public static void StoryboardPause()
	{
		let sb = scope Storyboard();
		sb.Add(new TestAnimation(), 0);
		sb.Start();
		sb.Pause();
		Test.Assert(sb.State == .Paused);
	}

	[Test]
	public static void StoryboardResume()
	{
		let sb = scope Storyboard();
		sb.Add(new TestAnimation(), 0);
		sb.Start();
		sb.Pause();
		sb.Resume();
		Test.Assert(sb.State == .Running);
	}

	[Test]
	public static void StoryboardCancel()
	{
		let sb = scope Storyboard();
		sb.Add(new TestAnimation(), 0);
		sb.Start();
		sb.Cancel();
		Test.Assert(sb.State == .Cancelled);
	}

	[Test]
	public static void StoryboardCompletes()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let sb = scope Storyboard();
		sb.SetTarget(panel);
		let anim = new TestAnimation();
		anim.Duration = 0.1f;
		sb.Add(anim, 0);
		sb.Start();
		sb.Update(0.2f);
		Test.Assert(sb.State == .Completed);
	}

	[Test]
	public static void StoryboardSequencesAnimations()
	{
		let context = scope GUIContext();
		let panel = scope Panel();
		context.RootElement = panel;

		let sb = scope Storyboard();
		sb.SetTarget(panel);
		let anim1 = new TestAnimation();
		anim1.Duration = 0.2f;
		let anim2 = new TestAnimation();
		anim2.Duration = 0.2f;
		sb.Add(anim1, 0);
		sb.Add(anim2, 0.2f);
		sb.Start();

		// Initially only anim1 should be running
		Test.Assert(anim1.State == .Running);
		Test.Assert(anim2.State == .Pending);

		// After 0.25s, anim1 completed, anim2 running
		sb.Update(0.25f);
		Test.Assert(anim1.State == .Completed);
		Test.Assert(anim2.State == .Running);
	}

	[Test]
	public static void StoryboardAddAfter()
	{
		let sb = scope Storyboard();
		let anim1 = new TestAnimation();
		anim1.Duration = 0.3f;
		let anim2 = new TestAnimation();
		anim2.Duration = 0.2f;
		sb.Add(anim1, 0);
		sb.AddAfter(anim2, anim1);
		// anim2 should start at 0.3s (after anim1 ends)
		Test.Assert(sb.TotalDuration == 0.5f);
	}
}

// === Test Helper ===

class TestAnimation : Animation
{
	public float LastProgress = 0;
	public int UpdateCount = 0;

	protected override void OnUpdate(float progress)
	{
		LastProgress = progress;
		UpdateCount++;
	}

	protected override void OnStart()
	{
	}

	protected override void OnReset()
	{
	}
}
