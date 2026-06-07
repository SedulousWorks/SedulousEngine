namespace Sedulous.GUI;

using System;
using System.Collections;

/// Captures and restores TreeView state (expansion, selection, scroll).
/// Useful for preserving state across data reloads or view rebuilds.
public class HierarchicalState
{
	/// Set of expanded node IDs.
	public HashSet<int32> ExpandedNodes = new .() ~ delete _;

	/// Set of selected flat positions.
	public HashSet<int32> SelectedPositions = new .() ~ delete _;

	/// Scroll Y offset.
	public float ScrollY;

	/// Capture the current state from a TreeView.
	public void CaptureState(TreeView tree)
	{
		ExpandedNodes.Clear();
		tree.FlatAdapter.GetExpandedNodes(ExpandedNodes);

		SelectedPositions.Clear();
		for (let pos in tree.Selection.SelectedPositions)
			SelectedPositions.Add(pos);

		ScrollY = tree.InternalListView.ScrollY;
	}

	/// Apply previously captured state to a TreeView.
	public void ApplyState(TreeView tree)
	{
		// Restore expansion.
		tree.FlatAdapter.SetExpandedNodes(ExpandedNodes);

		// Restore selection.
		tree.Selection.ClearSelection();
		for (let pos in SelectedPositions)
			tree.Selection.Select(pos);

		// Restore scroll.
		let currentScroll = tree.InternalListView.ScrollY;
		tree.InternalListView.ScrollBy(ScrollY - currentScroll);
	}
}
