using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A popup menu: themed rows, separators, submenus, and full keyboard navigation.
///
/// Shown through the PopupLayer. A menu taller than the screen CLAMPS to it and becomes
/// scrollable rather than running off the bottom, so every row stays reachable.
class ContextMenu : View, IPopupOwner
{
	private const float ItemHeight = 28.0f;
	private const float SeparatorHeight = 8.0f;
	private const float MinWidth = 150.0f;
	/// The frame's own padding above the first row and below the last.
	private const float FramePad = 4.0f;
	private const float WheelStep = 40.0f;

	private List<MenuItem> mItems = new .() ~ DeleteContainerAndItems!(_);
	private int32 mHoveredIndex = -1;
	/// BORROWED: the open submenu is owned by the MenuItem that carries it.
	private ContextMenu mOpenSubmenu = null;
	/// BORROWED: our parent in the chain, null at the root.
	private ContextMenu mParentMenu = null;
	/// BORROWED, and kept only so a submenu can be closed from the destructor.
	private PopupLayer mSubmenuLayer = null;
	/// The unclamped measure. Greater than Height means the menu scrolls.
	private float mContentHeight = 0.0f;
	private float mScrollY = 0.0f;

	public this()
	{
		IsFocusable = true;
		AddClass("contextmenu");
	}

	public ~this()
	{
		// Taken out of the layer BEFORE the items are deleted, since the layer would otherwise
		// hold a submenu that is about to be freed with its owning item.
		if ((mOpenSubmenu != null) && (mSubmenuLayer != null))
		{
			mSubmenuLayer.ClosePopup(mOpenSubmenu);
			mOpenSubmenu = null;
		}
	}

	public int32 ItemCount => (int32)mItems.Count;

	/// Borrowed.
	public MenuItem GetItem(int index) => mItems[index];

	/// The row drawn highlighted, or -1 for none.
	public int32 HoveredIndex => mHoveredIndex;

	// ---- Building ---------------------------------------------------------------------------

	/// CONSUMES the action delegate.
	public void AddItem(StringView label, delegate void() action, bool enabled = true)
	{
		mItems.Add(new MenuItem(label, action, enabled));
	}

	public void AddSeparator()
	{
		mItems.Add(MenuItem.CreateSeparator());
	}

	/// Adds a row that opens a submenu, and answers the row so the caller can fill it in. The
	/// submenu is OWNED by the row.
	public MenuItem AddSubmenu(StringView label)
	{
		let item = new MenuItem();
		item.Label.Set(label);

		let submenu = new ContextMenu();
		submenu.mParentMenu = this;
		item.Submenu = submenu;

		mItems.Add(item);
		return item;
	}

	// ---- Showing ----------------------------------------------------------------------------

	/// Shows the menu at a screen position, nudged back on screen if it would not fit.
	///
	/// The caller KEEPS its reference; the layer takes one of its own and drops it on close.
	/// A menu shown once and forgotten is released by its caller straight after showing, so
	/// the layer's is the last; a retained menu holds on to its own and can be shown again.
	public void Show(UIContext context, float x, float y, IPopupOwner owner = null)
	{
		// A menu can be RETAINED and shown again, so every show starts clean. Without this a
		// reopened menu came up with the previous session's row still highlighted, until the
		// pointer first moved.
		mHoveredIndex = -1;
		mScrollY = 0;

		// Cleared BEFORE the root is checked, so a show that cannot go ahead still leaves the
		// menu in the state the next one expects.
		let root = context.ActiveInputRoot;
		if (root == null)
			return;

		let logical = root.LogicalSize;
		Measure(BoxConstraints.Loose(logical.X, logical.Y));

		// Flipped back across the anchor rather than merely clamped, so a menu near the right
		// or bottom edge opens away from it instead of sitting under the pointer.
		var px = x;
		var py = y;
		if (px + MeasuredSize.X > logical.X)
			px = Max(0.0f, px - MeasuredSize.X);
		if (py + MeasuredSize.Y > logical.Y)
			py = Max(0.0f, py - MeasuredSize.Y);

		// AddRef because ShowPopup consumes and ClosePopup releases; the caller's reference is
		// its own business.
		AddRef();
		root.GetPopupLayer().ShowPopup(this, owner, px, py, true, false, true);

		context.GetFocusManager().SetFocus(this);
	}

