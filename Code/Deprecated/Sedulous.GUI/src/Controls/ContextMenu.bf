using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A popup menu that appears on right-click or programmatic invocation.
public class ContextMenu : Control, IPopupOwner
{
	// Items in the menu (items are owned by mItemsPanel, not this list)
	private List<UIElement> mItems ~ delete _;
	private StackPanel mItemsPanel ~ delete _;

	// Selection state
	private int mSelectedIndex = -1;

	// Submenu management
	private ContextMenu mOpenSubmenu ~ delete _;
	private MenuItem mSubmenuOwner;

	// Hover tracking for submenu auto-open
	private MenuItem mHoveredItem;
	private double mHoverStartTime = -1;
	private float mSubmenuOpenDelay = 0.25f;  // 250ms delay before opening submenu

	// Events
	private EventAccessor<delegate void(ContextMenu)> mOpened = new .() ~ delete _;
	private EventAccessor<delegate void(ContextMenu)> mClosed = new .() ~ delete _;

	// Appearance
	private float mMenuMinWidth = 150;
	private float mCornerRadius = 4;
	private Color mMenuBorderColor = Color(80, 80, 80, 255);
	private float mMenuBorderThickness = 1;

	/// Creates a new ContextMenu.
	public this()
	{
		IsFocusable = true;
		IsTabStop = false;
		Background = Color(45, 45, 45, 255);
		Padding = .(4, 4, 4, 4);
		// Don't stretch to fill container - size to content
		HorizontalAlignment = .Left;
		VerticalAlignment = .Top;

		mItems = new .();
		mItemsPanel = new StackPanel();
		mItemsPanel.Orientation = .Vertical;
		mItemsPanel.Spacing = 0;
	}

