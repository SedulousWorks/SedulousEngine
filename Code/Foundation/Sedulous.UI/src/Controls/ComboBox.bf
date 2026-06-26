namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Drop-down selector. Displays the selected item with a dropdown arrow.
/// Opens a dedicated dropdown panel (not ContextMenu) that matches the
/// ComboBox width and highlights the selected item.
public class ComboBox : View, IPopupOwner
{
	private List<String> mItems = new .() ~ { for (let s in _) delete s; delete _; };
	private int mSelectedIndex = -1;
	private bool mIsOpen;
	private float mArrowAreaWidth = 24;

	public Event<delegate void(ComboBox, int)> OnSelectionChanged ~ _.Dispose();

	public int SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			let clamped = Math.Clamp(value, -1, mItems.Count - 1);
			if (mSelectedIndex != clamped)
			{
				mSelectedIndex = clamped;
				Invalidate();
				OnSelectionChanged(this, clamped);
			}
		}
	}

	public StringView SelectedText =>
		(mSelectedIndex >= 0 && mSelectedIndex < mItems.Count) ? mItems[mSelectedIndex] : "";

	public int ItemCount => mItems.Count;
	public bool IsOpen => mIsOpen;

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		WantsArrowKeys = true;
		Cursor = .Hand;
	}

	/// Add an item. Returns the item index.
	public int AddItem(StringView text)
	{
		let index = mItems.Count;
		mItems.Add(new String(text));
		Invalidate();
		return index;
	}

	/// Remove an item by index.
	public void RemoveItem(int index)
	{
		if (index < 0 || index >= mItems.Count) return;
		delete mItems[index];
		mItems.RemoveAt(index);
		if (mSelectedIndex >= mItems.Count)
			mSelectedIndex = mItems.Count - 1;
		Invalidate();
	}

	/// Remove all items.
	public void ClearItems()
	{
		for (let s in mItems) delete s;
		mItems.Clear();
		mSelectedIndex = -1;
		Invalidate();
	}

	// === Measurement ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		float maxTextW = 0;
		float textH = fontSize;

		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font != null)
			{
				textH = font.Font.Metrics.LineHeight;
				for (let item in mItems)
				{
					let w = font.Font.MeasureString(item);
					if (w > maxTextW) maxTextW = w;
				}
			}
		}

		let padding = Thickness(8, 6);
		MeasuredSize = .(
			constraints.ConstrainWidth(padding.TotalHorizontal + maxTextW + mArrowAreaWidth),
			constraints.ConstrainHeight(padding.TotalVertical + textH));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let state = GetControlState();

		// Background
		let bg = ResolveStyleDrawable(.Background);
		if (bg != null)
			bg.Draw(ctx, bounds, state);
		else
		{
			var bgColor = Color(40, 42, 52, 255);
			if (IsHovered) bgColor = Palette.ComputeHover(bgColor);
			ctx.VG.FillRect(bounds, bgColor);
		}

		// Border - accent when open
		if (mIsOpen)
		{
			let accentColor = ResolveStyleColor(.AccentColor, .(80, 160, 255, 255));
			if (let rrd = bg as RoundedRectDrawable)
			{
				if (!rrd.Radii.IsZero)
					ctx.VG.StrokeRoundedRect(bounds, rrd.Radii, accentColor, 2.0f);
				else
					ctx.VG.StrokeRect(bounds, accentColor, 2.0f);
			}
			else
			{
				let cr = ResolveStyleFloat(.CornerRadius);
				if (cr > 0)
					ctx.VG.StrokeRoundedRect(bounds, cr, accentColor, 2.0f);
				else
					ctx.VG.StrokeRect(bounds, accentColor, 2.0f);
			}
		}

		// Selected text
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		if (mSelectedIndex >= 0 && mSelectedIndex < mItems.Count && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font != null)
			{
				let textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				let textBounds = RectangleF(8, 0, Width - 16 - mArrowAreaWidth, Height);
				ctx.VG.DrawText(mItems[mSelectedIndex], font, textBounds, .Left, .Middle, textColor);
			}
		}

		// Dropdown arrow via pseudo-element
		let arrowDrawable = ResolvePartDrawable("arrow", .Background, state);
		let arrowX = Width - mArrowAreaWidth * 0.5f;
		let arrowY = Height * 0.5f;
		let arrowSize = 8.0f;

		if (arrowDrawable != null)
		{
			arrowDrawable.Draw(ctx, .(arrowX - arrowSize * 0.5f, arrowY - arrowSize * 0.5f, arrowSize, arrowSize));
		}
		else
		{
			let arrowColor = ResolvePartColor("arrow", .TextColor, state, .(180, 185, 200, 255));
			let aSize = 4.0f;
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(arrowX - aSize, arrowY - aSize * 0.5f);
			ctx.VG.LineTo(arrowX + aSize, arrowY - aSize * 0.5f);
			ctx.VG.LineTo(arrowX, arrowY + aSize * 0.5f);
			ctx.VG.ClosePath();
			ctx.VG.Fill(arrowColor);
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		if (mIsOpen)
			CloseDropdown();
		else
			OpenDropdown();
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		if (e.Key == .Space || e.Key == .Return)
		{
			if (!mIsOpen) OpenDropdown();
			e.Handled = true;
		}
		else if (e.Key == .Up)
		{
			if (mSelectedIndex > 0) SelectedIndex = mSelectedIndex - 1;
			e.Handled = true;
		}
		else if (e.Key == .Down)
		{
			if (mSelectedIndex < mItems.Count - 1) SelectedIndex = mSelectedIndex + 1;
			e.Handled = true;
		}
		else if (e.Key == .Escape && mIsOpen)
		{
			CloseDropdown();
			e.Handled = true;
		}
	}

	/// Open the dropdown popup.
	public void OpenDropdown()
	{
		if (mIsOpen || mItems.Count == 0 || Context == null) return;

		let root = Context.ActiveInputRoot;
		if (root == null) return;

		let dropdown = new ComboBoxDropdown(this);
		let screenPos = LocalToScreen(.(0, Height));
		let logical = root.LogicalSize;
		let screen = RectangleF(0, 0, logical.X, logical.Y);

		dropdown.Measure(BoxConstraints.Loose(screen.Width, screen.Height));

		var sy = screenPos.Y;
		// Flip above if clipping bottom.
		if (sy + dropdown.MeasuredSize.Y > screen.Height)
			sy = screenPos.Y - Height - dropdown.MeasuredSize.Y;

		root.PopupLayer.ShowPopup(dropdown, this, screenPos.X, sy,
			closeOnClickOutside: true, isModal: false, ownsView: true);
		mIsOpen = true;
		Invalidate();
	}

	/// Close the dropdown.
	public void CloseDropdown()
	{
		mIsOpen = false;
		Invalidate();
	}

	/// IPopupOwner - called when dropdown is closed externally.
	public void OnPopupClosed(View popup)
	{
		mIsOpen = false;
		Invalidate();
	}

	public View OwnerView => this;

	public override void OnActivate()
	{
		if (!IsEffectivelyEnabled) return;
		OpenDropdown();
	}
}

