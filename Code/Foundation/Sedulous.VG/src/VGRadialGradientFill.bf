using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// A gradient outward from a centre.
class VGRadialGradientFill : IVGFill
{
	public Float2 Center = .Zero;
	public float Radius = 0.0f;
	public List<GradientStop> Stops = new .() ~ delete _;
	public VGGradientSpread Spread = .Pad;

	public this() {}

	public this(Float2 center, float radius)
	{
		Center = center;
		Radius = radius;
	}

	public void AddStop(float offset, Color color) => Stops.Add(.(offset, color));

	public Color GetColorAt(Float2 position, Rectangle bounds)
		=> SampleRamp(ColorUtils.ApplyGradientSpread(GetParameterAt(position, bounds), Spread));

	public float GetParameterAt(Float2 position, Rectangle bounds)
	{
		if (Radius < 0.0001f)
			return 0.0f;
		return Length(position - Center) / Radius;
	}

	public Color SampleRamp(float t) => ColorUtils.InterpolateStops(Stops, t);

	public Color BaseColor => Stops.IsEmpty ? Color.White : Stops[0].Color;
	public bool RequiresInterpolation => true;
	public VGGradientKind GradientKind => .Radial;
	VGGradientSpread IVGFill.Spread => Spread;

	/// The offset from the centre over the radius. The shader takes its LENGTH, which is
	/// the parameter; doing that per pixel is what stops a curved ramp from banding.
	public Float2 GradientCoord(Float2 position, Rectangle bounds)
	{
		let radius = (Radius < 0.0001f) ? 1.0f : Radius;
		return (position - Center) / radius;
	}
}
