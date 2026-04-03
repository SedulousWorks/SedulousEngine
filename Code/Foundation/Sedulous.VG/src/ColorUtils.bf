using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Utility functions for color interpolation
public static class ColorUtils
{
	/// Linearly interpolate between two colors
	public static Color LerpColor(Color a, Color b, float t)
	{
		let ct = Math.Clamp(t, 0.0f, 1.0f);
		return Color(
			(uint8)((float)a.R + ((float)b.R - (float)a.R) * ct),
			(uint8)((float)a.G + ((float)b.G - (float)a.G) * ct),
			(uint8)((float)a.B + ((float)b.B - (float)a.B) * ct),
			(uint8)((float)a.A + ((float)b.A - (float)a.A) * ct)
		);
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
