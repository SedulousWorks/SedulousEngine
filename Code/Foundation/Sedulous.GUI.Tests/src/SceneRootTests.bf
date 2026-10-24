using System;
using Sedulous.Core;
using Sedulous.VG;
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

	[Test]
	public static void MediaQueriesSeeTheRootsLogicalSizeAndItsDensity()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("@media (min-resolution: 2dppx) { label { opacity: 0.5; } } " +
			"@media (max-width: 500) { label { color: red; } }", sheet);
		let dense = SceneFixtures.NewScene();
		defer dense.ReleaseRef();
		dense.ViewportSize = .(800.0f, 600.0f);
		dense.DisplayScale = 2.0f;
		let label = new Label();
		defer label.ReleaseRef();
		dense.AddChild(label);
		let atDense = scope ResolvedStyle();
		sheet.Resolve(label, dense.MediaContext, atDense);
		Test.Assert(atDense.Has("opacity")); // 192 dpi >= 2dppx
		Test.Assert(atDense.Has("color")); // 400 logical <= 500

		let standard = SceneFixtures.NewScene();
		defer standard.ReleaseRef();
		standard.ViewportSize = .(800.0f, 600.0f);
		let atStandard = scope ResolvedStyle();
		sheet.Resolve(label, standard.MediaContext, atStandard);
		Test.Assert(!atStandard.Has("opacity"));
		Test.Assert(!atStandard.Has("color")); // 800 logical
	}

	[Test]
	public static void EachRootHasItsOwnDisplayScaleItsTreeLaysOutInLogicalUnits()
	{
		// Two windows on monitors of different density, the same tree in each.
		let standard = SceneFixtures.NewScene();
		defer standard.ReleaseRef();
		let dense = SceneFixtures.NewScene();
		defer dense.ReleaseRef();
		standard.ViewportSize = .(800.0f, 600.0f);
		dense.ViewportSize = .(800.0f, 600.0f);
		dense.DisplayScale = 2.0f;
		Test.Assert(NodeFixtures.Near(standard.Size.X, 800.0f));
		Test.Assert(NodeFixtures.Near(dense.Size.X, 400.0f)); // 800 device pixels at 2x
		Test.Assert(NodeFixtures.Near(dense.Size.Y, 300.0f));
		Test.Assert(NodeFixtures.Near(dense.MediaContext.Width, 400.0f));
		Test.Assert(NodeFixtures.Near(dense.MediaContext.Dpi, 192.0f));

		// A button at logical (10, 10), 40 x 20: at 1x it covers device 10..50, at 2x 20..100.
		Button MakeButton(SceneRoot root)
		{
			let made = new Button();
			made.Position = .(10.0f, 10.0f);
			made.Size = .(40.0f, 20.0f);
			root.AddChild(made);
			return made;
		}
		let a = MakeButton(standard);
		defer a.ReleaseRef();
		let b = MakeButton(dense);
		defer b.ReleaseRef();
		// Input arrives in device pixels and hit-tests through the root's scale.
		Test.Assert(standard.OverFind(.(30.0f, 20.0f)) == a);
		Test.Assert(standard.OverFind(.(70.0f, 40.0f)) != a); // past 50 at 1x
		Test.Assert(dense.OverFind(.(70.0f, 40.0f)) == b); // inside 20..100 at 2x
		Test.Assert(dense.OverFind(.(15.0f, 15.0f)) != b); // before 20 at 2x

		// Drawing goes through the same scale: the dense root's box lands at twice the place.
		let area = scope NodeBox();
		area.BackgroundColor = .(1.0f, 0.0f, 0.0f, 1.0f);
		b.SetBox(area);
		let canvas = scope VGContext();
		canvas.SetAnalyticBoxes(true);
		let dc = scope DrawContext(canvas);
		dense.Draw(dc);
		Test.Assert(canvas.GetBatch().BoxVertices.Count == 6);
		Test.Assert(NodeFixtures.Near(canvas.GetBatch().BoxVertices[0].HalfSize.X, 40.0f)); // 40 logical -> 80 device, halved
	}
}
