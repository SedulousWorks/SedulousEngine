using Sedulous.Core;

namespace Sedulous.UI;

/// A determinate or indeterminate progress indicator.
///
/// Value is clamped to 0..1 by its own Changed handler, which writes back with SetSilent: a
/// plain assignment from inside a Changed handler is swallowed by the property's reentrancy
/// guard, and would leave the out of range value in place.
class ProgressBar : View
{
	/// Progress, 0..1.
	public Property<float> Value = new .(0.0f) ~ delete _;
	public Property<bool> IsIndeterminate = new .(false) ~ delete _;

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

		if (Value.Value > 0)
		{
			// The fill drawable is drawn across the WHOLE bounds and clipped to the progress,
			// so a nine slice or a gradient keeps its proportions instead of being squashed.
			let fillWidth = Width * Value.Value;
			ctx.PushClip(.(0, 0, fillWidth, Height));
			if (let fill = ResolvePartDrawable("fill", .Background, state))
				fill.Draw(ctx, bounds);
			else
				ctx.VG.FillRect(bounds, .(80.0f / 255.0f, 150.0f / 255.0f, 240.0f / 255.0f, 1.0f));
			ctx.PopClip();
		}
	}
}
