using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// The developer overlays drawn OVER a view: its bounds, padding, margin, the hovered hit
/// target, the focus path, and its draw and tab order.
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
	private static readonly Color cZOrderColor = C(230, 120, 255, 230);
	private static readonly Color cBadgeColor = C(10, 12, 16, 210);

	/// Segments a (top), b (top right), c (bottom right), d (bottom), e (bottom left), f (top
	/// left) and g (middle) of each digit, as bits 0 to 6.
	private static readonly uint8[10] cDigits = .(0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F);

	/// A number drawn as seven segment strokes: an overlay needs no font, so it works in any
	/// GUI, whatever its fonts. Each digit is 5 x 9 at (x, y), with 2 between digits.
	private static void DrawNumber(UIDrawContext ctx, int number, float x, float y, Color color)
	{
		const float w = 5.0f;
		const float h = 9.0f;
		const float half = 4.5f;
		const float advance = 7.0f;
		const float stroke = 1.4f;

		int digits = DigitCount(number);
		var rest = number;
		for (int i = digits - 1; i >= 0; i--)
		{
			let segments = cDigits[rest % 10];
			rest /= 10;
			let dx = x + (float)i * advance;
			void Line(float x0, float y0, float x1, float y1) =>
				ctx.VG.DrawLine(.(dx + x0, y + y0), .(dx + x1, y + y1), color, stroke);

			if ((segments & 0x01) != 0) Line(0, 0, w, 0);
			if ((segments & 0x02) != 0) Line(w, 0, w, half);
			if ((segments & 0x04) != 0) Line(w, half, w, h);
			if ((segments & 0x08) != 0) Line(0, h, w, h);
			if ((segments & 0x10) != 0) Line(0, half, 0, h);
			if ((segments & 0x20) != 0) Line(0, 0, 0, half);
			if ((segments & 0x40) != 0) Line(0, half, w, half);
		}
	}

	private static int DigitCount(int number)
	{
		int digits = 1;
		for (var n = number; n >= 10; n /= 10)
			digits++;
		return digits;
	}

	/// A number on a dark badge at (x, y), wide enough for its digits.
	private static void DrawBadge(UIDrawContext ctx, int number, float x, float y, Color color)
	{
		ctx.VG.FillRect(.(x, y, 4.0f + 7.0f * (float)DigitCount(number), 13.0f), cBadgeColor);
		DrawNumber(ctx, number, x + 2.0f, y + 2.0f, color);
	}

	/// `drawIndex` is the view's place in its parent's draw order (ShowZOrder).
	public static void DrawOverlays(UIDrawContext ctx, View view, int drawIndex)
	{
		let settings = ctx.DebugSettings;
		let w = view.Width;
		let h = view.Height;

		// Padding, as green interior bands: the padding as layout uses it, the sheet's, the
		// field's and the background's.
		if (settings.ShowPadding)
		{
			let pad = view.ResolveBoxMetrics().Padding;
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

		// Draw order within the parent, a violet number at the top right.
		if (settings.ShowZOrder)
			DrawBadge(ctx, drawIndex, Math.Max(0.0f, w - 18.0f), 0.0f, cZOrderColor);

		// Tab order: a blue number at the top left of each stop, and a line on to the next.
		if (settings.ShowTabOrder && view.IsFocusable && (view.Context != null))
		{
			let stops = scope List<View>();
			view.Context.GetFocusManager().CollectTabStops(stops);
			let index = stops.IndexOf(view);
			if (index >= 0)
			{
				DrawBadge(ctx, index + 1, 0.0f, 0.0f, cFocusColor);
				if (index + 1 < stops.Count)
				{
					let next = stops[index + 1];
					let to = view.ScreenToLocal(next.LocalToScreen(.(next.Width * 0.5f, next.Height * 0.5f)));
					ctx.VG.DrawLine(.(w * 0.5f, h * 0.5f), to,
						Color(cFocusColor.R, cFocusColor.G, cFocusColor.B, 0.5f), 1.0f);
				}
			}
		}
	}
}
