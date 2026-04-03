using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A selectable item list control with support for single, multiple, and extended selection modes.
public class ListBox : ItemsControl
{
	private SelectionMode mSelectionMode = .Single;
	private List<int> mSelectedIndices = new .() ~ delete _;
	private int mAnchorIndex = -1;      // Anchor for range selection
	private int mFocusedIndex = -1;     // Currently focused item (keyboard navigation)
	private int mHoveredIndex = -1;     // Currently hovered item (mouse)

	// Type-ahead search
	private String mTypeAheadBuffer = new .() ~ delete _;
	private double mLastTypeAheadTime = 0;
	private const double TypeAheadResetDelay = 1.0;  // Reset after 1 second

	// Events
	private EventAccessor<delegate void(ListBox)> mSelectionChanged = new .() ~ delete _;

	/// Creates a new ListBox.
	public this()
	{
		// ListBox clips items to its bounds
		ClipToBounds = true;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ListBox";

	/// The selection mode.
	public SelectionMode SelectionMode
	{
		get => mSelectionMode;
		set
		{
			if (mSelectionMode != value)
			{
				mSelectionMode = value;
				// Clear selection when mode changes
				ClearSelection();
			}
		}
	}

	/// The index of the selected item (for Single mode) or the first selected item.
	/// Returns -1 if no item is selected.
	public int SelectedIndex
	{
		get => mSelectedIndices.Count > 0 ? mSelectedIndices[0] : -1;
		set
		{
			if (value < 0 || value >= ItemCount)
			{
				ClearSelection();
			}
			else
			{
				SelectSingle(value);
			}
		}
	}

	/// The selected item (for Single mode) or the first selected item.
	/// Returns null if no item is selected.
	public Object SelectedItem
	{
		get
		{
			let index = SelectedIndex;
			if (index < 0)
				return null;
			return GetItem(index);
		}
	}

	/// Gets a copy of the selected indices list.
	public void GetSelectedIndices(List<int> outIndices)
	{
		outIndices.Clear();
		for (let idx in mSelectedIndices)
			outIndices.Add(idx);
	}

	/// The number of selected items.
	public int SelectedCount => mSelectedIndices.Count;

	/// Event fired when selection changes.
	public EventAccessor<delegate void(ListBox)> SelectionChanged => mSelectionChanged;

	// === Selection Methods ===

	/// Selects a single item, clearing other selections.
	public void SelectSingle(int index)
	{
		if (index < 0 || index >= ItemCount)
			return;

		bool changed = mSelectedIndices.Count != 1 || (mSelectedIndices.Count > 0 && mSelectedIndices[0] != index);

		// Clear existing selection
		for (let idx in mSelectedIndices)
			SetItemSelected(idx, false);
		mSelectedIndices.Clear();

		// Select the new item
		mSelectedIndices.Add(index);
		SetItemSelected(index, true);
		mAnchorIndex = index;
		mFocusedIndex = index;

		if (changed)
			RaiseSelectionChanged();
	}

	/// Selects an item (in addition to existing selection).
	public void SelectItem(int index)
	{
		if (index < 0 || index >= ItemCount)
			return;

		if (mSelectionMode == .Single)
		{
			SelectSingle(index);
			return;
		}

		if (!IsItemSelected(index))
		{
			mSelectedIndices.Add(index);
			SetItemSelected(index, true);
			RaiseSelectionChanged();
		}
	}

	/// Deselects an item.
	public void DeselectItem(int index)
	{
		let listIndex = mSelectedIndices.IndexOf(index);
		if (listIndex >= 0)
		{
			mSelectedIndices.RemoveAt(listIndex);
			SetItemSelected(index, false);
			RaiseSelectionChanged();
		}
	}

	/// Toggles selection of an item.
	public void ToggleSelection(int index)
	{
		if (IsItemSelected(index))
			DeselectItem(index);
		else
			SelectItem(index);
	}

	/// Selects a range of items (inclusive).
	public void SelectRange(int startIndex, int endIndex)
	{
		if (mSelectionMode == .Single)
		{
			SelectSingle(endIndex);
			return;
		}

		let minIndex = Math.Min(startIndex, endIndex);
		let maxIndex = Math.Max(startIndex, endIndex);

		bool changed = false;
		for (int i = minIndex; i <= maxIndex; i++)
		{
			if (i >= 0 && i < ItemCount && !IsItemSelected(i))
			{
				mSelectedIndices.Add(i);
				SetItemSelected(i, true);
				changed = true;
			}
		}

		if (changed)
			RaiseSelectionChanged();
	}

	/// Clears all selection.
	public void ClearSelection()
	{
		if (mSelectedIndices.Count == 0)
			return;

		for (let idx in mSelectedIndices)
			SetItemSelected(idx, false);
		mSelectedIndices.Clear();

		RaiseSelectionChanged();
	}

	/// Selects all items (only for Multiple/Extended modes).
	public void SelectAll()
	{
		if (mSelectionMode == .Single)
			return;

		bool changed = false;
		for (int i = 0; i < ItemCount; i++)
		{
			if (!IsItemSelected(i))
			{
				mSelectedIndices.Add(i);
				SetItemSelected(i, true);
				changed = true;
			}
		}

		if (changed)
			RaiseSelectionChanged();
	}

	/// Returns whether an item is selected.
	public bool IsItemSelected(int index)
	{
		return mSelectedIndices.Contains(index);
	}

	/// Sets the visual selection state of an item container.
	private void SetItemSelected(int index, bool selected)
	{
		if (let container = GetContainer(index) as ISelectable)
			container.IsSelected = selected;
	}

	/// Raises the SelectionChanged event.
	private void RaiseSelectionChanged()
	{
		mSelectionChanged.[Friend]Invoke(this);
	}

	// === Keyboard Navigation ===

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Handled || ItemCount == 0)
			return;

