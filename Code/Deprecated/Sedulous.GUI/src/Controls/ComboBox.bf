using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A dropdown selection control that displays a list of items when opened.
public class ComboBox : Control, IPopupOwner
{
	// Selection (items are stored in mDropDownList)
	private int mSelectedIndex = -1;

	// Dropdown
	private bool mIsDropDownOpen = false;
	private bool mIsSyncingSelection = false;  // Suppresses close during OpenDropDown selection sync
	private ListBox mDropDownList;  // Owned by mDropDownContainer as its Child
	private float mDropDownMaxHeight = 200;
	private Border mDropDownContainer ~ delete _;

	// Display
	private TextBlock mSelectedText = new .() ~ delete _;
	private float mDropDownButtonWidth = 20;
	private ImageBrush? mArrowImage;

	// Events
	private EventAccessor<delegate void(ComboBox)> mSelectionChanged = new .() ~ delete _;
	private EventAccessor<delegate void(ComboBox, bool)> mDropDownStateChanged = new .() ~ delete _;

	// Internal event handlers
	private delegate void(ListBox) mListSelectionHandler;  // Owned by mDropDownList.SelectionChanged via Subscribe

	/// Creates a new ComboBox.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .Pointer;

		// Setup selected text display
		mSelectedText.SetParent(this);

		// Setup dropdown list
		mDropDownList = new ListBox();
		mDropDownList.SelectionMode = .Single;

		// Setup dropdown container (border around list)
		mDropDownContainer = new Border();
		mDropDownContainer.Child = mDropDownList;
		mDropDownContainer.BorderBrush = Color(100, 100, 100, 255);
		mDropDownContainer.SetBorderThickness(1);
		mDropDownContainer.Background = Color(45, 45, 45, 255);

		// Subscribe to list selection
		mListSelectionHandler = new => OnListSelectionChanged;
		mDropDownList.SelectionChanged.Subscribe(mListSelectionHandler);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ComboBox";

	/// Number of items.
	public int ItemCount => mDropDownList.ItemCount;

	/// The maximum height of the dropdown.
	public float DropDownMaxHeight
	{
		get => mDropDownMaxHeight;
		set => mDropDownMaxHeight = Math.Max(50, value);
	}

	/// Whether the dropdown is currently open.
	public bool IsDropDownOpen
	{
		get => mIsDropDownOpen;
		set
		{
			if (value)
				OpenDropDown();
			else
				CloseDropDown();
		}
	}

	/// The index of the selected item. -1 if nothing selected.
	public int SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			var newValue = value;
			if (newValue < -1 || newValue >= mDropDownList.ItemCount)
				newValue = -1;

