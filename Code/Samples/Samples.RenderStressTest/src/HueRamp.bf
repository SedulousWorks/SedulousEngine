using Sedulous.Core;

namespace Samples.RenderStressTest;

/// A hue to a colour, for the unique material mode.
///
/// Distinct colours are not decoration here: they are how a glance tells a batched grid from
/// an unbatched one.
static class HueRamp
{
	public static Float3 HsvToRgb(float hue, float saturation, float value)
	{
		let sector = (int32)(hue * 6.0f);
		let fraction = hue * 6.0f - (float)sector;
		let p = value * (1.0f - saturation);
		let q = value * (1.0f - fraction * saturation);
		let t = value * (1.0f - (1.0f - fraction) * saturation);

		switch (sector % 6)
		{
		case 0: return .(value, t, p);
		case 1: return .(q, value, p);
		case 2: return .(p, value, t);
		case 3: return .(p, q, value);
		case 4: return .(t, p, value);
		default: return .(value, p, q);
		}
	}
}
