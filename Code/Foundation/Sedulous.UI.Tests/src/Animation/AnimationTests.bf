namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class AnimationTests
{
	// === FloatAnimation ===

	[Test]
	public static void Float_AtStart_ReturnsFrom()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		anim.Start();
		anim.Update(0); // t=0
		Test.Assert(result == 0);
	}

	[Test]
	public static void Float_AtEnd_ReturnsTo()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		anim.Start();
		anim.Update(1.0f); // t=1
		Test.Assert(result == 100);
	}

	[Test]
	public static void Float_AtMid_ReturnsInterpolated()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		anim.Start();
		anim.Update(0.5f);
		Test.Assert(Math.Abs(result - 50) < 0.01f);
	}

	[Test]
	public static void Float_WithEasing_AppliesEasing()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; }, Easing.EaseInCubic);
		anim.Start();
		anim.Update(0.5f);
		// EaseInCubic at t=0.5 should be < 50 (starts slow)
		Test.Assert(result < 50);
		Test.Assert(result > 0);
	}

	[Test]
	public static void Float_Completes_ReturnsTrue()
	{
		let anim = scope FloatAnimation(0, 1, 0.5f, new (v) => { });
		anim.Start();
		Test.Assert(!anim.Update(0.3f));
		Test.Assert(anim.Update(0.3f)); // total 0.6 > 0.5
		Test.Assert(anim.IsComplete);
	}

	// === ColorAnimation ===

	[Test]
	public static void Color_Interpolates()
	{
		Color result = .Black;
		let anim = scope ColorAnimation(.(0, 0, 0, 255), .(255, 255, 255, 255), 1.0f,
			new [&result](v) => { result = v; });
		anim.Start();
		anim.Update(0.5f);
		// Should be approximately gray
		Test.Assert(result.R > 100 && result.R < 200);
	}

	// === Vector2Animation ===

	[Test]
	public static void Vector2_Interpolates()
	{
		Vector2 result = .Zero;
		let anim = scope Vector2Animation(.(0, 0), .(100, 200), 1.0f,
			new [&result](v) => { result = v; });
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
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		anim.Delay = 0.5f;
		anim.Start();
		anim.Update(0.3f); // still in delay
		Test.Assert(result == -1); // setter not called
		anim.Update(0.3f); // 0.6 total, 0.1 active
		Test.Assert(result >= 0);
	}

	// === AutoReverse ===

	[Test]
	public static void AutoReverse_PlaysBackward()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		anim.AutoReverse = true;
		anim.RepeatCount = 1;
		anim.Start();

		// First cycle forward
		anim.Update(1.0f); // completes cycle 0
		Test.Assert(Math.Abs(result - 100) < 0.01f || result == 100);

		// Second cycle backward (odd repeat)
		anim.Update(0.5f); // midpoint of reverse
		Test.Assert(result < 100); // going backward
	}

	// === RepeatCount ===

	[Test]
	public static void RepeatCount_PlaysMultipleTimes()
	{
		int applyCount = 0;
		let anim = scope FloatAnimation(0, 1, 0.1f, new [&applyCount](v) => { applyCount++; });
		anim.RepeatCount = 2; // play 3 times total
		anim.Start();

		anim.Update(0.1f); // cycle 0 complete
		Test.Assert(!anim.IsComplete);
		anim.Update(0.1f); // cycle 1 complete
		Test.Assert(!anim.IsComplete);
		anim.Update(0.1f); // cycle 2 complete
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
		anim.OnComplete.Add(new [&fired](a) => { fired = true; });
		anim.Start();
		anim.Update(1.0f);
		Test.Assert(fired);
	}

	// === Zero duration ===

	[Test]
	public static void ZeroDuration_SnapsToEnd()
	{
		float result = -1;
		let anim = scope FloatAnimation(0, 100, 0, new [&result](v) => { result = v; });
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
		let anim = scope FloatAnimation(0, 100, 0.5f, new [&result](v) => { result = v; });
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
		sb.Add(new FloatAnimation(0, 1, 0.1f, new [&](v) => { if (first < 0) first = order++; }));
		sb.Add(new FloatAnimation(0, 1, 0.1f, new [&](v) => { if (second < 0) second = order++; }));
		sb.Start();

		sb.Update(0.05f); // first child at t=0.5
		Test.Assert(first == 0);
		Test.Assert(second == -1); // second not started yet

		sb.Update(0.1f); // first completes, second starts
		sb.Update(0.05f); // second at t=0.5
		Test.Assert(second >= 0);
	}

	[Test]
	public static void Storyboard_Sequential_CompletesWhenAllDone()
	{
		let sb = scope Storyboard(.Sequential);
		sb.Add(new FloatAnimation(0, 1, 0.2f, new (v) => { }));
		sb.Add(new FloatAnimation(0, 1, 0.2f, new (v) => { }));
		sb.Start();

		sb.Update(0.1f); // first at 50%
		Test.Assert(!sb.IsComplete);
		sb.Update(0.15f); // first completes (0.25 > 0.2), second starts
		Test.Assert(!sb.IsComplete); // second still running
		sb.Update(0.2f); // second completes
		Test.Assert(sb.IsComplete);
	}

	// === Storyboard Parallel ===

	[Test]
	public static void Storyboard_Parallel_RunsSimultaneously()
	{
		bool aRan = false, bRan = false;

		let sb = scope Storyboard(.Parallel);
		sb.Add(new FloatAnimation(0, 1, 0.2f, new [&aRan](v) => { aRan = true; }));
		sb.Add(new FloatAnimation(0, 1, 0.1f, new [&bRan](v) => { bRan = true; }));
		sb.Start();

		sb.Update(0.05f);
		Test.Assert(aRan && bRan); // both started
	}

	[Test]
	public static void Storyboard_Parallel_CompletesWhenAllDone()
	{
		let sb = scope Storyboard(.Parallel);
		sb.Add(new FloatAnimation(0, 1, 0.1f, new (v) => { }));
		sb.Add(new FloatAnimation(0, 1, 0.3f, new (v) => { }));
		sb.Start();

		sb.Update(0.15f);
		Test.Assert(!sb.IsComplete); // second still running

		sb.Update(0.2f);
		Test.Assert(sb.IsComplete); // both done
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
	public static void Manager_DeferredAdd()
	{
		let mgr = scope AnimationManager();
		// Add an animation whose OnComplete adds another animation.
		let first = new FloatAnimation(0, 1, 0.1f, new (v) => { });
		first.OnComplete.Add(new [&mgr](a) =>
		{
			mgr.Add(new FloatAnimation(0, 1, 0.1f, new (v) => { }));
		});
		mgr.Add(first);

		mgr.Update(0.2f); // first completes, adds second to pending
		Test.Assert(mgr.ActiveCount == 1); // second now active
	}

	[Test]
	public static void Manager_CancelForView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let view = new ColorView();
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
		ctx.AddRootView(root);
		let view = new ColorView();
		root.AddView(view);
		let viewId = view.Id;

		let anim = new FloatAnimation(0, 1, 1.0f, new (v) => { });
		anim.Target = view;
		ctx.Animations.Add(anim);

		// Delete the view — should auto-cancel the animation.
		root.RemoveView(view, true);
		Test.Assert(ctx.Animations.ActiveCount == 0);
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
}