			if (mSelectedIndex != newValue)
			{
				mSelectedIndex = newValue;
				UpdateSelectedText();
				mSelectionChanged.[Friend]Invoke(this);
			}
		}
	}

	/// The selected item, or null if nothing selected.
	public Object SelectedItem
	{
		get
		{
			if (mSelectedIndex < 0 || mSelectedIndex >= mDropDownList.ItemCount)
				return null;
			return mDropDownList.GetItem(mSelectedIndex);
		}
	}

	/// Event fired when selection changes.
	public EventAccessor<delegate void(ComboBox)> SelectionChanged => mSelectionChanged;

	/// Event fired when dropdown opens or closes.
	public EventAccessor<delegate void(ComboBox, bool)> DropDownStateChanged => mDropDownStateChanged;

	/// Image for the dropdown arrow (replaces drawn triangle).
	public ImageBrush? ArrowImage
	{
		get => mArrowImage;
		set => mArrowImage = value;
	}

	// === Item Management ===

	/// Adds a string item to the combo box.
	/// The control creates and owns the string internally.
	public void AddText(StringView text)
	{
		mDropDownList.AddText(text);
		InvalidateLayout();
	}

	/// Adds an item to the combo box.
	/// Note: ComboBox does NOT take ownership of the item.
	public void AddItem(Object item)
	{
		mDropDownList.AddItem(item);
		InvalidateLayout();
	}

	/// Inserts a string item at the specified index.
	/// The control creates and owns the string internally.
	public void InsertText(int index, StringView text)
	{
		let clampedIndex = Math.Clamp(index, 0, mDropDownList.ItemCount);
		mDropDownList.InsertText(clampedIndex, text);

		// Adjust selection if needed
		if (mSelectedIndex >= clampedIndex)
			mSelectedIndex++;

		InvalidateLayout();
	}

	/// Inserts an item at the specified index.
	public void InsertItem(int index, Object item)
	{
		let clampedIndex = Math.Clamp(index, 0, mDropDownList.ItemCount);
		mDropDownList.InsertItem(clampedIndex, item);

		// Adjust selection if needed
		if (mSelectedIndex >= clampedIndex)
			mSelectedIndex++;

		InvalidateLayout();
	}

	/// Removes an item.
	public bool RemoveItem(Object item)
	{
		let index = mDropDownList.IndexOf(item);
		if (index < 0)
			return false;
		RemoveItemAt(index);
		return true;
	}

	/// Removes the item at the specified index.
	public void RemoveItemAt(int index)
	{
		if (index < 0 || index >= mDropDownList.ItemCount)
			return;

		mDropDownList.RemoveItemAt(index);

		// Adjust selection
		if (mSelectedIndex == index)
		{
			mSelectedIndex = -1;
			UpdateSelectedText();
			mSelectionChanged.[Friend]Invoke(this);
		}
		else if (mSelectedIndex > index)
		{
			mSelectedIndex--;
		}

		InvalidateLayout();
	}

	/// Clears all items.
	public void ClearItems()
	{
		mDropDownList.ClearItems();
		mSelectedIndex = -1;
		UpdateSelectedText();
		mSelectionChanged.[Friend]Invoke(this);
		InvalidateLayout();
	}

	/// Gets the item at the specified index.
	public Object GetItem(int index)
	{
		return mDropDownList.GetItem(index);
	}

	// === Dropdown Control ===

	/// Opens the dropdown.
	public void OpenDropDown()
	{
		if (mIsDropDownOpen || Context == null)
			return;

		// Sync selection to list (suppress close during sync)
		mIsSyncingSelection = true;
		mDropDownList.SelectedIndex = mSelectedIndex;
		mIsSyncingSelection = false;

		// Set open flag after sync so CloseDropDown() is also guarded by ordering
		mIsDropDownOpen = true;

		// Show popup anchored to this control
		Context.PopupLayer.ShowPopup(mDropDownContainer, this, ArrangedBounds, true);

		// Focus the list for keyboard navigation
		Context.FocusManager?.SetFocus(mDropDownList);

		mDropDownStateChanged.[Friend]Invoke(this, true);
	}

	/// Closes the dropdown.
	public void CloseDropDown()
	{
		if (!mIsDropDownOpen || Context == null)
			return;

		mIsDropDownOpen = false;
		Context.PopupLayer.ClosePopup(mDropDownContainer);

		// Return focus to combo box
		Context.FocusManager?.SetFocus(this);

		mDropDownStateChanged.[Friend]Invoke(this, false);
	}

	/// Toggles the dropdown open/closed.
	public void ToggleDropDown()
	{
		if (mIsDropDownOpen)
			CloseDropDown();
		else
			OpenDropDown();
	}

	// === IPopupOwner ===

	/// Called when the dropdown popup is closed externally (e.g., click outside).
	public void OnPopupClosed(UIElement popup)
	{
		if (popup == mDropDownContainer && mIsDropDownOpen)
		{
			mIsDropDownOpen = false;

			// Return focus to combo box
			Context?.FocusManager?.SetFocus(this);

			mDropDownStateChanged.[Friend]Invoke(this, false);
		}
	}

	// === Internal ===

	private void UpdateSelectedText()
	{
		if (mSelectedIndex >= 0 && mSelectedIndex < mDropDownList.ItemCount)
		{
			let item = mDropDownList.GetItem(mSelectedIndex);
			if (let str = item as String)
			{
				mSelectedText.Text = str;
			}
			else if (item != null)
			{
				let text = scope String();
				item.ToString(text);
				mSelectedText.Text = text;
			}
			else
			{
				mSelectedText.Text = "";
			}
		}
		else
		{
			mSelectedText.Text = "";
		}
	}

	private void OnListSelectionChanged(ListBox list)
	{
		let newIndex = list.SelectedIndex;
		if (newIndex >= 0 && newIndex != mSelectedIndex)
		{
			mSelectedIndex = newIndex;
			UpdateSelectedText();
			mSelectionChanged.[Friend]Invoke(this);
		}

		// Close dropdown after selection (but not during initial sync in OpenDropDown)
		if (!mIsSyncingSelection)
			CloseDropDown();
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mSelectedText.OnAttachedToContext(context);
		mDropDownContainer.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies default combo box styling from theme.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();

		// Apply theme dimensions
		mDropDownButtonWidth = theme?.ComboBoxDropDownButtonWidth ?? 20;
		mDropDownMaxHeight = theme?.ComboBoxDropDownMaxHeight ?? 200;

		// Apply dropdown container styling
		mDropDownContainer.BorderBrush = palette.Border;
		mDropDownContainer.Background = palette.Surface;
	}

	public override void OnDetachedFromContext()
	{
		// Close dropdown if open
		if (mIsDropDownOpen)
			CloseDropDown();

		mDropDownContainer.OnDetachedFromContext();
		mSelectedText.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure selected text
		mSelectedText.Measure(constraints);
		let textSize = mSelectedText.DesiredSize;

		// Calculate dropdown size
		mDropDownList.Measure(SizeConstraints.Unconstrained);
		let listDesired = mDropDownList.DesiredSize;

		// Dropdown height is clamped to max (account for container border)
		let borderExtra = mDropDownContainer.BorderThickness.TotalVertical;
		let dropdownHeight = Math.Min(listDesired.Height + borderExtra, mDropDownMaxHeight);
		mDropDownContainer.Height = dropdownHeight;
		mDropDownContainer.Width = Math.Max(listDesired.Width, constraints.MaxWidth != SizeConstraints.Infinity ? constraints.MaxWidth : 150);

		// ComboBox needs space for text + dropdown button
		let minHeight = Math.Max(textSize.Height + 8, 24);
		let minWidth = textSize.Width + mDropDownButtonWidth + 16;

		return .(minWidth, minHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Position selected text (leave room for dropdown button)
		let textBounds = RectangleF(
			contentBounds.X + 4,
			contentBounds.Y,
			contentBounds.Width - mDropDownButtonWidth - 8,
			contentBounds.Height
		);
		mSelectedText.Arrange(textBounds);

		// Update dropdown container size to match full ComboBox width (including border)
		mDropDownContainer.Width = ArrangedBounds.Width;
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background
		RenderBackground(ctx);

		// Draw border
		let borderColor = GetStateBorderColor();
		if (BorderThickness > 0)
			ctx.DrawRect(bounds, borderColor, BorderThickness);

		// Draw selected text
		mSelectedText.Render(ctx);

		// Draw dropdown button area
		let buttonX = bounds.Right - mDropDownButtonWidth;
		let buttonBounds = RectangleF(buttonX, bounds.Y, mDropDownButtonWidth, bounds.Height);

		// Try image-based arrow first
		if (mArrowImage.HasValue && mArrowImage.Value.IsValid)
		{
			var img = mArrowImage.Value;
			img.Tint = ControlStyle.ModulateTint(img.Tint, CurrentState);
			ctx.DrawImageBrush(img, buttonBounds);
		}
		else
		{
			// Dropdown arrow
			let arrowSize = 8f;
			let arrowX = buttonBounds.X + (buttonBounds.Width - arrowSize) / 2;
			let arrowY = buttonBounds.Y + (buttonBounds.Height - arrowSize / 2) / 2;

			let foreground = GetStateForeground();

			// Draw simple triangle arrow using polygon
			Vector2[3] arrowPoints = .(
				.(arrowX, arrowY),
				.(arrowX + arrowSize, arrowY),
				.(arrowX + arrowSize / 2, arrowY + arrowSize / 2)
			);
			ctx.FillPolygon(arrowPoints, foreground);
		}
	}

	// === Input ===

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && !e.Handled)
		{
			ToggleDropDown();
			e.Handled = true;
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Handled)
			return;

		switch (e.Key)
		{
		case .Space, .Return:
			if (!mIsDropDownOpen)
			{
				OpenDropDown();
				e.Handled = true;
			}

		case .Escape:
			if (mIsDropDownOpen)
			{
				CloseDropDown();
				e.Handled = true;
			}

		case .Up:
			if (!mIsDropDownOpen)
			{
				// Navigate selection without opening dropdown
				if (mSelectedIndex > 0)
					SelectedIndex = mSelectedIndex - 1;
				e.Handled = true;
			}

		case .Down:
			if (!mIsDropDownOpen)
			{
				if (mSelectedIndex < mDropDownList.ItemCount - 1)
					SelectedIndex = mSelectedIndex + 1;
				e.Handled = true;
			}

		default:
		}
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

	// === Visual Children ===

	public override int VisualChildCount => 1;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0)
			return mSelectedText;
		return null;
	}
}
