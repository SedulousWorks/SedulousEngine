using Sedulous.Core;

namespace Sedulous.UI;

/// The colour functions a style sheet can call: lighten, darken, alpha and mix.
static class ColorFunctions
{
	/// The amount is nought to one, written as a percentage in a sheet.
	public static Color Lighten(Color color, float amount) => Palette.Lighten(color, amount);
	public static Color Darken(Color color, float amount) => Palette.Darken(color, amount);

	/// Replaces the alpha channel, leaving the colour alone.
	public static Color Alpha(Color color, float alpha) =>
		.(color.R, color.G, color.B, Clamp(alpha, 0.0f, 1.0f));

	/// A linear blend: nought is all `a`, one is all `b`.
	public static Color Mix(Color a, Color b, float t)
	{
		let f = Clamp(t, 0.0f, 1.0f);
		return .(a.R + (b.R - a.R) * f, a.G + (b.G - a.G) * f, a.B + (b.B - a.B) * f,
			a.A + (b.A - a.A) * f);
	}
}