	public ~this()
	{

	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ContextMenu";

	/// Number of items in the menu.
	public int ItemCount => mItems.Count;

	/// Minimum width of the menu.
	public float MenuMinWidth
	{
		get => mMenuMinWidth;
		set => mMenuMinWidth = value;
	}

	/// Event fired when the menu is opened.
	public EventAccessor<delegate void(ContextMenu)> Opened => mOpened;

	/// Event fired when the menu is closed.
	public EventAccessor<delegate void(ContextMenu)> Closed => mClosed;

	/// Adds a menu item with the specified text.
	public MenuItem AddItem(StringView text)
	{
		let item = new MenuItem(text);
		AddItemInternal(item);
		return item;
	}

	/// Adds an existing menu item.
	public void AddItem(MenuItem item)
	{
		AddItemInternal(item);
	}

	/// Adds a separator.
	public void AddSeparator()
	{
		let separator = new MenuSeparator();
		mItems.Add(separator);
		mItemsPanel.AddChild(separator);
	}

	/// Gets an item by index.
	public UIElement GetItem(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return null;
		return mItems[index];
	}

	/// Removes all items.
	public void ClearItems()
	{
		for (let item in mItems)
		{
			mItemsPanel.RemoveChild(item, false);
		}
		DeleteContainerAndItems!(mItems);
		mItems = new .();
		mSelectedIndex = -1;
	}

	/// Shows the context menu at the specified position.
	public void Show(UIElement owner, Vector2 position)
	{
		if (Context == null)
			return;

		// Create anchor rect at click position
		let anchorRect = RectangleF(position.X, position.Y, 1, 1);
		Context.PopupLayer.ShowPopup(this, owner, anchorRect, true);

		mOpened.[Friend]Invoke(this);

		// Request focus
		Context?.FocusManager?.SetFocus(this);
	}

	/// Hides the context menu.
	public void Hide()
	{
		if (Context == null)
			return;

		// Close any open submenus first
		CloseSubmenu();

		Context.PopupLayer.ClosePopup(this);
		mClosed.[Friend]Invoke(this);
		mSelectedIndex = -1;
	}

	/// IPopupOwner implementation - called when popup is closed externally.
	public void OnPopupClosed(UIElement popup)
	{
		if (popup == this)
		{
			mClosed.[Friend]Invoke(this);
			mSelectedIndex = -1;
		}
	}

	private void AddItemInternal(UIElement item)
	{
		mItems.Add(item);
		mItemsPanel.AddChild(item);

		// Set parent menu reference for submenu notifications
		if (let menuItem = item as MenuItem)
			menuItem.ParentMenu = this;
	}

	/// Called by MenuItem when mouse enters it. Used to track hover for submenu auto-open.
	public void OnItemHovered(MenuItem item)
	{
		if (item == mHoveredItem)
			return;  // Same item, no change

		mHoveredItem = item;

		// If hovering over a different item, close any open submenu that's not for this item
		if (mSubmenuOwner != null && mSubmenuOwner != item)
		{
			CloseSubmenu();
		}

		// Start hover timer if item has sub-items
		if (item.HasSubItems)
		{
			mHoverStartTime = Context?.TotalTime ?? -1;
		}
		else
		{
			mHoverStartTime = -1;
		}
	}

	/// Updates the context menu (checks hover timer for submenu auto-open).
	public void Update(double totalTime)
	{
		// Check if we should auto-open a submenu
		if (mHoveredItem != null && mHoverStartTime >= 0 && mSubmenuOwner != mHoveredItem)
		{
			let elapsed = (float)(totalTime - mHoverStartTime);
			if (elapsed >= mSubmenuOpenDelay)
			{
				OpenSubmenuFor(mHoveredItem);
				mHoverStartTime = -1;  // Don't re-trigger
			}
		}
	}

	private void CloseSubmenu()
	{
		if (mOpenSubmenu != null)
		{
			mOpenSubmenu.Hide();
			delete mOpenSubmenu;
			mOpenSubmenu = null;
			mSubmenuOwner = null;
		}
	}

	private void OpenSubmenuFor(MenuItem item)
	{
		if (item == mSubmenuOwner)
			return;  // Already open for this item

		CloseSubmenu();

		if (!item.HasSubItems)
			return;

		// Create submenu
		mOpenSubmenu = new ContextMenu();
		for (int i = 0; i < item.SubItemCount; i++)
		{
			let subItem = item.GetSubItem(i);
			if (let menuItem = subItem as MenuItem)
			{
				let newItem = mOpenSubmenu.AddItem(menuItem.Text);
				newItem.ShortcutText = menuItem.ShortcutText;
				newItem.IsCheckable = menuItem.IsCheckable;
				newItem.IsChecked = menuItem.IsChecked;
				newItem.Command = menuItem.Command;
				newItem.CommandParameter = menuItem.CommandParameter;

				// Forward click event to the original item and close the menu chain
				let originalItem = menuItem;
				let parentMenu = this;
				newItem.Click.Subscribe(new [=](clickedItem) => {
					// Sync checkable state back to original
					if (originalItem.IsCheckable)
						originalItem.IsChecked = clickedItem.IsChecked;
					// Activate the original item (fires its Click event and command)
					originalItem.Activate();
					// Defer menu closure to avoid deleting this handler while it's executing
					// Use QueueAction to close after the current event handling completes
					if (parentMenu.Context != null)
						parentMenu.Context.QueueAction(new () => parentMenu.Hide());
					else
						parentMenu.Hide();
				});

				// Recursively handle nested submenus
				if (menuItem.HasSubItems)
				{
					for (int j = 0; j < menuItem.SubItemCount; j++)
					{
						let nestedItem = menuItem.GetSubItem(j);
						if (let nestedMenuItem = nestedItem as MenuItem)
							newItem.AddItem(nestedMenuItem.Text);
						else if (nestedItem is MenuSeparator)
							newItem.AddSeparator();
					}
				}
			}
			else if (subItem is MenuSeparator)
			{
				mOpenSubmenu.AddSeparator();
			}
		}

		// Position submenu to the right of the parent item
		let itemBounds = item.ArrangedBounds;
		let submenuPos = Vector2(ArrangedBounds.Right - 2, itemBounds.Y);

		// Need to attach to context before showing
		mOpenSubmenu.OnAttachedToContext(Context);
		mOpenSubmenu.Show(this, submenuPos);
		mSubmenuOwner = item;
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure the items panel with unconstrained width so it sizes to content
		// Only constrain height to viewport
		let panelConstraints = SizeConstraints.FromMaximum(
			float.MaxValue,
			constraints.MaxHeight
		);
		mItemsPanel.Measure(panelConstraints);

		let panelSize = mItemsPanel.DesiredSize;
		return .(
			Math.Max(mMenuMinWidth, panelSize.Width) + Padding.Left + Padding.Right,
			panelSize.Height + Padding.Top + Padding.Bottom
		);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Arrange items panel
		let innerBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Y + Padding.Top,
			contentBounds.Width - Padding.Left - Padding.Right,
			contentBounds.Height - Padding.Top - Padding.Bottom
		);
		mItemsPanel.Arrange(innerBounds);
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background
		if (Background.A > 0)
		{
			if (mCornerRadius > 0)
				ctx.FillRoundedRect(bounds, mCornerRadius, Background);
			else
				ctx.FillRect(bounds, Background);
		}

		// Render items
		mItemsPanel.Render(ctx);

		// Draw border
		if (mMenuBorderColor.A > 0 && mMenuBorderThickness > 0)
		{
			if (mCornerRadius > 0)
				ctx.DrawRoundedRect(bounds, mCornerRadius, mMenuBorderColor, mMenuBorderThickness);
			else
				ctx.DrawRect(bounds, mMenuBorderColor, mMenuBorderThickness);
		}
	}

