using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A root that counts its updates.
class CountingScene : SceneRoot
{
	public int Ticks = 0;

	public this(Sedulous.GUI.GUIContext gui) : base(gui)
	{
	}

	public override void OnUpdate(TimeSpan elapsed)
	{
		Ticks++;
	}
}

/// SceneRoot as the coordinator: root lookup, deferred Close through the MutationQueue, and the
/// update loop draining tree edits.
class SceneRootTests
{
	[Test]
	public static void NodesFindTheCoordinatorByWalkingToTheRoot()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let mid = new Node();
		defer mid.ReleaseRef();
		let leaf = new Node();
		defer leaf.ReleaseRef();
		root.AddChild(mid);
		mid.AddChild(leaf);

		Test.Assert(leaf.RootNode == root);
		Test.Assert(leaf.ActionManager == root.ActionManager);
		Test.Assert(leaf.MutationQueue == root.MutationQueue);
	}

	[Test]
	public static void CloseDefersRemovalUntilUpdateDrainsTheQueue()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let child = new Node();
		defer child.ReleaseRef();
		root.AddChild(child);

		child.Close();
		Test.Assert(root.ChildCount == 1); // not yet: deferred
		Test.Assert(!root.MutationQueue.IsEmpty);

		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(root.ChildCount == 0); // drained
		Test.Assert(root.MutationQueue.IsEmpty);
	}

	[Test]
	public static void CloseWithoutACoordinatorRemovesImmediately()
	{
		let parent = new Node(); // a plain Node, not a SceneRoot
		defer parent.ReleaseRef();
		let child = new Node();
		defer child.ReleaseRef();
		parent.AddChild(child);

		child.Close();
		Test.Assert(parent.ChildCount == 0); // immediate fallback
	}

	[Test]
	public static void UpdateWithNothingQueuedIsHarmless()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(root.ActionManager.IsEmpty);
		Test.Assert(root.MutationQueue.IsEmpty);
	}

	[Test]
	public static void OnUpdateHookFiresEachUpdate()
	{
		let gui = new GUIContext();
		defer gui.ReleaseRef();
		let scene = new CountingScene(gui);
		defer scene.ReleaseRef();
		gui.Update(SceneFixtures.Frame);
		gui.Update(SceneFixtures.Frame);
		Test.Assert(scene.Ticks == 2);
	}

	[Test]
	public static void ANodeFindsItsGUIsRootADetachedSubtreeHasNoneButKeepsItsTop()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let mid = new Node();
		defer mid.ReleaseRef();
		let leaf = new Node();
		defer leaf.ReleaseRef();
		root.AddChild(mid);
		mid.AddChild(leaf);
		Test.Assert(leaf.SceneRoot == root);
		Test.Assert(root.SceneRoot == root);

		mid.RemoveFromParent();
		Test.Assert(leaf.SceneRoot == null); // in no GUI now
		Test.Assert(leaf.RootNode == mid); // the detached subtree's top
	}
}
