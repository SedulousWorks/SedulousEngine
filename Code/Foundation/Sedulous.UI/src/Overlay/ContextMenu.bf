namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Popup context menu with themed items. Supports submenus, separators,
/// and full keyboard navigation. Shown via PopupLayer.
public class ContextMenu : View, IPopupOwner
{
	private List<MenuItem> mItems = new .() ~ {
		for (let item in _) delete item;
		delete _;
	};

	/// Heap objects that should be deleted when the menu is destroyed.
	private List<Object> mOwnedObjects ~ {
		if (_ != null) { for (let obj in _) delete obj; delete _; }
	};

	private int32 mHoveredIndex = -1;
	private ContextMenu mOpenSubmenu;
	private ContextMenu mParentMenu;
	private PopupLayer mSubmenuLayer; // non-owning ref for cleanup
	private float mItemHeight = 28;
	private float mSeparatorHeight = 8;
	private float mMinWidth = 150;

	public int ItemCount => mItems.Count;

	public this()
	{
		IsFocusable = true;
		AddClass("contextmenu");
	}

	public void AddItem(StringView label, delegate void() action, bool enabled = true)
	{
		mItems.Add(new MenuItem(label, action, enabled));
	}

	public void AddOwnedObject(Object obj)
	{
		if (mOwnedObjects == null)
			mOwnedObjects = new .();
		mOwnedObjects.Add(obj);
	}

	public void AddSeparator()
	{
		mItems.Add(MenuItem.CreateSeparator());
	}

	public MenuItem AddSubmenu(StringView label)
	{
		let item = new MenuItem();
		item.Label = new String(label);
		item.Submenu = new ContextMenu();
		item.Submenu.mParentMenu = this;
		mItems.Add(item);
		return item;
	}

	/// Show this menu at the given screen position.
	public void Show(UIContext ctx, float x, float y, IPopupOwner owner = null)
	{
		let root = ctx.ActiveInputRoot;
		if (root == null) return;

		let logical = root.LogicalSize;
		Measure(BoxConstraints.Loose(logical.X, logical.Y));
		let screen = RectangleF(0, 0, logical.X, logical.Y);

		var px = x;
		var py = y;

		if (px + MeasuredSize.X > screen.Width)
			px = Math.Max(0, px - MeasuredSize.X);
		if (py + MeasuredSize.Y > screen.Height)
			py = Math.Max(0, py - MeasuredSize.Y);

		root.PopupLayer.ShowPopup(this, owner, px, py,
			closeOnClickOutside: true, isModal: false, ownsView: true);

		// Request focus for keyboard navigation.
		ctx.FocusManager.SetFocus(this);
	}

	/// Close this menu and all submenus.
	public void Close()
	{
		CloseOpenSubmenu();
		let ctx = Context;
		if (ctx != null)
			ctx.MutationQueue.QueueAction(new () => {
				ctx.ActiveInputRoot?.PopupLayer.ClosePopup(this);
			});
	}

	/// Close the entire menu chain from root to leaf.
	public void CloseEntireChain()
	{
		var root = this;
		while (root.mParentMenu != null)
			root = root.mParentMenu;
		root.CloseOpenSubmenu();
		let ctx = root.Context;
		if (ctx != null)
			ctx.MutationQueue.QueueAction(new () => {
				ctx.ActiveInputRoot?.PopupLayer.ClosePopup(root);
			});
	}

	// === IPopupOwner ===

	public void OnPopupClosed(View popup)
	{
		if (mOpenSubmenu != null && popup === mOpenSubmenu)
			mOpenSubmenu = null;
	}

	// === Measurement ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		float totalH = 4; // top padding
		float maxW = mMinWidth;

		for (let item in mItems)
		{
			if (item.IsSeparator)
				totalH += mSeparatorHeight;
			else
				totalH += mItemHeight;

			if (item.Label != null && Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(14);
				if (font != null)
				{
					let textW = font.Font.MeasureString(item.Label) + 40;
					maxW = Math.Max(maxW, textW);
				}
			}
		}
		totalH += 4; // bottom padding

