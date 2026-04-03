using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Base class for controls that display a collection of items.
/// ItemsControl manages the items collection and generates visual containers for each item.
/// Items added via AddItem(Object) are NOT owned - caller retains ownership.
/// Items added via AddItem(StringView) ARE owned - the control creates and deletes the string.
/// ItemsControl DOES own the generated containers.
public class ItemsControl : Control
{
	/// Delegate for creating custom item containers.
	public delegate UIElement ItemTemplateFunc(Object item);

	// Item storage (references only, not owned unless in mOwnedStrings)
	private List<Object> mItems = new .() ~ delete _;

	// Strings created by AddItem(StringView) - we own these
	private HashSet<String> mOwnedStrings = new .() ~ DeleteContainerAndItems!(_);

	// Container storage (references only - owned by mItemsPanel)
	private List<UIElement> mContainers = new .() ~ delete _;

	// Layout panel (owned by mScrollViewer as its Content)
	private StackPanel mItemsPanel = new .();

	// ScrollViewer for scrolling support (owned)
	private ScrollViewer mScrollViewer = new .() ~ delete _;

	// Custom template function (owned)
	private ItemTemplateFunc mItemTemplate ~ delete _;

	/// Creates a new ItemsControl.
	public this()
	{
		// ItemsControl is focusable (for keyboard navigation)
		IsFocusable = true;
		IsTabStop = true;

		// Default to vertical stacking
		mItemsPanel.Orientation = .Vertical;

		// Set up scroll viewer with panel as content
		mScrollViewer.Content = mItemsPanel;
		mScrollViewer.HorizontalScrollBarVisibility = .Disabled;
		mScrollViewer.VerticalScrollBarVisibility = .Auto;
		mScrollViewer.SetParent(this);

		// Clips items to bounds automatically via ScrollViewer
		ClipToBounds = true;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ItemsControl";

	/// The number of items in the collection.
	public int ItemCount => mItems.Count;

	/// Custom item template function for creating containers.
	/// If null, default containers are created based on control type.
	public ItemTemplateFunc ItemTemplate
	{
		get => mItemTemplate;
		set
		{
			if (mItemTemplate != null)
				delete mItemTemplate;
			mItemTemplate = value;
			// Regenerate containers if we have items
			if (mItems.Count > 0)
				RegenerateContainers();
		}
	}

	/// The spacing between items.
	public float ItemSpacing
	{
		get => mItemsPanel.Spacing;
		set => mItemsPanel.Spacing = value;
	}

	// === Item Management ===

	/// Adds a string item to the collection.
	/// The control creates and owns the string internally.
	public void AddText(StringView text)
	{
		let str = new String(text);
		mOwnedStrings.Add(str);
		AddItem(str);
	}

	/// Adds an item to the collection.
	/// Note: ItemsControl does NOT take ownership of the item.
	public void AddItem(Object item)
	{
		mItems.Add(item);
		let container = CreateContainerForItem(item, mItems.Count - 1);
		mContainers.Add(container);
		mItemsPanel.AddChild(container);
		OnItemAdded(mItems.Count - 1, item);
		InvalidateLayout();
	}

	/// Inserts a string item at the specified index.
	/// The control creates and owns the string internally.
	public void InsertText(int index, StringView text)
	{
		let str = new String(text);
		mOwnedStrings.Add(str);
		InsertItem(index, str);
	}

	/// Inserts an item at the specified index.
	public void InsertItem(int index, Object item)
	{
		let clampedIndex = Math.Clamp(index, 0, mItems.Count);
		mItems.Insert(clampedIndex, item);

		let container = CreateContainerForItem(item, clampedIndex);
		mContainers.Insert(clampedIndex, container);
		mItemsPanel.InsertChild(clampedIndex, container);

		// Update indices of subsequent containers
		UpdateContainerIndices(clampedIndex + 1);

		OnItemAdded(clampedIndex, item);
		InvalidateLayout();
	}

	/// Removes an item from the collection.
	/// Returns true if the item was found and removed.
	/// Note: The item itself is NOT deleted (caller still owns it).
	public bool RemoveItem(Object item)
	{
		let index = mItems.IndexOf(item);
		if (index < 0)
			return false;
		RemoveItemAt(index);
		return true;
	}

	/// Removes the item at the specified index.
	/// If the item was added via AddItem(StringView), it will be deleted.
	public void RemoveItemAt(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return;

		let item = mItems[index];
		mItems.RemoveAt(index);

		// Remove and delete container
		let container = mContainers[index];
		mContainers.RemoveAt(index);
		mItemsPanel.RemoveChild(container);  // This queues deletion

		// Update indices of subsequent containers
		UpdateContainerIndices(index);

		// Delete owned string if applicable
		if (let str = item as String)
		{
			if (mOwnedStrings.Remove(str))
				delete str;
		}

		OnItemRemoved(index, item);
		InvalidateLayout();
	}

	/// Clears all items from the collection.
	/// Items added via AddItem(StringView) will be deleted.
	/// Items added via AddItem(Object) are NOT deleted (caller still owns them).
	public void ClearItems()
	{
		mItems.Clear();
		mItemsPanel.ClearChildren();  // Deletes containers
		mContainers.Clear();

		// Delete owned strings
		for (let str in mOwnedStrings)
			delete str;
		mOwnedStrings.Clear();

		OnItemsCleared();
		InvalidateLayout();
	}

	/// Gets the item at the specified index.
	public Object GetItem(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return null;
		return mItems[index];
	}

	/// Gets the index of an item.
	/// Returns -1 if not found.
	public int IndexOf(Object item)
	{
		return mItems.IndexOf(item);
	}

	/// Gets the container for the item at the specified index.
	public UIElement GetContainer(int index)
	{
		if (index < 0 || index >= mContainers.Count)
			return null;
		return mContainers[index];
	}

	// === Container Generation ===

	/// Creates a container for an item.
	/// Override in subclasses to create specific container types.
	protected virtual UIElement CreateContainerForItem(Object item, int index)
	{
		// Use custom template if provided
		if (mItemTemplate != null)
			return mItemTemplate(item);

		// Default: create a simple text container
		return CreateDefaultContainer(item, index);
	}

	/// Creates the default container for an item.
	/// Override to customize default container creation.
	protected virtual UIElement CreateDefaultContainer(Object item, int index)
	{
		let container = new ListBoxItem();
		PrepareContainerForItem(container, item, index);
		return container;
	}

	/// Prepares a container with content from an item.
	protected virtual void PrepareContainerForItem(UIElement container, Object item, int index)
	{
		if (let listBoxItem = container as ListBoxItem)
		{
			listBoxItem.Index = index;

			// Create content based on item type
			if (let str = item as String)
			{
				let text = new TextBlock();
				text.Text = str;
				listBoxItem.Content = text;
			}
			else if (item != null)
			{
				// Use ToString for other types
				let itemStr = scope String();
				item.ToString(itemStr);
				let text = new TextBlock();
				text.Text = itemStr;
				listBoxItem.Content = text;
			}
		}
	}

	/// Updates container indices after insertion/removal.
	private void UpdateContainerIndices(int startIndex)
	{
		for (int i = startIndex; i < mContainers.Count; i++)
		{
			if (let listBoxItem = mContainers[i] as ListBoxItem)
				listBoxItem.Index = i;
		}
	}

	/// Regenerates all containers (called when ItemTemplate changes).
	private void RegenerateContainers()
	{
		// Store items temporarily
		let items = scope List<Object>();
		for (let item in mItems)
			items.Add(item);

		// Clear existing containers
		mItemsPanel.ClearChildren();
		mContainers.Clear();
		mItems.Clear();

		// Re-add items with new containers
		for (let item in items)
			AddItem(item);
	}

	// === Callbacks for subclasses ===

	/// Called when an item is added.
	protected virtual void OnItemAdded(int index, Object item) { }

	/// Called when an item is removed.
	protected virtual void OnItemRemoved(int index, Object item) { }

	/// Called when all items are cleared.
	protected virtual void OnItemsCleared() { }

	// === Context Propagation ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mScrollViewer.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mScrollViewer.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Scrolling ===

	/// Current vertical scroll offset.
	public float ScrollOffset
	{
		get => mScrollViewer.VerticalOffset;
		set => mScrollViewer.VerticalOffset = value;
	}

	/// Total height of all content.
	public float ContentHeight => mScrollViewer.ExtentHeight;

	/// Height of the visible viewport.
	public float ViewportHeight => mScrollViewer.ViewportHeight;

	/// Maximum scroll offset.
	public float MaxScrollOffset => Math.Max(0, ContentHeight - ViewportHeight);

	/// Scrolls to make the item at the specified index visible.
	public void ScrollIntoView(int index)
	{
		if (index < 0 || index >= mContainers.Count)
			return;

		let container = mContainers[index];
		let itemBounds = container.ArrangedBounds;

		// Get bounds relative to the scroll content (mItemsPanel)
		let panelBounds = mItemsPanel.ArrangedBounds;
		let relativeBounds = RectangleF(
			itemBounds.X - panelBounds.X,
			itemBounds.Y - panelBounds.Y,
			itemBounds.Width,
			itemBounds.Height
		);

		mScrollViewer.ScrollToRect(relativeBounds);
	}

	// === Input ===

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);

		// Forward mouse wheel to scroll viewer
		if (!e.Handled)
			mScrollViewer.[Friend]OnMouseWheel(e);
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure scroll viewer (which measures content internally)
		let size = mScrollViewer.Measure(constraints);
		return size;
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		mScrollViewer.Arrange(contentBounds);
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		RenderBackground(ctx);
		mScrollViewer.Render(ctx);
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check if scrollbar was hit - return scrollbar for scrollbar interaction
		let scrollBarHit = mScrollViewer.HitTestScrollBars(point);
		if (scrollBarHit != null)
			return scrollBarHit;

		// ItemsControl handles all content input itself and uses GetItemIndexAtPoint
		// to determine which item was clicked. Don't return individual items.
		return this;
	}

	/// Gets the item index at a point.
	/// Returns -1 if no item is at the point.
	public int GetItemIndexAtPoint(Vector2 point)
	{
		// Hit test the panel content directly
		let hit = mItemsPanel.HitTest(point);
		if (let listBoxItem = hit as ListBoxItem)
			return listBoxItem.Index;
		return -1;
	}

	// === Visual Children ===

	public override int VisualChildCount => 1;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0)
			return mScrollViewer;
		return null;
	}
}
