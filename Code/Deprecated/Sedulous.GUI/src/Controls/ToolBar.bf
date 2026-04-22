using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A toolbar container that arranges buttons and controls horizontally or vertically.
/// Supports overflow handling when items don't fit.
public class ToolBar : Control
{
	private List<UIElement> mItems = new .() ~ delete _;  // Owns items added via AddButton/AddToggleButton/AddSeparator
	private StackPanel mItemsPanel ~ delete _;
	private Orientation mOrientation = .Horizontal;

	// Overflow handling
	private bool mShowOverflowButton = true;
	private float mOverflowButtonWidth = 20;
	private List<UIElement> mOverflowItems = new .() ~ delete _;
	private Button mOverflowButton ~ delete _;
	private ContextMenu mOverflowMenu ~ delete _;
	private bool mHasOverflow = false;

	/// Creates a new ToolBar.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;

		mItemsPanel = new StackPanel();
		mItemsPanel.Orientation = .Horizontal;
		mItemsPanel.Spacing = 2;

		// Create overflow button
		mOverflowButton = new Button(">>");
		mOverflowButton.Padding = .(4, 2, 4, 2);
		mOverflowButton.Visibility = .Collapsed;
		mOverflowButton.Click.Subscribe(new (btn) => ShowOverflowMenu());

		mOverflowMenu = new ContextMenu();
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ToolBar";

	/// The orientation of the toolbar (Horizontal or Vertical).
	public Orientation Orientation
	{
		get => mOrientation;
		set
		{
			if (mOrientation != value)
			{
				mOrientation = value;
				mItemsPanel.Orientation = value;

				// Update separator orientations
				for (let item in mItems)
				{
					if (let sep = item as ToolBarSeparator)
						sep.Orientation = value == .Horizontal ? .Vertical : .Horizontal;
				}

				InvalidateLayout();
			}
		}
	}

	/// Whether to show the overflow button when items don't fit.
	public bool ShowOverflowButton
	{
		get => mShowOverflowButton;
		set
		{
			if (mShowOverflowButton != value)
			{
				mShowOverflowButton = value;
				InvalidateLayout();
			}
		}
	}

	/// Number of items in the toolbar.
	public int ItemCount => mItems.Count;

	/// Adds an item to the toolbar.
	public void AddItem(UIElement item)
	{
		mItems.Add(item);
		mItemsPanel.AddChild(item);

		// Set separator orientation
		if (let sep = item as ToolBarSeparator)
			sep.Orientation = mOrientation == .Horizontal ? .Vertical : .Horizontal;

		InvalidateLayout();
	}

	/// Adds a button to the toolbar.
	public ToolBarButton AddButton(StringView text)
	{
		let button = new ToolBarButton(text);
		AddItem(button);
		return button;
	}

	/// Adds a toggle button to the toolbar.
	public ToolBarToggleButton AddToggleButton(StringView text)
	{
		let button = new ToolBarToggleButton(text);
		AddItem(button);
		return button;
	}

	/// Adds a separator to the toolbar.
	public ToolBarSeparator AddSeparator()
	{
		let sep = new ToolBarSeparator();
		AddItem(sep);
		return sep;
	}

	/// Removes an item from the toolbar.
	public void RemoveItem(UIElement item)
	{
		if (mItems.Remove(item))
		{
			mItemsPanel.RemoveChild(item);
			InvalidateLayout();
		}
	}

	/// Gets the item at the specified index.
	public UIElement GetItem(int index)
	{
		if (index >= 0 && index < mItems.Count)
			return mItems[index];
		return null;
	}

	/// Clears all items from the toolbar (deletes owned items).
	public void ClearItems()
	{
		for (let item in mItems)
			mItemsPanel.RemoveChild(item, deleteAfterRemove: false);
		DeleteContainerAndItems!(mItems);
		mItems = new .();
		mOverflowItems.Clear();
		InvalidateLayout();
	}

	/// Shows the overflow menu.
	private void ShowOverflowMenu()
	{
		if (mOverflowItems.Count == 0)
			return;

		mOverflowMenu.ClearItems();

		// Add overflow items to menu
		for (let item in mOverflowItems)
		{
			if (let button = item as ToolBarButton)
			{
				let menuItem = mOverflowMenu.AddItem(button.Text);
				let capturedButton = button;
				menuItem.Click.Subscribe(new [=](mi) => {
					// Simulate button click
					capturedButton.[Friend]OnClick();
				});
			}
			else if (let toggle = item as ToolBarToggleButton)
			{
				let menuItem = mOverflowMenu.AddItem(toggle.Text);
				menuItem.IsCheckable = true;
				menuItem.IsChecked = toggle.IsChecked;
				let capturedToggle = toggle;
				let capturedMenuItem = menuItem;
				menuItem.Click.Subscribe(new [=](mi) => {
					capturedToggle.IsChecked = !capturedToggle.IsChecked;
					capturedMenuItem.IsChecked = capturedToggle.IsChecked;
				});
			}
			else if (item is ToolBarSeparator)
			{
				mOverflowMenu.AddSeparator();
			}
		}

		// Show menu below overflow button
		let bounds = mOverflowButton.ArrangedBounds;
		mOverflowMenu.OnAttachedToContext(Context);
		mOverflowMenu.Show(this, .(bounds.X, bounds.Bottom));
	}

