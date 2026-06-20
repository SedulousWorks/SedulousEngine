using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Conic (angular/sweep) gradient fill around a center point
public class VGConicGradientFill : IVGFill
{
	/// Center of the gradient
	public Vector2 Center;
	/// Starting angle in radians
	public float StartAngle;
	/// Color stops defining the gradient
	public List<GradientStop> Stops = new .() ~ delete _;

	public this(Vector2 center, float startAngle = 0)
	{
		Center = center;
		StartAngle = startAngle;
	}

	/// Add a color stop
	public void AddStop(float offset, Color32 color)
	{
		Stops.Add(.(offset, color));
	}

	public Color32 GetColorAt(Vector2 position, RectangleF bounds)
	{
		let dx = position.X - Center.X;
		let dy = position.Y - Center.Y;
		var angle = (float)Math.Atan2(dy, dx) - StartAngle;

		// Normalize to 0..2PI
		while (angle < 0)
			angle += Math.PI_f * 2.0f;
		while (angle >= Math.PI_f * 2.0f)
			angle -= Math.PI_f * 2.0f;

		let t = angle / (Math.PI_f * 2.0f);

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
