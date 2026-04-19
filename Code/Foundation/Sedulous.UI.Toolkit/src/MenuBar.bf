namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Horizontal menu bar with dropdown ContextMenus.
/// Click a menu title to open its dropdown. While open, hover other
/// titles to switch menus. Escape or click outside closes.
public class MenuBar : ViewGroup, IPopupOwner
{
	private struct MenuEntry
	{
		public String Title;
		public ContextMenu Menu;
	}

	private List<MenuEntry> mMenus = new .() ~ {
		for (var entry in _)
		{
			delete entry.Title;
			delete entry.Menu;
		}
		delete _;
	};

	private int mActiveIndex = -1;
	private int mHoveredIndex = -1;
	private bool mMenuMode;       // true when a dropdown is open
	private float mItemHeight = 28;
	private float mItemPadding = 12;
	private float mFontSize = 13;

	// Cached item rects (rebuilt each draw).
	private List<RectangleF> mItemRects = new .() ~ delete _;

	public int MenuCount => mMenus.Count;

	public this()
	{
		IsFocusable = true;
	}

	/// Add a menu with the given title. Returns the ContextMenu to add items to.
	public ContextMenu AddMenu(StringView title)
	{
		MenuEntry entry;
		entry.Title = new String(title);
		entry.Menu = new ContextMenu();
		mMenus.Add(entry);
		InvalidateLayout();
		return entry.Menu;
	}

	// === IPopupOwner ===

	public void OnPopupClosed(View popup)
	{
		mActiveIndex = -1;
		mMenuMode = false;
	}

	// === Measurement ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(mItemHeight));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;
		let h = Height;

		// Background.
		if (!ctx.TryDrawDrawable("MenuBar.Background", .(0, 0, w, h), .Normal))
		{
			let bgColor = ctx.Theme?.GetColor("MenuBar.Background", .(35, 37, 46, 255)) ?? .(35, 37, 46, 255);
			ctx.VG.FillRect(.(0, 0, w, h), bgColor);
		}

		// Bottom border.
		let borderColor = ctx.Theme?.GetColor("MenuBar.Border", .(65, 70, 85, 255)) ?? .(65, 70, 85, 255);
		ctx.VG.FillRect(.(0, h - 1, w, 1), borderColor);

		// Rebuild item rects.
		RebuildItemRects(ctx);

		let hoverColor = ctx.Theme?.GetColor("MenuBar.ItemHover", .(60, 65, 80, 255)) ?? .(60, 65, 80, 255);
		let textColor = ctx.Theme?.GetColor("MenuBar.Text") ?? ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);

		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(mFontSize);
			if (font != null)
			{
				for (int i = 0; i < mMenus.Count && i < mItemRects.Count; i++)
				{
					let rect = mItemRects[i];

					// Hover/active highlight.
					if (i == mActiveIndex || i == mHoveredIndex)
					{
						if (!ctx.TryDrawDrawable("MenuBar.ItemBackground", rect, .Hover))
							ctx.VG.FillRect(rect, hoverColor);
					}

					// Text.
					ctx.VG.DrawText(mMenus[i].Title, font, rect, .Center, .Middle, textColor);
				}
			}
		}
	}

	private void RebuildItemRects(UIDrawContext ctx)
	{
		mItemRects.Clear();
		float x = 0;

		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(mFontSize);
			if (font != null)
			{
				for (let entry in mMenus)
				{
					let textW = font.Font.MeasureString(entry.Title);
					let itemW = textW + mItemPadding * 2;
					mItemRects.Add(.(x, 0, itemW, mItemHeight));
					x += itemW;
				}
			}
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		let clickedIdx = GetItemIndexAt(e.X, e.Y);
		if (clickedIdx < 0) return;

		if (mActiveIndex == clickedIdx && mMenuMode)
		{
			// Clicking the active menu title closes it.
			CloseActiveMenu();
		}
		else
		{
			OpenMenu(clickedIdx);
		}
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let idx = GetItemIndexAt(e.X, e.Y);
		mHoveredIndex = idx;

		// Menu mode: hover-switch to different menu.
		if (mMenuMode && idx >= 0 && idx != mActiveIndex)
			OpenMenu(idx);
	}

	public override void OnMouseLeave()
	{
		mHoveredIndex = -1;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!mMenuMode) return;

		switch (e.Key)
		{
		case .Left:
			if (mActiveIndex > 0)
				OpenMenu(mActiveIndex - 1);
			e.Handled = true;
		case .Right:
			if (mActiveIndex < mMenus.Count - 1)
				OpenMenu(mActiveIndex + 1);
			e.Handled = true;
		case .Escape:
			CloseActiveMenu();
			e.Handled = true;
		default:
		}
	}

	// === Internal ===

	private void OpenMenu(int index)
	{
		if (index < 0 || index >= mMenus.Count) return;

		// Close current menu if different.
		if (mActiveIndex >= 0 && mActiveIndex != index)
			CloseActiveMenu();

		mActiveIndex = index;
		mMenuMode = true;

		if (Context == null) return;

		let entry = mMenus[index];
		let rect = (index < mItemRects.Count) ? mItemRects[index] : RectangleF(0, 0, 0, 0);

		// Compute screen position below this menu item.
		float screenX = rect.X + Bounds.X;
		float screenY = Bounds.Y + mItemHeight;
		var v = Parent;
		while (v != null)
		{
			screenX += v.Bounds.X;
			screenY += v.Bounds.Y;
			v = v.Parent;
		}

		// Show via PopupLayer directly — MenuBar owns the ContextMenu (not PopupLayer).
		entry.Menu.Measure(.AtMost(Root.ViewportSize.X), .AtMost(Root.ViewportSize.Y));
		Context.PopupLayer.ShowPopup(entry.Menu, this, screenX, screenY,
			closeOnClickOutside: true, isModal: false, ownsView: false);
	}

	private void CloseActiveMenu()
	{
		if (mActiveIndex >= 0 && mActiveIndex < mMenus.Count && Context != null)
		{
			let menu = mMenus[mActiveIndex].Menu;
			// The menu is shown via PopupLayer — closing it will trigger OnPopupClosed.
			if (menu.IsAttached)
				Context.PopupLayer.ClosePopup(menu);
		}
		mActiveIndex = -1;
		mMenuMode = false;
	}

	private int GetItemIndexAt(float x, float y)
	{
		for (int i = 0; i < mItemRects.Count; i++)
		{
			let r = mItemRects[i];
			if (x >= r.X && x < r.X + r.Width && y >= r.Y && y < r.Y + r.Height)
				return i;
		}
		return -1;
	}
}
