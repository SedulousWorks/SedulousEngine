using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A horizontal menu bar containing MenuBarItem elements.
/// Supports keyboard navigation with Alt+key accelerators.
public class Menu : Control, IAcceleratorHandler
{
	private List<MenuBarItem> mItems = new .() ~ delete _;  // Items owned by mItemsPanel
	private StackPanel mItemsPanel ~ delete _;

	// Currently open dropdown
	private ContextMenu mOpenDropdown;
	private MenuBarItem mOpenDropdownOwner;

	// Keyboard navigation
	private int mSelectedIndex = -1;
	private bool mIsAltModeActive = false;

	/// Creates a new Menu bar.
	public this()
	{
		IsFocusable = true;
		IsTabStop = false;

		mItemsPanel = new StackPanel();
		mItemsPanel.Orientation = .Horizontal;
		mItemsPanel.Spacing = 0;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Menu";

	/// Number of menu items.
	public int ItemCount => mItems.Count;

	/// Whether Alt-key accelerator mode is active (shows underlines).
	public bool IsAltModeActive => mIsAltModeActive;

	/// Adds a menu item with the specified text.
	public MenuBarItem AddItem(StringView text)
	{
		let item = new MenuBarItem(text);
		AddItem(item);
		return item;
	}

	/// Adds an existing MenuBarItem.
	public void AddItem(MenuBarItem item)
	{
		item.ParentMenu = this;
		mItems.Add(item);
		mItemsPanel.AddChild(item);
		InvalidateLayout();
	}

	/// Removes a menu item.
	public void RemoveItem(MenuBarItem item)
	{
		if (mItems.Remove(item))
		{
			item.ParentMenu = null;
			mItemsPanel.RemoveChild(item);
			InvalidateLayout();
		}
	}

	/// Gets the menu item at the specified index.
	public MenuBarItem GetItem(int index)
	{
		if (index >= 0 && index < mItems.Count)
			return mItems[index];
		return null;
	}

	/// Clears all menu items.
	public void ClearItems()
	{
		CloseDropdown();
		for (let item in mItems)
		{
			item.ParentMenu = null;
			mItemsPanel.RemoveChild(item, deleteAfterRemove: false);
		}
		DeleteContainerAndItems!(mItems);
		mItems = new .();
		InvalidateLayout();
	}

	/// Activates Alt-key accelerator mode.
	public void ActivateAltMode()
	{
		if (!mIsAltModeActive)
		{
			mIsAltModeActive = true;
			// Select first item
			if (mItems.Count > 0)
				SetSelectedIndex(0);
		}
	}

	/// Deactivates Alt-key accelerator mode.
	public void DeactivateAltMode()
	{
		if (mIsAltModeActive)
		{
			mIsAltModeActive = false;
			SetSelectedIndex(-1);
			CloseDropdown();
		}
	}

	/// Opens the dropdown for the specified item.
	internal void OpenDropdown(MenuBarItem item)
	{
		if (mOpenDropdownOwner == item)
			return;

		// Close existing dropdown
		CloseDropdown();

		// Open new dropdown
		mOpenDropdownOwner = item;
		mOpenDropdown = item.DropdownMenu;
		item.[Friend]SetSelected(true);
		item.[Friend]OpenDropdown();

		// Update selected index
		let index = mItems.IndexOf(item);
		if (index >= 0)
			mSelectedIndex = index;
	}

	/// Closes the current dropdown.
	internal void CloseDropdown()
	{
		let owner = mOpenDropdownOwner;
		if (owner != null)
		{
			// Clear fields first to prevent re-entry issues
			mOpenDropdownOwner = null;
			mOpenDropdown = null;
			// Now safe to call methods that might trigger callbacks
			owner.[Friend]CloseDropdown();
			owner.[Friend]SetSelected(false);
		}
	}

	/// Called when a dropdown is closed externally.
	private void OnDropdownClosed(MenuBarItem item)
	{
		if (mOpenDropdownOwner == item)
		{
			mOpenDropdownOwner.[Friend]SetSelected(false);
			mOpenDropdownOwner = null;
			mOpenDropdown = null;
		}
	}

	/// Moves to the next menu item (right arrow).
	public void MoveToNextMenu()
	{
		if (mItems.Count == 0)
			return;

		int newIndex = mSelectedIndex + 1;
		if (newIndex >= mItems.Count)
			newIndex = 0;

		bool wasOpen = mOpenDropdownOwner != null;
		SetSelectedIndex(newIndex);

		if (wasOpen && mSelectedIndex >= 0)
			OpenDropdown(mItems[mSelectedIndex]);
	}

	/// Moves to the previous menu item (left arrow).
	public void MoveToPreviousMenu()
	{
		if (mItems.Count == 0)
			return;

		int newIndex = mSelectedIndex - 1;
		if (newIndex < 0)
			newIndex = mItems.Count - 1;

		bool wasOpen = mOpenDropdownOwner != null;
		SetSelectedIndex(newIndex);

		if (wasOpen && mSelectedIndex >= 0)
			OpenDropdown(mItems[mSelectedIndex]);
	}

	/// Sets the selected index.
	private void SetSelectedIndex(int index)
	{
		if (mSelectedIndex == index)
			return;

		// Deselect old
		if (mSelectedIndex >= 0 && mSelectedIndex < mItems.Count)
			mItems[mSelectedIndex].[Friend]SetSelected(false);

		mSelectedIndex = index;

		// Select new
		if (mSelectedIndex >= 0 && mSelectedIndex < mItems.Count)
			mItems[mSelectedIndex].[Friend]SetSelected(true);
	}

	/// Processes an accelerator key press.
	private bool ProcessAccelerator(char32 key)
	{
		let upperKey = key.ToUpper;
		for (int i = 0; i < mItems.Count; i++)
		{
			if (mItems[i].AcceleratorKey == upperKey)
			{
				SetSelectedIndex(i);
				OpenDropdown(mItems[i]);
				return true;
			}
		}
		return false;
	}

	// Input handling

	/// Handles global accelerator key events (IAcceleratorHandler implementation).
	public bool HandleAccelerator(KeyCode key, KeyModifiers modifiers)
	{
		// Handle Alt key to toggle Alt mode
		if (key == .LeftAlt || key == .RightAlt)
		{
			if (!mIsAltModeActive)
				ActivateAltMode();
			else
				DeactivateAltMode();
			return true;
		}

		// Handle Alt+letter to open menu directly
		if (modifiers.HasFlag(.Alt))
		{
			let c = KeyCodeToChar(key);
			if (c != '\0' && ProcessAccelerator(c))
				return true;
		}

		return false;
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Handled)
			return;

		switch (e.Key)
		{
		case .Left:
			MoveToPreviousMenu();
			e.Handled = true;

		case .Right:
			MoveToNextMenu();
			e.Handled = true;

		case .Down:
			if (mSelectedIndex >= 0 && mOpenDropdownOwner == null)
			{
				OpenDropdown(mItems[mSelectedIndex]);
				e.Handled = true;
			}

		case .Return, .Space:
			if (mSelectedIndex >= 0)
			{
				if (mOpenDropdownOwner == null)
					OpenDropdown(mItems[mSelectedIndex]);
				e.Handled = true;
			}

		case .Escape:
			if (mOpenDropdownOwner != null)
			{
				CloseDropdown();
				e.Handled = true;
			}
			else if (mIsAltModeActive)
			{
				DeactivateAltMode();
				e.Handled = true;
			}

		default:
			// Check for letter key when Alt mode is active (after pressing Alt alone)
			if (mIsAltModeActive)
			{
				let c = KeyCodeToChar(e.Key);
				if (c != '\0' && ProcessAccelerator(c))
					e.Handled = true;
			}
		}
	}