		MeasuredSize = .(constraints.ConstrainWidth(maxW), constraints.ConstrainHeight(totalH));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;
		let h = Height;
		let menuBounds = RectangleF(0, 0, w, h);

		// Background from theme.
		let bg = ResolveStyleDrawable(.Background);
		if (bg != null)
			bg.Draw(ctx, menuBounds, GetControlState());
		else
		{
			ctx.VG.FillRoundedRect(menuBounds, 4, .(45, 48, 58, 255));
			ctx.VG.StrokeRoundedRect(menuBounds, 4, .(70, 75, 90, 255), 1);
		}

		let textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
		let disabledColor = Palette.ComputeDisabled(textColor);
		let separatorColor = ResolveStyleColor(.BorderColor, .(70, 75, 90, 255));
		let hoverColor = ResolveStyleColor(.AccentColor, .(60, 120, 200, 100));

		let font = ctx.FontService?.GetFont(14);

		float y = 4;
		for (int32 i = 0; i < mItems.Count; i++)
		{
			let item = mItems[i];
			if (item.IsSeparator)
			{
				let sepY = y + mSeparatorHeight * 0.5f;
				ctx.VG.DrawLine(.(8, sepY), .(w - 8, sepY), separatorColor, 1);
				y += mSeparatorHeight;
				continue;
			}

			// Hover highlight
			if (i == mHoveredIndex)
			{
				let hoverRect = RectangleF(4, y, w - 8, mItemHeight);
				let hoverDrawable = ResolveStyleDrawable(.MenuItemHoverDrawable);
				if (hoverDrawable != null)
					hoverDrawable.Draw(ctx, hoverRect);
				else
					ctx.VG.FillRect(hoverRect, hoverColor);
			}

			// Label
			if (item.Label != null && font != null)
			{
				let color = item.Enabled ? textColor : disabledColor;
				ctx.VG.DrawText(item.Label, font, .(12, y, w - 24, mItemHeight), .Left, .Middle, color);
			}

			// Submenu arrow
			if (item.Submenu != null)
			{
				let arrowIcon = ResolvePartDrawable("submenu-arrow", .Background, GetControlState());
				let arrowX = w - 16;
				let arrowCY = y + mItemHeight * 0.5f;
				let arrowSize = 6.0f;

				if (arrowIcon != null)
				{
					arrowIcon.Draw(ctx, .(arrowX, arrowCY - arrowSize * 0.5f, arrowSize, arrowSize));
				}
				else
				{
					ctx.VG.BeginPath();
					ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.5f);
					ctx.VG.LineTo(arrowX + arrowSize * 0.6f, arrowCY);
					ctx.VG.LineTo(arrowX, arrowCY + arrowSize * 0.5f);
					ctx.VG.ClosePath();
					ctx.VG.Fill(textColor);
				}
			}

