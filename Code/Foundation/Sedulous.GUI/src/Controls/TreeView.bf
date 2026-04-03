using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A hierarchical tree control with expand/collapse support.
public class TreeView : Control
{
	// Internal layout
	private ScrollViewer mScrollViewer ~ delete _;
	private StackPanel mItemsPanel;  // Owned by scroll viewer

	// Tree data
	private List<TreeViewItem> mRootItems = new .() ~ DeleteContainerAndItems!(_);
	private List<TreeViewItem> mVisibleItems = new .() ~ delete _;  // References only

	// Selection state
	private TreeViewItem mSelectedItem;
	private List<TreeViewItem> mSelectedItems = new .() ~ delete _;  // All selected items (references only)
	private bool mMultiSelect = false;
	private int mFocusedIndex = -1;
	private int mHoveredIndex = -1;

	// Inline editing
	private bool mIsEditable = false;
	private TextBox mEditTextBox ~ delete _;
	private TreeViewItem mEditingItem;

	// Events
	private EventAccessor<delegate void(TreeView)> mSelectionChanged = new .() ~ delete _;
	private EventAccessor<delegate void(TreeView, TreeViewItem)> mItemExpanded = new .() ~ delete _;
	private EventAccessor<delegate void(TreeView, TreeViewItem)> mItemCollapsed = new .() ~ delete _;
	private EventAccessor<delegate void(TreeView, TreeViewItem, StringView)> mItemRenamed = new .() ~ delete _;

	/// Creates a new TreeView.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;

		// Create internal scroll viewer and items panel
		mScrollViewer = new ScrollViewer();
		mScrollViewer.SetParent(this);
		mScrollViewer.HorizontalScrollBarVisibility = .Auto;
		mScrollViewer.VerticalScrollBarVisibility = .Auto;

