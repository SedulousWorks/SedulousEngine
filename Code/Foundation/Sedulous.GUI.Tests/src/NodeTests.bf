using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The node tree: ownership, reparenting, z-order, geometry, world-space conversion, hit testing,
/// visibility, invalidation, and event listeners. Derived from eepp Scene::Node behavior, adapted
/// to the reference-counted child tree. A test makes nodes with `new` and lets go of its own
/// reference to each; a parent holds one of its own to each child.
class NodeTests
{
	[Test]
	public static void AddChildSetsParentAndCount()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let child = new Node();
		defer child.ReleaseRef();
		root.AddChild(child);

		Test.Assert(root.ChildCount == 1);
		Test.Assert(root.GetChildAt(0) == child);
		Test.Assert(child.Parent == root);
		Test.Assert(root.HasChild(child));
	}

	[Test]
	public static void ReparentingRemovesFromOldParent()
	{
		let a = new Node();
		defer a.ReleaseRef();
		let b = new Node();
		defer b.ReleaseRef();
		let child = new Node();
		defer child.ReleaseRef();
		a.AddChild(child);
		b.AddChild(child);

		Test.Assert(a.ChildCount == 0);
		Test.Assert(b.ChildCount == 1);
		Test.Assert(child.Parent == b);
	}

	[Test]
	public static void RemoveChildClearsParent()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let child = new Node();
		defer child.ReleaseRef();
		root.AddChild(child);
		root.RemoveChild(child);

		Test.Assert(root.ChildCount == 0);
		Test.Assert(child.Parent == null);
	}

	[Test]
	public static void ChildKeptAliveByTreeAfterExternalRefDrops()
	{
		let root = new Node();
		defer root.ReleaseRef();
		Node raw = null;
		{
			let child = new Node();
			raw = child;
			root.AddChild(child);
			child.ReleaseRef(); // the maker's reference let go; the tree still owns it
		}
		Test.Assert(root.ChildCount == 1);
		Test.Assert(root.GetChildAt(0) == raw);
		Test.Assert(raw.Parent == root);
	}

	[Test]
	public static void AChildHeldElsewhereOutlivesItsParentAndPointsAtNone()
	{
		let child = new Node();
		defer child.ReleaseRef();
		{
			let parent = new Node();
			parent.AddChild(child);
			parent.ReleaseRef(); // the parent's last reference dropped
		}
		Test.Assert(child.Parent == null);
		let other = new Node();
		defer other.ReleaseRef();
		other.AddChild(child); // it was reaching the freed parent to leave it
		Test.Assert(child.Parent == other);
	}

	[Test]
	public static void ZOrderAndSiblings()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let a = NodeFixtures.Box(root);
		let b = NodeFixtures.Box(root);
		let c = NodeFixtures.Box(root);

		Test.Assert(root.FirstChild == a);
		Test.Assert(root.LastChild == c);
		Test.Assert(a.NextSibling == b);
		Test.Assert(b.PrevSibling == a);

		a.ToFront(); // move a to end (topmost)
		Test.Assert(root.LastChild == a);
		a.ToBack();
		Test.Assert(root.FirstChild == a);
	}

	[Test]
	public static void SizeAndLocalBounds()
	{
		let node = new Node();
		defer node.ReleaseRef();
		node.Size = .(120.0f, 40.0f);
		Test.Assert(node.Size == Float2(120.0f, 40.0f));
		let b = node.LocalBounds;
		Test.Assert(b == Rect(0.0f, 0.0f, 120.0f, 40.0f));
	}

	[Test]
	public static void WorldPositionAccumulatesParentChain()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let child = NodeFixtures.Box(root);
		root.Position = .(100.0f, 0.0f);
		child.Position = .(10.0f, 5.0f);

		let screen = child.ScreenPosition;
		Test.Assert(NodeFixtures.Near(screen.X, 110.0f));
		Test.Assert(NodeFixtures.Near(screen.Y, 5.0f));
	}

	[Test]
	public static void HitTestReturnsTopmostChild()
	{
		let root = new Node();
		defer root.ReleaseRef();
		root.Size = .(200.0f, 200.0f);
		let a = NodeFixtures.Box(root);
		let b = NodeFixtures.Box(root); // b is topmost in the overlap
		a.Size = .(100.0f, 100.0f);
		b.Size = .(100.0f, 100.0f);

		Test.Assert(root.OverFind(.(50.0f, 50.0f)) == b);
		Test.Assert(root.OverFind(.(150.0f, 150.0f)) == root); // only root there
		Test.Assert(root.OverFind(.(300.0f, 300.0f)) == null); // outside all
	}

	[Test]
	public static void HiddenNodeIsNotHitAndHidesSubtree()
	{
		let root = new Node();
		defer root.ReleaseRef();
		root.Size = .(100.0f, 100.0f);
		root.Visible = false;
		Test.Assert(!root.Visible);
		Test.Assert(root.OverFind(.(50.0f, 50.0f)) == null);
	}

	[Test]
	public static void TreeVisibilityFollowsParents()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let child = NodeFixtures.Box(root);
		Test.Assert(child.IsTreeVisible);
		root.Visible = false;
		Test.Assert(!child.IsTreeVisible);
		Test.Assert(child.Visible); // its own flag is still true
	}

	[Test]
	public static void InvalidationBubblesToAncestors()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let child = NodeFixtures.Box(root);
		root.ClearNeedsRedraw();
		child.ClearNeedsRedraw();

		child.Size = .(10.0f, 10.0f);
		Test.Assert(child.NeedsRedraw);
		Test.Assert(root.NeedsRedraw); // bubbled up
	}

	[Test]
	public static void EventListenerFiresOnSizeChange()
	{
		let node = new Node();
		defer node.ReleaseRef();
		int fired = 0;
		EventType seen = .Close;
		let id = node.AddEventListener(.SizeChanged, new [&](e) =>
			{
				fired++;
				seen = e.Type;
			});

		node.Size = .(10.0f, 10.0f);
		Test.Assert(fired == 1);
		Test.Assert(seen == .SizeChanged);

		node.RemoveEventListener(id);
		node.Size = .(20.0f, 20.0f);
		Test.Assert(fired == 1); // no longer listening
	}

	[Test]
	public static void AListenerRemovesItselfOrAddsAnotherWhileListenersRun()
	{
		let node = new Node();
		defer node.ReleaseRef();
		int first = 0;
		int second = 0;
		int added = 0;
		uint32 firstId = 0;
		firstId = node.AddEventListener(.SizeChanged, new [&](e) =>
			{
				first++;
				Test.Assert(node.RemoveEventListener(firstId)); // its own: from inside it
				node.AddEventListener(.SizeChanged, new [&](inner) => { added++; });
			});
		node.AddEventListener(.SizeChanged, new [&](e) => { second++; });
		node.Size = .(10.0f, 10.0f);
		Test.Assert(first == 1);
		Test.Assert(second == 1); // the one after it still ran
		Test.Assert(added == 0); // the one added waits for the next event
		node.Size = .(20.0f, 20.0f);
		Test.Assert(first == 1); // gone
		Test.Assert(second == 2);
		Test.Assert(added == 1);
		Test.Assert(!node.RemoveEventListener(firstId)); // already gone
	}

	[Test]
	public static void ACommandHandlerRemovesItselfWhileItRuns()
	{
		let node = new Node();
		defer node.ReleaseRef();
		int ran = 0;
		uint32 token = 0;
		token = node.OnCommand("go", new [&](command) =>
			{
				ran++;
				Test.Assert(node.RemoveCommandHandler(token));
			});
		Test.Assert(node.HandlesCommand("go"));
		var run = CommandEvent();
		run.Id = "go";
		Test.Assert(node.RunCommandHandlers(ref run));
		Test.Assert(ran == 1);
		Test.Assert(!node.HandlesCommand("go"));
		Test.Assert(!node.RunCommandHandlers(ref run));
	}

	[Test]
	public static void SettingSameSizeDoesNotNotify()
	{
		let node = new Node();
		defer node.ReleaseRef();
		node.Size = .(10.0f, 10.0f);
		int fired = 0;
		node.AddEventListener(.SizeChanged, new [&](e) => { fired++; });
		node.Size = .(10.0f, 10.0f); // unchanged
		Test.Assert(fired == 0);
	}

	[Test]
	public static void AChildsIndexFollowsAddsMovesRemovesAndAMoveToAnotherParent()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let kids = scope List<Node>();
		for (int i = 0; i < 5; i++)
			kids.Add(NodeFixtures.Box(root));
		// The test holds its own reference to each, as it removes some and moves one away.
		for (let kid in kids)
			kid.AddRef();
		defer
		{
			for (let kid in kids)
				kid.ReleaseRef();
		}
		for (int i = 0; i < 5; i++)
			Test.Assert(root.GetChildIndex(kids[i]) == i);
		root.SetChildIndex(kids[4], 1);
		Test.Assert(root.GetChildIndex(kids[4]) == 1);
		Test.Assert(root.GetChildIndex(kids[1]) == 2);
		root.RemoveChild(kids[0]);
		Test.Assert(root.GetChildIndex(kids[0]) == Node.cInvalidIndex);
		Test.Assert(root.GetChildIndex(kids[4]) == 0);
		Test.Assert(kids[1].PrevSibling == kids[4]);

		let other = new Node();
		defer other.ReleaseRef();
		NodeFixtures.Box(other);
		other.AddChild(kids[3]);
		Test.Assert(other.GetChildIndex(kids[3]) == 1);
		Test.Assert(root.GetChildIndex(kids[3]) == Node.cInvalidIndex);
		Test.Assert(root.GetChildIndex(kids[2]) == 2);
		Test.Assert(root.GetChildIndex(null) == Node.cInvalidIndex);
	}
}