/// Dedicated dropdown panel for ComboBox. Matches parent width,
/// highlights selected and hovered items. Supports keyboard navigation.
class ComboBoxDropdown : View
{
	private ComboBox mOwner;
	private int32 mHoveredIndex = -1;
	private float mItemHeight = 28;

	public this(ComboBox owner)
	{
		IsFocusable = true;
		mOwner = owner;
		AddClass("contextmenu"); // reuse context menu styling for background
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let itemCount = mOwner.ItemCount;
		let totalH = 4 + mItemHeight * itemCount + 4;
		// Match the ComboBox width.
		let w = Math.Max(mOwner.Width, 100);
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(totalH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);

		// Background
		let bg = ResolveStyleDrawable(.Background);
		if (bg != null)
			bg.Draw(ctx, bounds, GetControlState());
		else
		{
			ctx.VG.FillRect(bounds, .(45, 48, 58, 255));
			ctx.VG.StrokeRect(bounds, .(70, 75, 90, 255), 1);
		}

		let textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
		let hoverColor = ResolveStyleColor(.AccentColor, .(60, 120, 200, 100));
		let selectedColor = Color(60, 120, 200, 50);
		let hoverDrawable = ResolveStyleDrawable(.MenuItemHoverDrawable);
		let fontSize = mOwner.ResolveStyleFloat(.FontSize, 14);
		let font = ctx.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);

