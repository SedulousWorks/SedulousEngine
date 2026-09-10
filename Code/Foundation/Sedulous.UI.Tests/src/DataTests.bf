using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The data layer a list or tree view sits on: the view recycler, the selection model, and the
/// adapter that flattens a tree into a list.
class DataTests
{
	// ---- ViewRecycler -----------------------------------------------------------------------

	[Test]
	public static void AnEmptyRecyclerHasNothingToHandOut()
	{
		let recycler = scope ViewRecycler();

		Test.Assert(recycler.Acquire(0) == null);
	}

	/// A recycled view comes back as the SAME instance, which is the whole point: the cost of a
	/// long list is what is on screen, not how far it scrolls.
	[Test]
	public static void ARecycledViewIsHandedBackAgain()
	{
		let recycler = scope ViewRecycler();
		let view = new TestView(50, 30);

		recycler.Recycle(view, 0);
		let reused = recycler.Acquire(0);

		Test.Assert(reused == view);
		Test.Assert(recycler.ReusedCount == 1);
		Test.Assert(recycler.RecycledCount == 1);

		reused.ReleaseRef();
	}

	/// The counters tell a healthy scroll from a leaking one: create a screenful, then reuse.
	[Test]
	public static void TheCountersFollowCreationRecyclingAndReuse()
	{
		let recycler = scope ViewRecycler();
		let adapter = scope SimpleListAdapter(5);

		let first = recycler.GetOrCreate(adapter, 0);
		Test.Assert(recycler.CreatedCount == 1);

		recycler.Recycle(first, 0);
		Test.Assert(recycler.RecycledCount == 1);

		let second = recycler.GetOrCreate(adapter, 1);
		Test.Assert(recycler.ReusedCount == 1);
		Test.Assert(second == first, "the same instance, re-bound");
		Test.Assert(recycler.CreatedCount == 1, "nothing new was built");

		second.ReleaseRef();
	}

	// ---- SelectionModel ---------------------------------------------------------------------

	[Test]
	public static void SingleModeReplacesTheSelection()
	{
		let selection = scope SelectionModel();
		selection.Mode = .Single;

		selection.Select(0);
		selection.Select(1);

		Test.Assert(!selection.IsSelected(0));
		Test.Assert(selection.IsSelected(1));
		Test.Assert(selection.SelectedCount == 1);
	}

	/// Select is a PLAIN CLICK and replaces the selection in every mode, multiple included.
	/// Extending is Toggle and SelectRange, which is what Ctrl and Shift drive.
	///
	/// Accumulating on a plain click was a real bug: a multi select list grew forever, since
	/// clicking around never cleared anything.
	[Test]
	public static void APlainSelectReplacesEvenInMultipleMode()
	{
		let selection = scope SelectionModel();
		selection.Mode = .Multiple;

		selection.Select(0);
		selection.Select(1);
		selection.Select(2);

		Test.Assert(!selection.IsSelected(0));
		Test.Assert(!selection.IsSelected(1));
		Test.Assert(selection.IsSelected(2));
		Test.Assert(selection.SelectedCount == 1);

		// Extending still works through the paths meant for it.
		selection.Toggle(0);
		Test.Assert(selection.SelectedCount == 2);
		selection.SelectRange(0, 3);
		Test.Assert(selection.SelectedCount == 4);

		selection.Select(1);
		Test.Assert(selection.SelectedCount == 1, "a plain click collapses it again");
		Test.Assert(selection.IsSelected(1));
	}

	[Test]
	public static void ToggleAddsThenRemoves()
	{
		let selection = scope SelectionModel();
		selection.Mode = .Multiple;

		selection.Select(0);
		selection.Toggle(0);
		Test.Assert(!selection.IsSelected(0));

		selection.Toggle(0);
		Test.Assert(selection.IsSelected(0));
	}

