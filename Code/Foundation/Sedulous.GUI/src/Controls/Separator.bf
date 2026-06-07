namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;
using System;

/// Horizontal or vertical divider line.
public class Separator : View
{
	public Orientation Orientation = .Horizontal;
	public float SeparatorThickness = 1;

	public this() { }
	public this(Orientation orientation) : this() { Orientation = orientation; }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation == .Horizontal)
			MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
				constraints.ConstrainHeight(SeparatorThickness));
		else
			MeasuredSize = .(constraints.ConstrainWidth(SeparatorThickness),
				constraints.ConstrainHeight(constraints.MaxHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let color = ResolveStyleColor(.BorderColor, .(80, 80, 90, 255));
		ctx.VG.FillRect(.(0, 0, Width, Height), color);
	}
}
