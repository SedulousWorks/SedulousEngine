using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The application menu bar: titles across the top, each opening a dropdown.
///
/// Click a title to open it; while one is open, MOVING over another title switches to it with
/// no second click, which is how a menu bar is expected to behave. Escape or a click outside
/// closes.
///
/// The bar OWNS its menus for its whole life rather than building one per open, so a caller can
/// keep the pointer AddMenu returned and add items to it at any time. The popup layer takes its
/// own reference when a menu is shown.
class MenuBar : ViewGroup, IPopupOwner
{
	private struct MenuEntry
	{
		/// OWNED.
		public String Title = null;
		/// OWNED.
		public ContextMenu Menu = null;

		public this() {}
	}

	private List<MenuEntry> mMenus = new .() ~ ReleaseEntries!(_);
	/// Rebuilt every draw, because the widths depend on the font the sheet resolves.
	private List<Rectangle> mItemRects = new .() ~ delete _;

	private int32 mActiveIndex = -1;
	private int32 mHoveredIndex = -1;
	/// True while a dropdown is open, which is what turns hovering into switching.
	private bool mMenuMode = false;

	private float mItemHeight = 28.0f;
	private float mItemPadding = 12.0f;
	private float mFontSize = 13.0f;

	public this()
	{
		IsFocusable = true;
	}

	private static mixin ReleaseEntries(var entries)
	{
		for (let entry in entries)
		{
			delete entry.Title;
			entry.Menu.ReleaseRef();
		}
		delete entries;
	}

	public int MenuCount => mMenus.Count;

	/// Adds a menu under a title. The menu comes back BORROWED, to add items to; the bar owns
	/// it and keeps it for its whole life.
	public ContextMenu AddMenu(StringView title)
	{
		MenuEntry entry = .();
		entry.Title = new String(title);
		entry.Menu = new ContextMenu();
		mMenus.Add(entry);
		Invalidate();
		return entry.Menu;
	}

	// ---- IPopupOwner ----------------------------------------------------------------------------

	public void OnPopupClosed(View popup)
	{
		mActiveIndex = -1;
		mMenuMode = false;
	}

	public View OwnerView => this;

	// ---- Drawing --------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, Color.Rgb(35, 37, 46));

		let borderColor = ResolveStyleColor(.BorderColor, Color.Rgb(65, 70, 85));
		ctx.VG.FillRect(Rectangle(0, Height - 1.0f, Width, 1.0f), borderColor);

		RebuildItemRects(ctx);

		let hoverColor = ResolveStyleColor(.AccentColor, Color.Rgb(60, 65, 80));
		let textColor = ResolveStyleColor(.TextColor, Color.Rgb(220, 225, 235));

		if (ctx.FontService == null)
			return;

		let font = ctx.FontService.GetFont(ResolveStyleFloat(.FontSize, mFontSize));
		if (font == null)
			return;

		let count = Math.Min(mMenus.Count, mItemRects.Count);
		for (int i < count)
		{
			let rect = mItemRects[i];

			// The OPEN menu keeps its highlight whether or not the pointer is still on it, so
			// the bar shows which dropdown is down.
			if ((i == mActiveIndex) || (i == mHoveredIndex))
			{
				let cornerRadius = ResolveStyleFloat(.CornerRadius, 0.0f);
				if (cornerRadius > 0.0f)
					ctx.VG.FillRoundedRect(rect, cornerRadius, hoverColor);
				else
					ctx.VG.FillRect(rect, hoverColor);
			}

			ctx.VG.DrawText(mMenus[i].Title, font, rect, .Center, .Middle, textColor);
		}
	}

	// ---- Input ----------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		let clicked = GetItemIndexAt(e.X, e.Y);
		if (clicked < 0)
			return;

		// Clicking the title of the open menu closes it, so the same gesture toggles.
		if ((mActiveIndex == clicked) && mMenuMode)
			CloseActiveMenu();
		else
			OpenMenu(clicked);

		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let index = GetItemIndexAt(e.X, e.Y);
		mHoveredIndex = index;

		if (mMenuMode && (index >= 0) && (index != mActiveIndex))
			OpenMenu(index);
	}

	public override void OnMouseLeave()
	{
		mHoveredIndex = -1;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!mMenuMode)
			return;

		switch (e.Key)
		{
		case .Left:
			if (mActiveIndex > 0)
				OpenMenu(mActiveIndex - 1);
			e.Handled = true;

		case .Right:
			if (mActiveIndex < (int32)mMenus.Count - 1)
				OpenMenu(mActiveIndex + 1);
			e.Handled = true;

		case .Escape:
			CloseActiveMenu();
			e.Handled = true;

		default:
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(0.0f), constraints.ConstrainHeight(mItemHeight));
	}

	// ---- Internals ------------------------------------------------------------------------------

	private void RebuildItemRects(UIDrawContext ctx)
	{
		mItemRects.Clear();

		if (ctx.FontService == null)
			return;

		let font = ctx.FontService.GetFont(ResolveStyleFloat(.FontSize, mFontSize));
		if (font == null)
			return;

		var x = 0.0f;
		for (let entry in mMenus)
		{
			let itemWidth = font.Font.MeasureString(entry.Title) + (mItemPadding * 2.0f);
			mItemRects.Add(.(x, 0, itemWidth, mItemHeight));
			x += itemWidth;
		}
	}

	private void OpenMenu(int32 index)
	{
		if ((index < 0) || (index >= mMenus.Count))
			return;

		if ((mActiveIndex >= 0) && (mActiveIndex != index))
			CloseActiveMenu();

		mActiveIndex = index;
		mMenuMode = true;

		if (Context == null)
			return;

		let root = Root();
		if (root == null)
			return;

		let rect = (index < mItemRects.Count) ? mItemRects[index] : Rectangle();

		// Two pixels below the bar, so the dropdown clears the bottom border rather than
		// sitting on it and reading as one shape with the bar.
		let screenPos = LocalToScreen(.(rect.X, mItemHeight + 2.0f));

		let menu = mMenus[index].Menu;
		menu.Measure(BoxConstraints.Loose(root.ViewportSize.X, root.ViewportSize.Y));

		// The popup layer CONSUMES a reference whatever it is told about ownership, and the bar
		// keeps its own for the menu's whole life, so it hands over an extra one.
		menu.AddRef();
		root.GetPopupLayer().ShowPopup(menu, this, screenPos.X, screenPos.Y, true, false, false);
	}

	private void CloseActiveMenu()
	{
		if ((mActiveIndex >= 0) && (mActiveIndex < mMenus.Count) && (Context != null))
		{
			let menu = mMenus[mActiveIndex].Menu;
			if (menu.Context != null)
			{
				if (let root = Root())
					root.GetPopupLayer().ClosePopup(menu);
			}
		}

		mActiveIndex = -1;
		mMenuMode = false;
	}

	/// HALF OPEN on the right and bottom edges, deliberately, rather than Rectangle.Contains,
	/// which includes both. Menu titles are laid edge to edge, so an inclusive test would give
	/// the shared column of pixels to the item on the LEFT, and the first match wins here.
	private int32 GetItemIndexAt(float x, float y)
	{
		for (int i < mItemRects.Count)
		{
			let rect = mItemRects[i];
			if ((x >= rect.X) && (x < rect.X + rect.Width) && (y >= rect.Y)
				&& (y < rect.Y + rect.Height))
				return (int32)i;
		}
		return -1;
	}
}
