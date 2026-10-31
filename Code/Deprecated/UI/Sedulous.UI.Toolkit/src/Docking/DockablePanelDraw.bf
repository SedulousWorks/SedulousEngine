using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[DockablePanel]]: the header band and the content ground behind whatever it hosts.
extension DockablePanel
{
	public override void OnDraw(UIDrawContext ctx)
	{
		let headerHeight = mShowHeader ? HeaderHeight : 0.0f;

		if (mShowHeader)
			DrawHeader(ctx);

		// A ground behind the content, so a panel hosting something translucent or smaller than
		// its region does not show whatever is docked behind it.
		if (let contentDrawable = ResolvePartDrawable("content", .Background, .Normal))
			contentDrawable.Draw(ctx, .(0, headerHeight, Width, Height - headerHeight));
		else
			ctx.VG.FillRect(.(0, headerHeight, Width, Height - headerHeight),
				Color.Rgb(42, 44, 54));

		DrawChildren(ctx);
	}

	private void DrawHeader(UIDrawContext ctx)
	{
		if (let headerDrawable = ResolvePartDrawable("header", .Background, .Normal))
			headerDrawable.Draw(ctx, .(0, 0, Width, HeaderHeight));
		else
			ctx.VG.FillRect(.(0, 0, Width, HeaderHeight), Color.Rgb(40, 44, 55));

		if (ctx.FontService != null)
		{
			if (let font = ctx.FontService.GetFont(ResolveStyleFloat(.FontSize, 12.0f)))
				ctx.VG.DrawText(mTitle, font, .(8, 0, Width - 30, HeaderHeight), .Left, .Middle,
					ResolveStyleColor(.TextColor, Color.Rgb(220, 225, 235)));
		}

		if (mClosable && !InChromedOSWindow())
			DrawCloseButton(ctx);
	}

	/// A themed icon where the sheet supplies one, and two strokes otherwise, so the control
	/// exists even with no theme loaded at all.
	private void DrawCloseButton(UIDrawContext ctx)
	{
		let centerX = Width - 14;
		let centerY = HeaderHeight * 0.5f;
		let arm = 4.0f;
		let color = ResolvePartColor("close-button", .TextColor, .Normal,
			.(180 / 255.0f, 185 / 255.0f, 200 / 255.0f, 150 / 255.0f));

		if (let icon = ResolvePartDrawable("close-button", .Background, .Normal))
		{
			let size = 2.0f * (arm + 2.0f);
			// The icon carries its own colours, so the resolved one is applied as OPACITY
			// rather than as a tint.
			ctx.VG.PushOpacity(color.A);
			icon.Draw(ctx, .(centerX - (size * 0.5f), centerY - (size * 0.5f), size, size));
			ctx.VG.PopOpacity();
			return;
		}

		ctx.VG.DrawLine(.(centerX - arm, centerY - arm), .(centerX + arm, centerY + arm), color, 1.5f);
		ctx.VG.DrawLine(.(centerX + arm, centerY - arm), .(centerX - arm, centerY + arm), color, 1.5f);
	}
}