	/// A range is INCLUSIVE at both ends, which is what a shift click means.
	[Test]
	public static void SelectRangeTakesBothEnds()
	{
		let selection = scope SelectionModel();
		selection.Mode = .Multiple;

		selection.SelectRange(2, 5);

		Test.Assert(selection.SelectedCount == 4);
		Test.Assert(selection.IsSelected(2));
		Test.Assert(selection.IsSelected(3));
		Test.Assert(selection.IsSelected(4));
		Test.Assert(selection.IsSelected(5));
	}

	[Test]
	public static void ClearingEmptiesTheSelection()
	{
		let selection = scope SelectionModel();
		selection.Mode = .Multiple;
		selection.Select(0);
		selection.Toggle(1);

		selection.ClearSelection();

		Test.Assert(selection.SelectedCount == 0);
	}

	/// Inserting an item MOVES the selected positions after it, so a selection survives an edit
	/// above it rather than silently pointing at the wrong rows.
	[Test]
	public static void InsertingShiftsTheSelectedPositionsAfterIt()
	{
		let selection = scope SelectionModel();
		selection.Mode = .Multiple;
		selection.Select(2);
		selection.Toggle(4);

		selection.ShiftIndices(3, 1); // an insert at three

		Test.Assert(selection.IsSelected(2), "before the insert, unchanged");
		Test.Assert(selection.IsSelected(5), "after it, moved along");
	}

	[Test]
	public static void NoneModeSelectsNothingAtAll()
	{
		let selection = scope SelectionModel();
		selection.Mode = .None;

		selection.Select(0);

		Test.Assert(selection.SelectedCount == 0);
	}

	// ---- FlattenedTreeAdapter ---------------------------------------------------------------

	[Test]
	public static void AFreshTreeShowsItsRootsOnly()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		Test.Assert(flat.ItemCount == 3, "three roots, none expanded");
	}

	/// Expanding INSERTS the children into the flat list, and collapsing removes them again: a
	/// collapsed subtree is absent rather than hidden, which is what keeps a big tree cheap.
	[Test]
	public static void ExpandingAndCollapsingAddAndRemoveTheChildren()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		flat.Expand(0); // root nought has two children
		Test.Assert(flat.ItemCount == 5);

		flat.Collapse(0);
		Test.Assert(flat.ItemCount == 3);

		flat.ToggleExpand(0);
		Test.Assert(flat.IsExpanded(0));
		Test.Assert(flat.ItemCount == 5);

		flat.ToggleExpand(0);
		Test.Assert(!flat.IsExpanded(0));
		Test.Assert(flat.ItemCount == 3);
	}

	/// The flat list carries both the node id and the DEPTH, which is what the binder indents
	/// by. The children sit directly after their parent, before the next root.
	[Test]
	public static void TheFlatListCarriesTheNodeIdAndTheDepth()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		flat.Expand(0);

		// Visible: 0, 10, 11, 1, 2
		Test.Assert(flat.GetNodeId(0) == 0);
		Test.Assert(flat.GetNodeId(1) == 10);
		Test.Assert(flat.GetNodeId(2) == 11);
		Test.Assert(flat.GetNodeId(3) == 1);

		Test.Assert(flat.GetDepth(0) == 0);
		Test.Assert(flat.GetDepth(1) == 1);
		Test.Assert(flat.GetDepth(2) == 1);
		Test.Assert(flat.GetDepth(3) == 0, "back to a root");
	}

	/// The expansion saves and restores by NODE ID, so it survives the tree being rebuilt from
	/// changed data where flat positions would not.
	[Test]
	public static void TheExpansionSavesAndRestoresByNodeId()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		flat.Expand(0);
		flat.Expand(1);

		let saved = scope HashSet<int32>();
		flat.GetExpandedNodes(saved);
		Test.Assert(saved.Contains(0));
		Test.Assert(saved.Contains(1));

		flat.Collapse(0);
		flat.Collapse(1);
		Test.Assert(flat.ItemCount == 3);

		flat.SetExpandedNodes(saved);

		Test.Assert(flat.IsExpanded(0));
		Test.Assert(flat.IsExpanded(1));
		Test.Assert(flat.ItemCount == 6, "three roots, two children of nought, one of one");
	}
}