		float y = 4;
		for (int32 i = 0; i < mOwner.ItemCount; i++)
		{
			let itemRect = RectangleF(4, y, Width - 8, mItemHeight);

			// Selected item highlight - use hover drawable shape but different color
			if (i == mOwner.SelectedIndex)
			{
				if (let rrd = hoverDrawable as RoundedRectDrawable)
				{
					if (!rrd.Radii.IsZero)
						ctx.VG.FillRoundedRect(itemRect, rrd.Radii, selectedColor);
					else
						ctx.VG.FillRect(itemRect, selectedColor);
				}
				else
					ctx.VG.FillRect(itemRect, selectedColor);
			}

			// Hover highlight
			if (i == mHoveredIndex)
			{
				if (hoverDrawable != null)
					hoverDrawable.Draw(ctx, itemRect);
				else
					ctx.VG.FillRect(itemRect, hoverColor);
			}

			// Text
			if (font != null)
				ctx.VG.DrawText(mOwner.[Friend]mItems[i], font, .(12, y, Width - 24, mItemHeight), .Left, .Middle, textColor);

			y += mItemHeight;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let newIndex = GetIndexAt(e.Y);
		if (newIndex != mHoveredIndex)
		{
			mHoveredIndex = newIndex;
			Invalidate();
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left) return;

		let index = GetIndexAt(e.Y);
		if (index >= 0 && index < mOwner.ItemCount)
		{
			mOwner.SelectedIndex = index;
			mOwner.CloseDropdown();
			// Close the popup.
			let ctx = Context;
			if (ctx != null)
				ctx.MutationQueue.QueueAction(new () => {
					ctx.ActiveInputRoot?.PopupLayer.ClosePopup(this);
				});
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		switch (e.Key)
		{
		case .Up:
			if (mHoveredIndex > 0) mHoveredIndex--;
			else if (mHoveredIndex < 0 && mOwner.ItemCount > 0) mHoveredIndex = (int32)mOwner.ItemCount - 1;
			Invalidate();
			e.Handled = true;
		case .Down:
			if (mHoveredIndex < mOwner.ItemCount - 1) mHoveredIndex++;
			else if (mHoveredIndex < 0 && mOwner.ItemCount > 0) mHoveredIndex = 0;
			Invalidate();
			e.Handled = true;
		case .Return:
			if (mHoveredIndex >= 0 && mHoveredIndex < mOwner.ItemCount)
			{
				mOwner.SelectedIndex = mHoveredIndex;
				mOwner.CloseDropdown();
				let ctx = Context;
				if (ctx != null)
					ctx.MutationQueue.QueueAction(new () => {
						ctx.ActiveInputRoot?.PopupLayer.ClosePopup(this);
					});
			}
			e.Handled = true;
		case .Escape:
			mOwner.CloseDropdown();
			let ctx = Context;
			if (ctx != null)
				ctx.MutationQueue.QueueAction(new () => {
					ctx.ActiveInputRoot?.PopupLayer.ClosePopup(this);
				});
			e.Handled = true;
		default:
		}
	}

	private int32 GetIndexAt(float localY)
	{
		let y = localY - 4;
		if (y < 0) return -1;
		let index = (int32)(y / mItemHeight);
		if (index >= mOwner.ItemCount) return -1;
		return index;
	}
}