	/// Closes this menu and anything it opened.
	public void Close()
	{
		CloseOpenSubmenu();

		let context = Context;
		if (context == null)
			return;

		// QUEUED: a close commonly runs from inside this menu's own event handling, and
		// destroying the view mid dispatch would pull the ground out from under it.
		context.MutationQueue.QueueAction(new () =>
			{
				if (let root = context.ActiveInputRoot)
					root.GetPopupLayer().ClosePopup(this);
			});
	}

	/// Closes the whole chain, root to leaf. What choosing an item does.
	public void CloseEntireChain()
	{
		var root = this;
		while (root.mParentMenu != null)
			root = root.mParentMenu;

		root.CloseOpenSubmenu();

		let context = root.Context;
		if (context == null)
			return;

		context.MutationQueue.QueueAction(new () =>
			{
				if (let activeRoot = context.ActiveInputRoot)
					activeRoot.GetPopupLayer().ClosePopup(root);
			});
	}

	// ---- IPopupOwner ------------------------------------------------------------------------

	public void OnPopupClosed(View popup)
	{
		if ((mOpenSubmenu != null) && (popup == mOpenSubmenu))
			mOpenSubmenu = null;
	}

	public View OwnerView => this;

	// ---- Input ------------------------------------------------------------------------------

	public override void OnMouseMove(MouseEventArgs e)
	{
		let newIndex = GetItemIndexAt(e.Y);
		if (newIndex == mHoveredIndex)
			return;

		mHoveredIndex = newIndex;
		Invalidate();

		// The old submenu goes whatever the new row is: hovering away from a submenu row
		// closes it, which is what makes a menu chain feel like one thing.
		CloseOpenSubmenu();

		if ((newIndex >= 0) && (newIndex < mItems.Count))
		{
			let item = mItems[newIndex];
			if ((item.Submenu != null) && item.Enabled)
				OpenSubmenuAt(newIndex);
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		let index = GetItemIndexAt(e.Y);
		if ((index < 0) || (index >= mItems.Count))
			return;

		let item = mItems[index];
		// A submenu row is not chosen by clicking: it opens on hover and is entered sideways.
		if (!item.Enabled || item.IsSeparator || (item.Submenu != null))
			return;

		if (item.Action != null)
			item.Action();

		CloseEntireChain();
		e.Handled = true;
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if ((MaxScrollY <= 0) || (e.DeltaY == 0))
			return;

		mScrollY = Clamp(mScrollY - e.DeltaY * WheelStep, 0.0f, MaxScrollY);

		// The rows moved under a stationary pointer, so the hover is recomputed and a submenu
		// whose anchor row scrolled away is dropped.
		let newIndex = GetItemIndexAt(e.Y);
		if (newIndex != mHoveredIndex)
		{
			mHoveredIndex = newIndex;
			CloseOpenSubmenu();
		}

		Invalidate();
		e.Handled = true;
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
			EnterSubmenu();
			e.Handled = true;
		case .Left:
			// Back out to the parent. At the root, Left does nothing but is still swallowed,
			// so it cannot escape the menu into whatever is behind it.
			if (mParentMenu != null)
				Close();
			e.Handled = true;
		case .Return:
			ActivateHovered();
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

	private void EnterSubmenu()
	{
		if ((mHoveredIndex < 0) || (mHoveredIndex >= mItems.Count))
			return;

		let item = mItems[mHoveredIndex];
		if ((item.Submenu == null) || !item.Enabled)
			return;

		OpenSubmenuAt(mHoveredIndex);
		FocusOpenSubmenu();
	}

	private void ActivateHovered()
	{
		if ((mHoveredIndex < 0) || (mHoveredIndex >= mItems.Count))
			return;

		let item = mItems[mHoveredIndex];
		if (!item.Enabled || item.IsSeparator)
			return;

		if (item.Submenu != null)
		{
			OpenSubmenuAt(mHoveredIndex);
			FocusOpenSubmenu();
			return;
		}

		if (item.Action != null)
			item.Action();

		CloseEntireChain();
	}

	private void FocusOpenSubmenu()
	{
		if (mOpenSubmenu == null)
			return;

		if (Context != null)
			Context.GetFocusManager().SetFocus(mOpenSubmenu);

		// Lands on the submenu's first selectable row, so arriving by keyboard never leaves
		// nothing highlighted.
		mOpenSubmenu.MoveFocusNext();
	}

	// ---- Keyboard navigation ----------------------------------------------------------------

	/// Wraps, and steps over separators.
	private void MoveFocusNext()
	{
		let count = (int32)mItems.Count;
		if (count == 0)
			return;

		for (int32 i = 1; i <= count; i++)
		{
			let index = (mHoveredIndex + i) % count;
			if (!mItems[index].IsSeparator)
			{
				mHoveredIndex = index;
				EnsureItemVisible(index);
				Invalidate();
				return;
			}
		}
	}

	private void MoveFocusPrev()
	{
		let count = (int32)mItems.Count;
		if (count == 0)
			return;

		int32 start = (mHoveredIndex < 0) ? 0 : mHoveredIndex;
		for (int32 i = 1; i <= count; i++)
		{
			let index = (start - i + count) % count;
			if (!mItems[index].IsSeparator)
			{
				mHoveredIndex = index;
				EnsureItemVisible(index);
				Invalidate();
				return;
			}
		}
	}

	private float MaxScrollY => Max(0.0f, mContentHeight - Height);

	/// Scrolls the least that brings a row fully inside the frame.
	private void EnsureItemVisible(int32 index)
	{
		let top = GetItemY(index);
		let bottom = top + ItemHeight + FramePad;

		if (top - mScrollY < 0)
			mScrollY = Max(0.0f, top - FramePad);
		else if (bottom - mScrollY > Height)
			mScrollY = Min(MaxScrollY, bottom - Height);
	}

	// ---- Geometry ---------------------------------------------------------------------------

	/// The row at a local Y, or -1 for none. A separator answers -1: it is not selectable.
	private int32 GetItemIndexAt(float localY)
	{
		var y = FramePad - mScrollY;
		for (int32 i = 0; i < mItems.Count; i++)
		{
			let height = mItems[i].IsSeparator ? SeparatorHeight : ItemHeight;
			if ((localY >= y) && (localY < y + height))
				return mItems[i].IsSeparator ? -1 : i;

			y += height;
		}
		return -1;
	}

	/// A row's top, in content coordinates, before scrolling.
	private float GetItemY(int32 index)
	{
		var y = FramePad;
		for (int32 i = 0; i < index; i++)
			y += mItems[i].IsSeparator ? SeparatorHeight : ItemHeight;

		return y;
	}

	private void OpenSubmenuAt(int32 index)
	{
		let item = mItems[index];
		if ((item.Submenu == null) || (Context == null))
			return;

		let root = Context.ActiveInputRoot;
		if (root == null)
			return;

		let submenu = item.Submenu;
		let logical = root.LogicalSize;

		// Measured BEFORE positioning, with its real size. Positioning against a guess let
		// tall submenus open downward and run off the screen; the positioner slides and clamps
		// correctly once it knows the height, and anything still too tall scrolls.
		submenu.mScrollY = 0;
		submenu.Measure(BoxConstraints.Loose(logical.X, logical.Y));

		let anchor = Rectangle(Bounds.X, Bounds.Y + GetItemY(index) - mScrollY, Width, ItemHeight);
		let position = PopupPositioner.Submenu(anchor, submenu.MeasuredSize,
			.(0, 0, logical.X, logical.Y));

		mOpenSubmenu = submenu;
		mSubmenuLayer = root.GetPopupLayer();

		// AddRef because the layer RELEASES on close, and the owning reference belongs to the
		// MenuItem. This is what Raptor spells as ownsView:false.
		submenu.AddRef();
		root.GetPopupLayer().ShowPopup(submenu, this, position.X, position.Y, false, false, false);
	}

	private void CloseOpenSubmenu()
	{
		if (mOpenSubmenu == null)
			return;

		// Depth first: a submenu's own submenu must go before it does.
		mOpenSubmenu.CloseOpenSubmenu();
		if (mSubmenuLayer != null)
			mSubmenuLayer.ClosePopup(mOpenSubmenu);

		mOpenSubmenu = null;
	}

	// ---- Measure and draw -------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var totalHeight = FramePad;
		var maxWidth = MinWidth;

		for (let item in mItems)
		{
			totalHeight += item.IsSeparator ? SeparatorHeight : ItemHeight;

			if (!item.Label.IsEmpty && (Context != null) && (Context.FontService != null))
			{
				let family = scope String();
				ResolveStyleFontFamily(family);
				if (let font = Context.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 14.0f)))
					maxWidth = Max(maxWidth, font.Font.MeasureString(item.Label) + 40);
			}
		}
		totalHeight += FramePad;

