using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A determinate or indeterminate progress indicator: a fill from 0 to 1, or, indeterminate, a
/// segment sliding across the track while it shows.
///
/// Value is clamped to 0..1 by its own Changed handler, which writes back with SetSilent: a
/// plain assignment from inside a Changed handler is swallowed by the property's reentrancy
/// guard, and would leave the out of range value in place.
class ProgressBar : View
{
	/// Progress, 0..1.
	public Property<float> Value = new .(0.0f) ~ delete _;
	public Property<bool> IsIndeterminate = new .(false) ~ delete _;

	/// Seconds the indeterminate segment takes to cross the track.
	public const float IndeterminatePeriod = 1.5f;

	public this()
	{
		Value.SetOwner(this, .Visual);
		IsIndeterminate.SetOwner(this, .Visual);
		Value.Changed.Add(new (val) =>
			{
				let clamped = Max(0.0f, Min(val, 1.0f));
				if (clamped != val)
					Value.SetSilent(clamped);
			});
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(200.0f)),
			constraints.ConstrainHeight(16.0f));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let state = GetControlState();

		if (let track = ResolvePartDrawable("track", .Background, state))
			track.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, .(50.0f / 255.0f, 52.0f / 255.0f, 62.0f / 255.0f, 1.0f));

		if (IsIndeterminate.Value)
		{
			// No known amount: a segment a third of the track slides across it, entering at the
			// left and leaving at the right, once every IndeterminatePeriod seconds.
			let time = (Context != null) ? Context.TotalTime : 0.0f;
			let phase = time / IndeterminatePeriod - Math.Floor(time / IndeterminatePeriod);
			let segment = Width / 3.0f;
			let left = Max(0.0f, phase * (Width + segment) - segment);
			let right = Min(Width, phase * (Width + segment));
			ctx.PushClip(.(left, 0, Max(0.0f, right - left), Height));
			DrawFill(ctx, bounds, state);
			ctx.PopClip();
			// It moves while it shows.
			Context?.RequestNextFrame();
		}
		else if (Value.Value > 0)
		{
			// The fill drawable is drawn across the WHOLE bounds and clipped to the progress,
			// so a nine slice or a gradient keeps its proportions instead of being squashed.
			let fillWidth = Width * Value.Value;
			ctx.PushClip(.(0, 0, fillWidth, Height));
			DrawFill(ctx, bounds, state);
			ctx.PopClip();
		}
	}

	private void DrawFill(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		if (let fill = ResolvePartDrawable("fill", .Background, state))
			fill.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, .(80.0f / 255.0f, 150.0f / 255.0f, 240.0f / 255.0f, 1.0f));
	}
}
