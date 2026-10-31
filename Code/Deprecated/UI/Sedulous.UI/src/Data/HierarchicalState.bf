using System;
using System.Collections;

namespace Sedulous.UI;

/// A snapshot of what a TreeView is showing: what is open, what is selected, and where it is
/// scrolled to.
///
/// For rebuilding a tree over changed data without losing the reader's place. An editor
/// refreshing its hierarchy over a modified scene captures before and applies after, so the
/// same nodes come back open and the view has not jumped.
class HierarchicalState
{
	public HashSet<int32> ExpandedNodes = new .() ~ delete _;
	public HashSet<int32> SelectedPositions = new .() ~ delete _;
	public float ScrollY = 0.0f;

	public void CaptureState(TreeView tree)
	{
		ExpandedNodes.Clear();
		if (tree.FlatAdapter != null)
			tree.FlatAdapter.GetExpandedNodes(ExpandedNodes);

		SelectedPositions.Clear();
		for (let position in tree.Selection.SelectedPositions)
			SelectedPositions.Add(position);

		ScrollY = tree.InternalListView.ScrollY;
	}

	public void ApplyState(TreeView tree)
	{
		// The expansion goes back FIRST, because the positions a selection is expressed in
		// only mean anything once the same nodes are open again.
		if (tree.FlatAdapter != null)
			tree.FlatAdapter.SetExpandedNodes(ExpandedNodes);

		tree.Selection.ClearSelection();
		for (let position in SelectedPositions)
			tree.Selection.Select(position);

		// Relative, because ScrollBy is what clamps to the rebuilt extent.
		tree.InternalListView.ScrollBy(ScrollY - tree.InternalListView.ScrollY);
	}
}
