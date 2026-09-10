using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// The animation subsystem: the clock and repeat policy on the base, the concrete value
/// animations, storyboards, and the manager that owns and ticks them.
class AnimationTests
{
	private static bool Near(float a, float b, float epsilon = 0.0001f) => Abs(a - b) <= epsilon;

	// ---- FloatAnimation ---------------------------------------------------------------------

	/// A zero delta applies the START value, so the first frame already looks right rather
	/// than showing whatever the property held before.
	[Test]
	public static void AnAnimationRunsFromItsStartToItsEnd()
	{
		var result = -1.0f;

		let animation = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		animation.Start();

		animation.Update(0);
		Test.Assert(result == 0);

		animation.Update(0.5f);
		Test.Assert(Near(result, 50));

		animation.Update(0.5f);
		Test.Assert(result == 100);
	}

	[Test]
	public static void AnEasingBendsTheProgress()
	{
		var result = -1.0f;

		let animation = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; },
			Easing.EaseInCubic);
		animation.Start();
		animation.Update(0.5f);

		Test.Assert(result < 50, "ease in starts slow");
		Test.Assert(result > 0);
	}

	/// Update answers whether the animation is FINISHED, which is what lets the manager drop
	/// it without a second query.
	[Test]
	public static void UpdateAnswersWhetherItIsFinished()
	{
		let animation = scope FloatAnimation(0, 1, 0.5f, new (v) => {});
		animation.Start();

		Test.Assert(!animation.Update(0.3f));
		Test.Assert(animation.Update(0.3f));
		Test.Assert(animation.IsComplete);
	}

	// ---- The other value kinds --------------------------------------------------------------

	[Test]
	public static void AColourAnimationInterpolatesTheChannels()
	{
		var result = Color.Black;

		let animation = scope ColorAnimation(Color(0, 0, 0, 1), Color(1, 1, 1, 1), 1.0f,
			new [&result](v) => { result = v; });
		animation.Start();
		animation.Update(0.5f);

		Test.Assert(result.R > 0.3f);
		Test.Assert(result.R < 0.8f);
	}

	[Test]
	public static void AVectorAnimationInterpolatesEachAxis()
	{
		var result = Float2.Zero;

		let animation = scope Float2Animation(.(0, 0), .(100, 200), 1.0f,
			new [&result](v) => { result = v; });
		animation.Start();
		animation.Update(0.5f);

		Test.Assert(Near(result.X, 50));
		Test.Assert(Near(result.Y, 100));
	}

	// ---- Timing -----------------------------------------------------------------------------

	/// A delay applies NOTHING while it runs: the setter is untouched, so the property keeps
	/// whatever it had rather than snapping to the start value early.
	[Test]
	public static void ADelayHoldsTheAnimationOff()
	{
		var result = -1.0f;

		let animation = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		animation.Delay = 0.5f;
		animation.Start();

		animation.Update(0.3f);
		Test.Assert(result == -1, "still inside the delay");

		animation.Update(0.3f); // six tenths in total, a tenth of it active
		Test.Assert(result >= 0);
	}

	/// Auto reverse plays the ODD repeats backward, so a pulse is one animation rather than a
	/// pair chained together.
	[Test]
	public static void AutoReversePlaysTheOddRepeatsBackward()
	{
		var result = -1.0f;

		let animation = scope FloatAnimation(0, 100, 1.0f, new [&result](v) => { result = v; });
		animation.AutoReverse = true;
		animation.RepeatCount = 1;
		animation.Start();

		animation.Update(1.0f); // the first cycle finishes
		animation.Update(0.5f); // halfway back
		Test.Assert(result < 100);
	}

	/// The repeat count is how many times to repeat AFTER the first play, so two means three
	/// cycles in all.
	[Test]
	public static void ARepeatCountPlaysThatManyTimesMore()
	{
		let animation = scope FloatAnimation(0, 1, 0.1f, new (v) => {});
		animation.RepeatCount = 2;
		animation.Start();

		animation.Update(0.1f);
		Test.Assert(!animation.IsComplete);
		animation.Update(0.1f);
		Test.Assert(!animation.IsComplete);
		animation.Update(0.1f);
		Test.Assert(animation.IsComplete);
	}

	[Test]
	public static void AnInfiniteRepeatNeverFinishes()
	{
		let animation = scope FloatAnimation(0, 1, 0.1f, new (v) => {});
		animation.RepeatCount = -1;
		animation.Start();

		for (int32 i < 100)
			animation.Update(0.1f);

		Test.Assert(!animation.IsComplete);
		Test.Assert(animation.IsRunning);
	}

	/// A zero duration SNAPS to the end rather than dividing by nought, and finishes in the
	/// same tick.
	[Test]
	public static void AZeroDurationSnapsToTheEnd()
	{
		var result = -1.0f;

		let animation = scope FloatAnimation(0, 100, 0, new [&result](v) => { result = v; });
		animation.Start();

		Test.Assert(animation.Update(0));
		Test.Assert(result == 100);
		Test.Assert(animation.IsComplete);
	}

	[Test]
	public static void OnCompleteFiresWhenItFinishes()
	{
		var fired = false;

		let animation = scope FloatAnimation(0, 1, 0.5f, new (v) => {});
		animation.OnComplete.Add(new [&fired](a) => { fired = true; });
		animation.Start();
		animation.Update(1.0f);

		Test.Assert(fired);
	}

	/// A finished animation stays finished until RESET, which is what stops a stray Start from
	/// replaying something that already ran.
	[Test]
	public static void ResetAllowsAReplay()
	{
		var result = -1.0f;

		let animation = scope FloatAnimation(0, 100, 0.5f, new [&result](v) => { result = v; });
		animation.Start();
		animation.Update(1.0f);
		Test.Assert(animation.IsComplete);

		animation.Reset();
		Test.Assert(!animation.IsComplete);
		Test.Assert(!animation.IsRunning, "reset does not restart it");

		animation.Start();
		animation.Update(0.25f);
		Test.Assert(Near(result, 50));
	}

	// ---- Storyboard -------------------------------------------------------------------------

	/// Sequential starts each child only when the one before it has finished.
	[Test]
	public static void ASequentialStoryboardRunsItsChildrenInOrder()
	{
		var order = 0;
		var first = -1;
		var second = -1;

		let storyboard = scope Storyboard(.Sequential);
		storyboard.Add(new FloatAnimation(0.0f, 1.0f, 0.1f,
			new [&first, &order](v) => { if (first < 0) first = order++; }));
		storyboard.Add(new FloatAnimation(0.0f, 1.0f, 0.1f,
			new [&second, &order](v) => { if (second < 0) second = order++; }));
		storyboard.Start();

		storyboard.Update(0.05f);
		Test.Assert(first == 0);
		Test.Assert(second == -1, "the second has not begun");

		storyboard.Update(0.1f);
		storyboard.Update(0.05f);
		Test.Assert(second >= 0);
	}

	[Test]
	public static void AParallelStoryboardRunsEveryChildAtOnce()
	{
		var firstRan = false;
		var secondRan = false;

		let storyboard = scope Storyboard(.Parallel);
		storyboard.Add(new FloatAnimation(0.0f, 1.0f, 0.2f,
			new [&firstRan](v) => { firstRan = true; }));
		storyboard.Add(new FloatAnimation(0.0f, 1.0f, 0.1f,
			new [&secondRan](v) => { secondRan = true; }));
		storyboard.Start();

		storyboard.Update(0.05f);

		Test.Assert(firstRan);
		Test.Assert(secondRan);
	}

	/// An empty storyboard finishes at once rather than waiting forever for children that
	/// never arrive.
	[Test]
	public static void AnEmptyStoryboardFinishesImmediately()
	{
		let storyboard = scope Storyboard(.Sequential);
		storyboard.Start();

		Test.Assert(storyboard.Update(0.016f));
		Test.Assert(storyboard.IsComplete);
	}

	// ---- AnimationManager -------------------------------------------------------------------

	[Test]
	public static void TheManagerDropsAnAnimationWhenItFinishes()
	{
		let manager = scope AnimationManager();
		manager.Add(new FloatAnimation(0.0f, 1.0f, 0.1f, new (v) => {}));
		Test.Assert(manager.ActiveCount == 1);

		manager.Update(0.2f);

		Test.Assert(manager.ActiveCount == 0);
	}

	[Test]
	public static void CancellingEverythingEmptiesTheManager()
	{
		let manager = scope AnimationManager();
		manager.Add(new FloatAnimation(0.0f, 1.0f, 1.0f, new (v) => {}));
		manager.Add(new FloatAnimation(0.0f, 1.0f, 1.0f, new (v) => {}));
		Test.Assert(manager.ActiveCount == 2);

		manager.CancelAll();

		Test.Assert(manager.ActiveCount == 0);
	}

	/// An animation added DURING a tick waits for the next one. An onComplete callback that
	/// starts the follow up must not mutate the list being walked.
	[Test]
	public static void AnAnimationAddedDuringATickIsHeldUntilAfterIt()
	{
		let manager = scope AnimationManager();
		let chained = new FloatAnimation(0.0f, 1.0f, 1.0f, new (v) => {});

		let first = new FloatAnimation(0.0f, 1.0f, 0.1f, new (v) => {});
		first.OnComplete.Add(new [&manager, &chained](a) => { manager.Add(chained); });
		manager.Add(first);

		manager.Update(0.2f); // the first finishes and queues the second from its callback

		Test.Assert(manager.ActiveCount == 1, "the chained one survived the merge");
	}

	// ---- The manager on a context -----------------------------------------------------------

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	[Test]
	public static void CancellingForAViewDropsOnlyItsAnimations()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let view = new TestView(50.0f, 30.0f);
		root.AddView(view);
		let other = new TestView(50.0f, 30.0f);
		root.AddView(other);

		let targeted = new FloatAnimation(0.0f, 1.0f, 1.0f, new (v) => {});
		targeted.Target = view;
		context.Animations.Add(targeted);

		let untargeted = new FloatAnimation(0.0f, 1.0f, 1.0f, new (v) => {});
		untargeted.Target = other;
		context.Animations.Add(untargeted);
		Test.Assert(context.Animations.ActiveCount == 2);

		context.Animations.CancelForView(view);

		Test.Assert(context.Animations.ActiveCount == 1, "the other view's is untouched");
	}

	/// Removing a view CANCELS what was animating it. An animation holds a raw pointer to its
	/// target, so one left running over a removed view writes to freed memory.
	[Test]
	public static void RemovingAViewCancelsItsAnimations()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let view = new TestView(50.0f, 30.0f);
		root.AddView(view);

		let animation = new FloatAnimation(0.0f, 1.0f, 1.0f, new (v) => {});
		animation.Target = view;
		context.Animations.Add(animation);
		Test.Assert(context.Animations.ActiveCount == 1);

		root.RemoveView(view);

		Test.Assert(context.Animations.ActiveCount == 0);
	}

	/// A live animation is a continuous damage producer: the frame has to redraw while one
	/// runs, since the redraw gate hands out no free frames.
	[Test]
	public static void ARunningAnimationKeepsTheFrameRedrawing()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let vg = scope VGContext();

		context.Animations.Add(new FloatAnimation(0.0f, 1.0f, 1.0f, new (v) => {}));
		context.BeginFrame(0.016f);
		Test.Assert(context.NeedsRedraw);
		Test.Assert(context.CurrentPhase == .Idle, "the phase is put back");

		// Drawing satisfies the damage, which is the only thing that clears it.
		context.DrawRootView(root, vg);
		Test.Assert(!context.NeedsRedraw);

		context.BeginFrame(0.016f);
		Test.Assert(context.NeedsRedraw, "still running, so still asking");

		context.Animations.CancelAll();
		context.DrawRootView(root, vg);
		context.BeginFrame(0.016f);
		Test.Assert(!context.NeedsRedraw, "nothing running, nothing to redraw for");
	}
}
