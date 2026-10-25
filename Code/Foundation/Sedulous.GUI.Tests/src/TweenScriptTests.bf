using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The tween verbs a script calls with its functions, through a fake one: OnFinished is called
/// once at the end, a group's Call steps in their order, a dead function never; each goes with
/// the tween or group that holds it. And who holds a tween: the caller alone once made, the
/// manager beside it while it runs, the caller alone again once it ends.
class TweenScriptTests
{
	/// A function that records `n` in `order` when called.
	private static FakeScriptDelegate Recording(List<int> order, int n)
	{
		let recording = new FakeScriptDelegate();
		recording.Body = new [=order, =n] (args, result) => { order.Add(n); };
		return recording;
	}

	[Test]
	public static void OnFinishedIsCalledOnceAtTheEndAndGoesWithTheTween()
	{
		let live = FakeScriptDelegate.Live;
		let bed = scope TweenBed("box { opacity: 1; }");
		let tween = bed.Widget.Animate("opacity", "0", 1.0f, "linear");
		let first = new FakeScriptDelegate();
		let done = new FakeScriptDelegate();
		Test.Assert(tween.OnFinishedScript(first) == tween);
		Test.Assert(tween.OnFinishedScript(done) == tween); // the first goes
		Test.Assert(FakeScriptDelegate.Live == live + 1);
		Test.Assert(tween.OnFinishedScript(null) == tween); // none: the one set stays
		Test.Assert(FakeScriptDelegate.Live == live + 1);

		bed.Frame(0.5);
		Test.Assert(done.Calls == 0);
		bed.Frame(0.75);
		Test.Assert(tween.IsDone);
		Test.Assert(done.Calls == 1);
		bed.Frame(1.0);
		Test.Assert(done.Calls == 1); // once

		tween.ReleaseRef(); // the last hold: the manager let go of its own at the end
		Test.Assert(FakeScriptDelegate.Live == live); // the function with it
	}

	[Test]
	public static void AGroupsCallStepsCallInOrderADeadOneNeverAndTheyGoWithTheGroup()
	{
		let live = FakeScriptDelegate.Live;
		let bed = scope TweenBed("box { opacity: 1; }");
		let order = scope List<int>();
		let sequence = new TweenSequence();
		let inner = new TweenParallel();
		inner.CallScript(Recording(order, 3));
		let fade = bed.Widget.CreateTween("opacity", "0", 1.0f, "linear");
		let dead = Recording(order, 9);
		dead.Alive = false; // its runtime went
		let finished = new FakeScriptDelegate();
		sequence.AddScript(fade)
			.CallScript(Recording(order, 1))
			.Wait(0.5f)
			.CallScript(Recording(order, 2))
			.AddGroupScript(inner)
			.CallScript(dead)
			.CallScript(null) // a step that calls nothing
			.OnFinishedScript(finished);
		fade.ReleaseRef(); // the sequence's keeps it
		inner.ReleaseRef();
		Test.Assert(sequence.StepCount == 7);
		Test.Assert(FakeScriptDelegate.Live == live + 5);

		bed.Widget.Play(sequence);
		bed.Frame(0.5);
		Test.Assert(order.IsEmpty);
		bed.Frame(0.75); // the fade ends at 1.0, the first call, then 0.25 of the wait
		Test.Assert((order.Count == 1) && (order[0] == 1));
		Test.Assert(finished.Calls == 0);
		bed.Frame(0.5); // the wait ends at 1.5: the second call, the inner group's, the end
		Test.Assert(order.Count == 3);
		Test.Assert((order[1] == 2) && (order[2] == 3));
		Test.Assert(dead.Calls == 0);
		Test.Assert(finished.Calls == 1);
		Test.Assert(sequence.IsDone);

		sequence.ReleaseRef(); // the last hold: its steps and every function go with it
		Test.Assert(FakeScriptDelegate.Live == live);
	}

	[Test]
	public static void ACreatedTweenIsTheCallersARunningOneTheManagersTooUntilItEnds()
	{
		let bed = scope TweenBed("box { opacity: 1; }");

		// Made: the caller's reference alone (what a script's handle keeps once the call has let
		// go of the one it handed over).
		let tween = bed.Widget.CreateTween("opacity", "0", 1.0f, "linear");
		defer tween.ReleaseRef();
		Test.Assert(tween.RefCount == 1);
		bed.Widget.RunAction(tween);
		Test.Assert(tween.RefCount == 2); // and the manager's, while it runs
		bed.Frame(0.5);
		Test.Assert(tween.RefCount == 2);
		bed.Frame(0.5);
		Test.Assert(tween.IsDone);
		Test.Assert(tween.RefCount == 1); // the manager's went at its end

		// Animate hands back a running one; a spring taking its property replaces it, and the
		// manager lets go of it at the next frame.
		let animated = bed.Widget.Animate("opacity", "0.5", 1.0f);
		defer animated.ReleaseRef();
		Test.Assert(animated.RefCount == 2);
		let spring = bed.Widget.SpringTo("opacity", "0");
		defer spring.ReleaseRef();
		Test.Assert(spring.RefCount == 2);
		bed.Frame(0.0);
		Test.Assert(animated.IsDone);
		Test.Assert(animated.RefCount == 1);
		// A spring already moving is handed back again, a reference for each caller.
		let again = bed.Widget.SpringTo("opacity", "1");
		Test.Assert(again == spring);
		Test.Assert(spring.RefCount == 3);
		again.ReleaseRef();
		Test.Assert(spring.RefCount == 2);

		// Play: the caller keeps its reference, the manager takes its own until the group ends.
		let group = new TweenSequence();
		defer group.ReleaseRef();
		bed.Widget.Play(group);
		Test.Assert(group.RefCount == 2);
		bed.Frame(0.0); // no steps: it ends at its first frame
		Test.Assert(group.IsDone);
		Test.Assert(group.RefCount == 1);
	}
}
