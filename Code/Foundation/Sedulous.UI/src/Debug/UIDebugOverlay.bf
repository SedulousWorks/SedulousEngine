namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.Fonts;

/// Draws debug overlays (bounds, padding, margin, focus, hit-target)
/// for the given view. Called after the normal draw pass.
public static class UIDebugOverlay
{
	private static readonly Color sBoundsColor         = .(255, 60, 60, 180);
	private static readonly Color sPaddingColor        = .(60, 200, 60, 60);
	private static readonly Color sMarginColor         = .(255, 160, 40, 60);
	private static readonly Color sDrawablePaddingColor = .(60, 120, 255, 60);
	private static readonly Color sHitTargetColor      = .(255, 255, 0, 100);
	private static readonly Color sFocusColor          = .(80, 160, 255, 200);

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
					ctx.VG.FillRect(.(0, 0, w, pad.Top), sPaddingColor);
					ctx.VG.FillRect(.(0, h - pad.Bottom, w, pad.Bottom), sPaddingColor);
					ctx.VG.FillRect(.(0, pad.Top, pad.Left, h - pad.Top - pad.Bottom), sPaddingColor);
					ctx.VG.FillRect(.(w - pad.Right, pad.Top, pad.Right, h - pad.Top - pad.Bottom), sPaddingColor);
				}
			}
		}

		// Drawable padding (blue interior bands — distinct from explicit padding)
		if (settings.ShowDrawablePadding)
		{
			if (let panel = view as Panel)
			{
				if (panel.Background != null)
				{
					let dp = panel.Background.DrawablePadding;
					if (!dp.IsZero)
					{
						ctx.VG.FillRect(.(0, 0, w, dp.Top), sDrawablePaddingColor);
						ctx.VG.FillRect(.(0, h - dp.Bottom, w, dp.Bottom), sDrawablePaddingColor);
						ctx.VG.FillRect(.(0, dp.Top, dp.Left, h - dp.Top - dp.Bottom), sDrawablePaddingColor);
						ctx.VG.FillRect(.(w - dp.Right, dp.Top, dp.Right, h - dp.Top - dp.Bottom), sDrawablePaddingColor);
					}
				}
			}
		}

		// Margin (orange exterior bands)
		if (settings.ShowMargin)
		{
			let lp = view.LayoutParams;
			if (lp != null && !lp.Margin.IsZero)
			{
				let m = lp.Margin;
				ctx.VG.FillRect(.(-m.Left, -m.Top, w + m.TotalHorizontal, m.Top), sMarginColor);
				ctx.VG.FillRect(.(-m.Left, h, w + m.TotalHorizontal, m.Bottom), sMarginColor);
				ctx.VG.FillRect(.(-m.Left, 0, m.Left, h), sMarginColor);
				ctx.VG.FillRect(.(w, 0, m.Right, h), sMarginColor);
			}
		}

		// Bounds (red outline)
		if (settings.ShowBounds)
		{
			ctx.VG.StrokeRect(.(0, 0, w, h), sBoundsColor, 1.0f);
		}

		// Hit target highlight (yellow fill on hovered view)
		if (settings.ShowHitTarget)
		{
			if (view.Context?.InputManager != null && view.Context.InputManager.HoveredId == view.Id)
				ctx.VG.FillRect(.(0, 0, w, h), sHitTargetColor);
		}

		// Focus path (blue outline on focused view + ancestors)
		if (settings.ShowFocusPath)
		{
			if (view.IsFocused)
				ctx.VG.StrokeRect(.(-2, -2, w + 4, h + 4), sFocusColor, 2.0f);
			else if (view.IsFocusWithin)
				ctx.VG.StrokeRect(.(-1, -1, w + 2, h + 2), .(sFocusColor.R, sFocusColor.G, sFocusColor.B, 80), 1.0f);
		}

		// Recycler stats on ListViews
		if (settings.ShowRecyclerStats)
		{
			if (let listView = view as ListView)
			{
				let r = listView.Recycler;
				let statsText = scope String();
				statsText.AppendF("C:{} R:{} U:{}", r.CreatedCount, r.RecycledCount, r.ReusedCount);

				ctx.VG.FillRoundedRect(.(2, 2, 140, 18), 4, .(0, 0, 0, 160));
				if (ctx.FontService != null)
				{
					let font = ctx.FontService.GetFont(12);
					if (font != null)
						ctx.VG.DrawText(statsText, font, .(6, 2, 130, 18), .Left, .Middle, .(200, 255, 200, 255));
				}
			}
		}
	}
}