		mItemsPanel = new StackPanel();
		mItemsPanel.Orientation = .Vertical;
		mItemsPanel.Spacing = 0;
		mScrollViewer.Content = mItemsPanel;
	}

	/// Destructor - clean up panel and edit state before items are deleted.
	public ~this()
	{
		// Cancel any active edit without committing
		if (mEditTextBox != null)
		{
			mEditingItem = null;
			mEditTextBox.OnDetachedFromContext();
			delete mEditTextBox;
			mEditTextBox = null;
		}

		// Remove items from panel without deleting them (they're owned by mRootItems)
		mItemsPanel?.ClearChildren(deleteAll: false);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TreeView";

	/// Number of root items.
	public int ItemCount => mRootItems.Count;

	/// The currently selected item (primary selection).
	/// Setting this clears multi-selection and selects only the specified item.
	public TreeViewItem SelectedItem
	{
		get => mSelectedItem;
		set
		{
			if (mSelectedItem != value || mSelectedItems.Count > 1)
			{
				// Cancel any active edit
				if (mEditingItem != null)
					EndEdit(false);

				// Deselect all items
				ClearSelectionVisuals();

				mSelectedItem = value;
				mSelectedItems.Clear();

				// Select new item
				if (mSelectedItem != null)
				{
					mSelectedItem.IsSelected = true;
					mSelectedItems.Add(mSelectedItem);
					mFocusedIndex = mVisibleItems.IndexOf(mSelectedItem);
				}
				else
				{
					mFocusedIndex = -1;
				}

				mSelectionChanged.[Friend]Invoke(this);
			}
		}
	}

	/// Whether multi-select is enabled (Ctrl+Click toggle, Shift+Click range).
	public bool MultiSelect
	{
		get => mMultiSelect;
		set => mMultiSelect = value;
	}

	/// All currently selected items (read-only reference list).
	public List<TreeViewItem> SelectedItems => mSelectedItems;

	/// Event fired when selection changes.
	public EventAccessor<delegate void(TreeView)> SelectionChanged => mSelectionChanged;

	/// Event fired when an item is expanded.
	public EventAccessor<delegate void(TreeView, TreeViewItem)> ItemExpanded => mItemExpanded;

	/// Event fired when an item is collapsed.
	public EventAccessor<delegate void(TreeView, TreeViewItem)> ItemCollapsed => mItemCollapsed;

	/// Whether items can be renamed inline (F2 to start editing).
	public bool IsEditable
	{
		get => mIsEditable;
		set => mIsEditable = value;
	}

	/// Whether an item is currently being edited.
	public bool IsEditing => mEditingItem != null;

	/// Event fired when an item is renamed (tree, item, newText).
	public EventAccessor<delegate void(TreeView, TreeViewItem, StringView)> ItemRenamed => mItemRenamed;

	// === Item Management ===

	/// Adds a root item with the specified text.
	public TreeViewItem AddItem(StringView text)
	{
		let item = new TreeViewItem(text);
		AddItem(item);
		return item;
	}

	/// Adds an existing TreeViewItem as a root item.
	public void AddItem(TreeViewItem item)
	{
		item.[Friend]mIndentLevel = 0;
		item.[Friend]mParentItem = null;
		item.SetParent(this);

		if (Context != null)
			item.OnAttachedToContext(Context);

		mRootItems.Add(item);
		RebuildVisibleItems();
	}

	/// Removes a root item.
	public void RemoveItem(TreeViewItem item)
	{
		let index = mRootItems.IndexOf(item);
		if (index < 0)
			return;

		// Remove from multi-selection if present
		item.IsSelected = false;
		mSelectedItems.Remove(item);

		// Clear primary selection if removing selected item
		if (mSelectedItem == item || IsDescendantOf(mSelectedItem, item))
		{
			mSelectedItem = mSelectedItems.Count > 0 ? mSelectedItems[mSelectedItems.Count - 1] : null;
			mFocusedIndex = mSelectedItem != null ? mVisibleItems.IndexOf(mSelectedItem) : -1;
		}

		// Remove from panel first (without deleting, we own it)
		mItemsPanel.ClearChildren(deleteAll: false);

		mRootItems.RemoveAt(index);
		item.SetParent(null);

		if (Context != null)
		{
			item.OnDetachedFromContext();
			Context.MutationQueue.QueueDelete(item);
		}
		else
		{
			delete item;
		}

		RebuildVisibleItems();
	}

	/// Removes all items.
	public void ClearItems()
	{
		if (mEditingItem != null)
			EndEdit(false);
		ClearSelectionVisuals();
		mSelectedItems.Clear();
		mSelectedItem = null;
		mFocusedIndex = -1;

		// Remove from panel first (without deleting, we own them)
		mItemsPanel.ClearChildren(deleteAll: false);
		mVisibleItems.Clear();

		for (let item in mRootItems)
		{
			item.SetParent(null);
			if (Context != null)
			{
				item.OnDetachedFromContext();
				Context.MutationQueue.QueueDelete(item);
			}
			else
			{
				delete item;
			}
		}
		mRootItems.Clear();
		InvalidateLayout();
	}

	/// Gets the root item at the specified index.
	public TreeViewItem GetItem(int index)
	{
		if (index < 0 || index >= mRootItems.Count)
			return null;
		return mRootItems[index];
	}

	// === Inline Editing ===

	/// Begins inline editing of the selected item.
	public void BeginEdit()
	{
		if (!mIsEditable || mSelectedItem == null || mEditingItem != null)
			return;

		BeginEditItem(mSelectedItem);
	}

	/// Begins inline editing of a specific item.
	private void BeginEditItem(TreeViewItem item)
	{
		if (Context == null)
			return;

		mEditingItem = item;

		// Create and configure TextBox
		if (mEditTextBox != null)
			delete mEditTextBox;

		mEditTextBox = new EditTextBox(this, item.Text);
		mEditTextBox.SetParent(this);
		mEditTextBox.OnAttachedToContext(Context);
		mEditTextBox.FontSize = 14;
		mEditTextBox.Padding = .(2, 2, 2, 2);

		// Select all text for easy replacement
		mEditTextBox.SelectAll();

		// Position the TextBox over the item's text area
		PositionEditTextBox();

		// Set focus to the TextBox
		Context.FocusManager?.SetFocus(mEditTextBox);
	}

	/// TextBox subclass that routes Enter/Escape/LostFocus back to the owning TreeView.
	private class EditTextBox : TextBox
	{
		private TreeView mOwner;

		public this(TreeView owner, StringView text) : base(text)
		{
			mOwner = owner;
		}

		protected override void OnKeyDown(KeyEventArgs e)
		{
			if (e.Key == .Return)
			{
				mOwner.EndEdit(true);
				e.Handled = true;
				return;
			}
			else if (e.Key == .Escape)
			{
				mOwner.EndEdit(false);
				e.Handled = true;
				return;
			}
			base.OnKeyDown(e);
		}

		protected override void OnLostFocus(FocusEventArgs e)
		{
			base.OnLostFocus(e);
			if (mOwner.mEditingItem != null)
				mOwner.EndEdit(true);
		}
	}

	/// Positions the edit TextBox over the editing item's text area.
	private void PositionEditTextBox()
	{
		if (mEditTextBox == null || mEditingItem == null)
			return;

		let itemIndex = mVisibleItems.IndexOf(mEditingItem);
		if (itemIndex < 0)
		{
			EndEdit(false);
			return;
		}

		let treeBounds = ArrangedBounds;
		let indent = mEditingItem.IndentLevel * TreeViewItem.IndentWidth;
		let textX = treeBounds.X + indent + TreeViewItem.ExpanderSize + 4;
		let itemY = treeBounds.Y + itemIndex * TreeViewItem.ItemHeight - mScrollViewer.VerticalOffset;

		let editBounds = RectangleF(textX, itemY, treeBounds.Right - textX, TreeViewItem.ItemHeight);

		mEditTextBox.Measure(.Unconstrained);
		mEditTextBox.Arrange(editBounds);
	}

	/// Ends inline editing, optionally committing the new text.
	public void EndEdit(bool commit)
	{
		if (mEditingItem == null)
			return;

		if (commit && mEditTextBox != null)
		{
			let newText = mEditTextBox.Text;
			if (newText != mEditingItem.Text)
			{
				mEditingItem.Text = newText;
				mItemRenamed.[Friend]Invoke(this, mEditingItem, newText);
			}
		}

		// Clean up
		if (mEditTextBox != null)
		{
			mEditTextBox.OnDetachedFromContext();
			delete mEditTextBox;
			mEditTextBox = null;
		}

		mEditingItem = null;

		// Return focus to the TreeView
		Context?.FocusManager?.SetFocus(this);
	}

	// === Tree Operations ===

	/// Expands all items recursively.
	public void ExpandAll()
	{
		for (let item in mRootItems)
			ExpandAllRecursive(item);
		RebuildVisibleItems();
	}

	private void ExpandAllRecursive(TreeViewItem item)
	{
		item.[Friend]mIsExpanded = true;  // Set directly to avoid rebuild per item
		for (int i = 0; i < item.ChildCount; i++)
		{
			if (let child = item.GetChild(i))
				ExpandAllRecursive(child);
		}
	}

	/// Collapses all items recursively.
	public void CollapseAll()
	{
		for (let item in mRootItems)
			CollapseAllRecursive(item);
		RebuildVisibleItems();
	}

	private void CollapseAllRecursive(TreeViewItem item)
	{
		item.[Friend]mIsExpanded = false;  // Set directly to avoid rebuild per item
		for (int i = 0; i < item.ChildCount; i++)
		{
			if (let child = item.GetChild(i))
				CollapseAllRecursive(child);
		}
	}

	/// Called when an item's expansion state changes.
	private void OnItemExpandedChanged(TreeViewItem item)
	{
		RebuildVisibleItems();

		if (item.IsExpanded)
			mItemExpanded.[Friend]Invoke(this, item);
		else
			mItemCollapsed.[Friend]Invoke(this, item);
	}

	// === Multi-Select Helpers ===

	/// Clears the IsSelected visual on all selected items.
	private void ClearSelectionVisuals()
	{
		for (let item in mSelectedItems)
			item.IsSelected = false;
	}

	/// Toggles an item in/out of the multi-selection.
	private void ToggleItemSelection(TreeViewItem item)
	{
		if (mEditingItem != null)
			EndEdit(false);

		let idx = mSelectedItems.IndexOf(item);
		if (idx >= 0)
		{
			// Deselect
			item.IsSelected = false;
			mSelectedItems.RemoveAt(idx);

			// Update primary selection
			mSelectedItem = mSelectedItems.Count > 0 ? mSelectedItems[mSelectedItems.Count - 1] : null;
		}
		else
		{
			// Add to selection
			item.IsSelected = true;
			mSelectedItems.Add(item);
			mSelectedItem = item;
		}

		mFocusedIndex = mSelectedItem != null ? mVisibleItems.IndexOf(mSelectedItem) : -1;
		mSelectionChanged.[Friend]Invoke(this);
	}

	/// Selects a range from the focused index to the target item.
	private void RangeSelect(TreeViewItem targetItem)
	{
		if (mEditingItem != null)
			EndEdit(false);

		let targetIndex = mVisibleItems.IndexOf(targetItem);
		if (targetIndex < 0) return;

		let anchorIndex = mFocusedIndex >= 0 ? mFocusedIndex : 0;

		// Clear existing selection
		ClearSelectionVisuals();
		mSelectedItems.Clear();

		// Select range
		let startIdx = Math.Min(anchorIndex, targetIndex);
		let endIdx = Math.Max(anchorIndex, targetIndex);
		for (int i = startIdx; i <= endIdx; i++)
		{
			let item = mVisibleItems[i];
			item.IsSelected = true;
			mSelectedItems.Add(item);
		}

		// Primary is the target
		mSelectedItem = targetItem;
		// Keep focused index at the anchor (don't update mFocusedIndex)
		mSelectionChanged.[Friend]Invoke(this);
	}

	// === Internal ===

	/// Checks if target is a descendant of ancestor.
	private bool IsDescendantOf(TreeViewItem target, TreeViewItem ancestor)
	{
		if (target == null || ancestor == null)
			return false;

		var current = target.ParentItem;
		while (current != null)
		{
			if (current == ancestor)
				return true;
			current = current.ParentItem;
		}
		return false;
	}

	/// Rebuilds the flattened list of visible items.
	private void RebuildVisibleItems()
	{
		// Remove all items from panel (don't delete - they're owned by mRootItems)
		mItemsPanel.ClearChildren(deleteAll: false);
		mVisibleItems.Clear();

		// Enumerate all visible items
		for (let item in mRootItems)
			item.EnumerateVisible(mVisibleItems);

		// Add to panel
		for (let item in mVisibleItems)
		{
			item.Height = .Fixed(TreeViewItem.ItemHeight);
			mItemsPanel.AddChild(item);
		}

		// Update focused index if selection exists
		if (mSelectedItem != null)
			mFocusedIndex = mVisibleItems.IndexOf(mSelectedItem);
		else
			mFocusedIndex = -1;

		InvalidateLayout();
	}

	/// Gets the visible item index for an item.
	private int GetVisibleItemIndex(TreeViewItem item)
	{
		return mVisibleItems.IndexOf(item);
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mScrollViewer.OnAttachedToContext(context);

		for (let item in mRootItems)
			item.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		for (let item in mRootItems)
			item.OnDetachedFromContext();

		mScrollViewer.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mScrollViewer.Measure(constraints);
		return mScrollViewer.DesiredSize;
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		mScrollViewer.Arrange(contentBounds);
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background
		let bgColor = Background.A > 0 ? Background : Color(30, 30, 30, 255);
		ctx.FillRect(bounds, bgColor);

		// Update hover state on visible items
		for (int i = 0; i < mVisibleItems.Count; i++)
		{
			mVisibleItems[i].[Friend]mIsHovered = (i == mHoveredIndex);
		}

		// Render scroll viewer (which renders items)
		mScrollViewer.Render(ctx);

		// Render edit TextBox on top of the item
		if (mEditTextBox != null && mEditingItem != null)
		{
			PositionEditTextBox();
			mEditTextBox.Render(ctx);
		}

		// Draw border
		let borderColor = BorderColor.A > 0 ? BorderColor : Color(80, 80, 80, 255);
		ctx.DrawRect(bounds, borderColor, 1);
	}

	// === Input ===

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		// Calculate which item is hovered
		let localY = e.ScreenY - ArrangedBounds.Y;
		let scrollOffset = mScrollViewer.VerticalOffset;
		let adjustedY = localY + scrollOffset;
		var newHovered = (int)(adjustedY / TreeViewItem.ItemHeight);

		if (newHovered < 0 || newHovered >= mVisibleItems.Count)
			newHovered = -1;

		if (newHovered != mHoveredIndex)
		{
			mHoveredIndex = newHovered;
		}
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		mHoveredIndex = -1;
	}

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);

		if (!e.Handled)
		{
			// Forward to scroll viewer (consistent with ScrollViewer: SmallChange * 3)
			let scrollAmount = 20 * 3;  // Match ScrollViewer's default scroll speed
			mScrollViewer.VerticalOffset = mScrollViewer.VerticalOffset - e.DeltaY * scrollAmount;
			e.Handled = true;
		}
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && !e.Handled)
		{
			// Calculate which item was clicked
			let localX = e.ScreenX - ArrangedBounds.X;
			let localY = e.ScreenY - ArrangedBounds.Y;
			let scrollOffset = mScrollViewer.VerticalOffset;
			let adjustedY = localY + scrollOffset;
			let itemIndex = (int)(adjustedY / TreeViewItem.ItemHeight);

			if (itemIndex >= 0 && itemIndex < mVisibleItems.Count)
			{
				let item = mVisibleItems[itemIndex];

				// Check if click is on expander
				if (item.HasChildren && item.IsInExpanderArea(localX))
				{
					item.IsExpanded = !item.IsExpanded;
				}
				else if (mMultiSelect && e.HasModifier(.Ctrl))
				{
					// Ctrl+Click: toggle item in multi-selection
					ToggleItemSelection(item);
				}
				else if (mMultiSelect && e.HasModifier(.Shift))
				{
					// Shift+Click: range select
					RangeSelect(item);
				}
				else
				{
					// Normal click: select single item
					SelectedItem = item;
				}

				e.Handled = true;
			}
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Handled || mVisibleItems.Count == 0)
			return;

		switch (e.Key)
		{
		case .Up:
			if (mFocusedIndex > 0)
			{
				mFocusedIndex--;
				SelectedItem = mVisibleItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .Down:
			if (mFocusedIndex < mVisibleItems.Count - 1)
			{
				mFocusedIndex++;
				SelectedItem = mVisibleItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .Left:
			if (mSelectedItem != null)
			{
				if (mSelectedItem.IsExpanded && mSelectedItem.HasChildren)
				{
					// Collapse current item
					mSelectedItem.IsExpanded = false;
				}
				else if (mSelectedItem.ParentItem != null)
				{
					// Go to parent
					SelectedItem = mSelectedItem.ParentItem;
					ScrollIntoView(mSelectedItem);
				}
			}
			e.Handled = true;

		case .Right:
			if (mSelectedItem != null)
			{
				if (!mSelectedItem.IsExpanded && mSelectedItem.HasChildren)
				{
					// Expand current item
					mSelectedItem.IsExpanded = true;
				}
				else if (mSelectedItem.HasChildren && mSelectedItem.ChildCount > 0)
				{
					// Go to first child
					SelectedItem = mSelectedItem.GetChild(0);
					ScrollIntoView(mSelectedItem);
				}
			}
			e.Handled = true;

		case .Home:
			if (mVisibleItems.Count > 0)
			{
				mFocusedIndex = 0;
				SelectedItem = mVisibleItems[0];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .End:
			if (mVisibleItems.Count > 0)
			{
				mFocusedIndex = mVisibleItems.Count - 1;
				SelectedItem = mVisibleItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .Space, .Return:
			if (mSelectedItem != null && mSelectedItem.HasChildren)
			{
				mSelectedItem.IsExpanded = !mSelectedItem.IsExpanded;
			}
			e.Handled = true;

		default:
		}
	}

	/// Scrolls to make the specified item visible.
	public void ScrollIntoView(TreeViewItem item)
	{
		if (item == null)
			return;

		let index = mVisibleItems.IndexOf(item);
		if (index < 0)
			return;

		let itemTop = index * TreeViewItem.ItemHeight;
		let itemBottom = itemTop + TreeViewItem.ItemHeight;
		let viewTop = mScrollViewer.VerticalOffset;
		let viewBottom = viewTop + mScrollViewer.ViewportHeight;

		if (itemTop < viewTop)
			mScrollViewer.VerticalOffset = itemTop;
		else if (itemBottom > viewBottom)
			mScrollViewer.VerticalOffset = itemBottom - mScrollViewer.ViewportHeight;
	}

	// === Visual Children ===

	public override int VisualChildCount => 1;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0)
			return mScrollViewer;
		return null;
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// If editing, check if the click is on the TextBox
		if (mEditTextBox != null && mEditTextBox.ArrangedBounds.Contains(point.X, point.Y))
			return mEditTextBox;

		// Only return scrollbars - we handle all content input ourselves
		let scrollbarHit = mScrollViewer.HitTestScrollBars(point);
		if (scrollbarHit != null)
			return scrollbarHit;

		return this;
	}
}
