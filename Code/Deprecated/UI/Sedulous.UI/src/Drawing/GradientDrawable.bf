using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// A gradient fill of the view's box, rounded by Radii: linear (two colours and a direction,
/// or colour stops along a CSS angle) or radial (stops from the centre out to the farthest
/// corner).
class GradientDrawable : Drawable
{
	public Color StartColor = .();
	public Color EndColor = .();
	public GradientDirection Direction = .TopToBottom;
	/// Colour stops at offsets along the gradient (0 to 1), in place of StartColor and EndColor.
	public List<GradientStop> Stops = new .() ~ delete _;
	/// A CSS angle in degrees, in place of Direction: 0 runs up, 90 to the right, 180 down; the
	/// gradient line passes through the centre and is as long as the box's extent along it.
	public float? AngleDegrees;
	/// Radial: from the centre out to the farthest corner (a circle).
	public bool Radial = false;
	/// The box's corners: the fill is rounded to them, and a shadow under it follows them.
	public CornerRadii Radii = .();
	/// Custom properties (`--name`) the colours come from where the drawn view has them, the
	/// written colours their fallbacks: StartColor's and EndColor's, and one per stop (empty for a
	/// written one) when StopVariables is as long as Stops.
	public String StartVariable = new .() ~ delete _;
	public String EndVariable = new .() ~ delete _;
	public List<String> StopVariables = new .() ~ DeleteContainerAndItems!(_);

	public this() {}

	public this(Color start, Color end, GradientDirection direction = .TopToBottom)
	{
		StartColor = start;
		EndColor = end;
		Direction = direction;
	}

	public override CornerRadii? OutlineRadii(ControlState state) => Radii;

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		let x = bounds.X;
		let y = bounds.Y;
		let width = bounds.Width;
		let height = bounds.Height;

		let builder = scope PathBuilder();
		if (Radii.IsZero)
		{
			builder.MoveTo(x, y);
			builder.LineTo(x + width, y);
			builder.LineTo(x + width, y + height);
			builder.LineTo(x, y + height);
			builder.Close();
		}
		else
		{
			ShapeBuilder.BuildRoundedRect(bounds, Radii, builder);
		}
		let path = builder.ToPath();
		defer delete path;

		let centre = Float2(x + width * 0.5f, y + height * 0.5f);
		if (Radial)
		{
			let fill = scope VGRadialGradientFill(centre, Math.Sqrt(width * width + height * height) * 0.5f);
			AddStopsTo(ctx, fill.Stops);
			ctx.VG.FillPath(path, fill);
			return;
		}

		Float2 from = .Zero;
		Float2 to = .Zero;
		if (AngleDegrees.HasValue)
		{
			let radians = AngleDegrees.Value * (Math.PI_f / 180.0f);
			let direction = Float2(Math.Sin(radians), -Math.Cos(radians));
			let half = (Math.Abs(width * direction.X) + Math.Abs(height * direction.Y)) * 0.5f;
			from = .(centre.X - direction.X * half, centre.Y - direction.Y * half);
			to = .(centre.X + direction.X * half, centre.Y + direction.Y * half);
		}
		else
		{
			switch (Direction)
			{
			case .TopToBottom:
				from = .(x, y);
				to = .(x, y + height);
			case .LeftToRight:
				from = .(x, y);
				to = .(x + width, y);
			case .TopLeftToBottomRight:
				from = .(x, y);
				to = .(x + width, y + height);
			case .TopRightToBottomLeft:
				from = .(x + width, y);
				to = .(x, y + height);
			}
		}

		let fill = scope VGLinearGradientFill(from, to);
		AddStopsTo(ctx, fill.Stops);
		ctx.VG.FillPath(path, fill);
	}

	private void AddStopsTo(UIDrawContext ctx, List<GradientStop> outStops)
	{
		if (Stops.IsEmpty)
		{
			outStops.Add(.(0.0f, ctx.ColorOf(StartColor, StartVariable)));
			outStops.Add(.(1.0f, ctx.ColorOf(EndColor, EndVariable)));
			return;
		}
		let named = StopVariables.Count == Stops.Count;
		for (int i < Stops.Count)
		{
			let stop = Stops[i];
			outStops.Add(.(stop.Offset, named ? ctx.ColorOf(stop.Color, StopVariables[i]) : stop.Color));
		}
	}
}