	// Layout

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure all items
		mItemsPanel.Measure(constraints);
		let panelSize = mItemsPanel.DesiredSize;

		// Measure overflow button
		mOverflowButton.Measure(constraints);

		float width = panelSize.Width + Padding.Left + Padding.Right;
		float height = panelSize.Height + Padding.Top + Padding.Bottom;

		if (mShowOverflowButton && mOrientation == .Horizontal)
			width += mOverflowButtonWidth;

		return .(width, height);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		mOverflowItems.Clear();
		mHasOverflow = false;

		let availableWidth = contentBounds.Width - Padding.Left - Padding.Right;
		let availableHeight = contentBounds.Height - Padding.Top - Padding.Bottom;

		float usedSpace = 0;
		float maxCrossSize = 0;

		// Calculate available space (reserve space for overflow button if needed)
		float availableMainAxis = mOrientation == .Horizontal ? availableWidth : availableHeight;
		if (mShowOverflowButton)
			availableMainAxis -= mOverflowButtonWidth;

		// First pass: determine which items fit
		for (let item in mItems)
		{
			let itemSize = mOrientation == .Horizontal ? item.DesiredSize.Width : item.DesiredSize.Height;
			let itemCrossSize = mOrientation == .Horizontal ? item.DesiredSize.Height : item.DesiredSize.Width;

			if (usedSpace + itemSize <= availableMainAxis)
			{
				// Item fits
				item.Visibility = .Visible;
				usedSpace += itemSize + mItemsPanel.Spacing;
				maxCrossSize = Math.Max(maxCrossSize, itemCrossSize);
			}
			else
			{
				// Item doesn't fit - move to overflow
				item.Visibility = .Collapsed;
				mOverflowItems.Add(item);
				mHasOverflow = true;
			}
		}

		// Arrange items panel
		let panelX = contentBounds.X + Padding.Left;
		let panelY = contentBounds.Y + Padding.Top;
		let panelWidth = mOrientation == .Horizontal ? usedSpace : availableWidth;
		let panelHeight = mOrientation == .Horizontal ? availableHeight : usedSpace;
		mItemsPanel.Arrange(.(panelX, panelY, panelWidth, panelHeight));

		// Arrange overflow button
		if (mShowOverflowButton && mHasOverflow)
		{
			mOverflowButton.Visibility = .Visible;
			if (mOrientation == .Horizontal)
			{
				let btnX = contentBounds.Right - Padding.Right - mOverflowButtonWidth;
				mOverflowButton.Arrange(.(btnX, panelY, mOverflowButtonWidth, availableHeight));
			}
			else
			{
				let btnY = contentBounds.Bottom - Padding.Bottom - mOverflowButtonWidth;
				mOverflowButton.Arrange(.(panelX, btnY, availableWidth, mOverflowButtonWidth));
			}
		}
		else
		{
			mOverflowButton.Visibility = .Collapsed;
		}
	}

	// Rendering

	protected override void RenderOverride(DrawContext ctx)
	{
		// Background
		RenderBackground(ctx);

		// Border
		let bounds = ArrangedBounds;
		ctx.DrawRect(bounds, BorderColor, 1);

		// Render items panel
		mItemsPanel.Render(ctx);

		// Render overflow button
		if (mOverflowButton.Visibility == .Visible)
			mOverflowButton.Render(ctx);
	}

	// Hit testing - must test mItemsPanel and mOverflowButton children

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Test overflow button first (it's on top)
		if (mOverflowButton.Visibility == .Visible)
		{
			let hit = mOverflowButton.HitTest(point);
			if (hit != null)
				return hit;
		}

		// Test the items panel and its children
		let hit = mItemsPanel.HitTest(point);
		if (hit != null)
			return hit;

		return this;
	}

	// Visual children

	public override int VisualChildCount => mOverflowButton.Visibility == .Visible ? 2 : 1;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0) return mItemsPanel;
		if (index == 1 && mOverflowButton.Visibility == .Visible) return mOverflowButton;
		return null;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mItemsPanel.OnAttachedToContext(context);
		mOverflowButton.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mItemsPanel.OnDetachedFromContext();
		mOverflowButton.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
