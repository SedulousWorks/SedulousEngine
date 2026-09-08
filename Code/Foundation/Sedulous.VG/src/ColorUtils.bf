using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// Interpolating along a gradient's stops.
static class ColorUtils
{
	public static Color LerpColor(Color a, Color b, float t) => Lerp(a, b, Clamp(t, 0.0f, 1.0f));

	/// The colour at parameter `t`, which is CLAMPED: a spread method has already mapped
	/// anything outside zero to one by the time this is called.
	public static Color InterpolateStops(Span<GradientStop> stops, float t)
	{
		// A gradient with no stops is white rather than an error: it is something an
		// importer produced, and a visible white is diagnosable where a crash is not.
		if (stops.IsEmpty)
			return .White;
		if (stops.Length == 1)
			return stops[0].Color;

		let clamped = Clamp(t, 0.0f, 1.0f);
		if (clamped <= stops[0].Offset)
			return stops[0].Color;
		if (clamped >= stops[stops.Length - 1].Offset)
			return stops[stops.Length - 1].Color;

		for (int i = 0; i < (stops.Length - 1); i++)
		{
			if ((clamped < stops[i].Offset) || (clamped > stops[i + 1].Offset))
				continue;

			let range = stops[i + 1].Offset - stops[i].Offset;
			// Two stops at the same offset are a HARD EDGE, which is how a gradient states
			// a colour band. Dividing by the zero range would be a NaN across the whole
			// span rather than the edge that was asked for.
			if (range < 0.0001f)
				return stops[i].Color;

			return LerpColor(stops[i].Color, stops[i + 1].Color, (clamped - stops[i].Offset) / range);
		}

		return stops[stops.Length - 1].Color;
	}

	/// Maps a raw gradient parameter through a spread method.
	///
	/// The CPU mirror of the renderer's ramp sampler address mode. The two must agree, or a
	/// gradient looks different depending on which path drew it.
	public static float ApplyGradientSpread(float t, VGGradientSpread spread)
	{
		switch (spread)
		{
		case .Repeat:
			return t - Floor(t);

		case .Reflect:
			let period = t - (2.0f * Floor(t * 0.5f));
			return (period <= 1.0f) ? period : (2.0f - period);

		case .Pad:
			return Clamp(t, 0.0f, 1.0f);
		}
	}
}
