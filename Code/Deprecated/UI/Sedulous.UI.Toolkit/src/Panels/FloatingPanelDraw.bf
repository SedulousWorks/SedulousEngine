using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Toolkit;

/// [[FloatingPanel]]: the chrome.
extension FloatingPanel
{
	public override void OnDraw(UIDrawContext ctx)
	{
		let radius = ResolveStyleFloat(.CornerRadius, 0.0f);
		let fill = ResolveStyleColor(.Background, .(0.149f, 0.157f, 0.196f, 1.0f));
		let border = ResolveStyleColor(.BorderColor, .(0.255f, 0.275f, 0.333f, 1.0f));

		ctx.VG.FillRoundedRect(Rectangle(0, 0, Width, Height), radius, fill);
		DrawHeader(ctx, radius, fill, border);

		// CLIPPED to the body, so a panel resized narrow keeps its content inside the frame
		// rather than painting over the border and out past the panel.
		if (!mCollapsed)
		{
			ctx.PushClip(Rectangle(ContentInset, HeaderHeight,
				Max(0.0f, Width - (2.0f * ContentInset)),
				Max(0.0f, Height - HeaderHeight - ContentInset)));
			DrawChildren(ctx);
			ctx.PopClip();
		}

		// The border goes on LAST, over the content's edges.
		ctx.VG.DrawBorderRoundedRect(Rectangle(0, 0, Width, Height), radius, border, 1.0f);

		if (!mCollapsed)
			DrawResizeGrip(ctx, border);
	}

	/// The title strip, rounded only at the TOP so it meets the body's corners cleanly instead
	/// of showing a seam where two fully rounded shapes meet.
	private void DrawHeader(UIDrawContext ctx, float radius, Color fill, Color border)
	{
		let headerHeight = mCollapsed ? Height : HeaderHeight;
		let headerFill = ResolvePartColor("header", .Background, .Normal, Darkened(fill));
		ctx.VG.FillRoundedRect(Rectangle(0, 0, Width, headerHeight),
			CornerRadii(radius, radius, 0.0f, 0.0f), headerFill);

		let chevronColor = ResolvePartColor("chevron", .TextColor, .Normal, border);
		DrawChevron(ctx, chevronColor);
		DrawTitle(ctx);
		DrawCloseCross(ctx, chevronColor);
	}

	/// Down when open, right when collapsed: the expander's convention, so the two read the
	/// same way.
	private void DrawChevron(UIDrawContext ctx, Color color)
	{
		let centerY = HeaderHeight * 0.5f;
		ctx.VG.BeginPath();

		if (!mCollapsed)
		{
			ctx.VG.MoveTo(ChevronX, centerY - (ChevronSize * 0.25f));
			ctx.VG.LineTo(ChevronX + (ChevronSize * 0.5f), centerY + (ChevronSize * 0.25f));
			ctx.VG.LineTo(ChevronX + ChevronSize, centerY - (ChevronSize * 0.25f));
		}
		else
		{
			ctx.VG.MoveTo(ChevronX + (ChevronSize * 0.25f), centerY - (ChevronSize * 0.5f));
			ctx.VG.LineTo(ChevronX + (ChevronSize * 0.75f), centerY);
			ctx.VG.LineTo(ChevronX + (ChevronSize * 0.25f), centerY + (ChevronSize * 0.5f));
		}

		ctx.VG.Stroke(color, 2.0f);
	}

	/// Between the chevron and the close box, so a long title is cut off rather than running
	/// under either control.
	private void DrawTitle(UIDrawContext ctx)
	{
		if (ctx.FontService == null)
			return;

		let font = ctx.FontService.GetFont(ResolveStyleFloat(.FontSize, 12.0f));
		if (font == null)
			return;

		let textColor = ResolveStyleColor(.TextColor, .(0.863f, 0.882f, 0.922f, 1.0f));
		ctx.VG.DrawText(mTitle, font,
			.(ChevronBoxWidth, 0, Max(0.0f, Width - ChevronBoxWidth - CloseBoxWidth), HeaderHeight),
			.Left, .Middle, textColor);
	}

	private void DrawCloseCross(UIDrawContext ctx, Color fallback)
	{
		let color = ResolvePartColor("close-button", .TextColor,
			mCloseHover ? .Hover : .Normal, fallback);
		let centerX = Width - (CloseBoxWidth * 0.5f);
		let centerY = HeaderHeight * 0.5f;
		let arm = 4.0f;

		ctx.VG.DrawLine(.(centerX - arm, centerY - arm), .(centerX + arm, centerY + arm), color, 1.5f);
		ctx.VG.DrawLine(.(centerX + arm, centerY - arm), .(centerX - arm, centerY + arm), color, 1.5f);
	}

	/// Three diagonal strokes in the corner, which is what says a corner can be dragged.
	private void DrawResizeGrip(UIDrawContext ctx, Color border)
	{
		for (int32 i = 1; i <= 3; i++)
		{
			let offset = (float)i * 4.0f;
			ctx.VG.DrawLine(.(Width - offset, Height - 2.0f), .(Width - 2.0f, Height - offset),
				border, 1.0f);
		}
	}

	private static Color Darkened(Color color) => .(color.R * 0.85f, color.G * 0.85f,
		color.B * 0.85f, color.A);
}