	// === Input ===

	protected override void OnKeyDown(KeyEventArgs e)
	{
		switch (e.Key)
		{
		case .Up:
			SelectPrevious();
			e.Handled = true;
		case .Down:
			SelectNext();
			e.Handled = true;
		case .Right:
			// Open submenu if current item has one
			if (mSelectedIndex >= 0)
			{
				if (let menuItem = mItems[mSelectedIndex] as MenuItem)
				{
					if (menuItem.HasSubItems)
					{
						OpenSubmenuFor(menuItem);
						e.Handled = true;
					}
				}
			}
		case .Left:
			// Close this menu if it's a submenu
			// (handled by parent)
			break;
		case .Return, .Space:
			ActivateSelected();
			e.Handled = true;
		case .Escape:
			Hide();
			e.Handled = true;
		default:
		}

		if (!e.Handled)
			base.OnKeyDown(e);
	}

	private void SelectNext()
	{
		if (mItems.Count == 0)
			return;

		// Find next selectable item
		var index = mSelectedIndex;
		for (int i = 0; i < mItems.Count; i++)
		{
			index = (index + 1) % mItems.Count;
			if (mItems[index] is MenuItem)
			{
				SetSelectedIndex(index);
				return;
			}
		}
	}

	private void SelectPrevious()
	{
		if (mItems.Count == 0)
			return;

		// Find previous selectable item
		var index = mSelectedIndex < 0 ? 0 : mSelectedIndex;
		for (int i = 0; i < mItems.Count; i++)
		{
			index = index - 1;
			if (index < 0)
				index = mItems.Count - 1;
			if (mItems[index] is MenuItem)
			{
				SetSelectedIndex(index);
				return;
			}
		}
	}

	private void SetSelectedIndex(int index)
	{
		// Clear old selection
		if (mSelectedIndex >= 0 && mSelectedIndex < mItems.Count)
		{
			if (let oldItem = mItems[mSelectedIndex] as MenuItem)
				oldItem.SetHighlighted(false);
		}

		mSelectedIndex = index;

		// Set new selection
		if (mSelectedIndex >= 0 && mSelectedIndex < mItems.Count)
		{
			if (let newItem = mItems[mSelectedIndex] as MenuItem)
				newItem.SetHighlighted(true);
		}
	}

	private void ActivateSelected()
	{
		if (mSelectedIndex >= 0 && mSelectedIndex < mItems.Count)
		{
			if (let menuItem = mItems[mSelectedIndex] as MenuItem)
			{
				if (menuItem.HasSubItems)
				{
					OpenSubmenuFor(menuItem);
				}
				else
				{
					menuItem.Activate();
					Hide();
				}
			}
		}
	}

	// === Visual child management ===

	public override int VisualChildCount => 1;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0)
			return mItemsPanel;
		return null;
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Test items panel and its children
		let hit = mItemsPanel.HitTest(point);
		if (hit != null)
			return hit;

		return this;
	}

	// === Lifecycle ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mItemsPanel.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies default context menu styling from theme.
	private void ApplyThemeDefaults()
	{
		let style = GetThemeStyle();
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();

		// Apply style properties
		Background = style.Background.A > 0 ? style.Background : palette.Surface;
		mMenuBorderColor = style.BorderColor.A > 0 ? style.BorderColor : palette.Border;
		mMenuBorderThickness = style.BorderThickness > 0 ? style.BorderThickness : 1;
		mCornerRadius = style.CornerRadius > 0 ? style.CornerRadius : (theme?.DefaultCornerRadius ?? 4);
		Padding = style.Padding.Left > 0 || style.Padding.Top > 0 ? style.Padding : .(4, 4, 4, 4);
	}

	public override void OnDetachedFromContext()
	{
		mItemsPanel.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
