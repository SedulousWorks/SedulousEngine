using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Radial gradient fill from a center point
public class VGRadialGradientFill : IVGFill
{
	/// Center of the gradient
	public Vector2 Center;
	/// Radius of the gradient
	public float Radius;
	/// Color stops defining the gradient
	public List<GradientStop> Stops = new .() ~ delete _;

	public this(Vector2 center, float radius)
	{
		Center = center;
		Radius = radius;
	}

	/// Add a color stop
	public void AddStop(float offset, Color32 color)
	{
		Stops.Add(.(offset, color));
	}

	public Color32 GetColorAt(Vector2 position, RectangleF bounds)
	{
		if (Radius < 0.0001f)
			return BaseColor;

		let dist = Vector2.Distance(position, Center);
		let t = dist / Radius;

		return ColorUtils.InterpolateStops(Stops, t);
	}

	public Color32 BaseColor
	{
		get
		{
			if (Stops.Count > 0)
				return Stops[0].Color;
			return Color32.White;
		}
	}

	public bool RequiresInterpolation => true;
}
