using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A navigation trail control showing a path of clickable items.
public class Breadcrumb : Control
{
	// Items collection (owned)
	private List<BreadcrumbItem> mItems = new .() ~ DeleteContainerAndItems!(_);

	// Separator between items
	private String mSeparator = new .(" > ") ~ delete _;
	private float mSeparatorWidth = 0;

	// Layout tracking
	private List<RectangleF> mItemBounds = new .() ~ delete _;
	private int mHoveredIndex = -1;

	// Events
	private EventAccessor<delegate void(Breadcrumb, BreadcrumbItem)> mItemClicked = new .() ~ delete _;

	/// Creates a new Breadcrumb.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Breadcrumb";

	/// Number of items in the breadcrumb.
	public int ItemCount => mItems.Count;

	/// The separator string between items.
	public StringView Separator
	{
		get => mSeparator;
		set
		{
			mSeparator.Set(value);
			InvalidateLayout();
		}
	}

	/// Event fired when an item is clicked.
	public EventAccessor<delegate void(Breadcrumb, BreadcrumbItem)> ItemClicked => mItemClicked;

	// === Item Management ===

	/// Adds an item with text content.
	public BreadcrumbItem AddItem(StringView text)
	{
		let item = new BreadcrumbItem(text);
		AddItem(item);
		return item;
	}

	/// Adds an item with text and associated value.
	public BreadcrumbItem AddItem(StringView text, Object value)
	{
		let item = new BreadcrumbItem(text, value);
		AddItem(item);
		return item;
	}

	/// Adds an existing BreadcrumbItem.
	public void AddItem(BreadcrumbItem item)
	{
		item.Index = mItems.Count;
		item.IsLast = true;
		item.SetParent(this);
		if (Context != null)
			item.OnAttachedToContext(Context);

		// Previous last item is no longer last
		if (mItems.Count > 0)
			mItems[mItems.Count - 1].IsLast = false;

		mItems.Add(item);
		InvalidateLayout();
	}

	/// Removes an item at the specified index.
	public void RemoveItemAt(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return;

		let item = mItems[index];
		mItems.RemoveAt(index);

		// Update indices
		for (int i = index; i < mItems.Count; i++)
			mItems[i].Index = i;

		// Update last flag
		if (mItems.Count > 0)
			mItems[mItems.Count - 1].IsLast = true;

		// Clean up item
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
		for (let item in mItems)
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
		mItems.Clear();
		InvalidateLayout();
	}

	/// Gets the item at the specified index.
	public BreadcrumbItem GetItem(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return null;
		return mItems[index];
	}

	/// Navigates to the specified index, removing all items after it.
	public void NavigateTo(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return;

		// Remove items after the target
		while (mItems.Count > index + 1)
		{
			RemoveItemAt(mItems.Count - 1);
		}
	}

	/// Navigates to the specified item, removing all items after it.
	public void NavigateTo(BreadcrumbItem item)
	{
		let index = mItems.IndexOf(item);
		if (index >= 0)
			NavigateTo(index);
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		for (let item in mItems)
			item.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		for (let item in mItems)
			item.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mItems.Count == 0)
			return .(0, 24);  // Minimum height

		float totalWidth = 0;
		float maxHeight = 0;

		// Estimate separator width (we'll calculate properly in arrange)
		mSeparatorWidth = mSeparator.Length * 8;  // Rough estimate

		for (int i = 0; i < mItems.Count; i++)
		{
			let item = mItems[i];
			item.Measure(constraints);
			let itemSize = item.DesiredSize;

			totalWidth += itemSize.Width;
			maxHeight = Math.Max(maxHeight, itemSize.Height);

			// Add separator width (except after last item)
			if (i < mItems.Count - 1)
				totalWidth += mSeparatorWidth;
		}

		return .(totalWidth, Math.Max(maxHeight, 24));
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		mItemBounds.Clear();

		if (mItems.Count == 0)
			return;

		float x = contentBounds.X;

		for (int i = 0; i < mItems.Count; i++)
		{
			let item = mItems[i];
			let itemSize = item.DesiredSize;

			let itemBounds = RectangleF(x, contentBounds.Y, itemSize.Width, contentBounds.Height);
			item.Arrange(itemBounds);
			mItemBounds.Add(itemBounds);

			x += itemSize.Width;

			// Add separator space (except after last item)
			if (i < mItems.Count - 1)
				x += mSeparatorWidth;
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background
		RenderBackground(ctx);

		// Draw items with separators
		for (int i = 0; i < mItems.Count && i < mItemBounds.Count; i++)
		{
			let item = mItems[i];
			item.IsItemHovered = (i == mHoveredIndex);
			item.Render(ctx);

			// Draw separator after item (except last)
			if (i < mItems.Count - 1)
			{
				let itemBounds = mItemBounds[i];
				let sepX = itemBounds.Right + 4;
				let sepY = bounds.Y + (bounds.Height - 16) / 2;

				let foreground = Foreground.A > 0 ? Foreground : Color(150, 150, 150, 255);
				ctx.DrawText(mSeparator, 14, .(sepX, sepY), foreground);
			}
		}
	}

	// === Input ===

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

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

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && !e.Handled)
		{
			let index = GetItemIndexAtPoint(.(e.ScreenX, e.ScreenY));
			if (index >= 0 && index < mItems.Count)
			{
				let item = mItems[index];
				// Don't fire click for last item (current location)
				if (!item.IsLast)
				{
					mItemClicked.[Friend]Invoke(this, item);
				}
				e.Handled = true;
			}
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		// Could add keyboard navigation if needed
	}

	private int GetItemIndexAtPoint(Vector2 point)
	{
		for (int i = 0; i < mItemBounds.Count; i++)
		{
			if (mItemBounds[i].Contains(point.X, point.Y))
				return i;
		}
		return -1;
	}

	// === Visual Children ===

	public override int VisualChildCount => mItems.Count;

	public override UIElement GetVisualChild(int index)
	{
		if (index >= 0 && index < mItems.Count)
			return mItems[index];
		return null;
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		return this;
	}
}
