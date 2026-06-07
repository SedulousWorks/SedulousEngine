namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Progress indicator showing a filled bar from 0 to 1.
public class ProgressBar : View
{
	/// Progress value (0 to 1).
	public Property<float> Value = new .(0) ~ delete _;

	/// Whether to show an indeterminate animation (not yet implemented).
	public Property<bool> IsIndeterminate = new .(false) ~ delete _;

	public this()
	{
		Value.SetOwner(this, .Visual);
		IsIndeterminate.SetOwner(this, .Visual);

		// Clamp Value to 0-1 range on change.
		Value.Changed.Add(new [&] (val) => {
			let clamped = Math.Clamp(val, 0, 1);
			if (clamped != val)
				Value.SetSilent(clamped);
		});
	}

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
		if (Value.Value > 0)
		{
			let fillW = Width * Value.Value;
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
				ctx.VG.FillRect(.(0, 0, Width * Value.Value, Height), .(80, 150, 240, 255));
				ctx.VG.PopClip();
			}
		}
	}
}