		let hasCtrl = e.HasModifier(.Ctrl);
		let hasShift = e.HasModifier(.Shift);

		switch (e.Key)
		{
		case .Up:
			NavigateUp(hasShift, hasCtrl);
			e.Handled = true;

		case .Down:
			NavigateDown(hasShift, hasCtrl);
			e.Handled = true;

		case .Home:
			NavigateToStart(hasShift, hasCtrl);
			e.Handled = true;

		case .End:
			NavigateToEnd(hasShift, hasCtrl);
			e.Handled = true;

		case .PageUp:
			NavigatePageUp(hasShift);
			e.Handled = true;

		case .PageDown:
			NavigatePageDown(hasShift);
			e.Handled = true;

		case .Space:
			if (mSelectionMode != .Single && mFocusedIndex >= 0)
			{
				ToggleSelection(mFocusedIndex);
				e.Handled = true;
			}

		case .A:
			if (hasCtrl && mSelectionMode != .Single)
			{
				SelectAll();
				e.Handled = true;
			}

		default:
		}
	}

	private void NavigateUp(bool extendSelection, bool keepSelection)
	{
		if (mFocusedIndex <= 0)
		{
			mFocusedIndex = 0;
		}
		else
		{
			mFocusedIndex--;
		}
		HandleNavigationSelection(extendSelection, keepSelection);
		ScrollIntoView(mFocusedIndex);
	}

	private void NavigateDown(bool extendSelection, bool keepSelection)
	{
		if (mFocusedIndex >= ItemCount - 1)
		{
			mFocusedIndex = ItemCount - 1;
		}
		else
		{
			if (mFocusedIndex < 0)
				mFocusedIndex = 0;
			else
				mFocusedIndex++;
		}
		HandleNavigationSelection(extendSelection, keepSelection);
		ScrollIntoView(mFocusedIndex);
	}

	private void NavigateToStart(bool extendSelection, bool keepSelection)
	{
		mFocusedIndex = 0;
		HandleNavigationSelection(extendSelection, keepSelection);
		ScrollIntoView(mFocusedIndex);
	}

	private void NavigateToEnd(bool extendSelection, bool keepSelection)
	{
		mFocusedIndex = ItemCount - 1;
		HandleNavigationSelection(extendSelection, keepSelection);
		ScrollIntoView(mFocusedIndex);
	}

	private void NavigatePageUp(bool extendSelection)
	{
		// Move by approximately one page (10 items or to start)
		let pageSize = 10;
		mFocusedIndex = Math.Max(0, mFocusedIndex - pageSize);
		HandleNavigationSelection(extendSelection, false);
		ScrollIntoView(mFocusedIndex);
	}

	private void NavigatePageDown(bool extendSelection)
	{
		let pageSize = 10;
		mFocusedIndex = Math.Min(ItemCount - 1, Math.Max(0, mFocusedIndex) + pageSize);
		HandleNavigationSelection(extendSelection, false);
		ScrollIntoView(mFocusedIndex);
	}

	private void HandleNavigationSelection(bool extendSelection, bool keepSelection)
	{
		if (mFocusedIndex < 0 || mFocusedIndex >= ItemCount)
			return;

		switch (mSelectionMode)
		{
		case .Single:
			SelectSingle(mFocusedIndex);

		case .Multiple:
			// In multiple mode, navigation just moves focus
			// Selection requires clicking or Space
			if (!keepSelection)
			{
				SelectSingle(mFocusedIndex);
			}

		case .Extended:
			if (extendSelection)
			{
				// Extend selection from anchor
				ClearSelection();
				SelectRange(mAnchorIndex >= 0 ? mAnchorIndex : 0, mFocusedIndex);
			}
			else if (!keepSelection)
			{
				SelectSingle(mFocusedIndex);
			}
		}
	}

	// === Mouse Input ===

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button != .Left)
			return;

		let index = GetItemIndexAtPoint(e.ScreenPosition);
		if (index < 0)
			return;

		let hasCtrl = e.HasModifier(.Ctrl);
		let hasShift = e.HasModifier(.Shift);

		mFocusedIndex = index;

		switch (mSelectionMode)
		{
		case .Single:
			SelectSingle(index);

		case .Multiple:
			// In multiple mode, clicking toggles
			ToggleSelection(index);
			mAnchorIndex = index;

		case .Extended:
			if (hasCtrl && hasShift)
			{
				// Extend selection from anchor without clearing
				SelectRange(mAnchorIndex >= 0 ? mAnchorIndex : 0, index);
			}
			else if (hasShift)
			{
				// Range selection from anchor
				ClearSelection();
				SelectRange(mAnchorIndex >= 0 ? mAnchorIndex : 0, index);
			}
			else if (hasCtrl)
			{
				// Toggle individual item
				ToggleSelection(index);
				mAnchorIndex = index;
			}
			else
			{
				// Simple click - select single
				SelectSingle(index);
			}
		}

		e.Handled = true;
	}

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		let index = GetItemIndexAtPoint(e.ScreenPosition);
		if (index != mHoveredIndex)
		{
			mHoveredIndex = index;
			// Trigger visual update
		}
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		mHoveredIndex = -1;
	}

	/// Returns whether the item at the specified index is currently hovered.
	public bool IsItemHovered(int index) => index >= 0 && index == mHoveredIndex;

	// === Type-Ahead Search ===

	protected override void OnTextInput(TextInputEventArgs e)
	{
		base.OnTextInput(e);

		if (ItemCount == 0)
			return;

		let currentTime = e.Timestamp;

		// Reset buffer if too much time has passed
		if (currentTime - mLastTypeAheadTime > TypeAheadResetDelay || mLastTypeAheadTime == 0)
			mTypeAheadBuffer.Clear();

		mLastTypeAheadTime = currentTime;
		mTypeAheadBuffer.Append(e.Character);

		// Search for matching item
		let matchIndex = FindMatchingItem(mTypeAheadBuffer);
		if (matchIndex >= 0)
		{
			SelectSingle(matchIndex);
			ScrollIntoView(matchIndex);
		}

		e.Handled = true;
	}

	/// Finds the first item starting with the search text (case-insensitive).
	private int FindMatchingItem(StringView searchText)
	{
		if (searchText.IsEmpty)
			return -1;

		for (int i = 0; i < ItemCount; i++)
		{
			let item = GetItem(i);
			if (item == null)
				continue;

			// Get item text
			String itemText = scope .();
			if (let str = item as String)
				itemText.Set(str);
			else
				item.ToString(itemText);

			// Case-insensitive prefix match
			if (itemText.Length >= searchText.Length)
			{
				bool matches = true;
				for (int j = 0; j < searchText.Length; j++)
				{
					if (searchText[j].ToLower != itemText[j].ToLower)
					{
						matches = false;
						break;
					}
				}
				if (matches)
					return i;
			}
		}

		return -1;
	}

	// === Item Callbacks ===

	protected override void OnItemRemoved(int index, Object item)
	{
		// Update selection indices
		for (int i = mSelectedIndices.Count - 1; i >= 0; i--)
		{
			if (mSelectedIndices[i] == index)
			{
				mSelectedIndices.RemoveAt(i);
			}
			else if (mSelectedIndices[i] > index)
			{
				mSelectedIndices[i]--;
			}
		}

		// Update focused index
		if (mFocusedIndex == index)
			mFocusedIndex = Math.Min(mFocusedIndex, ItemCount - 1);
		else if (mFocusedIndex > index)
			mFocusedIndex--;

		// Update anchor index
		if (mAnchorIndex == index)
			mAnchorIndex = Math.Min(mAnchorIndex, ItemCount - 1);
		else if (mAnchorIndex > index)
			mAnchorIndex--;
	}

	protected override void OnItemsCleared()
	{
		mSelectedIndices.Clear();
		mFocusedIndex = -1;
		mAnchorIndex = -1;
	}
}
