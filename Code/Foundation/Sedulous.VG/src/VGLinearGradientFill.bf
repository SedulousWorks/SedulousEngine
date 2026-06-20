using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Linear gradient fill between two points
public class VGLinearGradientFill : IVGFill
{
	/// Start point of the gradient line
	public Vector2 StartPoint;
	/// End point of the gradient line
	public Vector2 EndPoint;
	/// Color stops defining the gradient
	public List<GradientStop> Stops = new .() ~ delete _;

	public this(Vector2 startPoint, Vector2 endPoint)
	{
		StartPoint = startPoint;
		EndPoint = endPoint;
	}

	/// Add a color stop
	public void AddStop(float offset, Color32 color)
	{
		Stops.Add(.(offset, color));
	}

	public Color32 GetColorAt(Vector2 position, RectangleF bounds)
	{
		let gradientDir = EndPoint - StartPoint;
		let gradientLenSq = gradientDir.X * gradientDir.X + gradientDir.Y * gradientDir.Y;
		if (gradientLenSq < 0.0001f)
			return BaseColor;

		// Project position onto gradient line
		let toPoint = position - StartPoint;
		let t = (toPoint.X * gradientDir.X + toPoint.Y * gradientDir.Y) / gradientLenSq;

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