		// The UNCLAMPED height is kept: anything past the constraint is what makes the menu
		// scrollable rather than truncated.
		mContentHeight = totalHeight;
		MeasuredSize = .(constraints.ConstrainWidth(maxWidth),
			constraints.ConstrainHeight(totalHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
		{
			background.Draw(ctx, bounds, GetControlState());
		}
		else
		{
			ctx.VG.FillRoundedRect(bounds, 4.0f, Color(45 / 255.0f, 48 / 255.0f, 58 / 255.0f, 1.0f));
			ctx.VG.StrokeRoundedRect(bounds, 4.0f, Color(70 / 255.0f, 75 / 255.0f, 90 / 255.0f, 1.0f), 1.0f);
		}

		let textColor = ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		let disabledColor = Palette.ComputeDisabled(textColor);
		let separatorColor = ResolveStyleColor(.BorderColor, Color(70 / 255.0f, 75 / 255.0f, 90 / 255.0f, 1.0f));
		let hoverColor = ResolveStyleColor(.AccentColor, Color(60 / 255.0f, 120 / 255.0f, 200 / 255.0f, 100 / 255.0f));

		let family = scope String();
		ResolveStyleFontFamily(family);
		let font = (ctx.FontService != null)
			? ctx.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 14.0f))
			: null;