			y += mItemHeight;
		}
	}

	// === Input ===

	public override void OnMouseMove(MouseEventArgs e)
	{
		let newIndex = GetItemIndexAt(e.Y);
		if (newIndex != mHoveredIndex)
		{
			mHoveredIndex = newIndex;
			Invalidate();

			CloseOpenSubmenu();

			if (newIndex >= 0 && newIndex < mItems.Count)
			{
				let item = mItems[newIndex];
				if (item.Submenu != null && item.Enabled)
					OpenSubmenuAt(newIndex);
			}
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		let index = GetItemIndexAt(e.Y);
		if (index >= 0 && index < mItems.Count)
		{
			let item = mItems[index];
			if (item.Enabled && !item.IsSeparator && item.Submenu == null)
			{
				item.Action?.Invoke();
				CloseEntireChain();
				e.Handled = true;
			}
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		switch (e.Key)
		{
		case .Up:
			MoveFocusPrev();
			e.Handled = true;
		case .Down:
			MoveFocusNext();
			e.Handled = true;
		case .Right:
			// Open submenu
			if (mHoveredIndex >= 0 && mHoveredIndex < mItems.Count)
			{
				let item = mItems[mHoveredIndex];
				if (item.Submenu != null && item.Enabled)
				{
					OpenSubmenuAt(mHoveredIndex);
					// Focus the submenu
					if (mOpenSubmenu != null)
					{
						Context?.FocusManager.SetFocus(mOpenSubmenu);
						mOpenSubmenu.MoveFocusNext();
					}
				}
			}
			e.Handled = true;
		case .Left:
			// Close to parent
			if (mParentMenu != null)
				Close();
			e.Handled = true;
		case .Return:
			if (mHoveredIndex >= 0 && mHoveredIndex < mItems.Count)
			{
				let item = mItems[mHoveredIndex];
				if (item.Enabled && !item.IsSeparator)
				{
					if (item.Submenu != null)
					{
						OpenSubmenuAt(mHoveredIndex);
						if (mOpenSubmenu != null)
						{
							Context?.FocusManager.SetFocus(mOpenSubmenu);
							mOpenSubmenu.MoveFocusNext();
						}
					}
					else
					{
						item.Action?.Invoke();
						CloseEntireChain();
					}
				}
			}
			e.Handled = true;
		case .Escape:
			if (mParentMenu != null)
				Close();
			else
				CloseEntireChain();
			e.Handled = true;
		default:
		}
	}

	// === Keyboard navigation helpers ===

	private void MoveFocusNext()
	{
		int32 start = mHoveredIndex;
		for (int32 i = 1; i <= mItems.Count; i++)
		{
			int32 idx = (start + i) % (int32)mItems.Count;
			if (!mItems[idx].IsSeparator)
			{
				mHoveredIndex = idx;
				Invalidate();
				return;
			}
		}
	}

	private void MoveFocusPrev()
	{
		int32 start = (mHoveredIndex < 0) ? 0 : mHoveredIndex;
		for (int32 i = 1; i <= mItems.Count; i++)
		{
			int32 idx = (start - i + (int32)mItems.Count) % (int32)mItems.Count;
			if (!mItems[idx].IsSeparator)
			{
				mHoveredIndex = idx;
				Invalidate();
				return;
			}
		}
	}

	// === Internal ===

	private int32 GetItemIndexAt(float localY)
	{
		float y = 4;
		for (int32 i = 0; i < mItems.Count; i++)
		{
			let h = mItems[i].IsSeparator ? mSeparatorHeight : mItemHeight;
			if (localY >= y && localY < y + h)
				return mItems[i].IsSeparator ? -1 : i;
			y += h;
		}
		return -1;
	}

	private float GetItemY(int32 index)
	{
		float y = 4;
		for (int32 i = 0; i < index; i++)
			y += mItems[i].IsSeparator ? mSeparatorHeight : mItemHeight;
		return y;
	}

	private void OpenSubmenuAt(int32 index)
	{
		let item = mItems[index];
		if (item.Submenu == null || Context == null) return;

		let root = Context.ActiveInputRoot;
		if (root == null) return;

		let logical = root.LogicalSize;
		let (sx, sy) = PopupPositioner.Submenu(
			.(Bounds.X, Bounds.Y + GetItemY(index), Width, mItemHeight),
			.(item.Submenu.mMinWidth, 200),
			.(0, 0, logical.X, logical.Y));

		mOpenSubmenu = item.Submenu;
		mSubmenuLayer = root.PopupLayer;
		root.PopupLayer.ShowPopup(item.Submenu, this, sx, sy,
			closeOnClickOutside: false, isModal: false, ownsView: false);
	}

	private void CloseOpenSubmenu()
	{
		if (mOpenSubmenu != null)
		{
			mOpenSubmenu.CloseOpenSubmenu(); // recursive
			if (mSubmenuLayer != null)
				mSubmenuLayer.ClosePopup(mOpenSubmenu);
			mOpenSubmenu = null;
		}
	}

	public ~this()
	{
		// Close any open submenu from PopupLayer before items are deleted.
		if (mOpenSubmenu != null && mSubmenuLayer != null)
		{
			mSubmenuLayer.ClosePopup(mOpenSubmenu);
			mOpenSubmenu = null;
		}
	}
}
