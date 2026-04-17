namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using Sedulous.VG;

/// Draws debug overlays (bounds, padding, margin) for the given view.
/// Called after the normal draw pass when debug settings are enabled.
public static class UIDebugOverlay
{
	private static readonly Color sBoundsColor   = .(255, 60, 60, 180);
	private static readonly Color sPaddingColor  = .(60, 200, 60, 60);
	private static readonly Color sMarginColor   = .(255, 160, 40, 60);

	/// Draw debug overlays for a single view. Called in the view's
	/// local coordinate space (0,0 = top-left of view).
	public static void DrawOverlays(UIDrawContext ctx, View view)
	{
		let settings = ctx.DebugSettings;
		let w = view.Width;
		let h = view.Height;

		// Padding (green interior bands)
		if (settings.ShowPadding)
		{
			if (let vg = view as ViewGroup)
			{
				let pad = vg.Padding;
				if (!pad.IsZero)
				{
					ctx.VG.FillRect(.(0, 0, w, pad.Top), sPaddingColor);                         // top
					ctx.VG.FillRect(.(0, h - pad.Bottom, w, pad.Bottom), sPaddingColor);         // bottom
					ctx.VG.FillRect(.(0, pad.Top, pad.Left, h - pad.Top - pad.Bottom), sPaddingColor);   // left
					ctx.VG.FillRect(.(w - pad.Right, pad.Top, pad.Right, h - pad.Top - pad.Bottom), sPaddingColor); // right
				}
			}
		}

		// Margin (orange exterior bands) — drawn in parent space, so we
		// offset relative to the view's bounds. Requires pushing parent
		// context, which we don't have here. Instead, draw as negative-inset
		// rectangles from (0,0).
		if (settings.ShowMargin)
		{
			let lp = view.LayoutParams;
			if (lp != null && !lp.Margin.IsZero)
			{
				let m = lp.Margin;
				ctx.VG.FillRect(.(-m.Left, -m.Top, w + m.TotalHorizontal, m.Top), sMarginColor);         // top
				ctx.VG.FillRect(.(-m.Left, h, w + m.TotalHorizontal, m.Bottom), sMarginColor);           // bottom
				ctx.VG.FillRect(.(-m.Left, 0, m.Left, h), sMarginColor);                                  // left
				ctx.VG.FillRect(.(w, 0, m.Right, h), sMarginColor);                                       // right
			}
		}

		// Bounds (red outline)
		if (settings.ShowBounds)
		{
			ctx.VG.StrokeRect(.(0, 0, w, h), sBoundsColor, 1.0f);
		}
	}
}
