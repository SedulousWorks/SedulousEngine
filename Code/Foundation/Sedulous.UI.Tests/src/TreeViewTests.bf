using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The tree: an ordinary list over a flattened adapter, plus the indent, the chevrons and the
/// expansion.
///
/// SimpleTreeAdapter gives three roots, of which the first has two children and the second one.
class TreeViewTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 200, 300);
	}

	// ---- Flattening -------------------------------------------------------------------------

	[Test]
	public static void AnAdapterShowsItsRootsAndNothingElse()
	{
		let adapter = scope SimpleTreeAdapter();
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tree = new TreeView();
		tree.SetAdapter(adapter);
		root.AddView(tree);
		UITest.LayoutPass(context, root);

		Test.Assert(tree.FlatAdapter != null);
		Test.Assert(tree.FlatAdapter.ItemCount == 3, "three roots, collapsed");
	}

	/// A collapsed node's descendants are ABSENT from the flat list rather than hidden in it,
	/// which is what keeps a large collapsed tree cheap.
	[Test]
	public static void ExpandingAndCollapsingChangesWhatExists()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		Test.Assert(tree.FlatAdapter.ItemCount == 3);

		tree.ToggleExpand(0);
		Test.Assert(tree.FlatAdapter.ItemCount == 5, "root 0 brought its two children");

		tree.ToggleExpand(0);
		Test.Assert(tree.FlatAdapter.ItemCount == 3);
	}

	[Test]
	public static void ExpandedChildrenSitDirectlyBelowTheirParent()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		tree.FlatAdapter.Expand(1);
		Test.Assert(tree.FlatAdapter.ItemCount == 4);
		Test.Assert(tree.FlatAdapter.GetNodeId(2) == 20, "root 1's child, right after it");

		tree.FlatAdapter.Expand(0);
		Test.Assert(tree.FlatAdapter.ItemCount == 6);

		tree.FlatAdapter.Collapse(0);
		Test.Assert(tree.FlatAdapter.ItemCount == 4);
	}

	// ---- Indentation ------------------------------------------------------------------------

	/// The content inset is the ONE source of truth for where a row's text starts, because the
	/// chevron occupies the indent level before it. An adapter that hardcodes a pixel constant
	/// instead is how a chevron ends up drawn over the row text.
	[Test]
	public static void TheContentInsetClearsTheChevronColumn()
	{
		let tree = new TreeView();
		defer tree.ReleaseRef();

		Test.Assert(tree.ContentInset(0) == 20, "one indent past the root's chevron");
		Test.Assert(tree.ContentInset(1) == 40);
		Test.Assert(tree.ContentInset(2) == 60);

		tree.IndentWidth.Value = 12;
		Test.Assert(tree.ContentInset(0) == 12, "and it tracks the indent width");
		Test.Assert(tree.ContentInset(2) == 36);
	}

	/// A click in the chevron column toggles; one to the right of it does not. Only a node with
	/// children has a chevron to hit at all.
	[Test]
	public static void OnlyTheChevronColumnOfAParentToggles()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		// Root 0 has children, so its chevron column is the first indent width.
		Test.Assert(tree.IsArrowHit(0, 5));
		Test.Assert(!tree.IsArrowHit(0, 25), "past the chevron, into the content");

		// Root 2 is a leaf: nothing to expand, so nothing to hit.
		Test.Assert(!tree.IsArrowHit(2, 5));
	}

	// ---- Selection across a rebuild -----------------------------------------------------------

	[Test]
	public static void SelectionPassesThroughToTheList()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		tree.Selection.Select(0);
		Test.Assert(tree.Selection.IsSelected(0));
		Test.Assert(tree.Selection.FirstSelected() == 0);
	}

	/// Collapsing something ABOVE the selection shifts every flat index after it, so the
	/// selection is carried across by NODE id. Without that the highlight jumps to whichever
	/// row inherits the old index.
	[Test]
	public static void ACollapseAboveTheSelectionKeepsTheSameNodeSelected()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		tree.ToggleExpand(0); // root0, child, child, root1, root2
		Test.Assert(tree.FlatAdapter.ItemCount == 5);

		let root1Node = tree.FlatAdapter.GetNodeId(3);
		tree.Selection.Select(3);

		tree.ToggleExpand(0); // every index above root 0's children shifts down by two

		Test.Assert(tree.FlatAdapter.ItemCount == 3);
		let newPosition = tree.FlatAdapter.PositionOfNode(root1Node);
		Test.Assert(newPosition == 1);
		Test.Assert(tree.Selection.IsSelected(newPosition));
		Test.Assert(!tree.Selection.IsSelected(3), "and not the row that inherited the index");
	}

	/// A selected node the collapse HIDES drops out of the selection rather than being remapped
	/// onto some arbitrary surviving row.
	[Test]
	public static void CollapsingOverTheSelectionDropsIt()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		tree.ToggleExpand(0);
		Test.Assert(tree.FlatAdapter.ItemCount == 5);
		tree.Selection.Select(1); // a child of root 0

		tree.ToggleExpand(0);

		Test.Assert(tree.Selection.SelectedCount == 0);
	}

	/// Toggling reports which node it was, once.
	[Test]
	public static void TogglingReportsTheNode()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		var toggled = -1;
		var count = 0;
		tree.OnItemToggled.Add(new [&toggled, &count](nodeId) =>
			{
				toggled = nodeId;
				count++;
			});

		tree.ToggleExpand(0);

		Test.Assert(toggled == 0);
		Test.Assert(count == 1);
	}

	// ---- Adapter lifetime ---------------------------------------------------------------------

	/// Setting the adapter again rebuilds, which an editor refreshing a hierarchy over a
	/// changed scene does constantly. The list is detached from the old flattened adapter
	/// before that adapter is destroyed, or the detach itself reads freed memory.
	[Test]
	public static void SettingTheAdapterAgainRebuildsSafely()
	{
		let adapter = scope SimpleTreeAdapter();
		let other = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();

		tree.SetAdapter(adapter);
		let before = tree.FlatAdapter.ItemCount;

		tree.SetAdapter(adapter);
		Test.Assert(tree.FlatAdapter != null);
		Test.Assert(tree.FlatAdapter.ItemCount == before);

		tree.SetAdapter(other);
		Test.Assert(tree.FlatAdapter != null);
	}

	/// Null DETACHES rather than building a flattened adapter over nothing. Owners call it from
	/// their destructors, so a tree cannot outlive an adapter it does not own.
	[Test]
	public static void SettingANullAdapterDetaches()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();

		tree.SetAdapter(adapter);
		Test.Assert(tree.FlatAdapter != null);

		tree.SetAdapter(null);
		Test.Assert(tree.FlatAdapter == null);

		// And reattaching afterwards works.
		tree.SetAdapter(adapter);
		Test.Assert(tree.FlatAdapter != null);
		Test.Assert(tree.FlatAdapter.ItemCount > 0);
	}

	// ---- Keys -------------------------------------------------------------------------------

	/// A key the internal list does not want bubbles out to the tree, which maps the flat
	/// selection to a node id and offers it to the consumer. That is the whole path an editor's
	/// F2 or Delete takes.
	[Test]
	public static void AnUnhandledKeyReachesTheConsumerAsANodeId()
	{
		let adapter = scope SimpleTreeAdapter();
		let context = new UIContext();
		let root = new RootView();
		context.AddRootView(root);
		defer { root.ReleaseRef(); delete context; }

		let tree = new TreeView();
		root.AddView(tree);
		tree.SetAdapter(adapter);
		tree.Selection.Select(0);

		context.GetFocusManager().SetFocus(tree.InternalListView);

		var firedNode = -1;
		tree.OnItemKeyDown.Add(new [&firedNode](nodeId, args) =>
			{
				firedNode = nodeId;
				args.Handled = true;
			});

		Test.Assert(context.GetInputManager().ProcessKeyDown(.F2, .None, false));
		Test.Assert(firedNode == 0);
	}

	/// Right opens and Left closes, and neither is handled when there is nothing to do, so an
	/// arrow on a leaf still reaches the list's own navigation.
	[Test]
	public static void TheArrowsOpenAndCloseWithoutSwallowingWhatTheyCannotUse()
	{
		let adapter = scope SimpleTreeAdapter();
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tree = new TreeView();
		root.AddView(tree);
		tree.SetAdapter(adapter);
		UITest.LayoutPass(context, root);
		tree.Selection.Select(0);

		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		tree.OnKeyDown(right);
		Test.Assert(tree.FlatAdapter.IsExpanded(0));
		Test.Assert(right.Handled);

		// Already open: Right has nothing to do and lets the key past.
		let rightAgain = scope KeyEventArgs();
		rightAgain.Set(.Right, .None, false);
		tree.OnKeyDown(rightAgain);
		Test.Assert(!rightAgain.Handled);

		let left = scope KeyEventArgs();
		left.Set(.Left, .None, false);
		tree.OnKeyDown(left);
		Test.Assert(!tree.FlatAdapter.IsExpanded(0));
		Test.Assert(left.Handled);

		// A leaf has nothing to open, so Right passes through there too.
		tree.Selection.Select(2);
		let onLeaf = scope KeyEventArgs();
		onLeaf.Set(.Right, .None, false);
		tree.OnKeyDown(onLeaf);
		Test.Assert(!onLeaf.Handled);
	}

	// ---- HierarchicalState --------------------------------------------------------------------

	/// A snapshot puts the reader back where they were: the same nodes open, the same rows
	/// selected. What an editor captures before rebuilding a hierarchy and applies after.
	[Test]
	public static void AStateSnapshotRestoresWhatWasOpenAndSelected()
	{
		let adapter = scope SimpleTreeAdapter();
		let tree = new TreeView();
		defer tree.ReleaseRef();
		tree.SetAdapter(adapter);

		tree.FlatAdapter.Expand(0);
		tree.FlatAdapter.Expand(1);
		tree.Selection.Select(2);

		let state = scope HierarchicalState();
		state.CaptureState(tree);

		tree.FlatAdapter.Collapse(0);
		tree.FlatAdapter.Collapse(1);
		tree.Selection.ClearSelection();
		Test.Assert(tree.FlatAdapter.ItemCount == 3);

		state.ApplyState(tree);

		Test.Assert(tree.FlatAdapter.IsExpanded(0));
		Test.Assert(tree.FlatAdapter.IsExpanded(1));
		Test.Assert(tree.FlatAdapter.ItemCount == 6);
		Test.Assert(tree.Selection.IsSelected(2));
	}
}
