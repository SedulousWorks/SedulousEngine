using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[Timeline]]: the ruler, the label gutter, the dopesheet rows, the playhead and the box
/// select overlay.
///
/// Every colour comes from the theme with a fallback; none is hand picked in the draw path. The
/// gutter and the row stripes are DERIVED from the one themed band rather than being separate
/// tokens, so a retheme moves all of them together.
extension Timeline
{
	public override void OnDraw(UIDrawContext ctx)
	{
		// Everything clips to the widget: a tick label near the right edge and a long lane
		// label both want to paint past it otherwise.
		ctx.PushClip(Rectangle(0, 0, Width, Height));

		let band = ResolveStyleColor(.Background, Color.Rgb(24, 25, 30));
		ctx.VG.FillRect(Rectangle(0, 0, Width, Height), band);

		DrawRuler(ctx);

		if (LabelColumnWidth > 0.0f)
			DrawLabelGutter(ctx, band);

		DrawLanes(ctx, band);
		DrawPlayhead(ctx);

		if (mBoxSelecting)
			DrawBoxSelection(ctx);

		ctx.PopClip();
	}

	private void DrawRuler(UIDrawContext ctx)
	{
		let tickColor = ResolveStyleColor(.BorderColor, Color.Rgb(62, 64, 74));
		let labelColor = ResolveStyleColor(.TextDimColor, Color.Rgb(150, 152, 162));
		let font = (ctx.FontService != null) ? ctx.FontService.GetFont(9.0f) : null;

		let step = PickTickStep(mPixelsPerSecond, MinLabelSpacing);
		let startTime = Max(XToTime(Max(LabelColumnWidth, 0.0f)), 0.0f);
		let endTime = XToTime(Width);

		// Ticks are indexed, not accumulated. Adding the step repeatedly drifts in single
		// precision and the drift REACHES THE LABEL: a tick meant to read 0.0005 prints as
		// 0.0005322. Multiplying an integer by the step stays exact at every tick.
		let firstTick = (int64)Floor(startTime / step);
		let lastTick = (int64)Ceil(endTime / step);

		for (int64 tick = firstTick; tick <= lastTick; tick++)
		{
			let t = (float)tick * step;
			if (t < -1e-4f)
				continue;

			let x = TimeToX(t);
			if ((x >= LabelColumnWidth) && (x <= Width))
			{
				ctx.VG.FillRect(.(x, Height * 0.45f, 1.0f, Height * 0.55f), tickColor);

				if (font != null)
					ctx.VG.DrawText(FormatTime(t, .. scope String()), font,
						.(x + 3.0f, 1.0f, 46.0f, 12.0f), .Left, .Top, labelColor);
			}

			// A shorter tick halfway to the next label, which is what makes the spacing
			// readable without doubling the number of labels.
			let minorX = TimeToX(t + (step * 0.5f));
			if ((minorX >= LabelColumnWidth) && (minorX <= Width))
				ctx.VG.FillRect(.(minorX, Height * 0.72f, 1.0f, Height * 0.28f), tickColor);
		}
	}

	/// The gutter is the band DARKENED, so one themed background keeps it distinct from the
	/// ruler without a second token carrying its own fallback.
	private void DrawLabelGutter(UIDrawContext ctx, Color band)
	{
		ctx.VG.FillRect(Rectangle(0, 0, LabelColumnWidth, Height),
			.(band.R * 0.82f, band.G * 0.82f, band.B * 0.82f, band.A));

		let labelColor = ResolveStyleColor(.TextDimColor, Color.Rgb(150, 152, 162));
		let accent = ResolveStyleColor(.AccentColor, Color.Rgb(90, 150, 235));
		// LARGER than the ruler's digits: nine point reads as fine print, and a track name is
		// something the user picks from rather than glances at.
		let font = (ctx.FontService != null) ? ctx.FontService.GetFont(12.0f) : null;

		// Clipped to the gutter, so a long property path never bleeds into the key grid.
		ctx.PushClip(Rectangle(0, 0, LabelColumnWidth, Height));

		var laneY = RulerHeight;
		for (int i = 0; i < mLanes.Count; i++)
		{
			let lane = mLanes[i];

			if (i == mSelectedLane)
				ctx.VG.FillRect(.(0, laneY, LabelColumnWidth, lane.Height),
					.(accent.R, accent.G, accent.B, 0.28f));

			if ((font != null) && !lane.Label.IsEmpty)
				ctx.VG.DrawText(lane.Label, font,
					.(6.0f, laneY, LabelColumnWidth - 10.0f, lane.Height), .Left, .Middle,
					labelColor);

			laneY += lane.Height;
		}

		ctx.PopClip();
	}

