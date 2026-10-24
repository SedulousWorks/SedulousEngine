using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Actions on a SceneRoot's clock: tweens of a plain node's reflected properties (x, y, opacity), a
// sequence of them, waits and calls, a run on a node in no GUI, and a target destroyed before its
// action ends. They moved here from eepp's Move, Fade, Delay, Runnable and Sequence actions, which
// the tweens took the place of.

/// Actions on a GUI's clock: tweens of a plain node, sequences, waits, calls.
class ActionTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void ATweenMovesAPlainNodesPositionAndIsDroppedOnceDone()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = new Node();
		defer node.ReleaseRef();
		root.AddChild(node);

		let tween = node.Animate("x", "100", 1.0f, "linear");
		defer tween.ReleaseRef();
		Test.Assert(root.ActionManager.Count == 1);
		root.Context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(node.Position.X, 50.0f));
		root.Context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(node.Position.X, 100.0f));
		Test.Assert(root.ActionManager.IsEmpty); // finished: dropped (a reflected property keeps its value)
	}

	[Test]
	public static void APlainNodesOpacityIsItsReflectedOne()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = new Node();
		defer node.ReleaseRef();
		root.AddChild(node);

		let tween = node.Animate("opacity", "0", 1.0f, "linear");
		defer tween.ReleaseRef();
		tween.From("1");
		root.Context.Update(SceneFixtures.Seconds(0.25));
		Test.Assert(Near(node.Alpha, 0.75f));
		root.Context.Update(SceneFixtures.Seconds(0.75));
		Test.Assert(Near(node.Alpha, 0.0f));
	}

	[Test]
	public static void ACallAfterAWaitFiresOnce()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = new Node();
		defer node.ReleaseRef();
		root.AddChild(node);

		int calls = 0;
		let sequence = new TweenSequence();
		defer sequence.ReleaseRef();
		sequence.Wait(0.5f).Call(new [&] () => { calls++; });
		node.RunAction(sequence);
		root.Context.Update(SceneFixtures.Seconds(0.25));
		Test.Assert(calls == 0);
		root.Context.Update(SceneFixtures.Seconds(0.25));
		Test.Assert(calls == 1);
		root.Context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(calls == 1);
		Test.Assert(root.ActionManager.IsEmpty);
	}

	[Test]
	public static void ASequenceOfMovesRunsThemInOrder()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = new Node();
		defer node.ReleaseRef();
		root.AddChild(node);

		let sequence = new TweenSequence();
		defer sequence.ReleaseRef();
		let across = node.CreateTween("x", "100", 1.0f, "linear");
		defer across.ReleaseRef();
		let down = node.CreateTween("y", "50", 1.0f, "linear");
		defer down.ReleaseRef();
		sequence.Add(across)
			.Add(down);
		node.RunAction(sequence);
		root.Context.Update(SceneFixtures.Seconds(1.0));
		Test.Assert(Near(node.Position.X, 100.0f));
		Test.Assert(Near(node.Position.Y, 0.0f));
		root.Context.Update(SceneFixtures.Seconds(1.0));
		Test.Assert(Near(node.Position.Y, 50.0f));
		Test.Assert(root.ActionManager.IsEmpty);
	}

	[Test]
	public static void ARunOnANodeInNoGUIDoesNothing()
	{
		let node = new Node();
		defer node.ReleaseRef();
		let tween = node.Animate("x", "100", 1.0f);
		defer tween.ReleaseRef();
		Test.Assert(tween != null); // shaped like any, inert
		Test.Assert(node.ActionManager == null);
		Test.Assert(Near(node.Position.X, 0.0f));
	}

	[Test]
	public static void OneWhoseTargetIsDestroyedIsDroppedNotRunOnFreedMemory()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		int ticks = 0;
		{
			let node = new Node();
			root.AddChild(node);
			let wait = new TweenWait(10.0f);
			wait.SetOnDone(new [&] (action) => { ticks++; });
			node.RunAction(wait);
			wait.ReleaseRef(); // the manager's keeps it
			Test.Assert(root.ActionManager.Count == 1);
			root.RemoveChild(node);
			node.ReleaseRef(); // the last reference goes with the scope
		}
		root.Context.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(root.ActionManager.Count == 0);
		Test.Assert(ticks == 0);
	}
}
