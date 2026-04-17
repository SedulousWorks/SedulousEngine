namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Popup context menu with themed items. Supports submenus via
/// MenuItem.Submenu. Shown via PopupLayer.
public class ContextMenu : View, IPopupOwner
{
	private List<MenuItem> mItems = new .() ~ {
		for (let item in _) delete item;
		delete _;
	};

	private int32 mHoveredIndex = -1;
	private ContextMenu mOpenSubmenu;
	private ContextMenu mParentMenu;
	private float mItemHeight = 28;
	private float mSeparatorHeight = 8;
	private float mMinWidth = 150;

	public void AddItem(StringView label, delegate void() action, bool enabled = true)
	{
		mItems.Add(new MenuItem(label, action, enabled));
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

	/// Show this menu at the given screen position, clamping to screen bounds.
	public void Show(UIContext ctx, float x, float y)
	{
		// Measure first to know the popup size, then clamp to screen.
		Measure(.AtMost(ctx.Root.ViewportSize.X), .AtMost(ctx.Root.ViewportSize.Y));
		let screen = RectangleF(0, 0, ctx.Root.ViewportSize.X, ctx.Root.ViewportSize.Y);

		var px = x;
		var py = y;

		// Flip left if clipping right edge.
		if (px + MeasuredSize.X > screen.Width)
			px = Math.Max(0, px - MeasuredSize.X);
		// Flip up if clipping bottom edge.
		if (py + MeasuredSize.Y > screen.Height)
			py = Math.Max(0, py - MeasuredSize.Y);

		ctx.PopupLayer.ShowPopup(this, null, px, py, closeOnClickOutside: true, isModal: false, ownsView: false);
	}

	/// Close this menu and all submenus.
	public void Close()
	{
		CloseOpenSubmenu();
		let ctx = Context;
		if (ctx != null)
			ctx.MutationQueue.QueueAction(new () => {
				ctx.PopupLayer?.ClosePopup(this);
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
				ctx.PopupLayer?.ClosePopup(root);
			});
	}

	/// When detached from context (popup closed externally e.g. by click-outside),
	/// close any open submenus.
	public override void OnDetachedFromContext()
	{
		CloseOpenSubmenu();
		base.OnDetachedFromContext();
	}

	// === IPopupOwner ===

	public void OnPopupClosed(View popup)
	{
		if (mOpenSubmenu != null && popup === mOpenSubmenu)
			mOpenSubmenu = null;
	}

	// === Measurement ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float totalH = 4; // top padding
		float maxW = mMinWidth;

		for (let item in mItems)
		{
			if (item.IsSeparator)
				totalH += mSeparatorHeight;
			else
				totalH += mItemHeight;

			// Measure text width if possible.
			if (item.Label != null && Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(14);
				if (font != null)
				{
					let textW = font.Font.MeasureString(item.Label) + 40; // padding + submenu arrow
					maxW = Math.Max(maxW, textW);
				}
			}
		}
		totalH += 4; // bottom padding

		MeasuredSize = .(wSpec.Resolve(maxW), hSpec.Resolve(totalH));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;
		let h = Height;

		// Background
		let bgColor = ctx.Theme?.GetColor("ContextMenu.Background", .(45, 48, 58, 240)) ?? .(45, 48, 58, 240);
		let borderColor = ctx.Theme?.GetColor("ContextMenu.Border", .(70, 75, 90, 255)) ?? .(70, 75, 90, 255);
		ctx.VG.FillRoundedRect(.(0, 0, w, h), 4, bgColor);
		ctx.VG.StrokeRoundedRect(.(0, 0, w, h), 4, borderColor, 1);

		let hoverColor = ctx.Theme?.GetColor("ContextMenu.Hover", .(60, 120, 200, 100)) ?? .(60, 120, 200, 100);
		let textColor = ctx.Theme?.GetColor("ContextMenu.Text") ?? ctx.Theme?.GetColor("Label.Foreground") ?? .(220, 225, 235, 255);
		let disabledColor = Palette.ComputeDisabled(textColor);
		let separatorColor = ctx.Theme?.GetColor("ContextMenu.Separator", borderColor) ?? borderColor;

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
				ctx.VG.FillRoundedRect(.(4, y, w - 8, mItemHeight), 3, hoverColor);

			// Label
			if (item.Label != null && ctx.FontService != null)
			{
				let font = ctx.FontService.GetFont(14);
				if (font != null)
				{
					let color = item.Enabled ? textColor : disabledColor;
					ctx.VG.DrawText(item.Label, font, .(12, y, w - 24, mItemHeight), .Left, .Middle, color);
				}
			}

			// Submenu arrow — right-pointing VG triangle.
			if (item.Submenu != null)
			{
				let arrowX = w - 16;
				let arrowCY = y + mItemHeight * 0.5f;
				let arrowSize = 6.0f;
				ctx.VG.BeginPath();
				ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.5f);
				ctx.VG.LineTo(arrowX + arrowSize * 0.6f, arrowCY);
				ctx.VG.LineTo(arrowX, arrowCY + arrowSize * 0.5f);
				ctx.VG.ClosePath();
				ctx.VG.Fill(textColor);
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

			// Close old submenu.
			CloseOpenSubmenu();

			// Open new submenu on hover.
			if (newIndex >= 0 && newIndex < mItems.Count)
			{
				let item = mItems[newIndex];
				if (item.Submenu != null && item.Enabled && Context != null)
				{
					let (sx, sy) = PopupPositioner.PositionSubmenu(
						.(Bounds.X, Bounds.Y + GetItemY(newIndex), Width, mItemHeight),
						.(item.Submenu.mMinWidth, 200),
						.(0, 0, Context.Root.ViewportSize.X, Context.Root.ViewportSize.Y));
					mOpenSubmenu = item.Submenu;
					Context.PopupLayer.ShowPopup(item.Submenu, this, sx, sy,
						closeOnClickOutside: false, isModal: false, ownsView: false);
				}
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

	private void CloseOpenSubmenu()
	{
		if (mOpenSubmenu != null && Context != null)
		{
			mOpenSubmenu.CloseOpenSubmenu(); // recursive
			Context.PopupLayer.ClosePopup(mOpenSubmenu);
			mOpenSubmenu = null;
		}
	}
}
