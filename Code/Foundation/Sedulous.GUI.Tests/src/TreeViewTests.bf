using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// TreeModel + TreeView tests: hierarchical navigation (RowCount(parent)/Index/ParentIndex/
// HasChildren), and a TreeView that flattens visible nodes, expands/collapses (arrow click +
// keyboard), and remaps selection by node id across re-flattening.

/// A tree model's navigation, and the TreeView over it.
class TreeViewTests
{
	/// Tree:  A [A1 [A1x], A2],  B; and a tree view 260 by 300 over it (tall enough to realise
	/// every visible row) in a root 400 by 400. The model outlives the view.
	private class Bed
	{
		public TreeModel Model = new .() ~ delete _;
		public SceneRoot Root;
		public TreeView Tree;
		public int32 A;
		public int32 B;
		public int32 A1;
		public int32 A2;
		public int32 A1x;

		public this()
		{
			A = Model.AddNode(TreeModel.Root, "A");
			B = Model.AddNode(TreeModel.Root, "B");
			A1 = Model.AddNode(A, "A1");
			A2 = Model.AddNode(A, "A2");
			A1x = Model.AddNode(A1, "A1x");
			Root = SceneFixtures.NewScene(400.0f, 400.0f);
			Tree = new TreeView();
			Tree.Size = .(260.0f, 300.0f);
			Tree.RowHeight = 20.0f;
			Tree.IndentWidth = 16.0f;
			Root.AddChild(Tree);
			Tree.ReleaseRef(); // the tree holds it
			Tree.Model = Model;
			Root.UpdateLayout();
		}

		public ~this()
		{
			Root.ReleaseRef(); // before the model the view listens to
		}

		public EventDispatcher D => Root.EventDispatcher;
	}

	[Test]
	public static void TreeModelHierarchyNavigation()
	{
		// Tree:  A [A1 [A1x], A2],  B
		let model = scope TreeModel();
		let a = model.AddNode(TreeModel.Root, "A");
		model.AddNode(TreeModel.Root, "B");
		let a1 = model.AddNode(a, "A1");
		model.AddNode(a, "A2");
		model.AddNode(a1, "A1x");

		Test.Assert(model.RowCount() == 2); // two roots
		let ia = model.Index(0, 0, ModelIndex()); // A
		Test.Assert(model.Data(ia).AsString == "A");
		Test.Assert(model.HasChildren(ia));
		Test.Assert(model.RowCount(ia) == 2); // A1, A2

		let ia1 = model.Index(0, 0, ia); // A1
		Test.Assert(model.Data(ia1).AsString == "A1");
		Test.Assert(model.RowCount(ia1) == 1); // A1x
		Test.Assert(model.ParentIndex(ia1) == ia); // A1's parent is A

		let ib = model.Index(1, 0, ModelIndex()); // B
		Test.Assert(!model.HasChildren(ib));
		Test.Assert(!model.ParentIndex(ia).IsValid); // A is a root
	}

	[Test]
	public static void CollapsedShowsOnlyRootsExpandingRevealsChildren()
	{
		let b = scope Bed();
		Test.Assert(b.Tree.VisibleRowCount == 2); // A, B (collapsed)

		b.Tree.ExpandItem(0); // expand A -> A, A1, A2, B
		Test.Assert(b.Tree.VisibleRowCount == 4);
		Test.Assert(b.Tree.IsItemExpanded(0));
		Test.Assert(b.Tree.ItemDepth(1) == 1); // A1 is a child

		b.Tree.ExpandItem(1); // expand A1 -> A, A1, A1x, A2, B
		Test.Assert(b.Tree.VisibleRowCount == 5);
		Test.Assert(b.Tree.ItemDepth(2) == 2); // A1x is a grandchild

		b.Tree.CollapseItem(0); // collapse A -> A, B
		Test.Assert(b.Tree.VisibleRowCount == 2);
	}

