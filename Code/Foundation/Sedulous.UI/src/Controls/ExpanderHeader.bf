using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// An Expander's header band: a real layout row, not something the expander paints.
///
/// Being a row is what lets the actions be an ordinary right-aligned child, so a click they
/// handle never reaches the band's toggle, and oversized actions grow the band rather than
/// overflowing it.
///
/// It draws from the OWNER's styling parts, so a sheet writes `Expander::header` rather than
/// having to know this type exists.
class ExpanderHeader : ViewGroup
{
	private const float ChevronSize = 8.0f;
	private const float ChevronX = 8.0f;
	private const float TextGap = 8.0f;
	/// The actions block's inset from the right edge.
	private const float ActionsPad = 4.0f;
	/// Band padding above and below, when the actions are what set its height.
	private const float ActionsVPad = 2.0f;

	/// BORROWED: the expander owns this band, not the other way round. Never null.
	private Expander mOwner;
	/// BORROWED: held as a child, so the group's own reference is the owning one.
	private View mActions = null;

	public this(Expander owner)
	{
		mOwner = owner;
		Cursor = .Hand;
	}

	/// Borrowed; may be null.
	public View Actions => mActions;

	/// Replaces the actions, CONSUMING the caller's reference. Null clears.
	public void SetActions(View actions)
	{
		if (mActions != null)
			RemoveView(mActions);

		mActions = actions;
		if (actions != null)
			AddView(actions);
	}

	/// The overload that also places the child; the other keeps whatever placement it carries.
	public void SetActions(View actions, LayoutStyle layout)
	{
		if (actions != null)
			actions.SetLayout(layout);

		SetActions(actions);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		// An already handled press was taken by an action, and must not also toggle.
		if (!IsEffectivelyEnabled() || e.Handled || (e.Button != .Left))
			return;

		mOwner.Toggle();
		e.Handled = true;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var bandHeight = mOwner.HeaderHeight.Value;

		if ((mActions != null) && (mActions.Visibility != .Gone))
		{
			mActions.Measure(constraints.Loosen());
			bandHeight = Max(bandHeight, mActions.MeasuredSize.Y + ActionsVPad * 2.0f);
		}

		MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(200.0f)),
			constraints.ConstrainHeight(bandHeight));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if ((mActions == null) || (mActions.Visibility == .Gone))
			return;

		let size = mActions.MeasuredSize;
		mActions.Layout(Max(0.0f, width - size.X - ActionsPad), Max(0.0f, (height - size.Y) * 0.5f),
			size.X, size.Y);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let band = Rectangle(0, 0, Width, Height);

		// The hover is the BAND's own, not the expander's: a sheet writing
		// `Expander::header:hover` means the pointer is over the header, not over the body.
		var bandState = GetControlState();
		if (!mOwner.IsEffectivelyEnabled())
			bandState |= .Disabled;

		if (let header = mOwner.ResolvePartDrawable("header", .Background, bandState))
			header.Draw(ctx, band, bandState);
		else
			ctx.VG.FillRect(band, Color(50 / 255.0f, 55 / 255.0f, 68 / 255.0f, 1.0f));

		DrawChevron(ctx, bandState);
		DrawTitle(ctx);
		DrawChildren(ctx);
	}

	private void DrawChevron(UIDrawContext ctx, ControlState bandState)
	{
		let cy = Height * 0.5f;

		// Expanded reads as Checked, so a theme can style the two directions as one part with
		// a state rather than as two drawables.
		var chevronState = bandState;
		if (mOwner.IsExpanded)
			chevronState |= .Checked;

		if (let chevron = mOwner.ResolvePartDrawable("chevron", .Background, chevronState))
		{
			chevron.Draw(ctx, .(ChevronX, cy - ChevronSize * 0.5f, ChevronSize, ChevronSize));
			return;
		}

		let color = mOwner.ResolvePartColor("chevron", .TextColor, chevronState,
			Color(180 / 255.0f, 185 / 255.0f, 200 / 255.0f, 1.0f));

		ctx.VG.BeginPath();
		if (mOwner.IsExpanded)
		{
			// Pointing down.
			ctx.VG.MoveTo(ChevronX, cy - ChevronSize * 0.25f);
			ctx.VG.LineTo(ChevronX + ChevronSize * 0.5f, cy + ChevronSize * 0.25f);
			ctx.VG.LineTo(ChevronX + ChevronSize, cy - ChevronSize * 0.25f);
		}
		else
		{
			// Pointing right.
			ctx.VG.MoveTo(ChevronX + ChevronSize * 0.25f, cy - ChevronSize * 0.5f);
			ctx.VG.LineTo(ChevronX + ChevronSize * 0.75f, cy);
			ctx.VG.LineTo(ChevronX + ChevronSize * 0.25f, cy + ChevronSize * 0.5f);
		}
		ctx.VG.Stroke(color, 2.0f);
	}

	private void DrawTitle(UIDrawContext ctx)
	{
		let title = mOwner.HeaderText;
		if (title.IsEmpty || (ctx.FontService == null))
			return;

		let family = scope String();
		mOwner.ResolveStyleFontFamily(family);
		let font = ctx.FontService.GetFont(family, mOwner.ResolveStyleFloat(.FontSize, 16.0f));
		if (font == null)
			return;

		let color = mOwner.ResolveStyleColor(.TextColor,
			Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));

		// The title's rect STOPS where the actions block begins, so a long title is truncated
		// by its own bounds rather than running underneath the buttons.
		let textX = ChevronX + ChevronSize + TextGap;
		let textWidth = Max(0.0f, Width - textX - ReservedActionsWidth - 4.0f);
		ctx.VG.DrawText(title, font, .(textX, 0, textWidth, Height), .Left, .Middle, color);
	}

	/// The width the title must not paint into: the actions block plus its insets, and zero
	/// when there are none.
	private float ReservedActionsWidth
	{
		get
		{
			if ((mActions == null) || (mActions.Visibility == .Gone))
				return 0.0f;

			return mActions.MeasuredSize.X + ActionsPad * 2.0f;
		}
	}
}
