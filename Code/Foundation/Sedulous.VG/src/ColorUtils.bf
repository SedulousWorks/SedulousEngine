using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Utility functions for color interpolation
public static class ColorUtils
{
	/// Linearly interpolate between two colors
	public static Color LerpColor(Color a, Color b, float t)
	{
		return Color.Lerp(a, b, Math.Clamp(t, 0.0f, 1.0f));
	}

	/// Interpolate through gradient stops at parameter t (0-1)
	public static Color InterpolateStops(Span<GradientStop> stops, float t)
	{
		if (stops.Length == 0)
			return Color.White;

		if (stops.Length == 1)
			return stops[0].Color;

		let ct = Math.Clamp(t, 0.0f, 1.0f);

		// Before first stop
		if (ct <= stops[0].Offset)
			return stops[0].Color;

		// After last stop
		if (ct >= stops[stops.Length - 1].Offset)
			return stops[stops.Length - 1].Color;

		// Find bounding stops
		for (int i = 0; i < stops.Length - 1; i++)
		{
			if (ct >= stops[i].Offset && ct <= stops[i + 1].Offset)
			{
				let range = stops[i + 1].Offset - stops[i].Offset;
				if (range < 0.0001f)
					return stops[i].Color;
				let localT = (ct - stops[i].Offset) / range;
				return LerpColor(stops[i].Color, stops[i + 1].Color, localT);
			}
		}

		return stops[stops.Length - 1].Color;
	}
}