	[Test]
	public static void ClickingTheArrowTogglesExpansion()
	{
		let b = scope Bed();
		// Root A's arrow: row 0 (y in [0,20]), depth 0 -> arrow at x in [0,16].
		SceneFixtures.Click(b.D, .(8.0f, 10.0f));
		Test.Assert(b.Tree.VisibleRowCount == 4); // expanded
		Test.Assert(b.Tree.IsItemExpanded(0));

		SceneFixtures.Click(b.D, .(8.0f, 10.0f));
		Test.Assert(b.Tree.VisibleRowCount == 2); // collapsed again
	}

	[Test]
	public static void SelectionIsRemappedByNodeIdAcrossExpandCollapse()
	{
		let b = scope Bed();
		b.Tree.ExpandItem(0); // flat: A(0), A1(1), A2(2), B(3)
		b.Tree.SelectedItem = 3; // select B
		let selId = b.Tree.SelectedIndex.InternalId;

		b.Tree.CollapseItem(0); // flat: A(0), B(1) - B moved
		Test.Assert(b.Tree.SelectedItem == 1); // remapped to B's new row
		Test.Assert(b.Tree.SelectedIndex.InternalId == selId); // same node
	}

	[Test]
	public static void KeyboardRightExpandsAndLeftCollapsesTheSelection()
	{
		let b = scope Bed();
		b.Tree.RequestFocus();
		b.Tree.SelectedItem = 0; // select A
		b.D.InjectKeyDown((uint32)KeyCode.Right); // expand A
		Test.Assert(b.Tree.VisibleRowCount == 4);
		Test.Assert(b.Tree.IsItemExpanded(0));
		b.D.InjectKeyDown((uint32)KeyCode.Left); // collapse A
		Test.Assert(b.Tree.VisibleRowCount == 2);
		Test.Assert(!b.Tree.IsItemExpanded(0));
	}

	[Test]
	public static void InRightToLeftLeftExpandsAndRightCollapsesTowardTheWayItIsIndented()
	{
		let b = scope Bed();
		b.Root.SetLayoutDirection(.RightToLeft);
		b.Tree.RequestFocus();
		b.Tree.SelectedItem = 0;
		b.D.InjectKeyDown((uint32)KeyCode.Left); // toward the inline end: expand
		Test.Assert(b.Tree.IsItemExpanded(0));
		b.D.InjectKeyDown((uint32)KeyCode.Right); // toward the start: collapse
		Test.Assert(!b.Tree.IsItemExpanded(0));
	}

	/// A chain twenty levels deep at 32 px a level: the rows in view (about fifteen of 20 px in
	/// 300) pass the view's 260 px by their indent alone, so the rows grow that wide and the view
	/// scrolls sideways.
	[Test]
	public static void ARowDeeperThanTheViewIsWideMakesTheRowsThatWide()
	{
		let model = scope TreeModel();
		var parent = TreeModel.Root;
		for (int depth < 20)
			parent = model.AddNode(parent, "Level");
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef(); // before the model the view listens to
		let tree = new TreeView();
		tree.Size = .(260.0f, 300.0f);
		tree.RowHeight = 20.0f;
		tree.IndentWidth = 32.0f;
		root.AddChild(tree);
		tree.ReleaseRef(); // the root holds it
		tree.Model = model;
		root.UpdateLayout();
		Test.Assert(tree.ContentExtent.X <= 260.0f + 0.5f, "collapsed: nothing passes the edge");
		for (int32 item < 20)
			tree.ExpandItem(item);
		root.UpdateLayout();
		root.UpdateLayout(); // the widest row measured as it binds; the rows take it next
		Test.Assert(tree.ContentExtent.X > 10.0f * 32.0f, scope $"{tree.ContentExtent.X}");
		let row = tree.RowForItem(10);
		Test.Assert(row != null);
		Test.Assert(Math.Abs(row.Size.X - tree.ContentExtent.X) < 0.01f);
	}
}
