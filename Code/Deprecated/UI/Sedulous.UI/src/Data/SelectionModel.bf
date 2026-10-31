using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// Selection state, kept SEPARATE from the view showing it, so several views can share one
/// selection and none of them owns it.
class SelectionModel
{
	public SelectionMode Mode = .Single;

	/// Fired after any change, once per change however many indices moved.
	public Event<delegate void()> OnSelectionChanged ~ _.Dispose();

	private HashSet<int32> mSelected = new .() ~ delete _;

	/// Where a Shift range starts: the last plain or Ctrl pick. Minus one when there is none.
	public int32 Anchor { get; private set; } = -1;
	/// The row keyboard navigation moves from: the last pick or range end. Minus one when
	/// there is none.
	public int32 Caret { get; private set; } = -1;

	public int SelectedCount => mSelected.Count;
	public bool IsSelected(int32 index) => mSelected.Contains(index);

	/// Selects an index EXCLUSIVELY, which is what a plain click means.
	///
	/// The previous selection clears in EVERY mode, Multiple included. Extending is what
	/// Toggle and SelectRange are for; if Multiple accumulated here, plain clicking would grow
	/// the selection forever and never shrink it.
	public void Select(int32 index)
	{
		if (Mode == .None)
			return;
		Anchor = index;
		Caret = index;
		// Already exactly this, so nothing changed and nobody needs telling.
		if ((mSelected.Count == 1) && mSelected.Contains(index))
			return;

		mSelected.Clear();
		mSelected.Add(index);
		OnSelectionChanged();
	}

	public void Deselect(int32 index)
	{
		if (mSelected.Remove(index))
			OnSelectionChanged();
	}

	/// Drops selected indices that no longer exist.
	///
	/// Called when the data set changes: a stale index would silently highlight whatever row
	/// has since moved into that position.
	public void PruneFrom(int32 count)
	{
		let stale = scope List<int32>();
		for (let index in mSelected)
		{
			if ((index < 0) || (index >= count))
				stale.Add(index);
		}
		if (stale.IsEmpty)
			return;

		for (let index in stale)
			mSelected.Remove(index);
		if (Anchor >= count)
			Anchor = -1;
		if (Caret >= count)
			Caret = -1;
		OnSelectionChanged();
	}

	/// Replaces the whole selection in one step, and so fires ONE change.
	///
	/// For remapping positional selection after the data set shifts under it, as expanding or
	/// collapsing a tree does.
	public void ReplaceAll(Span<int32> indices)
	{
		mSelected.Clear();
		for (let index in indices)
		{
			if (index >= 0)
				mSelected.Add(index);
		}
		OnSelectionChanged();
	}

	/// Toggles one index, which is what a Ctrl click means.
	public void Toggle(int32 index)
	{
		if (Mode == .None)
			return;
		Anchor = index;
		Caret = index;

		if (IsSelected(index))
		{
			Deselect(index);
			return;
		}

		if (Mode == .Single)
			mSelected.Clear();
		if (mSelected.Add(index))
			OnSelectionChanged();
	}

	/// Selects the inclusive range, which is what a Shift click means. Single mode takes only
	/// the far end.
	public void SelectRange(int32 from, int32 to)
	{
		if (Mode == .None)
			return;
		if (Mode == .Single)
		{
			Select(to);
			return;
		}

		let low = Min(from, to);
		let high = Max(from, to);
		mSelected.Clear();
		for (int32 i = low; i <= high; i++)
			mSelected.Add(i);
		OnSelectionChanged();
	}

	/// Extends from the anchor to `index`, which is what Shift click and Shift arrow mean: the
	/// range always runs from where it started, so repeated extension grows or shrinks it.
	/// Without an anchor it is a plain pick.
	public void ExtendTo(int32 index)
	{
		if (Mode == .None)
			return;
		if ((Anchor < 0) || (Mode == .Single))
		{
			Select(index);
			return;
		}
		SelectRange(Anchor, index);
		Caret = index;
	}

	public void ClearSelection()
	{
		Anchor = -1;
		Caret = -1;
		if (mSelected.IsEmpty)
			return;
		mSelected.Clear();
		OnSelectionChanged();
	}

	/// BORROWED.
	public HashSet<int32> SelectedPositions => mSelected;

	/// The first selected index, or minus one.
	public int32 FirstSelected()
	{
		for (let index in mSelected)
			return index;
		return -1;
	}

	/// Moves indices when items are inserted or removed at or above `startPos`. A positive
	/// delta is an insertion and a negative one a removal.
	public void ShiftIndices(int32 startPos, int32 delta)
	{
		let previous = scope List<int32>();
		for (let index in mSelected)
			previous.Add(index);

		mSelected.Clear();
		for (let index in previous)
		{
			if (index < startPos)
			{
				mSelected.Add(index);
				continue;
			}
			let shifted = index + delta;
			// A removal can push an index below nought, and that item is simply gone.
			if (shifted >= 0)
				mSelected.Add(shifted);
		}
		if (Anchor >= startPos)
			Anchor = Math.Max(Anchor + delta, -1);
		if (Caret >= startPos)
			Caret = Math.Max(Caret + delta, -1);
	}
}
