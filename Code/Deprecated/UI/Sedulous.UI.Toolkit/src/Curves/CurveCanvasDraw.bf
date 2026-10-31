using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CurveCanvas]]: the drawing. A grid with axis labels, one polyline per visible channel, key
/// markers, and the tangent handles of whichever key is selected.
extension CurveCanvas
{
	public override void OnDraw(UIDrawContext ctx)
	{
		UpdateAutoFit();

		// EVERYTHING clips to the canvas. A cubic overshoots between keys, and the value frame
		// is a viewport the user can pan, so off frame segments and handles are normal and must
		// never paint outside the widget.
		ctx.PushClip(Rectangle(0, 0, Width, Height));

		ctx.VG.FillRect(Rectangle(0, 0, Width, Height),
			ResolveStyleColor(.Background, Color.Rgb(28, 28, 33)));

		DrawGrid(ctx);

		for (int32 c = 0; c < mChannels.Count; c++)
		{
			let channel = mChannels[c];
			if (channel.Hidden || channel.Keys.IsEmpty)
				continue;

			DrawCurve(ctx, c);
			DrawKeys(ctx, c);

			if ((c == mSelectedChannel) && (mSelectedKey >= 0)
				&& (mSelectedKey < channel.Keys.Count) && (channel.Interpolation == .Hermite))
				DrawTangentHandles(ctx, c);
		}

		ctx.PopClip();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(200.0f), constraints.ConstrainHeight(120.0f));
	}

	private void DrawGrid(UIDrawContext ctx)
	{
		let gridColor = ResolveStyleColor(.BorderColor, Color.Rgb(50, 50, 58));

		for (int32 i = 0; i <= GridDivisions; i++)
		{
			let x = ((float)i / GridDivisions) * Width;
			ctx.VG.FillRect(.(x, 0, 1, Height), gridColor);
		}

		for (int32 i = 0; i <= GridDivisions; i++)
		{
			let y = ((float)i / GridDivisions) * Height;
			// The last line is pulled INSIDE the canvas, so the bottom rule is visible rather
			// than falling on the first row outside it.
			ctx.VG.FillRect(.(0, Min(y, Height - 1), Width, 1), gridColor);
		}

		if (ctx.FontService == null)
			return;

		if (let font = ctx.FontService.GetFont(9.0f))
			DrawAxisLabels(ctx, font);
	}

	/// The end labels are pushed INWARD rather than centred on their line, because a label
	/// centred on the top or bottom rule would be half outside the canvas and clipped away.
	private void DrawAxisLabels(UIDrawContext ctx, CachedFont font)
	{
		let labelColor = ResolveStyleColor(.TextDimColor, Color.Rgb(120, 122, 132));

		for (int32 i = 0; i <= GridDivisions; i++)
		{
			let fraction = (float)i / GridDivisions;
			let text = FormatShort(ValueMax - (fraction * (ValueMax - ValueMin)), .. scope String());

			if (i == 0)
				ctx.VG.DrawText(text, font, .(2, 1, 42, 14), .Left, .Top, labelColor);
			else if (i == GridDivisions)
				ctx.VG.DrawText(text, font, .(2, Height - 15, 42, 14), .Left, .Bottom, labelColor);
			else
				ctx.VG.DrawText(text, font, .(2, (fraction * Height) - 7, 42, 14), .Left, .Middle,
					labelColor);
		}

		for (int32 i = 0; i <= GridDivisions; i++)
		{
			let fraction = (float)i / GridDivisions;
			let lineX = fraction * Width;
			// Read back THROUGH the transform, so the labels say the right seconds under a
			// shared zoom and scroll as well as under the standalone fit.
			let text = FormatShort(XToTime(lineX), .. scope String());

			if (i == 0)
				ctx.VG.DrawText(text, font, .(2, Height - 13, 32, 12), .Left, .Bottom, labelColor);
			else if (i == GridDivisions)
				ctx.VG.DrawText(text, font, .(Width - 34, Height - 13, 32, 12), .Right, .Bottom,
					labelColor);
			else
				ctx.VG.DrawText(text, font, .(lineX - 16, Height - 13, 32, 12), .Center, .Bottom,
					labelColor);
		}
	}

	/// Sampled in SCREEN x rather than in time, so the polyline covers exactly what is on screen
	/// at any zoom and the sample density does not change with the clip's length.
	private void DrawCurve(UIDrawContext ctx, int32 channelIndex)
	{
		ctx.VG.BeginPath();

		for (int32 i = 0; i <= CurveSamples; i++)
		{
			let x = ((float)i / CurveSamples) * Width;
			let y = ValueToY(Evaluate(channelIndex, XToTime(x)));

			if (i == 0)
				ctx.VG.MoveTo(x, y);
			else
				ctx.VG.LineTo(x, y);
		}

		ctx.VG.Stroke(mChannels[channelIndex].StrokeColor, 1.5f);
	}

	private void DrawKeys(UIDrawContext ctx, int32 channelIndex)
	{
		let channel = mChannels[channelIndex];
		let selectedColor = Color.Rgb(255, 220, 100);

		for (int32 i = 0; i < channel.Keys.Count; i++)
		{
			let center = Float2(TimeToX(channel.Keys[i].Time), ValueToY(channel.Keys[i].Value));
			let isSelected = (channelIndex == mSelectedChannel) && (i == mSelectedKey);

			ctx.VG.FillCircle(center, KeyDrawRadius,
				isSelected ? selectedColor : channel.StrokeColor);

			// The selected key also gets a RING, so it reads as selected even against a channel
			// whose own colour is close to the highlight.
			if (isSelected)
				ctx.VG.StrokeCircle(center, KeyDrawRadius + 2, selectedColor, 1.5f);
		}
	}

	/// The handle colours SAY THE MODE: one colour for a mirrored pair, two different ones for a
	/// broken pair, and grey for a flat key that ignores dragging.
	private void DrawTangentHandles(UIDrawContext ctx, int32 channelIndex)
	{
		let key = mChannels[channelIndex].Keys[mSelectedKey];
		let anchor = Float2(TimeToX(key.Time), ValueToY(key.Value));

		Color incoming;
		Color outgoing;
		switch (key.Mode)
		{
		case .Mirrored:
			incoming = Color.Rgb(180, 200, 255);
			outgoing = incoming;

		case .Free:
			incoming = Color.Rgb(255, 140, 120);
			outgoing = Color.Rgb(120, 220, 160);

		case .Flat:
			incoming = Color.Rgb(120, 122, 132);
			outgoing = incoming;
		}

		ComputeHandlePos(channelIndex, mSelectedKey, false, let ix, let iy);
		ComputeHandlePos(channelIndex, mSelectedKey, true, let ox, let oy);

		ctx.VG.DrawLine(anchor, .(ix, iy), incoming, 1);
		ctx.VG.DrawLine(anchor, .(ox, oy), outgoing, 1);
		ctx.VG.FillRect(.(ix - HandleDrawRadius, iy - HandleDrawRadius, HandleDrawRadius * 2,
			HandleDrawRadius * 2), incoming);
		ctx.VG.FillRect(.(ox - HandleDrawRadius, oy - HandleDrawRadius, HandleDrawRadius * 2,
			HandleDrawRadius * 2), outgoing);
	}

	/// Two decimals with the trailing zeros, and any trailing point, trimmed off. An axis label
	/// reading "0.50" where it could read "0.5" is noise at nine pixels.
	private static void FormatShort(float value, String outText)
	{
		let start = outText.Length;
		value.ToString(outText, "F2", null);

		if (!outText.Substring(start).Contains('.'))
			return;

		while ((outText.Length > start) && (outText[outText.Length - 1] == '0'))
			outText.RemoveFromEnd(1);

		if ((outText.Length > start) && (outText[outText.Length - 1] == '.'))
			outText.RemoveFromEnd(1);
	}
}
