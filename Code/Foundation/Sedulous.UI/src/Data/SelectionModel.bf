namespace Sedulous.UI;

using System;
using System.Collections;

public enum SelectionMode { None, Single, Multiple }

/// Decoupled selection state. Tracks selected indices independently
/// of the data view. Multiple views can share one SelectionModel.
public class SelectionModel
{
	public SelectionMode Mode = .Single;
	private HashSet<int32> mSelected = new .() ~ delete _;

	public Event<delegate void()> OnSelectionChanged ~ _.Dispose();

	/// Number of selected items.
	public int SelectedCount => mSelected.Count;

	/// Check if an index is selected.
	public bool IsSelected(int32 index) => mSelected.Contains(index);

	/// Select an index. In Single mode, clears previous selection.
	public void Select(int32 index)
	{
		if (Mode == .None) return;
		if (Mode == .Single) mSelected.Clear();
		if (mSelected.Add(index))
			OnSelectionChanged();
	}

	/// Deselect an index.
	public void Deselect(int32 index)
	{
		if (mSelected.Remove(index))
			OnSelectionChanged();
	}

	/// Toggle selection of an index (for Ctrl+click).
	public void Toggle(int32 index)
	{
		if (Mode == .None) return;
		if (IsSelected(index)) Deselect(index);
		else
		{
			if (Mode == .Single) mSelected.Clear();
			if (mSelected.Add(index))
				OnSelectionChanged();
		}
	}

	/// Select a range of indices from..to inclusive (for Shift+click).
	/// In Single mode, selects only `to`.
	public void SelectRange(int32 from, int32 to)
	{
		if (Mode == .None) return;
		if (Mode == .Single) { Select(to); return; }

		let lo = Math.Min(from, to);
		let hi = Math.Max(from, to);
		mSelected.Clear();
		for (int32 i = lo; i <= hi; i++)
			mSelected.Add(i);
		OnSelectionChanged();
	}

	/// Clear all selections.
	public void ClearSelection()
	{
		if (mSelected.Count > 0)
		{
			mSelected.Clear();
			OnSelectionChanged();
		}
	}

	/// Get all selected indices.
	public HashSet<int32> SelectedPositions => mSelected;

	/// Get the first selected index, or -1.
	public int32 FirstSelected
	{
		get
		{
			for (let idx in mSelected) return idx;
			return -1;
		}
	}

	/// Adjust indices when items are inserted/removed above them.
	/// delta > 0 = insertion, delta < 0 = removal.
	public void ShiftIndices(int32 startPos, int32 delta)
	{
		let oldSelected = scope List<int32>();
		for (let idx in mSelected) oldSelected.Add(idx);

		mSelected.Clear();
		for (let idx in oldSelected)
		{
			if (idx >= startPos)
			{
				let newIdx = idx + delta;
				if (newIdx >= 0) // guard against negative indices
					mSelected.Add(newIdx);
			}
			else
				mSelected.Add(idx);
		}
	}
}
