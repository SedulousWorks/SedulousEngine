using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// A gradient along the line between two points.
///
/// Its parameter is AFFINE, which is why it needs no per pixel shader: interpolating it
/// across a triangle gives exactly the right answer.
class VGLinearGradientFill : IVGFill
{
	public Float2 StartPoint = .Zero;
	public Float2 EndPoint = .Zero;
	public List<GradientStop> Stops = new .() ~ delete _;
	public VGGradientSpread Spread = .Pad;

	public this() {}

	public this(Float2 startPoint, Float2 endPoint)
	{
		StartPoint = startPoint;
		EndPoint = endPoint;
	}

	public void AddStop(float offset, Color color) => Stops.Add(.(offset, color));

	public Color GetColorAt(Float2 position, Rectangle bounds)
		=> SampleRamp(ColorUtils.ApplyGradientSpread(GetParameterAt(position, bounds), Spread));

	/// The projection of the point onto the gradient line, normalised by its length.
	public float GetParameterAt(Float2 position, Rectangle bounds)
	{
		let direction = EndPoint - StartPoint;
		let lengthSquared = (direction.X * direction.X) + (direction.Y * direction.Y);
		// A degenerate gradient is one colour rather than a division by zero.
		if (lengthSquared < 0.0001f)
			return 0.0f;

		let toPoint = position - StartPoint;
		return ((toPoint.X * direction.X) + (toPoint.Y * direction.Y)) / lengthSquared;
	}

	public Color SampleRamp(float t) => ColorUtils.InterpolateStops(Stops, t);

	public Color BaseColor => Stops.IsEmpty ? Color.White : Stops[0].Color;
	public bool RequiresInterpolation => true;
	public VGGradientKind GradientKind => .Linear;
	VGGradientSpread IVGFill.Spread => Spread;
	public Float2 GradientCoord(Float2 position, Rectangle bounds) => .Zero;
}
