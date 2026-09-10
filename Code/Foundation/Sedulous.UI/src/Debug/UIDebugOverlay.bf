using Sedulous.Core;

namespace Sedulous.UI;

/// The developer overlays drawn OVER a view: its bounds, padding, margin, the hovered hit
/// target and the focus path.
///
/// Drawn after the view's own OnDraw, in the view's LOCAL coordinates, which is why the
/// margin bands can use negative offsets to reach outside the box.
static class UIDebugOverlay
{
	private static Color C(float r, float g, float b, float a) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);

	private static readonly Color cBoundsColor = C(255, 60, 60, 180);
	private static readonly Color cPaddingColor = C(60, 200, 60, 60);
	private static readonly Color cMarginColor = C(255, 160, 40, 60);
	private static readonly Color cHitTargetColor = C(255, 255, 0, 100);
	private static readonly Color cFocusColor = C(80, 160, 255, 200);

	public static void DrawOverlays(UIDrawContext ctx, View view)
	{
		let settings = ctx.DebugSettings;
		let w = view.Width;
		let h = view.Height;

		// Padding, as green interior bands. Only a group HAS a padding field.
		if (settings.ShowPadding)
		{
			if (let group = view as ViewGroup)
			{
				let pad = group.Padding;
				if (!pad.IsZero)
				{
					ctx.VG.FillRect(.(0, 0, w, pad.Top), cPaddingColor);
					ctx.VG.FillRect(.(0, h - pad.Bottom, w, pad.Bottom), cPaddingColor);
					ctx.VG.FillRect(.(0, pad.Top, pad.Left, h - pad.Top - pad.Bottom),
						cPaddingColor);
					ctx.VG.FillRect(.(w - pad.Right, pad.Top, pad.Right, h - pad.Top - pad.Bottom),
						cPaddingColor);
				}
			}
		}

		// Margin, as orange bands OUTSIDE the box.
		if (settings.ShowMargin)
		{
			let margin = view.Layout.Margin.Value;
			if (!margin.IsZero)
			{
				ctx.VG.FillRect(.(-margin.Left, -margin.Top, w + margin.TotalHorizontal,
					margin.Top), cMarginColor);
				ctx.VG.FillRect(.(-margin.Left, h, w + margin.TotalHorizontal, margin.Bottom),
					cMarginColor);
				ctx.VG.FillRect(.(-margin.Left, 0, margin.Left, h), cMarginColor);
				ctx.VG.FillRect(.(w, 0, margin.Right, h), cMarginColor);
			}
		}

		// Bounds, as a red outline.
		if (settings.ShowBounds)
			ctx.VG.StrokeRect(.(0, 0, w, h), cBoundsColor, 1.0f);

		// The hit target, as a yellow wash over whatever is hovered.
		if (settings.ShowHitTarget && view.IsHovered())
			ctx.VG.FillRect(.(0, 0, w, h), cHitTargetColor);

		// The focus path: a solid ring on the focused view, and a fainter one on every
		// ancestor the focus is inside, so the chain reads at a glance.
		if (settings.ShowFocusPath)
		{
			if (view.IsFocused())
			{
				ctx.VG.StrokeRect(.(-2, -2, w + 4, h + 4), cFocusColor, 2.0f);
			}
			else if (view.IsFocusWithin())
			{
				ctx.VG.StrokeRect(.(-1, -1, w + 2, h + 2),
					Color(cFocusColor.R, cFocusColor.G, cFocusColor.B, 80.0f / 255.0f), 1.0f);
			}
		}
	}
}
