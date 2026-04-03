using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A grid view of items displayed as tiles.
public class TileView : Control
{
	// Internal layout
	private ScrollViewer mScrollViewer ~ delete _;
	private WrapPanel mItemsPanel;  // Owned by scroll viewer

	// Items
	private List<TileViewItem> mItems = new .() ~ DeleteContainerAndItems!(_);

	// Selection state
	private TileViewItem mSelectedItem;
	private int mFocusedIndex = -1;
	private int mHoveredIndex = -1;

	// Tile dimensions
	private float mTileWidth = 80;
	private float mTileHeight = 90;
	private float mTileSpacing = 8;

	// Events
	private EventAccessor<delegate void(TileView)> mSelectionChanged = new .() ~ delete _;

	/// Creates a new TileView.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;

		// Create internal scroll viewer and wrap panel
		mScrollViewer = new ScrollViewer();
		mScrollViewer.SetParent(this);
		mScrollViewer.HorizontalScrollBarVisibility = .Disabled;
		mScrollViewer.VerticalScrollBarVisibility = .Auto;

		mItemsPanel = new WrapPanel();
		mItemsPanel.Orientation = .Horizontal;
		mItemsPanel.ItemWidth = mTileWidth;
		mItemsPanel.ItemHeight = mTileHeight;
		mScrollViewer.Content = mItemsPanel;
	}

	/// Destructor - clean up panel before items are deleted.
	public ~this()
	{
		// Remove items from panel without deleting them (they're owned by mItems)
		mItemsPanel?.ClearChildren(deleteAll: false);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TileView";

	/// Number of items.
	public int ItemCount => mItems.Count;

	/// The currently selected item.
	public TileViewItem SelectedItem
	{
		get => mSelectedItem;
		set
		{
			if (mSelectedItem != value)
			{
				// Deselect old item
				if (mSelectedItem != null)
					mSelectedItem.IsSelected = false;

				mSelectedItem = value;

				// Select new item
				if (mSelectedItem != null)
				{
					mSelectedItem.IsSelected = true;
					mFocusedIndex = mSelectedItem.Index;
				}
				else
				{
					mFocusedIndex = -1;
				}

				mSelectionChanged.[Friend]Invoke(this);
			}
		}
	}

	/// The width of each tile.
	public float TileWidth
	{
		get => mTileWidth;
		set
		{
			if (mTileWidth != value)
			{
				mTileWidth = value;
				mItemsPanel.ItemWidth = value;

				// Update all existing items
				for (let item in mItems)
					item.Width = .Fixed(value);

				InvalidateLayout();
			}
		}
	}

	/// The height of each tile.
	public float TileHeight
	{
		get => mTileHeight;
		set
		{
			if (mTileHeight != value)
			{
				mTileHeight = value;
				mItemsPanel.ItemHeight = value;

				// Update all existing items
				for (let item in mItems)
					item.Height = .Fixed(value);

				InvalidateLayout();
			}
		}
	}

	/// The spacing between tiles.
	public float TileSpacing
	{
		get => mTileSpacing;
		set
		{
			if (mTileSpacing != value)
			{
				mTileSpacing = value;
				// WrapPanel doesn't have spacing, tiles will be adjacent
				InvalidateLayout();
			}
		}
	}

	/// Event fired when selection changes.
	public EventAccessor<delegate void(TileView)> SelectionChanged => mSelectionChanged;

	// === Item Management ===

	/// Adds an item with the specified text (creates a centered TextBlock as content).
	public TileViewItem AddItem(StringView text)
	{
		let item = new TileViewItem();

		// Create a simple text content
		let textBlock = new TextBlock(text);
		textBlock.TextAlignment = .Center;
		textBlock.VerticalAlignment = .Center;
		textBlock.HorizontalAlignment = .Center;
		item.Content = textBlock;

		AddItem(item);
		return item;
	}

	/// Adds an empty TileViewItem (caller should set Content).
	public TileViewItem AddItem()
	{
		let item = new TileViewItem();
		AddItem(item);
		return item;
	}

	/// Adds an existing TileViewItem.
	public void AddItem(TileViewItem item)
	{
		item.Index = mItems.Count;
		item.Width = .Fixed(mTileWidth);
		item.Height = .Fixed(mTileHeight);
		item.SetParent(this);

		if (Context != null)
			item.OnAttachedToContext(Context);

		mItems.Add(item);
		mItemsPanel.AddChild(item);

		InvalidateLayout();
	}

	/// Removes an item.
	public void RemoveItem(TileViewItem item)
	{
		let index = mItems.IndexOf(item);
		if (index < 0)
			return;

		// Clear selection if removing selected item
		if (mSelectedItem == item)
			SelectedItem = null;

		mItems.RemoveAt(index);
		mItemsPanel.RemoveChild(item, deleteAfterRemove: false);  // Don't delete - we own it

		// Update indices
		for (int i = index; i < mItems.Count; i++)
			mItems[i].Index = i;

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

		InvalidateLayout();
	}

	/// Removes all items.
	public void ClearItems()
	{
		SelectedItem = null;

		for (let item in mItems)
		{
			mItemsPanel.RemoveChild(item, deleteAfterRemove: false);  // Don't delete - we own it
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
		mItems.Clear();
		InvalidateLayout();
	}

	/// Gets the item at the specified index.
	public TileViewItem GetItem(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return null;
		return mItems[index];
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mScrollViewer.OnAttachedToContext(context);

		for (let item in mItems)
			item.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		for (let item in mItems)
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

		// Update hover state on items
		for (int i = 0; i < mItems.Count; i++)
		{
			mItems[i].[Friend]mIsHovered = (i == mHoveredIndex);
		}

		// Render scroll viewer (which renders items)
		mScrollViewer.Render(ctx);

		// Draw border
		let borderColor = BorderColor.A > 0 ? BorderColor : Color(80, 80, 80, 255);
		ctx.DrawRect(bounds, borderColor, 1);
	}

	// === Input ===

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		// Find which item is under the mouse
		let newHovered = GetItemIndexAtPoint(.(e.ScreenX, e.ScreenY));

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
			let itemIndex = GetItemIndexAtPoint(.(e.ScreenX, e.ScreenY));

			if (itemIndex >= 0 && itemIndex < mItems.Count)
			{
				SelectedItem = mItems[itemIndex];
				e.Handled = true;
			}
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Handled || mItems.Count == 0)
			return;

		// Calculate columns per row for navigation
		let viewWidth = ArrangedBounds.Width;
		let columns = Math.Max(1, (int)(viewWidth / mTileWidth));

		switch (e.Key)
		{
		case .Up:
			if (mFocusedIndex >= columns)
			{
				mFocusedIndex -= columns;
				SelectedItem = mItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .Down:
			if (mFocusedIndex + columns < mItems.Count)
			{
				mFocusedIndex += columns;
				SelectedItem = mItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			else if (mFocusedIndex < mItems.Count - 1)
			{
				// Go to last item if not enough for full row
				mFocusedIndex = mItems.Count - 1;
				SelectedItem = mItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .Left:
			if (mFocusedIndex > 0)
			{
				mFocusedIndex--;
				SelectedItem = mItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .Right:
			if (mFocusedIndex < mItems.Count - 1)
			{
				mFocusedIndex++;
				SelectedItem = mItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .Home:
			if (mItems.Count > 0)
			{
				mFocusedIndex = 0;
				SelectedItem = mItems[0];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		case .End:
			if (mItems.Count > 0)
			{
				mFocusedIndex = mItems.Count - 1;
				SelectedItem = mItems[mFocusedIndex];
				ScrollIntoView(mSelectedItem);
			}
			e.Handled = true;

		default:
		}
	}

	/// Gets the item index at the specified point.
	private int GetItemIndexAtPoint(Vector2 point)
	{
		for (int i = 0; i < mItems.Count; i++)
		{
			if (mItems[i].ArrangedBounds.Contains(point.X, point.Y))
				return i;
		}
		return -1;
	}

	/// Scrolls to make the specified item visible.
	public void ScrollIntoView(TileViewItem item)
	{
		if (item == null)
			return;

		let itemBounds = item.ArrangedBounds;
		let viewTop = mScrollViewer.VerticalOffset;
		let viewBottom = viewTop + mScrollViewer.ViewportHeight;

		// Adjust item bounds relative to scroll viewer content
		let relativeTop = itemBounds.Y - mItemsPanel.ArrangedBounds.Y;
		let relativeBottom = relativeTop + itemBounds.Height;

		if (relativeTop < viewTop)
			mScrollViewer.VerticalOffset = relativeTop;
		else if (relativeBottom > viewBottom)
			mScrollViewer.VerticalOffset = relativeBottom - mScrollViewer.ViewportHeight;
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

		// Only return scrollbars - we handle all content input ourselves
		let scrollbarHit = mScrollViewer.HitTestScrollBars(point);
		if (scrollbarHit != null)
			return scrollbarHit;

		return this;
	}
}
