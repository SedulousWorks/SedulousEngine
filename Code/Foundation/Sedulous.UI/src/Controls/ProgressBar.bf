namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Progress indicator displaying a 0..1 fill ratio.
public class ProgressBar : View
{
	private float mProgress;
	private Color? mTrackColor;
	private Color? mFillColor;

	public float Progress
	{
		get => mProgress;
		set
		{
			let clamped = Math.Clamp(value, 0, 1);
			if (mProgress != clamped)
			{
				mProgress = clamped;
				InvalidateVisual();
			}
		}
	}

	public Color TrackColor
	{
		get => mTrackColor ?? Context?.Theme?.GetColor("ProgressBar.Track", .(50, 52, 62, 255)) ?? .(50, 52, 62, 255);
		set => mTrackColor = value;
	}

	public Color FillColor
	{
		get => mFillColor ?? Context?.Theme?.GetColor("ProgressBar.Fill") ?? Context?.Theme?.Palette.PrimaryAccent ?? .(80, 130, 230, 255);
		set => mFillColor = value;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let desiredH = Context?.Theme?.GetDimension("ProgressBar.Height", 16) ?? 16;
		MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(desiredH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let radius = Height * 0.5f;
		let bounds = RectangleF(0, 0, Width, Height);

		// Track.
		if (!ctx.TryDrawDrawable("ProgressBar.Track", bounds, GetControlState()))
			ctx.VG.FillRoundedRect(bounds, radius, TrackColor);

		// Fill - clip so the rounded left edge is preserved.
		let fillW = Width * mProgress;
		if (fillW > 0)
		{
			let fillBounds = RectangleF(0, 0, fillW, Height);
			if (!ctx.TryDrawDrawable("ProgressBar.Fill", fillBounds, GetControlState()))
			{
				ctx.VG.PushClipRect(.(0, 0, fillW, Height));
				ctx.VG.FillRoundedRect(bounds, radius, FillColor);
				ctx.VG.PopClip();
			}
		}
	}
}
