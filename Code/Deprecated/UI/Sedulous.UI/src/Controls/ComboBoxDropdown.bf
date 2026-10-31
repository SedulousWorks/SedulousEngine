using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// The list a ComboBox opens.
///
/// Not a ContextMenu: it matches the box's width and marks which item is currently chosen,
/// neither of which a menu does. It reuses the menu's STYLING though, by carrying the same
/// class, so a theme dresses both with one rule.
class ComboBoxDropdown : View
{
	private const float ItemHeight = 28.0f;
	/// The frame's own padding above the first row and below the last.
	private const float FramePad = 4.0f;
	/// A dropdown never gets narrower than this, however short its items are.
	private const float MinWidth = 100.0f;

	/// BORROWED: the box owns nothing here, and outlives this by construction.
	private ComboBox mOwner;
	private int32 mHoveredIndex = -1;

	public this(ComboBox owner)
	{
		mOwner = owner;
		IsFocusable = true;
		AddClass("contextmenu");
	}

	public int32 HoveredIndex => mHoveredIndex;

	// ---- Input ------------------------------------------------------------------------------

	public override void OnMouseMove(MouseEventArgs e)
	{
		let newIndex = GetIndexAt(e.Y);
		if (newIndex == mHoveredIndex)
			return;

		mHoveredIndex = newIndex;
		Invalidate();
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		let index = GetIndexAt(e.Y);
		if ((index < 0) || (index >= mOwner.ItemCount))
			return;

		Choose(index);
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		switch (e.Key)
		{
		case .Up:
			// Nothing highlighted yet: arriving from below lands on the LAST item.
			if (mHoveredIndex > 0)
				mHoveredIndex--;
			else if ((mHoveredIndex < 0) && (mOwner.ItemCount > 0))
				mHoveredIndex = mOwner.ItemCount - 1;

			Invalidate();
			e.Handled = true;
		case .Down:
			if (mHoveredIndex < mOwner.ItemCount - 1)
				mHoveredIndex++;
			else if ((mHoveredIndex < 0) && (mOwner.ItemCount > 0))
				mHoveredIndex = 0;

			Invalidate();
			e.Handled = true;
		case .Return:
			if ((mHoveredIndex >= 0) && (mHoveredIndex < mOwner.ItemCount))
				Choose(mHoveredIndex);

			e.Handled = true;
		case .Escape:
			// Closes WITHOUT choosing, so the box keeps whatever it had.
			mOwner.CloseDropdown();
			QueueSelfClose();
			e.Handled = true;
		default:
		}
	}

	private void Choose(int32 index)
	{
		mOwner.SetSelectedIndex(index);
		mOwner.CloseDropdown();
		QueueSelfClose();
	}

	/// QUEUED, so the popup is not torn down in the middle of the input dispatch that is still
	/// running through it.
	private void QueueSelfClose()
	{
		if (Context == null)
			return;

		let context = Context;
		context.MutationQueue.QueueAction(new () =>
			{
				if (let root = context.ActiveInputRoot)
					root.GetPopupLayer().ClosePopup(this);
			});
	}

	// ---- Measure and draw -------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let totalHeight = FramePad * 2 + ItemHeight * mOwner.ItemCount;
		// As wide as the box it hangs from, so the two read as one control.
		let width = Max(mOwner.Width, MinWidth);

		MeasuredSize = .(constraints.ConstrainWidth(width), constraints.ConstrainHeight(totalHeight));
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
			ctx.VG.FillRect(bounds, Color(45 / 255.0f, 48 / 255.0f, 58 / 255.0f, 1.0f));
			ctx.VG.StrokeRect(bounds, Color(70 / 255.0f, 75 / 255.0f, 90 / 255.0f, 1.0f), 1.0f);
		}

		let textColor = ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));

		// The highlights FILL an item's rect, so they take a translucent tint of the accent
		// rather than the accent itself: an opaque fill would paint a solid block over the text.
		let accent = ResolveStyleColor(.AccentColor, Color(60 / 255.0f, 120 / 255.0f, 200 / 255.0f, 1.0f));
		let hoverColor = Color(accent.R, accent.G, accent.B, 100 / 255.0f);
		let selectedColor = Color(accent.R, accent.G, accent.B, 50 / 255.0f);
		let hoverDrawable = ResolveStyleDrawable(.MenuItemHoverDrawable);

		let family = scope String();
		ResolveStyleFontFamily(family);
		let fontSize = mOwner.ResolveStyleFloat(.FontSize, 14.0f);
		let font = (ctx.FontService != null) ? ctx.FontService.GetFont(family, fontSize) : null;

		var y = FramePad;
		for (int32 i = 0; i < mOwner.ItemCount; i++)
		{
			let itemRect = Rectangle(FramePad, y, Width - FramePad * 2, ItemHeight);

			// The CHOSEN item is tinted faintly and the HOVERED one strongly, so both can show
			// at once and be told apart.
			if (i == mOwner.SelectedIndex)
				DrawSelectedTint(ctx, itemRect, selectedColor, hoverDrawable);

			if (i == mHoveredIndex)
			{
				if (hoverDrawable != null)
					hoverDrawable.Draw(ctx, itemRect);
				else
					ctx.VG.FillRect(itemRect, hoverColor);
			}

			if (font != null)
			{
				ctx.VG.DrawText(mOwner.ItemAt(i), font, .(12, y, Width - 24, ItemHeight), .Left,
					.Middle, textColor);
			}

			y += ItemHeight;
		}
	}

	/// The selected tint borrows the hover drawable's CORNERS but not its colour, so it matches
	/// the theme's shape without being as loud as a hover.
	private void DrawSelectedTint(UIDrawContext ctx, Rectangle itemRect, Color color,
		Drawable hoverDrawable)
	{
		if (let rounded = hoverDrawable as RoundedRectDrawable)
		{
			if (!rounded.Radii.IsZero)
			{
				ctx.VG.FillRoundedRect(itemRect, rounded.Radii, color);
				return;
			}
		}

		ctx.VG.FillRect(itemRect, color);
	}

	/// The item at a local Y, or -1 for none.
	private int32 GetIndexAt(float localY)
	{
		let y = localY - FramePad;
		if (y < 0)
			return -1;

		let index = (int32)(y / ItemHeight);
		return (index >= mOwner.ItemCount) ? -1 : index;
	}
}
