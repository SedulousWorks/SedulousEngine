namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using System;

/// Horizontal or vertical divider line.
public class Separator : View
{
	public Property<Orientation> Orientation = new .(.Horizontal) ~ delete _;
	public Property<float> SeparatorThickness = new .(1) ~ delete _;

	public this()
	{
		Orientation.SetOwner(this);
		SeparatorThickness.SetOwner(this);
	}

	public this(Orientation orientation) : this()
	{
		Orientation.SetSilent(orientation);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation.Value == .Horizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
				constraints.ConstrainHeight(SeparatorThickness.Value));
		else
			MeasuredSize = .(constraints.ConstrainWidth(SeparatorThickness.Value),
				constraints.ConstrainHeight(constraints.MaxHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let color = ResolveStyleColor(.BorderColor, .(80, 80, 90, 255));
		ctx.VG.FillRect(.(0, 0, Width, Height), color);
	}
}