	/// Alternating rows and one marker per key. A selected lane takes a wash of the accent, and
	/// a live key drag offsets the selected markers so the move is visible before it is applied.
	private void DrawLanes(UIDrawContext ctx, Color band)
	{
		let rowEven = Color(band.R * 1.12f, band.G * 1.12f, band.B * 1.12f, band.A);
		let rowOdd = Color(band.R * 1.24f, band.G * 1.24f, band.B * 1.24f, band.A);
		let keyColor = ResolveStyleColor(.TextDimColor, Color.Rgb(170, 174, 186));
		let accent = ResolveStyleColor(.AccentColor, Color.Rgb(90, 150, 235));

		var laneY = RulerHeight;
		for (int li = 0; li < mLanes.Count; li++)
		{
			let lane = mLanes[li];
			let isSelected = li == mSelectedLane;

			ctx.VG.FillRect(.(LabelColumnWidth, laneY, Width - LabelColumnWidth, lane.Height),
				isSelected ? Color(accent.R, accent.G, accent.B, 0.18f)
					: (((li & 1) != 0) ? rowOdd : rowEven));

			let centerY = laneY + (lane.Height * 0.5f);
			for (int ki = 0; ki < lane.KeyTimes.Count; ki++)
			{
				let keySelected = mSelection.Contains(Pack((uint32)li, (uint32)ki));
				var x = TimeToX(lane.KeyTimes[ki]);
				if (keySelected && mKeyDragging)
					x += mDragDeltaX;

				// Culled with a radius of slack, so a marker straddling an edge still draws its
				// visible half.
				if ((x < LabelColumnWidth - KeyRadius) || (x > Width + KeyRadius))
					continue;

				ctx.VG.FillCircle(.(x, centerY), KeyRadius, keySelected ? accent : keyColor);
			}

			laneY += lane.Height;
		}
	}

	/// A line with a flag at the top.
	///
	/// SNAPPED to a whole pixel and drawn two wide, because a fractional position anti aliases
	/// across two columns and the line shimmers between one and two pixels as it advances.
	private void DrawPlayhead(UIDrawContext ctx)
	{
		let x = TimeToX(mPlayhead);
		if ((x < LabelColumnWidth - 0.5f) || (x > Width))
			return;

		let snapped = Round(x);
		let color = ResolveStyleColor(.ErrorColor, Color.Rgb(232, 84, 84));
		ctx.VG.FillRect(.(snapped - 1.0f, 0, 2.0f, Height), color);
		ctx.VG.FillRect(.(snapped - 4.0f, 0, 8.0f, 5.0f), color);
	}

	private void DrawBoxSelection(UIDrawContext ctx)
	{
		let accent = ResolveStyleColor(.AccentColor, Color.Rgb(90, 150, 235));
		ctx.VG.FillRect(.(Min(mBoxStart.X, mBoxEnd.X), Min(mBoxStart.Y, mBoxEnd.Y),
			Abs(mBoxEnd.X - mBoxStart.X), Abs(mBoxEnd.Y - mBoxStart.Y)),
			.(accent.R, accent.G, accent.B, 0.18f));
	}

	/// A tick's label. Frames when a display rate was given, else seconds at FOUR significant
	/// digits: every step in the one, two, five family prints exactly at that width, and single
	/// precision noise never reaches the ruler.
	private void FormatTime(float t, String outText)
	{
		if (DisplayFps > 0)
		{
			((int32)Round(t * (float)DisplayFps)).ToString(outText);
			outText.Append('f');
			return;
		}

		t.ToString(outText, "G4", null);
		outText.Append('s');
	}
}