	/// Converts a KeyCode to a character for accelerator matching.
	private char32 KeyCodeToChar(KeyCode key)
	{
		switch (key)
		{
		case .A: return 'A';
		case .B: return 'B';
		case .C: return 'C';
		case .D: return 'D';
		case .E: return 'E';
		case .F: return 'F';
		case .G: return 'G';
		case .H: return 'H';
		case .I: return 'I';
		case .J: return 'J';
		case .K: return 'K';
		case .L: return 'L';
		case .M: return 'M';
		case .N: return 'N';
		case .O: return 'O';
		case .P: return 'P';
		case .Q: return 'Q';
		case .R: return 'R';
		case .S: return 'S';
		case .T: return 'T';
		case .U: return 'U';
		case .V: return 'V';
		case .W: return 'W';
		case .X: return 'X';
		case .Y: return 'Y';
		case .Z: return 'Z';
		default: return '\0';
		}
	}

	// Layout

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mItemsPanel.Measure(constraints);
		let panelSize = mItemsPanel.DesiredSize;
		return .(panelSize.Width + Padding.Left + Padding.Right,
				 panelSize.Height + Padding.Top + Padding.Bottom);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		let panelBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Y + Padding.Top,
			contentBounds.Width - Padding.Left - Padding.Right,
			contentBounds.Height - Padding.Top - Padding.Bottom
		);
		mItemsPanel.Arrange(panelBounds);
	}

	// Rendering

	protected override void RenderOverride(DrawContext ctx)
	{
		// Background
		RenderBackground(ctx);

		// Render items panel
		mItemsPanel.Render(ctx);

		// Bottom border
		let bounds = ArrangedBounds;
		ctx.DrawLine(.(bounds.X, bounds.Bottom - 1), .(bounds.Right, bounds.Bottom - 1), BorderColor, 1);
	}

	// Hit testing - must test mItemsPanel children

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Test the items panel and its children
		let hit = mItemsPanel.HitTest(point);
		if (hit != null)
			return hit;

		return this;
	}

	// Visual children

	public override int VisualChildCount => 1;
	public override UIElement GetVisualChild(int index) => index == 0 ? mItemsPanel : null;

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mItemsPanel.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mItemsPanel.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
