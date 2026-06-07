namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class AnimationTests
{
	// === FloatAnimation ===

	[Test]
	public static void Float_AtStart_ReturnsFrom()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result] (v) => { result = v; });
		anim.Start();
		anim.Update(0);
		Test.Assert(result == 0);
	}

	[Test]
	public static void Float_AtEnd_ReturnsTo()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result] (v) => { result = v; });
		anim.Start();
		anim.Update(1.0f);
		Test.Assert(result == 100);
	}

	[Test]
	public static void Float_AtMid_ReturnsInterpolated()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result] (v) => { result = v; });
		anim.Start();
		anim.Update(0.5f);
		Test.Assert(Math.Abs(result - 50) < 0.01f);
	}

	[Test]
	public static void Float_WithEasing_AppliesEasing()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result] (v) => { result = v; }, Easing.EaseInCubic);
		anim.Start();
		anim.Update(0.5f);
		Test.Assert(result < 50);
		Test.Assert(result > 0);
	}

	[Test]
	public static void Float_Completes_ReturnsTrue()
	{
		let anim = scope FloatAnimation(0, 1, 0.5f, new (v) => { });
		anim.Start();
		Test.Assert(!anim.Update(0.3f));
		Test.Assert(anim.Update(0.3f));
		Test.Assert(anim.IsComplete);
	}

	// === ColorAnimation ===

	[Test]
	public static void Color_Interpolates()
	{
		Color result = .Black;
		let anim = scope ColorAnimation(.(0, 0, 0, 255), .(255, 255, 255, 255), 1.0f,
			new [&result] (v) => { result = v; });
		anim.Start();
		anim.Update(0.5f);
		Test.Assert(result.R > 100 && result.R < 200);
	}

	// === Vector2Animation ===

	[Test]
	public static void Vector2_Interpolates()
	{
		Vector2 result = .Zero;
		let anim = scope Vector2Animation(.(0, 0), .(100, 200), 1.0f,
			new [&result] (v) => { result = v; });
		anim.Start();
		anim.Update(0.5f);
		Test.Assert(Math.Abs(result.X - 50) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 100) < 0.01f);
	}

	// === Delay ===

	[Test]
	public static void Delay_WaitsBeforePlaying()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result] (v) => { result = v; });
		anim.Delay = 0.5f;
		anim.Start();
		anim.Update(0.3f); // still in delay
		Test.Assert(result == -1);
		anim.Update(0.3f); // 0.6 total, 0.1 active
		Test.Assert(result >= 0);
	}

	// === AutoReverse ===

	[Test]
	public static void AutoReverse_PlaysBackward()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result] (v) => { result = v; });
		anim.AutoReverse = true;
		anim.RepeatCount = 1;
		anim.Start();

		anim.Update(1.0f); // completes cycle 0
		anim.Update(0.5f); // midpoint of reverse
		Test.Assert(result < 100);
	}

	// === RepeatCount ===

	[Test]
	public static void RepeatCount_PlaysMultipleTimes()
	{
		let anim = scope FloatAnimation(0, 1, 0.1f, new (v) => { });
		anim.RepeatCount = 2;
		anim.Start();

		anim.Update(0.1f);
		Test.Assert(!anim.IsComplete);
		anim.Update(0.1f);
		Test.Assert(!anim.IsComplete);
		anim.Update(0.1f);
		Test.Assert(anim.IsComplete);
	}

	[Test]
	public static void RepeatInfinite_NeverCompletes()
	{
		let anim = scope FloatAnimation(0, 1, 0.1f, new (v) => { });
		anim.RepeatCount = -1;
		anim.Start();

		for (int i = 0; i < 100; i++)
			anim.Update(0.1f);

		Test.Assert(!anim.IsComplete);
		Test.Assert(anim.IsRunning);
	}

	// === OnComplete event ===

	[Test]
	public static void OnComplete_FiresWhenDone()
	{
		bool fired = false;
		let anim = scope FloatAnimation(0, 1, 0.5f, new (v) => { });
		anim.OnComplete.Add(new [&fired] (a) => { fired = true; });
		anim.Start();
		anim.Update(1.0f);
		Test.Assert(fired);
	}

	// === Zero duration ===

	[Test]
	public static void ZeroDuration_SnapsToEnd()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 0, new [&result] (v) => { result = v; });
		anim.Start();
		Test.Assert(anim.Update(0));
		Test.Assert(result == 100);
		Test.Assert(anim.IsComplete);
	}

	// === Reset ===

	[Test]
	public static void Reset_AllowsReplay()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 0.5f, new [&result] (v) => { result = v; });
		anim.Start();
		anim.Update(1.0f);
		Test.Assert(anim.IsComplete);

		anim.Reset();
		Test.Assert(!anim.IsComplete);
		Test.Assert(!anim.IsRunning);

		anim.Start();
		anim.Update(0.25f);
		Test.Assert(Math.Abs(result - 50) < 0.01f);
	}

	// === Storyboard Sequential ===

	[Test]
	public static void Storyboard_Sequential_RunsInOrder()
	{
		int order = 0;
		int first = -1, second = -1;

		let sb = scope Storyboard(.Sequential);
		sb.Add(new FloatAnimation(0, 1, 0.1f, new [&] (v) => { if (first < 0) first = order++; }));
		sb.Add(new FloatAnimation(0, 1, 0.1f, new [&] (v) => { if (second < 0) second = order++; }));
		sb.Start();

		sb.Update(0.05f);
		Test.Assert(first == 0);
		Test.Assert(second == -1);

		sb.Update(0.1f);
		sb.Update(0.05f);
		Test.Assert(second >= 0);
	}

	[Test]
	public static void Storyboard_Parallel_RunsSimultaneously()
	{
		bool aRan = false, bRan = false;

		let sb = scope Storyboard(.Parallel);
		sb.Add(new FloatAnimation(0, 1, 0.2f, new [&aRan] (v) => { aRan = true; }));
		sb.Add(new FloatAnimation(0, 1, 0.1f, new [&bRan] (v) => { bRan = true; }));
		sb.Start();

		sb.Update(0.05f);
		Test.Assert(aRan && bRan);
	}

	// === AnimationManager ===

	[Test]
	public static void Manager_DeletesOnComplete()
	{
		let mgr = scope AnimationManager();
		mgr.Add(new FloatAnimation(0, 1, 0.1f, new (v) => { }));
		Test.Assert(mgr.ActiveCount == 1);

		mgr.Update(0.2f);
		Test.Assert(mgr.ActiveCount == 0);
	}

	[Test]
	public static void Manager_CancelAll()
	{
		let mgr = scope AnimationManager();
		mgr.Add(new FloatAnimation(0, 1, 1.0f, new (v) => { }));
		mgr.Add(new FloatAnimation(0, 1, 1.0f, new (v) => { }));
		Test.Assert(mgr.ActiveCount == 2);

		mgr.CancelAll();
		Test.Assert(mgr.ActiveCount == 0);
	}

	[Test]
	public static void Manager_CancelForView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let anim = new FloatAnimation(0, 1, 1.0f, new (v) => { });
		anim.Target = view;
		ctx.Animations.Add(anim);
		Test.Assert(ctx.Animations.ActiveCount == 1);

		ctx.Animations.CancelForView(view);
		Test.Assert(ctx.Animations.ActiveCount == 0);
	}

	[Test]
	public static void Manager_AutoCancelOnViewDelete()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let anim = new FloatAnimation(0, 1, 1.0f, new (v) => { });
		anim.Target = view;
		ctx.Animations.Add(anim);

		root.RemoveView(view, true);
		Test.Assert(ctx.Animations.ActiveCount == 0);
	}
}
