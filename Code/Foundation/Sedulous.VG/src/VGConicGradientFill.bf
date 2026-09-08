using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// A gradient sweeping around a centre.
///
/// It wraps inherently, so it has no spread method: every angle is already inside one turn.
class VGConicGradientFill : IVGFill
{
	public Float2 Center = .Zero;
	/// In radians.
	public float StartAngle = 0.0f;
	public List<GradientStop> Stops = new .() ~ delete _;

	public this() {}

	public this(Float2 center, float startAngle = 0.0f)
	{
		Center = center;
		StartAngle = startAngle;
	}

	public void AddStop(float offset, Color color) => Stops.Add(.(offset, color));

	/// Padded rather than wrapped, which costs nothing: the parameter is an angle over a
	/// full turn and is already inside zero to one by construction.
	public Color GetColorAt(Float2 position, Rectangle bounds)
		=> SampleRamp(ColorUtils.ApplyGradientSpread(GetParameterAt(position, bounds), .Pad));

	public float GetParameterAt(Float2 position, Rectangle bounds)
	{
		var angle = Atan2(position.Y - Center.Y, position.X - Center.X) - StartAngle;

		// Into one full turn. A loop rather than a modulo because the angle is at most one
		// turn out either way, and the loop keeps the sign handling obvious.
		while (angle < 0.0f)
			angle += TwoPi;
		while (angle >= TwoPi)
			angle -= TwoPi;

		return angle / TwoPi;
	}

	public Color SampleRamp(float t) => ColorUtils.InterpolateStops(Stops, t);

	public Color BaseColor => Stops.IsEmpty ? Color.White : Stops[0].Color;
	public bool RequiresInterpolation => true;
	public VGGradientKind GradientKind => .Conic;

	/// The offset from the centre, rotated BACK by the start angle, so the shader's own
	/// angle measurement starts where this fill says it does.
	public Float2 GradientCoord(Float2 position, Rectangle bounds)
	{
		let d = position - Center;
		let c = Cos(-StartAngle);
		let s = Sin(-StartAngle);
		return .((d.X * c) - (d.Y * s), (d.X * s) + (d.Y * c));
	}
}