		// Clipped, so scrolled rows do not bleed past the frame.
		ctx.PushClip(bounds);
		var y = FramePad - mScrollY;
		for (int32 i = 0; i < mItems.Count; i++)
		{
			let item = mItems[i];
			if (item.IsSeparator)
			{
				let separatorY = y + SeparatorHeight * 0.5f;
				ctx.VG.DrawLine(.(8, separatorY), .(Width - 8, separatorY), separatorColor, 1.0f);
				y += SeparatorHeight;
				continue;
			}

			if (i == mHoveredIndex)
				DrawHover(ctx, .(4, y, Width - 8, ItemHeight), hoverColor);

			if (!item.Label.IsEmpty && (font != null))
			{
				ctx.VG.DrawText(item.Label, font, .(12, y, Width - 24, ItemHeight), .Left, .Middle,
					item.Enabled ? textColor : disabledColor);
			}

			if (item.Submenu != null)
				DrawSubmenuArrow(ctx, y, textColor);

			y += ItemHeight;
		}
		ctx.PopClip();

		DrawOverflowHints(ctx, textColor);
	}

	private void DrawHover(UIDrawContext ctx, Rectangle rect, Color fallback)
	{
		if (let hoverDrawable = ResolveStyleDrawable(.MenuItemHoverDrawable))
			hoverDrawable.Draw(ctx, rect);
		else
			ctx.VG.FillRect(rect, fallback);
	}

	private void DrawSubmenuArrow(UIDrawContext ctx, float rowY, Color color)
	{
		let arrowX = Width - 16;
		let arrowCY = rowY + ItemHeight * 0.5f;
		let arrowSize = 6.0f;

		if (let arrowIcon = ResolvePartDrawable("submenu-arrow", .Background, GetControlState()))
		{
			arrowIcon.Draw(ctx, .(arrowX, arrowCY - arrowSize * 0.5f, arrowSize, arrowSize));
			return;
		}

		ctx.VG.BeginPath();
		ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.5f);
		ctx.VG.LineTo(arrowX + arrowSize * 0.6f, arrowCY);
		ctx.VG.LineTo(arrowX, arrowCY + arrowSize * 0.5f);
		ctx.VG.ClosePath();
		ctx.VG.Fill(color);
	}

	/// A chevron at whichever edge is clipping, so a scrollable menu reads as having more
	/// rather than looking silently cut off.
	private void DrawOverflowHints(UIDrawContext ctx, Color color)
	{
		if (MaxScrollY <= 0)
			return;

		let cx = Width * 0.5f;
		let arrow = 5.0f;

		if (mScrollY > 0)
		{
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(cx - arrow, 2 + arrow);
			ctx.VG.LineTo(cx, 2);
			ctx.VG.LineTo(cx + arrow, 2 + arrow);
			ctx.VG.ClosePath();
			ctx.VG.Fill(color);
		}

		if (mScrollY < MaxScrollY)
		{
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(cx - arrow, Height - 2 - arrow);
			ctx.VG.LineTo(cx, Height - 2);
			ctx.VG.LineTo(cx + arrow, Height - 2 - arrow);
			ctx.VG.ClosePath();
			ctx.VG.Fill(color);
		}
	}
}
