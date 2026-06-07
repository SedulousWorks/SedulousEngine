namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Progress indicator showing a filled bar from 0 to 1.
public class ProgressBar : View
{
	private float mValue;

	/// Progress value (0 to 1).
	public float Value
	{
		get => mValue;
		set
		{
			let clamped = Math.Clamp(value, 0, 1);
			if (mValue == clamped) return;
			mValue = clamped;
			Invalidate();
		}
	}

	/// Whether to show an indeterminate animation (not yet implemented).
	public bool IsIndeterminate;

	public this() { }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(16));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);

		// Track
		let trackDrawable = ResolveStyleDrawable(.TrackDrawable);
		if (trackDrawable != null)
			trackDrawable.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, .(50, 52, 62, 255));

		// Fill
		if (mValue > 0)
		{
			let fillW = Width * mValue;
			let fillDrawable = ResolveStyleDrawable(.FillDrawable);
			if (fillDrawable != null)
			{
				ctx.VG.PushClipRect(.(0, 0, fillW, Height));
				fillDrawable.Draw(ctx, bounds);
				ctx.VG.PopClip();
			}
			else
			{
				ctx.VG.PushClipRect(.(0, 0, fillW, Height));
				ctx.VG.FillRect(.(0, 0, Width * mValue, Height), .(80, 150, 240, 255));
				ctx.VG.PopClip();
			}
		}
	}
}
